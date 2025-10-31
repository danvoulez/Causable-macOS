import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Errors that can occur during client operations
public enum ClientError: Error {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, message: String)
    case networkError(Error)
    case signingError(Error)
    case encodingError
    case decodingError
}

/// Response from the ingest endpoint
public struct IngestResponse: Codable {
    public let id: String
    public let acceptedAt: String?
    public let digest: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case acceptedAt = "accepted_at"
        case digest
    }
}

/// Main client for interacting with the LogLineOS Cloud API
public final class CausableClient: @unchecked Sendable {
    private let baseURL: URL
    private let tokenProvider: @Sendable () -> String
    private let signer: SpanSigner
    private let outbox: OutboxStore
    private let session: URLSession
    
    /// Initialize the client
    /// - Parameters:
    ///   - baseURL: Base URL of the LogLineOS Cloud API
    ///   - tokenProvider: Closure that returns the current authentication token
    ///   - signer: Signer for cryptographic operations
    ///   - outbox: Outbox store for offline persistence
    public init(
        baseURL: URL,
        tokenProvider: @escaping @Sendable () -> String,
import Crypto

// MARK: - Causable Client

public final class CausableClient {
    private let baseURL: URL
    private let tokenProvider: () -> String?
    private let signer: SpanSigner
    private let outbox: OutboxStore
    
    public init(
        baseURL: URL,
        tokenProvider: @escaping () -> String?,
        signer: SpanSigner,
        outbox: OutboxStore
    ) {
        self.baseURL = baseURL
        self.tokenProvider = tokenProvider
        self.signer = signer
        self.outbox = outbox
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }
    
    /// Sign a span envelope
    private func signSpan(_ span: inout SpanEnvelope) throws {
        let encoder = JSONEncoder.causableCanonical
        
        // Create a copy without digest/signature for canonical encoding
        var unsigned = span
        unsigned.digest = nil
        unsigned.signature = nil
        
        let canonical = try encoder.encode(unsigned)
        let digestBytes = DigestUtils.computeDigestBytes(canonical)
        let digestHex = DigestUtils.computeDigest(canonical)
        
        do {
            let sig = try signer.sign(digestBytes)
            let pubkey = try signer.publicKeyHex()
            
            span.digest = digestHex
            span.signature = Signature(
                algo: "ed25519",
                pubkey: pubkey,
                sig: sig.hexString
            )
        } catch {
            throw ClientError.signingError(error)
        }
    }
    
    /// Ingest a span to the Cloud API
    /// - Parameter span: The span to ingest
    /// - Returns: The span ID returned by the server
    public func ingest(span: SpanEnvelope) async throws -> String {
        var signedSpan = span
        try signSpan(&signedSpan)
        
        guard let url = URL(string: "/api/spans", relativeTo: baseURL) else {
            throw ClientError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(tokenProvider())", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Generate idempotency key
        if let tenantId = signedSpan.metadata.tenantId,
           let digest = signedSpan.digest,
           let keyData = "\(tenantId)-\(digest)".data(using: .utf8) {
            request.setValue(keyData.hexString, forHTTPHeaderField: "X-Idempotency-Key")
        }
        
        let encoder = JSONEncoder.causableCanonical
        request.httpBody = try encoder.encode(signedSpan)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ClientError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw ClientError.httpError(statusCode: httpResponse.statusCode, message: message)
            }
            
            let decoder = JSONDecoder()
            let ingestResponse = try decoder.decode(IngestResponse.self, from: data)
            return ingestResponse.id
            
        } catch let error as ClientError {
            throw error
        } catch {
            throw ClientError.networkError(error)
        }
    }
    
    /// Fetch a manifest from the Cloud API
    /// - Parameter name: Name of the manifest (e.g., "loglineos_core_manifest@v1")
    /// - Returns: The manifest data
    public func fetchManifest(name: String) async throws -> Data {
        guard let url = URL(string: "/manifest/\(name)", relativeTo: baseURL) else {
            throw ClientError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(tokenProvider())", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ClientError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw ClientError.httpError(statusCode: httpResponse.statusCode, message: message)
            }
            
            return data
            
        } catch let error as ClientError {
            throw error
        } catch {
            throw ClientError.networkError(error)
        }
    }
    
    /// Process the outbox, attempting to send pending spans
    /// - Returns: Number of spans successfully sent
    @discardableResult
    public func processOutbox() async -> Int {
        var successCount = 0
        
        // Process up to 10 spans per batch
        for _ in 0..<10 {
            guard let entry = try? outbox.nextAttempt() else {
                break
            }
            
            // Decode the span from JSON
            guard let spanData = entry.spanJson.data(using: .utf8),
                  let span = try? JSONDecoder().decode(SpanEnvelope.self, from: spanData) else {
                // Invalid span, remove from outbox
                try? outbox.markSent(id: entry.id)
                continue
            }
            
            do {
                _ = try await ingest(span: span)
                try outbox.markSent(id: entry.id)
                successCount += 1
            } catch {
                try? outbox.markFailed(id: entry.id, error: error)
            }
        }
        
        return successCount
    }
    }
    
    // MARK: - Enrollment
    
    public struct EnrollmentRequest: Codable {
        public let pubkey: String
        public let deviceFingerprint: String
        
        enum CodingKeys: String, CodingKey {
            case pubkey
            case deviceFingerprint = "device_fingerprint"
        }
        
        public init(pubkey: String, deviceFingerprint: String) {
            self.pubkey = pubkey
            self.deviceFingerprint = deviceFingerprint
        }
    }
    
    public struct EnrollmentResponse: Codable {
        public let deviceId: String
        public let tenantId: String
        public let ownerId: String
        public let token: String
        
        enum CodingKeys: String, CodingKey {
            case deviceId = "device_id"
            case tenantId = "tenant_id"
            case ownerId = "owner_id"
            case token
        }
    }
    
    public func enroll(pubkey: String, deviceFingerprint: String) async throws -> EnrollmentResponse {
        let url = baseURL.appendingPathComponent("/api/enroll")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let enrollRequest = EnrollmentRequest(pubkey: pubkey, deviceFingerprint: deviceFingerprint)
        request.httpBody = try JSONEncoder().encode(enrollRequest)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw CausableError.enrollmentFailed
        }
        
        return try JSONDecoder().decode(EnrollmentResponse.self, from: data)
    }
    
    // MARK: - Ingest
    
    public struct IngestResponse: Codable {
        public let id: String
        public let acceptedAt: String
        public let digest: String
        
        enum CodingKeys: String, CodingKey {
            case id
            case acceptedAt = "accepted_at"
            case digest
        }
    }
    
    public func ingest(span: SpanEnvelope) async throws -> String {
        // Sign the span
        var signedSpan = span
        let canonical = try canonicalJSON(span)
        let digest = SHA256.hash(data: canonical)
        let digestData = Data(digest)
        let signature = try signer.sign(digestData)
        
        signedSpan.digest = "sha256:" + digestData.hexString
        signedSpan.signature = SpanEnvelope.Signature(
            algo: "ed25519",
            pubkey: try signer.publicKeyHex(),
            sig: signature.hexString
        )
        
        // Store in outbox first
        let spanJson = try String(data: JSONEncoder().encode(signedSpan), encoding: .utf8)!
        try outbox.enqueue(spanId: span.id, digest: signedSpan.digest!, spanJson: spanJson)
        
        // Attempt immediate upload
        return try await uploadSpan(spanId: span.id, spanJson: spanJson, digest: signedSpan.digest!)
    }
    
    private func uploadSpan(spanId: String, spanJson: String, digest: String) async throws -> String {
        let url = baseURL.appendingPathComponent("/api/spans")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = tokenProvider() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Idempotency key
        let idempotencyKey = digest
        request.setValue(idempotencyKey, forHTTPHeaderField: "X-Idempotency-Key")
        
        request.httpBody = spanJson.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CausableError.invalidResponse
        }
        
        if (200...299).contains(httpResponse.statusCode) {
            let ingestResponse = try JSONDecoder().decode(IngestResponse.self, from: data)
            try outbox.markSuccess(spanId: spanId)
            return ingestResponse.id
        } else {
            try outbox.markFailure(spanId: spanId)
            throw CausableError.ingestFailed(statusCode: httpResponse.statusCode)
        }
    }
    
    // MARK: - Upload Outbox
    
    public func drainOutbox() async {
        while let item = try? outbox.nextAttempt() {
            do {
                // Extract digest from span JSON
                guard let spanData = item.spanJson.data(using: .utf8),
                      let span = try? JSONDecoder().decode(SpanEnvelope.self, from: spanData),
                      let digest = span.digest else {
                    try outbox.markSuccess(spanId: item.id)
                    continue
                }
                
                _ = try await uploadSpan(spanId: item.id, spanJson: item.spanJson, digest: digest)
            } catch {
                try? outbox.markFailure(spanId: item.id)
                break // Stop draining on failure
            }
        }
    }
    
    // MARK: - Fetch Manifest
    
    public func fetchManifest(name: String) async throws -> Data {
        let url = baseURL.appendingPathComponent("/manifest/\(name)")
        var request = URLRequest(url: url)
        
        if let token = tokenProvider() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw CausableError.manifestFetchFailed
        }
        
        return data
    }
    
    // MARK: - SSE Stream
    
    public func sseStream(params: [URLQueryItem]) -> AsyncThrowingStream<Data, Error> {
        AsyncThrowingStream { continuation in
            Task {
                var urlComponents = URLComponents(url: baseURL.appendingPathComponent("/api/timeline/stream"), resolvingAgainstBaseURL: true)!
                urlComponents.queryItems = params
                
                guard let url = urlComponents.url else {
                    continuation.finish(throwing: CausableError.invalidURL)
                    return
                }
                
                var request = URLRequest(url: url)
                request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                
                if let token = tokenProvider() {
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                }
                
                do {
                    #if canImport(FoundationNetworking)
                    // On Linux, we need a simpler implementation
                    let (data, response) = try await URLSession.shared.data(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse,
                          (200...299).contains(httpResponse.statusCode) else {
                        continuation.finish(throwing: CausableError.sseStreamFailed)
                        return
                    }
                    
                    // Parse SSE data (simplified)
                    if let dataStr = String(data: data, encoding: .utf8) {
                        let lines = dataStr.components(separatedBy: "\n")
                        for line in lines {
                            if line.hasPrefix("data: ") {
                                let dataStr = String(line.dropFirst(6))
                                if let eventData = dataStr.data(using: .utf8) {
                                    continuation.yield(eventData)
                                }
                            }
                        }
                    }
                    continuation.finish()
                    #else
                    // On macOS, use the bytes API
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse,
                          (200...299).contains(httpResponse.statusCode) else {
                        continuation.finish(throwing: CausableError.sseStreamFailed)
                        return
                    }
                    
                    for try await line in bytes.lines {
                        if line.hasPrefix("data: ") {
                            let dataStr = String(line.dropFirst(6))
                            if let data = dataStr.data(using: .utf8) {
                                continuation.yield(data)
                            }
                        }
                    }
                    
                    continuation.finish()
                    #endif
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func canonicalJSON(_ span: SpanEnvelope) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(span)
    }
}

// MARK: - Errors

public enum CausableError: Error {
    case enrollmentFailed
    case invalidResponse
    case ingestFailed(statusCode: Int)
    case manifestFetchFailed
    case invalidURL
    case sseStreamFailed
}
