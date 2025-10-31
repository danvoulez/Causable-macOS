import Foundation
import SQLite

/// Errors that can occur during outbox operations
public enum OutboxError: Error {
    case databaseError(String)
    case encodingError
    case decodingError
    case notFound
}

/// Represents a span in the outbox queue
public struct OutboxEntry: Sendable {
    public let id: String
    public let digest: String
    public let spanJson: String
    public let tries: Int
    public let nextAttemptAt: Date
    
    public init(id: String, digest: String, spanJson: String, tries: Int = 0, nextAttemptAt: Date = Date()) {
        self.id = id
        self.digest = digest
        self.spanJson = spanJson
        self.tries = tries
        self.nextAttemptAt = nextAttemptAt
    }
}

/// Configuration constants for outbox retry behavior
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
            t.column(tries)
            t.column(nextAttemptAt)
        })
        
        // Create index on next_attempt_at for efficient scheduling
        try db.run(outbox.createIndex(nextAttemptAt, ifNotExists: true))
    }
    
    /// Add a span to the outbox
    public func enqueue(span: SpanEnvelope) throws {
        let encoder = JSONEncoder.causableCanonical
        guard let spanData = try? encoder.encode(span),
              let jsonString = String(data: spanData, encoding: .utf8) else {
            throw OutboxError.encodingError
        }
        
        let digest = span.digest ?? DigestUtils.computeDigest(spanData)
        
        let insert = outbox.insert(
            self.id <- span.id,
            self.digest <- digest,
            self.spanJson <- jsonString,
            self.tries <- 0,
            self.nextAttemptAt <- Date()
        )
        
        do {
            try db.run(insert)
        } catch {
            throw OutboxError.databaseError("Failed to enqueue span: \(error)")
        }
    }
    
    /// Get the next span that should be attempted
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
    
    /// Mark a span as successfully sent and remove from outbox
    public func markSent(id: String) throws {
        let entry = outbox.filter(self.id == id)
        let deleted = try db.run(entry.delete())
        
        if deleted == 0 {
            throw OutboxError.notFound
        }
    }
    
    /// Mark a span as failed and schedule retry with exponential backoff
    public func markFailed(id: String, error: Error) throws {
        let entry = outbox.filter(self.id == id)
        
        guard let row = try db.pluck(entry) else {
            throw OutboxError.notFound
        }
        
        let currentTries = row[tries]
        let newTries = currentTries + 1
        
        // Exponential backoff: 1min, 2min, 4min, 8min, 16min, capped at 30min
        let backoffSeconds = min(
            pow(2.0, Double(newTries)) * OutboxConfig.baseBackoffSeconds,
            OutboxConfig.maxBackoffSeconds
        )
        let nextAttempt = Date().addingTimeInterval(backoffSeconds)
        
        try db.run(entry.update(
            self.tries <- newTries,
            self.nextAttemptAt <- nextAttempt
        ))
    }
    
    /// Get the current size of the outbox
    public func count() throws -> Int {
        return try db.scalar(outbox.count)
    }
    
    /// Clear all entries from the outbox (for testing)
    public func clear() throws {
        try db.run(outbox.delete())
    }
}
