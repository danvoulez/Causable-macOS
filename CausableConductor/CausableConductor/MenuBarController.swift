import Cocoa
import AppKit

class MenuBarController: NSObject {
    private var statusItem: NSStatusItem?
    private var menu: NSMenu?
    private var activityObserver: ActivityObserver?
    private var xpcConnection: XPCConnection?
    private var isConnected = false
    private var pendingCount = 0
    
    // Menu item indices for easy reference
    private enum MenuIndex: Int {
        case connectionStatus = 0
        case observerStatus = 1
        case separator1 = 2
        case toggleObserver = 3
        case drainOutbox = 4
        case separator2 = 5
        case about = 6
        case settings = 7
        case separator3 = 8
        case quit = 9
    }
    
    func setup() {
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
    
    private func buildMenu() {
        menu = NSMenu()
        menu?.autoenablesItems = false
        
        // Connection Status
        let connectionItem = NSMenuItem(title: "⚪️ Connecting...", action: nil, keyEquivalent: "")
        connectionItem.isEnabled = false
        menu?.addItem(connectionItem)
        
        // Observer Status
        let observerItem = NSMenuItem(title: "👁 Observer: Active", action: nil, keyEquivalent: "")
        observerItem.isEnabled = false
        menu?.addItem(observerItem)
        
        menu?.addItem(NSMenuItem.separator())
        
        // Toggle Observer
        let pauseItem = NSMenuItem(title: "⏸ Pause Observer", action: #selector(toggleObserver), keyEquivalent: "p")
        pauseItem.target = self
        pauseItem.isEnabled = true
        menu?.addItem(pauseItem)
        
        // Drain Outbox
        let drainItem = NSMenuItem(title: "📤 Drain Outbox", action: #selector(drainOutbox), keyEquivalent: "d")
        drainItem.target = self
        drainItem.isEnabled = true
        drainItem.toolTip = "Manually upload pending spans"
        menu?.addItem(drainItem)
        
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
            menu?.item(at: MenuIndex.toggleObserver.rawValue)?.title = "⏸ Pause Observer"
            menu?.item(at: MenuIndex.observerStatus.rawValue)?.title = "👁 Observer: Active"
            statusItem?.button?.image = NSImage(systemSymbolName: "chart.line.uptrend.xyaxis", accessibilityDescription: "Active")
        } else {
            menu?.item(at: MenuIndex.toggleObserver.rawValue)?.title = "▶️ Resume Observer"
            menu?.item(at: MenuIndex.observerStatus.rawValue)?.title = "⏸ Observer: Paused"
            statusItem?.button?.image = NSImage(systemSymbolName: "pause.circle", accessibilityDescription: "Paused")
        }
    }
    
    @objc private func drainOutbox() {
        // Disable button during operation
        menu?.item(at: MenuIndex.drainOutbox.rawValue)?.isEnabled = false
        menu?.item(at: MenuIndex.drainOutbox.rawValue)?.title = "📤 Draining..."
        
        xpcConnection?.drainOutbox { [weak self] success in
            DispatchQueue.main.async {
                self?.menu?.item(at: MenuIndex.drainOutbox.rawValue)?.isEnabled = true
                self?.menu?.item(at: MenuIndex.drainOutbox.rawValue)?.title = "📤 Drain Outbox"
                
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
                    self.menu?.item(at: MenuIndex.connectionStatus.rawValue)?.title = connectionText
                    
                    // Update observer status with pending count
                    if pending > 0 {
                        self.menu?.item(at: MenuIndex.observerStatus.rawValue)?.title = "📊 \(pending) spans pending"
                        // Update menu bar icon badge (if possible)
                        self.statusItem?.button?.toolTip = "Causable Conductor - \(pending) pending"
                    } else {
                        self.statusItem?.button?.toolTip = "Causable Conductor - All synced"
                    }
                    
                } else {
                    // Connection failed
                    self.isConnected = false
                    self.menu?.item(at: MenuIndex.connectionStatus.rawValue)?.title = "🔴 Disconnected"
                    self.statusItem?.button?.toolTip = "Causable Conductor - Offline"
                }
            }
        }
    }
    
    private func showNotification(title: String, message: String) {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = message
        notification.soundName = nil // Silent notification
        
        NSUserNotificationCenter.default.deliver(notification)
    }
}
