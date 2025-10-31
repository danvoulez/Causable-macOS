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
// MARK: - Outbox Store

public final class OutboxStore {
    private let db: Connection
    
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
    private let kv = Table("kv")
    private let key = Expression<String>("key")
    private let valueJson = Expression<String>("value_json")
    
    public init(path: String) throws {
        self.db = try Connection(path)
        try createTables()
    }
    
    private func createTables() throws {
        try db.run(outbox.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(digest, unique: true)
            t.column(spanJson)
            t.column(tries, defaultValue: 0)
            t.column(nextAttemptAt)
        })
        
        try db.run(outbox.createIndex(nextAttemptAt, ifNotExists: true))
        
        try db.run(kv.create(ifNotExists: true) { t in
            t.column(key, primaryKey: true)
            t.column(valueJson)
        })
    }
    
    public func enqueue(spanId: String, digest: String, spanJson: String) throws {
        let row = outbox.insert(
            self.id <- spanId,
            self.digest <- digest,
            self.spanJson <- spanJson,
            self.tries <- 0,
            self.nextAttemptAt <- Date()
        )
        try db.run(row)
    }
    
    public func nextAttempt() throws -> (id: String, spanJson: String)? {
        let now = Date()
        let query = outbox
            .filter(nextAttemptAt <= now)
            .order(nextAttemptAt.asc)
            .limit(1)
        
        guard let row = try db.pluck(query) else {
            return nil
        }
        
        return (id: row[id], spanJson: row[spanJson])
    }
    
    public func markSuccess(spanId: String) throws {
        let item = outbox.filter(id == spanId)
        try db.run(item.delete())
    }
    
    public func markFailure(spanId: String, backoffSeconds: TimeInterval = 60) throws {
        let item = outbox.filter(id == spanId)
        
        guard let row = try db.pluck(item) else {
            return
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
        // Exponential backoff with jitter and max 30 minutes
        let baseBackoff = min(backoffSeconds * pow(2.0, Double(newTries)), 1800)
        let jitter = Double.random(in: 0...0.3) * baseBackoff
        let nextAttempt = Date().addingTimeInterval(baseBackoff + jitter)
        
        try db.run(item.update(
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
    public func pendingCount() throws -> Int {
        return try db.scalar(outbox.count)
    }
    
    // MARK: - Key-Value Store
    
    public func setValue(_ value: String, forKey key: String) throws {
        let row = kv.filter(self.key == key)
        if try db.pluck(row) != nil {
            try db.run(row.update(self.valueJson <- value))
        } else {
            try db.run(kv.insert(self.key <- key, self.valueJson <- value))
        }
    }
    
    public func getValue(forKey key: String) throws -> String? {
        let row = kv.filter(self.key == key)
        return try db.pluck(row)?[valueJson]
    }
}
