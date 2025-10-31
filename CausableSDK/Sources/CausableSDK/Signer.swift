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
// MARK: - Span Signer Protocol

public protocol SpanSigner {
    func publicKeyHex() throws -> String
    func sign(_ digest: Data) throws -> Data
}

// MARK: - Ed25519 Signer Implementation

public final class Ed25519Signer: SpanSigner {
    private let privateKey: Curve25519.Signing.PrivateKey
    
    public init() throws {
        self.privateKey = Curve25519.Signing.PrivateKey()
    }
    
    public init(privateKeyData: Data) throws {
        self.privateKey = try Curve25519.Signing.PrivateKey(rawRepresentation: privateKeyData)
    }
    
    public func publicKeyHex() throws -> String {
        return privateKey.publicKey.rawRepresentation.hexString
    }
    
    public func sign(_ digest: Data) throws -> Data {
        return try privateKey.signature(for: digest)
    }
    
    /// Get the raw representation of the private key for storage
    public func rawPrivateKey() -> Data {
    public func privateKeyData() -> Data {
        return privateKey.rawRepresentation
    }
}

/// Error types for signing operations
public enum SignerError: Error {
    case invalidKeyFormat
    case signingFailed
    case publicKeyExtractionFailed
// MARK: - Keychain Storage

public enum KeychainError: Error {
    case unableToStore
    case unableToRetrieve
    case notFound
    case invalidData
}

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
public final class KeychainSigner: SpanSigner {
    private let service: String
    private let account: String
    private let signer: Ed25519Signer
    
    public init(service: String = "dev.causable.mac", account: String = "device-key") throws {
        self.service = service
        self.account = account
        
        // Try to load existing key from keychain
        if let keyData = try? Self.loadKey(service: service, account: account) {
            self.signer = try Ed25519Signer(privateKeyData: keyData)
        } else {
            // Generate new key and store it
            self.signer = try Ed25519Signer()
            try Self.saveKey(signer.privateKeyData(), service: service, account: account)
        }
    }
    
    public func publicKeyHex() throws -> String {
        return try signer.publicKeyHex()
    }
    
    public func sign(_ digest: Data) throws -> Data {
        return try signer.sign(digest)
    }
    
    private static func saveKey(_ keyData: Data, service: String, account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unableToStore
        }
    }
    
    private static func loadKey(service: String, account: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.notFound
            }
            throw KeychainError.unableToRetrieve
        }
        
        guard let keyData = result as? Data else {
            throw KeychainError.invalidData
        }
        
        return keyData
    }
}
#endif

// MARK: - Data Extension

extension Data {
    var hexString: String {
        return map { String(format: "%02x", $0) }.joined()
    }
    
    init?(hexString: String) {
        let len = hexString.count / 2
        var data = Data(capacity: len)
        var index = hexString.startIndex
        for _ in 0..<len {
            let nextIndex = hexString.index(index, offsetBy: 2)
            guard let byte = UInt8(hexString[index..<nextIndex], radix: 16) else {
                return nil
            }
            data.append(byte)
            index = nextIndex
        }
        self = data
    }
}
