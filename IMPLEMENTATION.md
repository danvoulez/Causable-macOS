# Implementation Guide for Causable Conductor macOS

This guide explains how to complete the Xcode project setup for the Causable Conductor macOS application.

## Prerequisites

- macOS 13.0 or later
- Xcode 15.0 or later
- Apple Developer account (for code signing and Keychain access)

## Project Structure Created

The repository now contains:

1. **CausableSDK** - Swift Package with core functionality
2. **CausableConductor** - macOS application Swift files
3. **NotaryXPCService** - XPC service Swift files

## Steps to Complete in Xcode

### 1. Create New Xcode Project

1. Open Xcode
2. File → New → Project
3. Choose "macOS" → "App"
4. Product Name: `CausableConductor`
5. Bundle Identifier: `dev.causable.mac`
6. Interface: SwiftUI
7. Language: Swift
8. Save to: `Causable-macOS/CausableConductor/`

### 2. Add CausableSDK Dependency

1. In Project Navigator, select the project
2. Select the app target
3. Go to "General" → "Frameworks, Libraries, and Embedded Content"
4. Click "+" → "Add Other..." → "Add Package Dependency..."
5. Select the local `CausableSDK` package
6. Add `CausableSDK` to the app target

### 3. Replace Generated Files

Replace the Xcode-generated files with the ones in the repository:

- `CausableConductor/CausableConductor/CausableConductorApp.swift`
- `CausableConductor/CausableConductor/MenuBarController.swift`
- `CausableConductor/CausableConductor/ActivityObserver.swift`
- `CausableConductor/CausableConductor/XPCConnection.swift`
- `CausableConductor/CausableConductor/Info.plist`
- `CausableConductor/CausableConductor/CausableConductor.entitlements`

### 4. Create XPC Service Target

1. File → New → Target
2. Choose "macOS" → "XPC Service"
3. Product Name: `NotaryXPCService`
4. Bundle Identifier: `dev.causable.notary`

Add these files to the XPC target:
- `NotaryXPCService/NotaryXPCProtocol.swift`
- `NotaryXPCService/NotaryXPCService.swift`
- `NotaryXPCService/Info.plist`

### 5. Configure XPC Service

1. In the XPC service target build settings:
   - Set "Principal Class" to blank (handled in code)
   - Add `CausableSDK` to Frameworks

2. Add XPC service to main app:
   - Select main app target
   - Build Phases → "Embed XPC Services"
   - Add NotaryXPCService

### 6. Configure Entitlements

Main App (`CausableConductor.entitlements`):
```xml
<key>com.apple.security.app-sandbox</key>
<true/>
<key>com.apple.security.network.client</key>
<true/>
<key>keychain-access-groups</key>
<array>
    <string>$(AppIdentifierPrefix)dev.causable.mac</string>
</array>
```

XPC Service entitlements (create `NotaryXPCService.entitlements`):
```xml
<key>com.apple.security.app-sandbox</key>
<true/>
<key>com.apple.security.network.client</key>
<true/>
<key>keychain-access-groups</key>
<array>
    <string>$(AppIdentifierPrefix)dev.causable.mac</string>
</array>
```

### 7. Configure Build Settings

For both targets:
- Minimum Deployment: macOS 13.0
- Swift Language Version: Swift 5
- Code Signing: Automatic (or configure with your team)

### 8. Build and Test

1. Select CausableConductor scheme
2. Build (⌘B)
3. Run (⌘R)

The app should:
- Appear as a menu bar icon
- Not appear in the Dock (LSUIElement is set)
- Show menu with options when clicked

## Testing the Implementation

### Test Enrollment Flow

1. Launch the app
2. The XPC service should auto-start
3. Open Console.app and filter for "Causable"
4. Trigger enrollment:
   ```swift
   // In XPCConnection, call:
   enroll(deviceFingerprint: "test-device") { success, error in
       print("Enrollment: \(success), error: \(error ?? "none")")
   }
   ```

### Test Activity Observer

1. Enable Observer from menu
2. Switch between apps
3. Check Console.app for activity logs
4. Verify spans are being created

### Test Outbox

1. Disconnect from internet
2. Generate some activity
3. Check outbox count in menu
4. Reconnect to internet
5. Manually drain outbox
6. Verify count goes to 0

### Test XPC Communication

1. Check Health status
2. Verify it returns valid JSON
3. Test span enqueuing
4. Verify no crashes or hangs

## Troubleshooting

### XPC Service Not Launching

- Check Console.app for errors
- Verify bundle identifiers match
- Ensure XPC service is embedded in app bundle
- Check entitlements are properly signed

### Keychain Access Denied

- Verify entitlements include keychain-access-groups
- Check code signing is valid
- Ensure app is signed with same team ID

### Activity Observer Not Working

- Request Accessibility permissions (System Settings → Privacy & Security → Accessibility)
- Verify NSWorkspace notifications are firing
- Check polling timer is active

### Network Errors

- Verify network.client entitlement
- Check base URL is correct
- Test with mock server first

## Production Checklist

Before releasing:

- [ ] Configure production Cloud URL
- [ ] Implement proper error handling and recovery
- [ ] Add crash reporting (if applicable)
- [ ] Set up automatic updates (consider Sparkle framework)
- [ ] Code sign with Developer ID Application certificate
- [ ] Notarize the app with Apple
- [ ] Create DMG installer
- [ ] Write user documentation
- [ ] Create Privacy Policy
- [ ] Test on clean macOS installation

## Architecture Notes

### Why XPC Service?

The XPC service provides:
- **Security**: Isolated process for cryptographic operations
- **Reliability**: Can restart independently if it crashes
- **Privilege Separation**: Keys never leave the XPC service

### Why SQLite for Outbox?

- **Persistence**: Survives app/system crashes
- **ACID**: Transactions ensure data integrity
- **Performance**: Fast enough for local queue
- **Zero config**: No server setup needed

### Why Ed25519?

- **Fast**: Faster than RSA
- **Small**: Smaller keys and signatures
- **Secure**: Modern, well-analyzed algorithm
- **Native**: Supported by CryptoKit/swift-crypto

## Next Steps

After completing the Xcode setup:

1. Test end-to-end flow
2. Implement EPIC-MAC-003 (Timeline Canvas UI) if needed
3. Add SSE stream consumption
4. Implement policy updates
5. Add comprehensive error handling
6. Create installer package
7. Submit for notarization

## Resources

- [XPC Services Documentation](https://developer.apple.com/documentation/xpc)
- [App Sandbox Guide](https://developer.apple.com/documentation/security/app_sandbox)
- [Keychain Services](https://developer.apple.com/documentation/security/keychain_services)
- [Swift Crypto](https://github.com/apple/swift-crypto)
