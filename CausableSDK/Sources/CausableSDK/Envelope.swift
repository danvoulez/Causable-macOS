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
// MARK: - Span Envelope

public struct SpanEnvelope: Codable {
    public let id: String
    public let entityType: String
    public let who: String
    public let did: String
    public let this: String
    public let status: String
    public let input: [String: AnyCodable]?
    public let output: [String: AnyCodable]?
    public let metadata: SpanMetadata
    public var input: [String: AnyCodable]
    public var output: [String: AnyCodable]
    public var metadata: Metadata
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
    public struct Metadata: Codable {
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
        
        public init(tenantId: String?, ownerId: String?, deviceId: String?, ts: String) {
            self.tenantId = tenantId
            self.ownerId = ownerId
            self.deviceId = deviceId
            self.ts = ts
        }
    }
    
    public struct Signature: Codable {
        public let algo: String
        public let pubkey: String
        public let sig: String
        
        public init(algo: String, pubkey: String, sig: String) {
            self.algo = algo
            self.pubkey = pubkey
            self.sig = sig
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case entityType = "entity_type"
        case who, did, this, status, input, output, metadata, visibility, digest, signature
    }
    
    public init(
        id: String = UUID().uuidString,
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
        input: [String: AnyCodable] = [:],
        output: [String: AnyCodable] = [:],
        metadata: Metadata,
        visibility: String = "private"
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
    }
}

// MARK: - AnyCodable

public struct AnyCodable: Codable {
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
        
        switch value {
        case is NSNull:
            try container.encodeNil()
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
        // Compare values based on their actual types
        switch (lhs.value, rhs.value) {
        case let (l as Bool, r as Bool):
            return l == r
        case let (l as Int, r as Int):
            return l == r
        case let (l as Double, r as Double):
            return l == r
        case let (l as String, r as String):
            return l == r
        case let (l as [Any], r as [Any]):
            guard l.count == r.count else { return false }
            return zip(l, r).allSatisfy { AnyCodable($0) == AnyCodable($1) }
        case let (l as [String: Any], r as [String: Any]):
            guard l.keys.sorted() == r.keys.sorted() else { return false }
            return l.keys.allSatisfy { key in
                guard let lval = l[key], let rval = r[key] else { return false }
                return AnyCodable(lval) == AnyCodable(rval)
            }
        case (is NSNull, is NSNull):
            return true
        default:
            return false
        default:
            let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "Unsupported type")
            throw EncodingError.invalidValue(value, context)
        }
    }
}
