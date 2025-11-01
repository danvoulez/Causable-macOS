import Cocoa
import AppKit
import UserNotifications

class MenuBarController: NSObject {
    private var statusItem: NSStatusItem?
    private var menu: NSMenu?
    private var activityObserver: ActivityObserver?
    private var xpcConnection: XPCConnection?
    private var isConnected = false
    private var pendingCount = 0
    
    // Store references to menu items instead of using indices
    private weak var connectionStatusItem: NSMenuItem?
    private weak var observerStatusItem: NSMenuItem?
    private weak var toggleObserverItem: NSMenuItem?
    private weak var drainOutboxItem: NSMenuItem?
    
    func setup() {
        // Request notification permissions
        requestNotificationPermissions()
        
        // Create menu bar item with enhanced visuals
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "chart.line.uptrend.xyaxis", accessibilityDescription: "Causable Conductor")
            button.action = #selector(statusItemClicked)
            button.target = self
            button.toolTip = "Causable Conductor - Activity Observer"
        }
        
        // Build enhanced menu
        buildMenu()
        
        // Initialize XPC connection
        xpcConnection = XPCConnection()
        xpcConnection?.connect()
        
        // Initialize activity observer
        activityObserver = ActivityObserver(xpcConnection: xpcConnection)
        activityObserver?.start()
        
        // Update status immediately and periodically
        updateStatus()
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            self?.updateStatus()
        }
    }
    
    private func requestNotificationPermissions() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                NSLog("Notification permission error: \(error)")
            }
        }
    }
    
    private func buildMenu() {
        menu = NSMenu()
        menu?.autoenablesItems = false
        
        // Connection Status
        let connectionItem = NSMenuItem(title: "⚪️ Connecting...", action: nil, keyEquivalent: "")
        connectionItem.isEnabled = false
        menu?.addItem(connectionItem)
        connectionStatusItem = connectionItem
        
        // Observer Status
        let observerItem = NSMenuItem(title: "👁 Observer: Active", action: nil, keyEquivalent: "")
        observerItem.isEnabled = false
        menu?.addItem(observerItem)
        observerStatusItem = observerItem
        
        menu?.addItem(NSMenuItem.separator())
        
        // Toggle Observer
        let pauseItem = NSMenuItem(title: "⏸ Pause Observer", action: #selector(toggleObserver), keyEquivalent: "p")
        pauseItem.target = self
        pauseItem.isEnabled = true
        menu?.addItem(pauseItem)
        toggleObserverItem = pauseItem
        
        // Drain Outbox
        let drainItem = NSMenuItem(title: "📤 Drain Outbox", action: #selector(drainOutbox), keyEquivalent: "d")
        drainItem.target = self
        drainItem.isEnabled = true
        drainItem.toolTip = "Manually upload pending spans"
        menu?.addItem(drainItem)
        drainOutboxItem = drainItem
        
        menu?.addItem(NSMenuItem.separator())
        
        // About
        let aboutItem = NSMenuItem(title: "About Causable Conductor", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        aboutItem.isEnabled = true
        menu?.addItem(aboutItem)
        
        // Settings
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        settingsItem.isEnabled = true
        menu?.addItem(settingsItem)
        
        menu?.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit Causable Conductor", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        quitItem.isEnabled = true
        menu?.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    func teardown() {
        activityObserver?.stop()
        xpcConnection?.disconnect()
    }
    
    @objc private func statusItemClicked() {
        // Force immediate status update when menu is opened
        updateStatus()
    }
    
    @objc private func toggleObserver() {
        if let observer = activityObserver {
            if observer.isRunning {
                observer.stop()
                updateObserverUI(running: false)
                showNotification(title: "Observer Paused", message: "Activity tracking has been paused")
            } else {
                observer.start()
                updateObserverUI(running: true)
                showNotification(title: "Observer Resumed", message: "Activity tracking has been resumed")
            }
        }
    }
    
    private func updateObserverUI(running: Bool) {
        if running {
            toggleObserverItem?.title = "⏸ Pause Observer"
            observerStatusItem?.title = "👁 Observer: Active"
            statusItem?.button?.image = NSImage(systemSymbolName: "chart.line.uptrend.xyaxis", accessibilityDescription: "Active")
        } else {
            toggleObserverItem?.title = "▶️ Resume Observer"
            observerStatusItem?.title = "⏸ Observer: Paused"
            statusItem?.button?.image = NSImage(systemSymbolName: "pause.circle", accessibilityDescription: "Paused")
        }
    }
    
    @objc private func drainOutbox() {
        // Disable button during operation
        drainOutboxItem?.isEnabled = false
        drainOutboxItem?.title = "📤 Draining..."
        
        xpcConnection?.drainOutbox { [weak self] success in
            DispatchQueue.main.async {
                self?.drainOutboxItem?.isEnabled = true
                self?.drainOutboxItem?.title = "📤 Drain Outbox"
                
                if success {
                    self?.showNotification(title: "Outbox Drained", message: "Pending spans have been uploaded")
                    self?.updateStatus()
                } else {
                    self?.showNotification(title: "Drain Failed", message: "Unable to drain outbox. Check connection.")
                }
            }
        }
    }
    
    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "Causable Conductor"
        alert.informativeText = """
        Version 1.0.0
        
        A macOS-native core system for observing and notarizing activity to LogLineOS Cloud.
        
        Features:
        • Passive activity observation
        • Secure Ed25519 signing
        • Offline-first with persistent outbox
        • Privacy-focused design
        
        © 2025 Causable
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
    
    @objc private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
    
    @objc private func quit() {
        activityObserver?.stop()
        NSApp.terminate(nil)
    }
    
    private func updateStatus() {
        xpcConnection?.getHealth { [weak self] healthJson in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                // Parse health JSON and update menu
                if let data = healthJson.data(using: .utf8),
                   let health = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    
                    let pending = health["outbox_pending"] as? Int ?? 0
                    let enrolled = health["enrolled"] as? Bool ?? false
                    
                    self.pendingCount = pending
                    self.isConnected = true
                    
                    // Update connection status
                    let connectionText = enrolled ? "🟢 Connected" : "🟡 Not Enrolled"
                    self.connectionStatusItem?.title = connectionText
                    
                    // Update observer status with pending count
                    if pending > 0 {
                        self.observerStatusItem?.title = "📊 \(pending) spans pending"
                        // Update menu bar icon badge (if possible)
                        self.statusItem?.button?.toolTip = "Causable Conductor - \(pending) pending"
                    } else {
                        self.statusItem?.button?.toolTip = "Causable Conductor - All synced"
                    }
                    
                } else {
                    // Connection failed
                    self.isConnected = false
                    self.connectionStatusItem?.title = "🔴 Disconnected"
                    self.statusItem?.button?.toolTip = "Causable Conductor - Offline"
                }
            }
        }
    }
    
    private func showNotification(title: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = nil // Silent notification
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                NSLog("Notification error: \(error)")
            }
        }
    }
}
