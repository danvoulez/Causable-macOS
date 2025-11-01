import Foundation
import Crypto

#if os(macOS)
import Security

/// Ed25519 signer that stores keys in the macOS Keychain
public final class KeychainSigner: SpanSigner, @unchecked Sendable {
    private let privateKey: Curve25519.Signing.PrivateKey
    private let keychainTag = "dev.causable.signing-key"
    
    /// Initialize by loading or creating a key in the Keychain
    public init() throws {
        if let existingKey = try? KeychainSigner.loadKeyFromKeychain() {
            self.privateKey = existingKey
        } else {
            // Generate new key and store in Keychain
            let newKey = Curve25519.Signing.PrivateKey()
            try KeychainSigner.saveKeyToKeychain(newKey)
            self.privateKey = newKey
        }
    }
    
    public func publicKeyHex() throws -> String {
        return privateKey.publicKey.rawRepresentation.hexString
    }
    
    public func sign(_ digest: Data) throws -> Data {
        return try privateKey.signature(for: digest)
    }
    
    /// Get the raw private key representation
    public func rawPrivateKey() -> Data {
        return privateKey.rawRepresentation
    }
    
    // MARK: - Keychain Operations
    
    private static func saveKeyToKeychain(_ key: Curve25519.Signing.PrivateKey) throws {
        let tag = "dev.causable.signing-key".data(using: .utf8)!
        let keyData = key.rawRepresentation
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: tag,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        // Delete any existing key first
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw OutboxError.databaseError("Failed to save key to Keychain: \(status)")
        }
    }
    
    private static func loadKeyFromKeychain() throws -> Curve25519.Signing.PrivateKey {
        let tag = "dev.causable.signing-key".data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: tag,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            throw OutboxError.databaseError("Key not found in Keychain")
        }
        
        guard let keyData = result as? Data else {
            throw OutboxError.databaseError("Invalid key data")
        }
        
        return try Curve25519.Signing.PrivateKey(rawRepresentation: keyData)
    }
}
#endif
