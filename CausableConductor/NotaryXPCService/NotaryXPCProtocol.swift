import Foundation

/// Protocol definition for the Notary XPC Service
/// This protocol defines the interface between the Menu Bar App and the Notary Core
@objc protocol NotaryXPCProtocol {
    /// Enqueue a span for signing and eventual upload
    /// - Parameters:
    ///   - span: Serialized SpanEnvelope as Data
    ///   - reply: Completion handler with success status and optional error message
    func enqueueSpan(_ span: Data, with reply: @escaping (Bool, String?) -> Void)
    
    /// Update policy configuration
    /// - Parameters:
    ///   - json: Policy configuration as JSON data
    ///   - reply: Completion handler with success status
    func setPolicy(_ json: Data, with reply: @escaping (Bool) -> Void)
    
    /// Health check endpoint
    /// - Parameter reply: Completion handler with health status JSON string
    func health(_ reply: @escaping (String) -> Void)
    
    /// Get current outbox status
    /// - Parameter reply: Completion handler with pending span count
    func outboxStatus(_ reply: @escaping (Int) -> Void)
    
    /// Trigger manual outbox drain attempt
    /// - Parameter reply: Completion handler with success status
    func drainOutbox(_ reply: @escaping (Bool) -> Void)
    
    /// Enroll device with Cloud (first-time setup)
    /// - Parameters:
    ///   - deviceFingerprint: Unique device identifier
    ///   - reply: Completion handler with success status and optional error
    func enroll(deviceFingerprint: String, with reply: @escaping (Bool, String?) -> Void)
}
