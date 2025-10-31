import XCTest
@testable import CausableSDK

/// Integration tests demonstrating end-to-end SDK usage
final class IntegrationTests: XCTestCase {
    
    func testEndToEndSpanCreationSigningAndOutbox() throws {
        // 1. Create a signer
        let signer = Ed25519Signer()
        
        // 2. Create an outbox
        let outbox = try OutboxStore() // In-memory
        
        // 3. Create a span
        let metadata = SpanMetadata(
            tenantId: "tenant-123",
            ownerId: "owner-456",
            deviceId: "device-789",
            ts: "2025-10-31T18:00:00Z"
        )
        
        var span = SpanEnvelope(
            id: "span-integration-001",
            entityType: "activity",
            who: "observer:menubar@1.0.0",
            did: "focused",
            this: "device:test-device",
            status: "complete",
            input: nil,
            output: nil,
            metadata: metadata,
            visibility: "private"
        )
        
        // 4. Sign the span
        let encoder = JSONEncoder.causableCanonical
        let canonical = try encoder.encode(span)
        let digestBytes = DigestUtils.computeDigestBytes(canonical)
        let digestHex = DigestUtils.computeDigest(canonical)
        let sig = try signer.sign(digestBytes)
        let pubkey = try signer.publicKeyHex()
        
        span.digest = digestHex
        span.signature = Signature(
            algo: "ed25519",
            pubkey: pubkey,
            sig: sig.hexString
        )
        
        // 5. Verify the span is properly signed
        XCTAssertNotNil(span.digest)
        XCTAssertNotNil(span.signature)
        XCTAssertTrue(span.digest!.starts(with: "b3:"))
        XCTAssertEqual(span.signature?.algo, "ed25519")
        
        // 6. Store in outbox
        try outbox.enqueue(span: span)
        XCTAssertEqual(try outbox.count(), 1)
        
        // 7. Retrieve from outbox
        let entry = try outbox.nextAttempt()
        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.id, span.id)
        XCTAssertEqual(entry?.digest, span.digest)
        
        // 8. Simulate successful send
        try outbox.markSent(id: span.id)
        XCTAssertEqual(try outbox.count(), 0)
    }
    
    func testClientInitialization() throws {
        // Verify that the client can be initialized with all required components
        let signer = Ed25519Signer()
        let outbox = try OutboxStore()
        
        let baseURL = URL(string: "https://api.example.com")!
        let tokenProvider: () -> String = { "test-token" }
        
        let client = CausableClient(
            baseURL: baseURL,
            tokenProvider: tokenProvider,
            signer: signer,
            outbox: outbox
        )
        
        // Client should be successfully initialized
        XCTAssertNotNil(client)
    }
    
    func testSpanCanonicalEncoding() throws {
        // Verify that two identical spans produce the same canonical encoding
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
        
        let span2 = SpanEnvelope(
            id: "span-001",
            entityType: "activity",
            who: "test",
            did: "test",
            this: "test",
            status: "complete",
            metadata: metadata,
            visibility: "private"
        )
        
        let encoder = JSONEncoder.causableCanonical
        let data1 = try encoder.encode(span1)
        let data2 = try encoder.encode(span2)
        
        XCTAssertEqual(data1, data2)
        
        let digest1 = DigestUtils.computeDigest(data1)
        let digest2 = DigestUtils.computeDigest(data2)
        
        XCTAssertEqual(digest1, digest2)
    }
}
