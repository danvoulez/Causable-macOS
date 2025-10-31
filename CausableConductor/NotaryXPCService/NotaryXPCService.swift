import Foundation
import CausableSDK

/// Main implementation of the Notary XPC Service
/// This service is the secure boundary for all cryptographic operations
class NotaryXPCService: NSObject, NotaryXPCProtocol {
    
    private var client: CausableClient?
    private var signer: KeychainSigner?
    private var outbox: OutboxStore?
    private var deviceToken: String?
    private var deviceId: String?
    private var tenantId: String?
    private var ownerId: String?
    
    override init() {
        super.init()
        setupService()
    }
    
    private func setupService() {
        do {
            // Initialize outbox
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let causableDir = appSupport.appendingPathComponent("dev.causable.notary")
            try FileManager.default.createDirectory(at: causableDir, withIntermediateDirectories: true)
            let dbPath = causableDir.appendingPathComponent("outbox.db").path
            
            self.outbox = try OutboxStore(path: dbPath)
            
            // Initialize signer (creates key if needed)
            #if os(macOS)
            self.signer = try KeychainSigner()
            #else
            self.signer = try Ed25519Signer()
            #endif
            
            // Load stored credentials
            loadCredentials()
            
            // Initialize client if we have credentials
            if let token = deviceToken {
                setupClient(token: token)
            }
            
            // Start background outbox drain timer
            startOutboxDrainTimer()
            
        } catch {
            NSLog("NotaryXPCService: Failed to initialize: \(error)")
        }
    }
    
    private func setupClient(token: String) {
        guard let outbox = self.outbox, let signer = self.signer else {
            return
        }
        
        // TODO: Make base URL configurable
        let baseURL = URL(string: "https://api.causable.dev")!
        
        self.client = CausableClient(
            baseURL: baseURL,
            tokenProvider: { [weak self] in self?.deviceToken },
            signer: signer,
            outbox: outbox
        )
    }
    
    private func loadCredentials() {
        guard let outbox = self.outbox else { return }
        
        do {
            self.deviceToken = try outbox.getValue(forKey: "device_token")
            self.deviceId = try outbox.getValue(forKey: "device_id")
            self.tenantId = try outbox.getValue(forKey: "tenant_id")
            self.ownerId = try outbox.getValue(forKey: "owner_id")
        } catch {
            NSLog("NotaryXPCService: No stored credentials found")
        }
    }
    
    private func saveCredentials() {
        guard let outbox = self.outbox else { return }
        
        do {
            if let token = deviceToken {
                try outbox.setValue(token, forKey: "device_token")
            }
            if let deviceId = deviceId {
                try outbox.setValue(deviceId, forKey: "device_id")
            }
            if let tenantId = tenantId {
                try outbox.setValue(tenantId, forKey: "tenant_id")
            }
            if let ownerId = ownerId {
                try outbox.setValue(ownerId, forKey: "owner_id")
            }
        } catch {
            NSLog("NotaryXPCService: Failed to save credentials: \(error)")
        }
    }
    
    // MARK: - Background Tasks
    
    private var drainTimer: Timer?
    
    private func startOutboxDrainTimer() {
        // Drain outbox every 30 seconds
        drainTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task {
                await self?.drainOutboxAsync()
            }
        }
    }
    
    private func drainOutboxAsync() async {
        guard let client = self.client else { return }
        await client.drainOutbox()
    }
    
    // MARK: - NotaryXPCProtocol Implementation
    
    func enqueueSpan(_ span: Data, with reply: @escaping (Bool, String?) -> Void) {
        Task {
            do {
                guard let client = self.client else {
                    reply(false, "Service not initialized. Please enroll first.")
                    return
                }
                
                let decoder = JSONDecoder()
                var spanEnvelope = try decoder.decode(SpanEnvelope.self, from: span)
                
                // Ensure metadata has device info
                if spanEnvelope.metadata.deviceId == nil {
                    spanEnvelope.metadata = SpanEnvelope.Metadata(
                        tenantId: self.tenantId,
                        ownerId: self.ownerId,
                        deviceId: self.deviceId,
                        ts: spanEnvelope.metadata.ts
                    )
                }
                
                // Ingest the span (this will sign, store in outbox, and attempt upload)
                _ = try await client.ingest(span: spanEnvelope)
                
                reply(true, nil)
            } catch {
                NSLog("NotaryXPCService: Failed to enqueue span: \(error)")
                reply(false, error.localizedDescription)
            }
        }
    }
    
    func setPolicy(_ json: Data, with reply: @escaping (Bool) -> Void) {
        // TODO: Implement policy update logic
        do {
            guard let outbox = self.outbox else {
                reply(false)
                return
            }
            
            if let jsonString = String(data: json, encoding: .utf8) {
                try outbox.setValue(jsonString, forKey: "current_policy")
            }
            
            reply(true)
        } catch {
            NSLog("NotaryXPCService: Failed to set policy: \(error)")
            reply(false)
        }
    }
    
    func health(_ reply: @escaping (String) -> Void) {
        let health: [String: Any] = [
            "status": "ok",
            "service": "dev.causable.notary",
            "version": "1.0.0",
            "enrolled": deviceToken != nil,
            "signer": signer != nil ? "active" : "inactive",
            "outbox_pending": (try? outbox?.pendingCount()) ?? 0,
            "device_id": deviceId ?? "none"
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: health),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            reply(jsonString)
        } else {
            reply("{\"status\":\"error\"}")
        }
    }
    
    func outboxStatus(_ reply: @escaping (Int) -> Void) {
        let count = (try? outbox?.pendingCount()) ?? 0
        reply(count)
    }
    
    func drainOutbox(_ reply: @escaping (Bool) -> Void) {
        Task {
            await drainOutboxAsync()
            reply(true)
        }
    }
    
    func enroll(deviceFingerprint: String, with reply: @escaping (Bool, String?) -> Void) {
        Task {
            do {
                guard let signer = self.signer else {
                    reply(false, "Signer not initialized")
                    return
                }
                
                let pubkey = try signer.publicKeyHex()
                
                // TODO: Make base URL configurable
                let baseURL = URL(string: "https://api.causable.dev")!
                
                // Create temporary client for enrollment
                guard let outbox = self.outbox else {
                    reply(false, "Outbox not initialized")
                    return
                }
                
                let tempClient = CausableClient(
                    baseURL: baseURL,
                    tokenProvider: { nil },
                    signer: signer,
                    outbox: outbox
                )
                
                let response = try await tempClient.enroll(pubkey: pubkey, deviceFingerprint: deviceFingerprint)
                
                // Store credentials
                self.deviceToken = response.token
                self.deviceId = response.deviceId
                self.tenantId = response.tenantId
                self.ownerId = response.ownerId
                
                saveCredentials()
                
                // Setup client with new token
                setupClient(token: response.token)
                
                NSLog("NotaryXPCService: Enrollment successful. Device ID: \(response.deviceId)")
                reply(true, nil)
                
            } catch {
                NSLog("NotaryXPCService: Enrollment failed: \(error)")
                reply(false, error.localizedDescription)
            }
        }
    }
}

// MARK: - XPC Service Entry Point

class NotaryXPCServiceDelegate: NSObject, NSXPCListenerDelegate {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(with: NotaryXPCProtocol.self)
        newConnection.exportedObject = NotaryXPCService()
        newConnection.resume()
        return true
    }
}

// Main entry point for XPC service
let delegate = NotaryXPCServiceDelegate()
let listener = NSXPCListener.service()
listener.delegate = delegate
listener.resume()
RunLoop.main.run()
