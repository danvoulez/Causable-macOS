import XCTest
@testable import CausableSDK

final class UtilsTests: XCTestCase {
    
    func testCanonicalJSONEncoding() throws {
        struct TestStruct: Codable {
            let z: String
            let a: String
            let m: String
        }
        
        let test = TestStruct(z: "last", a: "first", m: "middle")
        let encoder = JSONEncoder.causableCanonical
        let data = try encoder.encode(test)
        let json = String(data: data, encoding: .utf8)!
        
        // Keys should be sorted
        XCTAssertTrue(json.starts(with: "{\"a\":"))
        XCTAssertTrue(json.contains("\"m\":"))
        XCTAssertTrue(json.contains("\"z\":"))
    }
    
    func testDigestComputation() {
        let data = "test".data(using: .utf8)!
        let digest = DigestUtils.computeDigest(data)
        
        XCTAssertTrue(digest.starts(with: "b3:"))
        XCTAssertEqual(digest.count, 3 + 64) // "b3:" + 64 hex chars for SHA256
    }
    
    func testDigestDeterministic() {
        let data = "test".data(using: .utf8)!
        let digest1 = DigestUtils.computeDigest(data)
        let digest2 = DigestUtils.computeDigest(data)
        
        XCTAssertEqual(digest1, digest2)
    }
    
    func testHexStringConversion() {
        let data = Data([0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF])
        let hex = data.hexString
        
        XCTAssertEqual(hex, "0123456789abcdef")
    }
    
    func testHexStringRoundTrip() {
        let original = Data([0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF])
        let hex = original.hexString
        let restored = Data(hexString: hex)
        
        XCTAssertEqual(original, restored)
    }
    
    func testInvalidHexString() {
        let invalid = Data(hexString: "zzz")
        XCTAssertNil(invalid)
        
        let oddLength = Data(hexString: "123")
        XCTAssertNil(oddLength)
    }
}
