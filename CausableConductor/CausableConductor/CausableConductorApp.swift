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
    @State private var isEnrolled = false
    @State private var deviceId = "Not available"
    @State private var lastSync = "Never"
    @State private var isRefreshing = false
    @State private var isDraining = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with icon and title
            HStack(spacing: 12) {
                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Causable Conductor")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Activity Observer & Notary")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Status Section
                    GroupBox(label: Label("Status", systemImage: "info.circle")) {
                        VStack(spacing: 12) {
                            StatusRow(
                                icon: isEnrolled ? "checkmark.circle.fill" : "exclamationmark.circle.fill",
                                iconColor: isEnrolled ? .green : .orange,
                                title: "Enrollment",
                                value: isEnrolled ? "Active" : "Pending"
                            )
                            
                            Divider()
                            
                            StatusRow(
                                icon: "network",
                                iconColor: healthStatus == "Connected" ? .green : .red,
                                title: "Connection",
                                value: healthStatus
                            )
                            
                            Divider()
                            
                            StatusRow(
                                icon: "tray.full",
                                iconColor: outboxCount > 0 ? .orange : .green,
                                title: "Pending Spans",
                                value: "\(outboxCount)"
                            )
                            
                            Divider()
                            
                            StatusRow(
                                icon: "clock",
                                iconColor: .blue,
                                title: "Last Sync",
                                value: lastSync
                            )
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Observer Controls Section
                    GroupBox(label: Label("Observer", systemImage: "eye")) {
                        VStack(spacing: 12) {
                            Toggle(isOn: $isObserving) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Enable Activity Tracking")
                                        .fontWeight(.medium)
                                    Text("Monitor app and window focus changes")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .toggleStyle(.switch)
                            .onChange(of: isObserving) { newValue in
                                toggleObserver(newValue)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Actions Section
                    GroupBox(label: Label("Actions", systemImage: "bolt")) {
                        VStack(spacing: 8) {
                            Button(action: refreshStatus) {
                                HStack {
                                    Image(systemName: isRefreshing ? "arrow.clockwise" : "arrow.clockwise")
                                    Text("Refresh Status")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isRefreshing)
                            
                            Button(action: drainOutbox) {
                                HStack {
                                    Image(systemName: "tray.and.arrow.up")
                                    Text("Upload Pending Spans")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .disabled(isDraining || outboxCount == 0)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Device Info Section
                    GroupBox(label: Label("Device", systemImage: "desktopcomputer")) {
                        VStack(spacing: 8) {
                            HStack {
                                Text("Device ID:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(deviceId)
                                    .font(.system(.body, design: .monospaced))
                                    .textSelection(.enabled)
                            }
                            
                            Button("Copy Device ID") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(deviceId, forType: .string)
                            }
                            .buttonStyle(.borderless)
                            .font(.caption)
                        }
                        .padding(.vertical, 8)
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Footer
            HStack {
                Text("Version 1.0.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Link("Documentation", destination: URL(string: "https://github.com/danvoulez/Causable-macOS")!)
                    .font(.caption)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(width: 450, height: 600)
        .onAppear {
            refreshStatus()
        }
    }
    
    private func refreshStatus() {
        guard !isRefreshing else { return }
        isRefreshing = true
        
        // TODO: Implement actual status refresh via XPC
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            healthStatus = "Connected"
            isEnrolled = true
            deviceId = "dev-\(UUID().uuidString.prefix(8))"
            lastSync = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .short)
            isRefreshing = false
        }
    }
    
    private func drainOutbox() {
        guard !isDraining else { return }
        isDraining = true
        
        // TODO: Implement drain via XPC
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            outboxCount = 0
            lastSync = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .short)
            isDraining = false
        }
    }
    
    private func toggleObserver(_ enabled: Bool) {
        // TODO: Implement observer toggle via XPC
        print("Observer toggled: \(enabled)")
    }
}

struct StatusRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 20)
            
            Text(title)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    SettingsView()
}
