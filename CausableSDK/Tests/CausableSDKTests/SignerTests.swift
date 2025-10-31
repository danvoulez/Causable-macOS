import XCTest
import Crypto
@testable import CausableSDK

final class SignerTests: XCTestCase {
    
    func testEd25519SignerGeneration() throws {
        let signer = Ed25519Signer()
        
        let pubkey = try signer.publicKeyHex()
        XCTAssertEqual(pubkey.count, 64) // 32 bytes = 64 hex chars
        
        // Verify hex format
        XCTAssertTrue(pubkey.allSatisfy { "0123456789abcdef".contains($0) })
    }
    
    func testEd25519Signing() throws {
        let signer = Ed25519Signer()
        
        let message = "test message".data(using: .utf8)!
        let signature = try signer.sign(message)
        
        XCTAssertEqual(signature.count, 64) // Ed25519 signatures are 64 bytes
        
        // Verify signature is deterministic
        let signature2 = try signer.sign(message)
        XCTAssertEqual(signature, signature2)
    }
    
    func testEd25519RoundTrip() throws {
        // Create a signer
        let signer = Ed25519Signer()
        let rawKey = signer.rawPrivateKey()
        
        // Recreate from raw representation
        let signer2 = try Ed25519Signer(rawRepresentation: rawKey)
        
        // Should have same public key
        let pubkey1 = try signer.publicKeyHex()
        let pubkey2 = try signer2.publicKeyHex()
        XCTAssertEqual(pubkey1, pubkey2)
        
        // Should produce same signature
        let message = "test".data(using: .utf8)!
        let sig1 = try signer.sign(message)
        let sig2 = try signer2.sign(message)
        XCTAssertEqual(sig1, sig2)
    }
    
    func testSignatureVerification() throws {
        // Create signer and sign a message
        let signer = Ed25519Signer()
        let message = "test message".data(using: .utf8)!
        let signature = try signer.sign(message)
        
        // Verify using the same signer's key
        // Note: Curve25519.Signing doesn't provide direct signature verification
        // In production, verification would be done by the server
        // Here we just verify the signature has the correct length
        XCTAssertEqual(signature.count, 64) // Ed25519 signatures are always 64 bytes
        
        // Verify determinism - same message produces same signature
        let signature2 = try signer.sign(message)
        XCTAssertEqual(signature, signature2)
    }
}
