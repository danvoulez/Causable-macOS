import Foundation
import Crypto

/// Protocol for signing span digests
public protocol SpanSigner: Sendable {
    /// Returns the public key in hexadecimal format
    func publicKeyHex() throws -> String
    
    /// Signs the given digest and returns the signature
    func sign(_ digest: Data) throws -> Data
}

/// Ed25519 signer implementation using CryptoKit
public final class Ed25519Signer: SpanSigner, @unchecked Sendable {
    private let privateKey: Curve25519.Signing.PrivateKey
    
    /// Initialize with an existing private key
    public init(privateKey: Curve25519.Signing.PrivateKey) {
        self.privateKey = privateKey
    }
    
    /// Initialize by generating a new key pair
    public convenience init() {
        self.init(privateKey: Curve25519.Signing.PrivateKey())
    }
    
    /// Initialize from a raw private key representation
    public convenience init(rawRepresentation: Data) throws {
        let key = try Curve25519.Signing.PrivateKey(rawRepresentation: rawRepresentation)
        self.init(privateKey: key)
    }
    
    public func publicKeyHex() throws -> String {
        return privateKey.publicKey.rawRepresentation.map { String(format: "%02x", $0) }.joined()
    }
    
    public func sign(_ digest: Data) throws -> Data {
        return try privateKey.signature(for: digest)
    }
    
    /// Get the raw representation of the private key for storage
    public func rawPrivateKey() -> Data {
        return privateKey.rawRepresentation
    }
}

/// Error types for signing operations
public enum SignerError: Error {
    case invalidKeyFormat
    case signingFailed
    case publicKeyExtractionFailed
}
