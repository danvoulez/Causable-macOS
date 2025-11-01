import Foundation
import SQLite

/// Errors that can occur during outbox operations
public enum OutboxError: Error {
    case databaseError(String)
    case encodingError
    case decodingError
    case notFound
}

/// Represents an entry in the outbox
public struct OutboxEntry {
    public let id: String
    public let digest: String
    public let spanJson: String
    public let tries: Int
    public let nextAttemptAt: Date
    
    public init(id: String, digest: String, spanJson: String, tries: Int, nextAttemptAt: Date) {
        self.id = id
        self.digest = digest
        self.spanJson = spanJson
        self.tries = tries
        self.nextAttemptAt = nextAttemptAt
    }
}

private enum OutboxConfig {
    /// Base backoff time in seconds
    static let baseBackoffSeconds: Double = 60.0
    /// Maximum backoff time in seconds (30 minutes)
    static let maxBackoffSeconds: Double = 30.0 * 60.0
}

/// SQLite-backed persistent outbox for spans awaiting upload
public final class OutboxStore: @unchecked Sendable {
    private let db: Connection
    
    // Table definition
    private let outbox = Table("outbox")
    private let id = Expression<String>("id")
    private let digest = Expression<String>("digest")
    private let spanJson = Expression<String>("span_json")
    private let tries = Expression<Int>("tries")
    private let nextAttemptAt = Expression<Date>("next_attempt_at")
    
    /// Initialize the outbox store with a database file path
    public init(path: String) throws {
        do {
            db = try Connection(path)
            try createTableIfNeeded()
        } catch {
            throw OutboxError.databaseError("Failed to initialize database: \(error)")
        }
    }
    
    /// Initialize with an in-memory database (for testing)
    public convenience init() throws {
        try self.init(path: ":memory:")
    }
    
    private func createTableIfNeeded() throws {
        try db.run(outbox.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(digest, unique: true)
            t.column(spanJson)
            t.column(tries, defaultValue: 0)
            t.column(nextAttemptAt, defaultValue: Date())
        })
        
        // Create index on next_attempt_at for efficient querying
        try db.run(outbox.createIndex(nextAttemptAt, ifNotExists: true))
    }
    
    /// Enqueue a span for upload
    public func enqueue(span: SpanEnvelope) throws {
        let encoder = JSONEncoder.causableCanonical
        guard let json = try? encoder.encode(span),
              let jsonString = String(data: json, encoding: .utf8) else {
            throw OutboxError.encodingError
        }
        
        // Use the span's existing digest if available, otherwise compute one
        let digestValue = span.digest ?? DigestUtils.computeDigest(json)
        
        do {
            try db.run(outbox.insert(
                id <- span.id,
                digest <- digestValue,
                spanJson <- jsonString,
                tries <- 0,
                nextAttemptAt <- Date()
            ))
        } catch {
            throw OutboxError.databaseError("Failed to enqueue: \(error)")
        }
    }
    
    /// Get the next span ready for upload attempt
    public func nextAttempt() throws -> OutboxEntry? {
        let now = Date()
        let query = outbox
            .filter(nextAttemptAt <= now)
            .order(nextAttemptAt.asc)
            .limit(1)
        
        guard let row = try db.pluck(query) else {
            return nil
        }
        
        return OutboxEntry(
            id: row[id],
            digest: row[digest],
            spanJson: row[spanJson],
            tries: row[tries],
            nextAttemptAt: row[nextAttemptAt]
        )
    }
    
    /// Mark a span as successfully sent (removes from outbox)
    public func markSent(id spanId: String) throws {
        let entry = outbox.filter(id == spanId)
        do {
            try db.run(entry.delete())
        } catch {
            throw OutboxError.databaseError("Failed to delete: \(error)")
        }
    }
    
    /// Mark a span upload as failed, schedule retry with exponential backoff
    public func markFailed(id spanId: String, error: Error) throws {
        let entry = outbox.filter(id == spanId)
        
        guard let row = try db.pluck(entry) else {
            throw OutboxError.notFound
        }
        
        let currentTries = row[tries]
        let newTries = currentTries + 1
        
        // Calculate backoff with exponential growth
        let backoffSeconds = min(
            OutboxConfig.baseBackoffSeconds * pow(2.0, Double(newTries - 1)),
            OutboxConfig.maxBackoffSeconds
        )
        
        // Add jitter (±20%)
        let jitter = Double.random(in: 0.8...1.2)
        let finalBackoff = backoffSeconds * jitter
        
        let nextAttempt = Date().addingTimeInterval(finalBackoff)
        
        do {
            try db.run(entry.update(
                tries <- newTries,
                nextAttemptAt <- nextAttempt
            ))
        } catch {
            throw OutboxError.databaseError("Failed to update: \(error)")
        }
    }
    
    /// Get the number of pending spans in the outbox
    public func count() throws -> Int {
        return try db.scalar(outbox.count)
    }
    
    /// Clear all entries from the outbox (for testing)
    public func clear() throws {
        try db.run(outbox.delete())
    }
}
