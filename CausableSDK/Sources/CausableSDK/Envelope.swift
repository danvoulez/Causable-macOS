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

/// A type-erased codable value wrapper to support dynamic JSON structures
public struct AnyCodable: Codable, Equatable, Sendable {
    public let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else if container.decodeNil() {
            value = NSNull()
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported type"
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        case is NSNull:
            try container.encodeNil()
        default:
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Unsupported type"
                )
            )
        }
    }
    
    public static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        // Simple comparison - for production, would need more sophisticated logic
        "\(lhs.value)" == "\(rhs.value)"
    }
}
