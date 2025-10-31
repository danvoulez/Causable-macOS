import Foundation

class XPCConnection {
    private var connection: NSXPCConnection?
    private var proxy: NotaryXPCProtocol?
    
    func connect() {
        connection = NSXPCConnection(serviceName: "dev.causable.notary")
        connection?.remoteObjectInterface = NSXPCInterface(with: NotaryXPCProtocol.self)
        
        connection?.invalidationHandler = { [weak self] in
            NSLog("XPCConnection: Connection invalidated")
            self?.connection = nil
            self?.proxy = nil
            
            // Attempt to reconnect after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self?.connect()
            }
        }
        
        connection?.interruptionHandler = { [weak self] in
            NSLog("XPCConnection: Connection interrupted")
            // Connection will automatically resume
        }
        
        connection?.resume()
        
        proxy = connection?.remoteObjectProxyWithErrorHandler { error in
            NSLog("XPCConnection: Remote proxy error: \(error)")
        } as? NotaryXPCProtocol
        
        NSLog("XPCConnection: Connected to Notary XPC service")
    }
    
    func disconnect() {
        connection?.invalidate()
        connection = nil
        proxy = nil
    }
    
    // MARK: - XPC Methods
    
    func enqueueSpan(_ span: Data, completion: @escaping (Bool, String?) -> Void) {
        guard let proxy = proxy else {
            completion(false, "Not connected to XPC service")
            return
        }
        
        proxy.enqueueSpan(span) { success, error in
            completion(success, error)
        }
    }
    
    func setPolicy(_ json: Data, completion: @escaping (Bool) -> Void) {
        guard let proxy = proxy else {
            completion(false)
            return
        }
        
        proxy.setPolicy(json) { success in
            completion(success)
        }
    }
    
    func getHealth(completion: @escaping (String) -> Void) {
        guard let proxy = proxy else {
            completion("{\"status\":\"disconnected\"}")
            return
        }
        
        proxy.health { healthJson in
            completion(healthJson)
        }
    }
    
    func getOutboxStatus(completion: @escaping (Int) -> Void) {
        guard let proxy = proxy else {
            completion(0)
            return
        }
        
        proxy.outboxStatus { count in
            completion(count)
        }
    }
    
    func drainOutbox(completion: @escaping (Bool) -> Void) {
        guard let proxy = proxy else {
            completion(false)
            return
        }
        
        proxy.drainOutbox { success in
            completion(success)
        }
    }
    
    func enroll(deviceFingerprint: String, completion: @escaping (Bool, String?) -> Void) {
        guard let proxy = proxy else {
            completion(false, "Not connected to XPC service")
            return
        }
        
        proxy.enroll(deviceFingerprint: deviceFingerprint) { success, error in
            completion(success, error)
        }
    }
}
