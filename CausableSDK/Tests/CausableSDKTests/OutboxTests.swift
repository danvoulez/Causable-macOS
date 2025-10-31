import XCTest
@testable import CausableSDK

final class OutboxTests: XCTestCase {
    
    var outbox: OutboxStore!
    
    override func setUp() async throws {
        outbox = try OutboxStore() // In-memory database
    }
    
    override func tearDown() async throws {
        try? outbox.clear()
        outbox = nil
    }
    
    func testEnqueueSpan() throws {
        let metadata = SpanMetadata(ts: "2025-10-31T18:00:00Z")
        let span = SpanEnvelope(
            id: "span-001",
            entityType: "activity",
            who: "test",
            did: "test",
            this: "test",
            status: "complete",
            metadata: metadata,
            visibility: "private"
        )
        
        try outbox.enqueue(span: span)
        
        let count = try outbox.count()
        XCTAssertEqual(count, 1)
    }
    
    func testNextAttempt() throws {
        let metadata = SpanMetadata(ts: "2025-10-31T18:00:00Z")
        let span = SpanEnvelope(
            id: "span-001",
            entityType: "activity",
            who: "test",
            did: "test",
            this: "test",
            status: "complete",
            metadata: metadata,
            visibility: "private"
        )
        
        try outbox.enqueue(span: span)
        
        let entry = try outbox.nextAttempt()
        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.id, "span-001")
        XCTAssertEqual(entry?.tries, 0)
    }
    
    func testMarkSent() throws {
        let metadata = SpanMetadata(ts: "2025-10-31T18:00:00Z")
        let span = SpanEnvelope(
            id: "span-001",
            entityType: "activity",
            who: "test",
            did: "test",
            this: "test",
            status: "complete",
            metadata: metadata,
            visibility: "private"
        )
        
        try outbox.enqueue(span: span)
        XCTAssertEqual(try outbox.count(), 1)
        
        try outbox.markSent(id: "span-001")
        XCTAssertEqual(try outbox.count(), 0)
    }
    
    func testMarkFailed() throws {
        let metadata = SpanMetadata(ts: "2025-10-31T18:00:00Z")
        let span = SpanEnvelope(
            id: "span-001",
            entityType: "activity",
            who: "test",
            did: "test",
            this: "test",
            status: "complete",
            metadata: metadata,
            visibility: "private"
        )
        
        try outbox.enqueue(span: span)
        
        let entry1 = try outbox.nextAttempt()
        XCTAssertEqual(entry1?.tries, 0)
        
        try outbox.markFailed(id: "span-001", error: NSError(domain: "test", code: 1))
        
        // Entry should still exist but with incremented tries
        XCTAssertEqual(try outbox.count(), 1)
        
        // The next attempt time should be in the future, so nextAttempt() should return nil now
        let entry2 = try outbox.nextAttempt()
        XCTAssertNil(entry2) // Should be nil because nextAttemptAt is in the future
    }
    
    func testExponentialBackoff() throws {
        let metadata = SpanMetadata(ts: "2025-10-31T18:00:00Z")
        let span = SpanEnvelope(
            id: "span-001",
            entityType: "activity",
            who: "test",
            did: "test",
            this: "test",
            status: "complete",
            metadata: metadata,
            visibility: "private"
        )
        
        try outbox.enqueue(span: span)
        
        // Simulate multiple failures
        for i in 0..<5 {
            try outbox.markFailed(id: "span-001", error: NSError(domain: "test", code: 1))
        }
        
        // Entry should still exist
        XCTAssertEqual(try outbox.count(), 1)
    }
    
    func testUniquenessConstraint() throws {
        let metadata = SpanMetadata(ts: "2025-10-31T18:00:00Z")
        let span1 = SpanEnvelope(
            id: "span-001",
            entityType: "activity",
            who: "test",
            did: "test",
            this: "test",
            status: "complete",
            metadata: metadata,
            visibility: "private"
        )
        
        try outbox.enqueue(span: span1)
        
        // Trying to enqueue the same span again should fail due to unique digest
        XCTAssertThrowsError(try outbox.enqueue(span: span1))
    }
}
