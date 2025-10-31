import SwiftUI

@main
struct CausableConductorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBarController: MenuBarController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from Dock (menu bar only app)
        NSApp.setActivationPolicy(.accessory)
        
        // Initialize menu bar controller
        menuBarController = MenuBarController()
        menuBarController?.setup()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        menuBarController?.teardown()
    }
}

struct SettingsView: View {
    @State private var isObserving = true
    @State private var healthStatus = "Checking..."
    @State private var outboxCount = 0
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Causable Conductor")
                .font(.title)
            
            Divider()
            
            HStack {
                Text("Status:")
                Text(healthStatus)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Pending Spans:")
                Text("\(outboxCount)")
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            Toggle("Enable Observer", isOn: $isObserving)
            
            Button("Refresh Status") {
                refreshStatus()
            }
            
            Button("Drain Outbox") {
                drainOutbox()
            }
        }
        .padding()
        .frame(width: 300, height: 250)
        .onAppear {
            refreshStatus()
        }
    }
    
    private func refreshStatus() {
        // TODO: Implement status refresh via XPC
        healthStatus = "Connected"
    }
    
    private func drainOutbox() {
        // TODO: Implement drain via XPC
    }
}
