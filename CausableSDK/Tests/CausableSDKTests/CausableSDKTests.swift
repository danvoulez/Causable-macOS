import XCTest
@testable import CausableSDK

final class CausableSDKTests: XCTestCase {
    
    // MARK: - Envelope Tests
    
    func testSpanEnvelopeEncoding() throws {
        let metadata = SpanEnvelope.Metadata(
            tenantId: "tenant-123",
            ownerId: "owner-456",
            deviceId: "device-789",
            ts: "2024-01-01T00:00:00Z"
        )
        
        let span = SpanEnvelope(
            id: "test-id",
            entityType: "activity",
            who: "observer:menubar@1.0.0",
            did: "focused",
            this: "device:test",
            status: "complete",
            input: [:],
            output: [:],
            metadata: metadata,
            visibility: "private"
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(span)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SpanEnvelope.self, from: data)
        
        XCTAssertEqual(span.id, decoded.id)
        XCTAssertEqual(span.entityType, decoded.entityType)
        XCTAssertEqual(span.who, decoded.who)
        XCTAssertEqual(span.did, decoded.did)
        XCTAssertEqual(span.status, decoded.status)
    }
    
    // MARK: - Signer Tests
    
    func testEd25519SignerGeneration() throws {
        let signer = try Ed25519Signer()
        let pubkey = try signer.publicKeyHex()
        
        XCTAssertEqual(pubkey.count, 64) // 32 bytes in hex
    }
    
    func testEd25519Signing() throws {
        let signer = try Ed25519Signer()
        let message = "test message".data(using: .utf8)!
        
        let signature = try signer.sign(message)
        
        XCTAssertEqual(signature.count, 64) // Ed25519 signature is 64 bytes
    }
    
    func testSignerPersistence() throws {
        let signer1 = try Ed25519Signer()
        let privateKey = signer1.privateKeyData()
        
        let signer2 = try Ed25519Signer(privateKeyData: privateKey)
        
        XCTAssertEqual(try signer1.publicKeyHex(), try signer2.publicKeyHex())
    }
    
    // MARK: - Outbox Tests
    
    func testOutboxEnqueueAndRetrieve() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("test-\(UUID().uuidString).db").path
        
        let outbox = try OutboxStore(path: dbPath)
        
        try outbox.enqueue(spanId: "span-1", digest: "digest-1", spanJson: "{\"test\":1}")
        
        let item = try outbox.nextAttempt()
        XCTAssertNotNil(item)
        XCTAssertEqual(item?.id, "span-1")
        XCTAssertEqual(item?.spanJson, "{\"test\":1}")
        
        try FileManager.default.removeItem(atPath: dbPath)
    }
    
    func testOutboxMarkSuccess() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("test-\(UUID().uuidString).db").path
        
        let outbox = try OutboxStore(path: dbPath)
        
        try outbox.enqueue(spanId: "span-1", digest: "digest-1", spanJson: "{\"test\":1}")
        try outbox.markSuccess(spanId: "span-1")
        
        let item = try outbox.nextAttempt()
        XCTAssertNil(item)
        
        try FileManager.default.removeItem(atPath: dbPath)
    }
    
    func testOutboxMarkFailure() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("test-\(UUID().uuidString).db").path
        
        let outbox = try OutboxStore(path: dbPath)
        
        try outbox.enqueue(spanId: "span-1", digest: "digest-1", spanJson: "{\"test\":1}")
        
        // Should be available immediately
        var item = try outbox.nextAttempt()
        XCTAssertNotNil(item)
        
        // Mark as failed - should schedule for future
        try outbox.markFailure(spanId: "span-1", backoffSeconds: 60)
        
        // Should not be available immediately
        item = try outbox.nextAttempt()
        XCTAssertNil(item)
        
        try FileManager.default.removeItem(atPath: dbPath)
    }
    
    func testOutboxPendingCount() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("test-\(UUID().uuidString).db").path
        
        let outbox = try OutboxStore(path: dbPath)
        
        XCTAssertEqual(try outbox.pendingCount(), 0)
        
        try outbox.enqueue(spanId: "span-1", digest: "digest-1", spanJson: "{\"test\":1}")
        try outbox.enqueue(spanId: "span-2", digest: "digest-2", spanJson: "{\"test\":2}")
        
        XCTAssertEqual(try outbox.pendingCount(), 2)
        
        try outbox.markSuccess(spanId: "span-1")
        
        XCTAssertEqual(try outbox.pendingCount(), 1)
        
        try FileManager.default.removeItem(atPath: dbPath)
    }
    
    // MARK: - Data Extension Tests
    
    func testHexStringConversion() {
        let data = Data([0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF])
        let hexString = data.hexString
        
        XCTAssertEqual(hexString, "0123456789abcdef")
        
        let convertedBack = Data(hexString: hexString)
        XCTAssertEqual(data, convertedBack)
    }
}
