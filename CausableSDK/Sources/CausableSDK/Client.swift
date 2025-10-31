import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
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
