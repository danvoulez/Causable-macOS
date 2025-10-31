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
           let digest = signedSpan.digest {
            let idempotencyKey = "\(tenantId)-\(digest)".data(using: .utf8)!.hexString
            request.setValue(idempotencyKey, forHTTPHeaderField: "X-Idempotency-Key")
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
