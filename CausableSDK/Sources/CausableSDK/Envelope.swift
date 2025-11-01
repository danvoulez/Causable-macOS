import Foundation

/// Represents a cryptographic signature for a span
public struct Signature: Codable, Equatable, Sendable {
    public let algo: String
    public let pubkey: String
    public let sig: String
    
    public init(algo: String, pubkey: String, sig: String) {
        self.algo = algo
        self.pubkey = pubkey
        self.sig = sig
    }
}

/// Metadata associated with a span
public struct SpanMetadata: Codable, Equatable, Sendable {
    public let tenantId: String?
    public let ownerId: String?
    public let deviceId: String?
    public let ts: String
    
    enum CodingKeys: String, CodingKey {
        case tenantId = "tenant_id"
        case ownerId = "owner_id"
        case deviceId = "device_id"
        case ts
    }
    
    public init(tenantId: String? = nil, ownerId: String? = nil, deviceId: String? = nil, ts: String) {
        self.tenantId = tenantId
        self.ownerId = ownerId
        self.deviceId = deviceId
        self.ts = ts
    }
}

/// Canonical span envelope as defined in the Blueprint
public struct SpanEnvelope: Codable, Equatable, Sendable {
    public let id: String
    public let entityType: String
    public let who: String
    public let did: String
    public let this: String
    public let status: String
    public let input: [String: AnyCodable]?
    public let output: [String: AnyCodable]?
    public let metadata: SpanMetadata
    public let visibility: String
    public var digest: String?
    public var signature: Signature?
    
    enum CodingKeys: String, CodingKey {
        case id
        case entityType = "entity_type"
        case who
        case did
        case this
        case status
        case input
        case output
        case metadata
        case visibility
        case digest
        case signature
    }
    
    public init(
        id: String,
        entityType: String,
        who: String,
        did: String,
        this: String,
        status: String,
        input: [String: AnyCodable]? = nil,
        output: [String: AnyCodable]? = nil,
        metadata: SpanMetadata,
        visibility: String,
        digest: String? = nil,
        signature: Signature? = nil
    ) {
        self.id = id
        self.entityType = entityType
        self.who = who
        self.did = did
        self.this = this
        self.status = status
        self.input = input
        self.output = output
        self.metadata = metadata
        self.visibility = visibility
        self.digest = digest
        self.signature = signature
    }
}

// MARK: - AnyCodable

public struct AnyCodable: Codable, Sendable {
    public let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self.value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self.value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported type")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if value is NSNull {
            try container.encodeNil()
        } else if let bool = value as? Bool {
            try container.encode(bool)
        } else if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let string = value as? String {
            try container.encode(string)
        } else if let array = value as? [Any] {
            try container.encode(array.map { AnyCodable($0) })
        } else if let dictionary = value as? [String: Any] {
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        } else {
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(codingPath: [], debugDescription: "Unsupported type")
            )
        }
    }
}

extension AnyCodable: Equatable {
    public static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        switch (lhs.value, rhs.value) {
        case (is NSNull, is NSNull):
            return true
        case (let left as Bool, let right as Bool):
            return left == right
        case (let left as Int, let right as Int):
            return left == right
        case (let left as Double, let right as Double):
            return left == right
        case (let left as String, let right as String):
            return left == right
        case (let left as [Any], let right as [Any]):
            return left.count == right.count && zip(left, right).allSatisfy { AnyCodable($0) == AnyCodable($1) }
        case (let left as [String: Any], let right as [String: Any]):
            return left.count == right.count && left.allSatisfy { key, value in
                guard let rightValue = right[key] else { return false }
                return AnyCodable(value) == AnyCodable(rightValue)
            }
        default:
            return false
        }
    }
}
