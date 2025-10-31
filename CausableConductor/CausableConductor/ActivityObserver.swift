import Foundation
import AppKit
import CausableSDK

class ActivityObserver {
    private weak var xpcConnection: XPCConnection?
    private(set) var isRunning = false
    
    private var workspaceNotificationObserver: NSObjectProtocol?
    private var pollTimer: Timer?
    
    // Privacy: Patterns to redact from window titles
    private let redactionPatterns = [
        "password",
        "credit card",
        "ssn",
        "social security",
        "private",
        "confidential"
    ]
    
    private var lastActivity: (app: String, window: String)?
    
    init(xpcConnection: XPCConnection?) {
        self.xpcConnection = xpcConnection
    }
    
    func start() {
        guard !isRunning else { return }
        isRunning = true
        
        // Register for app activation notifications
        workspaceNotificationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAppActivation(notification)
        }
        
        // Start polling timer as fallback (every 15 seconds)
        pollTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            self?.pollActivity()
        }
        
        NSLog("ActivityObserver: Started")
    }
    
    func stop() {
        guard isRunning else { return }
        isRunning = false
        
        if let observer = workspaceNotificationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            workspaceNotificationObserver = nil
        }
        
        pollTimer?.invalidate()
        pollTimer = nil
        
        NSLog("ActivityObserver: Stopped")
    }
    
    private func handleAppActivation(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }
        
        let appName = app.localizedName ?? "Unknown"
        let windowTitle = getFrontmostWindowTitle() ?? ""
        
        recordActivity(app: appName, window: windowTitle)
    }
    
    private func pollActivity() {
        guard isRunning else { return }
        
        // Get frontmost app
        if let frontApp = NSWorkspace.shared.frontmostApplication {
            let appName = frontApp.localizedName ?? "Unknown"
            let windowTitle = getFrontmostWindowTitle() ?? ""
            
            recordActivity(app: appName, window: windowTitle)
        }
    }
    
    private func getFrontmostWindowTitle() -> String? {
        guard let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }
        
        // Find the frontmost window
        for window in windowList {
            if let ownerName = window[kCGWindowOwnerName as String] as? String,
               let windowName = window[kCGWindowName as String] as? String,
               let layer = window[kCGWindowLayer as String] as? Int,
               layer == 0 { // Normal window layer
                return windowName
            }
        }
        
        return nil
    }
    
    private func recordActivity(app: String, window: String) {
        // Debounce: Don't record if same as last activity
        if let last = lastActivity, last.app == app && last.window == window {
            return
        }
        
        lastActivity = (app, window)
        
        // Redact sensitive information
        let redactedWindow = redactSensitiveInfo(window)
        
        // Create activity span
        let span = createActivitySpan(app: app, window: redactedWindow)
        
        // Send to XPC service
        sendSpan(span)
        
        NSLog("ActivityObserver: Recorded activity - App: \(app), Window: \(redactedWindow)")
    }
    
    private func redactSensitiveInfo(_ text: String) -> String {
        let lowerText = text.lowercased()
        
        for pattern in redactionPatterns {
            if lowerText.contains(pattern) {
                return "[REDACTED]"
            }
        }
        
        return text
    }
    
    private func createActivitySpan(app: String, window: String) -> SpanEnvelope {
        let now = ISO8601DateFormatter().string(from: Date())
        
        let metadata = SpanEnvelope.Metadata(
            tenantId: nil,
            ownerId: nil,
            deviceId: nil,
            ts: now
        )
        
        let input: [String: AnyCodable] = [
            "app_name": AnyCodable(app),
            "window_title": AnyCodable(window)
        ]
        
        return SpanEnvelope(
            entityType: "activity",
            who: "observer:menubar@1.0.0",
            did: "focused",
            this: "device:local",
            status: "complete",
            input: input,
            output: [:],
            metadata: metadata,
            visibility: "private"
        )
    }
    
    private func sendSpan(_ span: SpanEnvelope) {
        do {
            let encoder = JSONEncoder()
            let spanData = try encoder.encode(span)
            
            xpcConnection?.enqueueSpan(spanData) { success, error in
                if !success {
                    NSLog("ActivityObserver: Failed to enqueue span: \(error ?? "unknown error")")
                }
            }
        } catch {
            NSLog("ActivityObserver: Failed to encode span: \(error)")
        }
    }
}
