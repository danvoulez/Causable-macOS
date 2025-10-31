import Cocoa
import AppKit

class MenuBarController: NSObject {
    private var statusItem: NSStatusItem?
    private var menu: NSMenu?
    private var activityObserver: ActivityObserver?
    private var xpcConnection: XPCConnection?
    
    func setup() {
        // Create menu bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "chart.line.uptrend.xyaxis", accessibilityDescription: "Causable")
            button.action = #selector(statusItemClicked)
            button.target = self
        }
        
        // Create menu
        menu = NSMenu()
        
        menu?.addItem(NSMenuItem(title: "Status: Active", action: nil, keyEquivalent: ""))
        menu?.addItem(NSMenuItem.separator())
        
        let pauseItem = NSMenuItem(title: "Pause Observer", action: #selector(toggleObserver), keyEquivalent: "p")
        pauseItem.target = self
        menu?.addItem(pauseItem)
        
        let drainItem = NSMenuItem(title: "Drain Outbox", action: #selector(drainOutbox), keyEquivalent: "d")
        drainItem.target = self
        menu?.addItem(drainItem)
        
        menu?.addItem(NSMenuItem.separator())
        
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu?.addItem(settingsItem)
        
        menu?.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu?.addItem(quitItem)
        
        statusItem?.menu = menu
        
        // Initialize XPC connection
        xpcConnection = XPCConnection()
        xpcConnection?.connect()
        
        // Initialize activity observer
        activityObserver = ActivityObserver(xpcConnection: xpcConnection)
        activityObserver?.start()
        
        // Update status periodically
        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.updateStatus()
        }
    }
    
    func teardown() {
        activityObserver?.stop()
        xpcConnection?.disconnect()
    }
    
    @objc private func statusItemClicked() {
        updateStatus()
    }
    
    @objc private func toggleObserver() {
        if let observer = activityObserver {
            if observer.isRunning {
                observer.stop()
                menu?.item(at: 2)?.title = "Resume Observer"
                statusItem?.button?.image = NSImage(systemSymbolName: "pause.circle", accessibilityDescription: "Paused")
            } else {
                observer.start()
                menu?.item(at: 2)?.title = "Pause Observer"
                statusItem?.button?.image = NSImage(systemSymbolName: "chart.line.uptrend.xyaxis", accessibilityDescription: "Active")
            }
        }
    }
    
    @objc private func drainOutbox() {
        xpcConnection?.drainOutbox { success in
            DispatchQueue.main.async {
                if success {
                    NSLog("Outbox drain initiated")
                }
            }
        }
    }
    
    @objc private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
    
    @objc private func quit() {
        NSApp.terminate(nil)
    }
    
    private func updateStatus() {
        xpcConnection?.getHealth { healthJson in
            DispatchQueue.main.async { [weak self] in
                // Parse health JSON and update menu
                if let data = healthJson.data(using: .utf8),
                   let health = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let pending = health["outbox_pending"] as? Int {
                    
                    let statusText = pending > 0 ? "Status: \(pending) pending" : "Status: Active"
                    self?.menu?.item(at: 0)?.title = statusText
                }
            }
        }
    }
}
