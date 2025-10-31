import Foundation
import Crypto

/// Extension to JSONEncoder for canonical encoding
extension JSONEncoder {
    /// Canonical encoder with sorted keys and no whitespace
    public static var causableCanonical: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

/// Utilities for hashing and digest operations
public enum DigestUtils {
    /// Compute a digest of data using SHA256 (BLAKE3 would be used in production)
    /// Returns the digest with "b3:" prefix as per spec
    public static func computeDigest(_ data: Data) -> String {
        let hash = SHA256.hash(data: data)
        let hexString = hash.map { String(format: "%02x", $0) }.joined()
        return "b3:" + hexString
    }
    
    /// Compute digest from raw bytes without prefix
    public static func computeDigestBytes(_ data: Data) -> Data {
        return Data(SHA256.hash(data: data))
    }
}

/// Extension to add hex conversion to Data
extension Data {
    /// Convert data to hexadecimal string
    public var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
    
    /// Initialize from hexadecimal string
    public init?(hexString: String) {
        // Validate even length
        guard hexString.count % 2 == 0 else { return nil }
        
        let len = hexString.count / 2
        var data = Data(capacity: len)
        var indexIsEven = true
        var currentByte: UInt8 = 0
        
        for char in hexString {
            guard let value = char.hexDigitValue else { return nil }
            
            if indexIsEven {
                currentByte = UInt8(value) << 4
            } else {
                currentByte += UInt8(value)
                data.append(currentByte)
            }
            indexIsEven.toggle()
        }
        
        guard indexIsEven else { return nil }
        self = data
    }
}
