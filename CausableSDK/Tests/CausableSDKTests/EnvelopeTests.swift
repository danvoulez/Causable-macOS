import XCTest
@testable import CausableSDK

final class EnvelopeTests: XCTestCase {
    
    func testSpanEnvelopeEncoding() throws {
        let metadata = SpanMetadata(
            tenantId: "tenant-123",
            ownerId: "owner-456",
            deviceId: "device-789",
            ts: "2025-10-31T18:00:00Z"
        )
        
        let span = SpanEnvelope(
            id: "span-001",
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
        
        let encoder = JSONEncoder.causableCanonical
        let data = try encoder.encode(span)
        let json = String(data: data, encoding: .utf8)!
        
        XCTAssertTrue(json.contains("\"entity_type\":\"activity\""))
        XCTAssertTrue(json.contains("\"visibility\":\"private\""))
        
        // Test decoding
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SpanEnvelope.self, from: data)
        XCTAssertEqual(decoded.id, span.id)
        XCTAssertEqual(decoded.entityType, span.entityType)
        XCTAssertEqual(decoded.metadata.tenantId, span.metadata.tenantId)
    }
    
    func testAnyCodableEncoding() throws {
        let dict: [String: AnyCodable] = [
            "string": AnyCodable("test"),
            "number": AnyCodable(42),
            "bool": AnyCodable(true),
            "array": AnyCodable([1, 2, 3])
        ]
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(dict)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode([String: AnyCodable].self, from: data)
        
        XCTAssertEqual(decoded.count, 4)
    }
    
    func testSignatureEncoding() throws {
        let sig = Signature(
            algo: "ed25519",
            pubkey: "abc123",
            sig: "def456"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(sig)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Signature.self, from: data)
        
        XCTAssertEqual(decoded.algo, sig.algo)
        XCTAssertEqual(decoded.pubkey, sig.pubkey)
        XCTAssertEqual(decoded.sig, sig.sig)
    }
}
