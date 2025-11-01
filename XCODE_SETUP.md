# Xcode Project Setup Guide

## Complete Step-by-Step Instructions for Setting Up Causable Conductor in Xcode

This guide provides detailed instructions for creating and configuring the Xcode project for Causable Conductor.

---

## Prerequisites

- **macOS**: 13.0 (Ventura) or later
- **Xcode**: 15.0 or later
- **Apple Developer Account**: Required for code signing and testing
- **Command Line Tools**: Install via `xcode-select --install`

---

## Part 1: Create the Main App Project

### 1.1 Create New Xcode Project

1. **Launch Xcode**
2. Select **File → New → Project** (or ⌘⇧N)
3. Choose **macOS** tab at the top
4. Select **App** template
5. Click **Next**

### 1.2 Configure Project Settings

Fill in the project details:

- **Product Name**: `CausableConductor`
- **Team**: Select your development team
- **Organization Identifier**: `dev.causable` (or your own)
- **Bundle Identifier**: Will auto-generate as `dev.causable.CausableConductor`
- **Interface**: **SwiftUI**
- **Language**: **Swift**
- **Storage**: None (we'll use our own)
- **Hosting**: None
- **Include Tests**: ✅ (Optional but recommended)

Click **Next** and save to: `/path/to/Causable-macOS/CausableConductor/`

**Important**: Make sure to save inside the existing `CausableConductor` directory, not create a new one.

---

## Part 2: Add Local Swift Package (CausableSDK)

### 2.1 Add Package Dependency

1. In Project Navigator, select the **CausableConductor** project (top item)
2. Select the **CausableConductor** target
3. Go to **General** tab
4. Scroll to **Frameworks, Libraries, and Embedded Content**
5. Click the **+** button
6. Click **Add Other...** → **Add Package Dependency...**
7. In the search field, click **Add Local...**
8. Navigate to and select the `CausableSDK` folder (one level up from CausableConductor)
9. Click **Add Package**
10. Ensure **CausableSDK** is checked
11. Click **Add Package**

### 2.2 Verify Package Integration

- In Project Navigator, you should see **CausableSDK** under **Package Dependencies**
- Build the project (⌘B) to ensure it compiles

---

## Part 3: Replace Generated Files with Repository Files

### 3.1 Remove Generated Files

In Project Navigator, **delete** these generated files (Move to Trash):
- `CausableConductorApp.swift` (we have our own version)
- `ContentView.swift` (not needed)
- Any other generated SwiftUI files

### 3.2 Add Repository Files to Project

1. In Finder, navigate to `Causable-macOS/CausableConductor/CausableConductor/`
2. Select these files:
   - `CausableConductorApp.swift`
   - `MenuBarController.swift`
   - `ActivityObserver.swift`
   - `XPCConnection.swift`
3. Drag them into Xcode, into the **CausableConductor** group
4. In the dialog:
   - ✅ **Copy items if needed** (uncheck - files are already in place)
   - ✅ **Create groups**
   - ✅ **Add to targets**: CausableConductor
5. Click **Finish**

---

## Part 4: Configure Info.plist

### 4.1 Set Application Type (Menu Bar Only)

1. Select the **CausableConductor** target
2. Go to **Info** tab
3. Find or add these keys:

**Method 1: Using Info tab**
- Hover over any key and click **+**
- Add key: `Application is agent (UIElement)`
- Set value: **YES** (Boolean)

**Method 2: Using Info.plist file directly**
If you have an `Info.plist` file in your project, add:
```xml
<key>LSUIElement</key>
<true/>
```

### 4.2 Add Privacy Descriptions

Add these required privacy keys:

| Key | Value |
|-----|-------|
| `NSUserNotificationsUsageDescription` | `Causable Conductor sends notifications about activity sync status and important events.` |
| `NSAccessibilityUsageDescription` | `Causable Conductor needs accessibility access to monitor which apps you're using for activity tracking.` |

**In Xcode Info tab:**
1. Click **+** to add new key
2. Start typing "Privacy" to see autocomplete options
3. Select **Privacy - User Notifications Usage Description**
4. Set value as shown above
5. Repeat for **Privacy - Accessibility Usage Description**

---

## Part 5: Create and Configure XPC Service Target

### 5.1 Add XPC Service Target

1. Select **File → New → Target** (or ⌘⇧T)
2. Choose **macOS** tab
3. Select **XPC Service** template
4. Click **Next**

### 5.2 Configure XPC Service

- **Product Name**: `NotaryXPCService`
- **Team**: Same as main app
- **Organization Identifier**: `dev.causable`
- **Bundle Identifier**: `dev.causable.NotaryXPCService`
- Click **Finish**

### 5.3 Add Files to XPC Service Target

1. In Project Navigator, find the **NotaryXPCService** group
2. Delete the generated `main.swift` file
3. In Finder, go to `Causable-macOS/CausableConductor/NotaryXPCService/`
4. Select these files:
   - `NotaryXPCProtocol.swift`
   - `NotaryXPCService.swift`
5. Drag into Xcode's **NotaryXPCService** group
6. In dialog:
   - ⬜ **Copy items if needed** (uncheck)
   - ✅ **Create groups**
   - ✅ **Add to targets**: NotaryXPCService
7. Click **Finish**

### 5.4 Add CausableSDK to XPC Service

1. Select **NotaryXPCService** target
2. Go to **General** tab
3. Under **Frameworks and Libraries**, click **+**
4. Find and add **CausableSDK**
5. Ensure it's set to **Embed & Sign** or **Do Not Embed** (for XPC services, typically "Do Not Embed")

### 5.5 Configure XPC Service Build Settings

1. Select **NotaryXPCService** target
2. Go to **Build Settings** tab
3. Search for "Principal Class"
4. Set **Principal Class** to blank (empty)
   - The service listener is configured in code

---

## Part 6: Embed XPC Service in Main App

### 6.1 Embed XPC Service

1. Select **CausableConductor** target (main app)
2. Go to **Build Phases** tab
3. Look for **Embed XPC Services** section
   - If it doesn't exist, click **+** → **New Copy Files Phase**
   - Change **Destination** to **XPC Services**
   - Rename phase to "Embed XPC Services"
4. Click **+** in the Embed XPC Services section
5. Select **NotaryXPCService.xpc**
6. Click **Add**

### 6.2 Verify Embedding

Build the project (⌘B) and check:
1. Open **Products** folder in Project Navigator
2. Right-click **CausableConductor.app** → **Show in Finder**
3. Right-click app → **Show Package Contents**
4. Navigate to **Contents/XPCServices/**
5. Verify **NotaryXPCService.xpc** is present

---

## Part 7: Configure Entitlements

### 7.1 Main App Entitlements

1. Select **CausableConductor** target
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**

Add these capabilities:
- **App Sandbox**: Enable
  - Under Network:
    - ✅ **Outgoing Connections (Client)**
  - File Access: Leave all unchecked (default)
  
- **Keychain Sharing**: Add
  - Add keychain group: `$(AppIdentifierPrefix)dev.causable.mac`

4. Verify the entitlements file was created: `CausableConductor.entitlements`

### 7.2 XPC Service Entitlements

1. Select **NotaryXPCService** target
2. Go to **Signing & Capabilities** tab
3. Add same capabilities as main app:
   - **App Sandbox**: Enable (same settings)
   - **Keychain Sharing**: Same keychain group

The XPC service must have matching sandbox and keychain entitlements.

### 7.3 Verify Entitlements Files

Check that both entitlements files exist and contain:

**CausableConductor.entitlements:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
    <key>keychain-access-groups</key>
    <array>
        <string>$(AppIdentifierPrefix)dev.causable.mac</string>
    </array>
</dict>
</plist>
```

**NotaryXPCService.entitlements:** (same content)

---

## Part 8: Configure Code Signing

### 8.1 Main App Signing

1. Select **CausableConductor** target
2. Go to **Signing & Capabilities** tab
3. Under **Signing**:
   - ✅ **Automatically manage signing**
   - **Team**: Select your team
   - **Bundle Identifier**: `dev.causable.CausableConductor`

### 8.2 XPC Service Signing

1. Select **NotaryXPCService** target
2. Same settings as main app
3. **Bundle Identifier**: `dev.causable.NotaryXPCService`

**Important**: Both must use the same Team ID for keychain sharing to work.

---

## Part 9: Configure Build Settings

### 9.1 Deployment Target

For both targets:
1. Go to **Build Settings** tab
2. Search for "deployment target"
3. Set **macOS Deployment Target**: `13.0` or later

### 9.2 Swift Language Version

1. Search for "swift language"
2. Verify **Swift Language Version**: `Swift 5`

### 9.3 Hardened Runtime

For both targets:
1. Search for "hardened runtime"
2. Enable **Hardened Runtime**: **Yes**
3. This is required for notarization

---

## Part 10: Build and Test

### 10.1 Clean Build Folder

1. Select **Product → Clean Build Folder** (⌘⇧K)
2. This ensures a fresh build

### 10.2 Build Project

1. Select **Product → Build** (⌘B)
2. Check for any errors in the Issue Navigator
3. Common issues:
   - Missing imports: Ensure CausableSDK is linked to both targets
   - Code signing: Verify Team is selected
   - Entitlements: Check both .entitlements files exist

### 10.3 Run Application

1. Select **Product → Run** (⌘R)
2. The app should:
   - Launch without appearing in Dock
   - Show a menu bar icon (chart icon)
   - Clicking icon shows menu
3. Check Console.app for logs:
   - Filter: `process:CausableConductor`
   - Look for enrollment and observer startup messages

---

## Part 11: Test XPC Communication

### 11.1 Verify XPC Service Launch

1. Run the app
2. Open **Activity Monitor**
3. Search for "NotaryXPCService"
4. It should be running as a separate process
5. Parent process should be "CausableConductor"

### 11.2 Test Menu Functions

1. Click menu bar icon
2. Try these functions:
   - **Pause Observer**: Should show "Resume Observer" after clicking
   - **Drain Outbox**: Should show "Draining..." then complete
   - **Settings**: Should open settings window
3. Check Console.app for XPC communication logs

---

## Part 12: Configure for Distribution (Optional)

### 12.1 Archive for Distribution

1. Select **Product → Archive**
2. Xcode will build and open Organizer
3. Select the archive
4. Click **Distribute App**

### 12.2 Choose Distribution Method

- **Developer ID**: For distribution outside App Store
- **App Store**: For App Store submission
- **Export**: For testing or manual distribution

### 12.3 Notarization

For distribution outside App Store:
1. Export with Developer ID certificate
2. Use `xcrun notarytool` to submit for notarization
3. Wait for approval (usually < 1 hour)
4. Staple the notarization ticket:
   ```bash
   xcrun stapler staple CausableConductor.app
   ```

---

## Troubleshooting

### Issue: Build Errors with CausableSDK

**Solution**: 
1. Remove package dependency
2. Clean build folder (⌘⇧K)
3. Re-add package as local dependency
4. Build again

### Issue: XPC Service Not Launching

**Solution**:
1. Check Console.app for XPC errors
2. Verify XPC service is embedded (Build Phases → Embed XPC Services)
3. Ensure both targets have matching code signing team
4. Check entitlements are identical for sandbox and keychain

### Issue: Keychain Access Denied

**Solution**:
1. Verify both targets have **Keychain Sharing** capability
2. Ensure keychain group matches: `$(AppIdentifierPrefix)dev.causable.mac`
3. Check that both use same Team ID for signing
4. Delete old keychain items and re-run

### Issue: App Not Showing in Menu Bar

**Solution**:
1. Check `Info.plist` has `LSUIElement = true`
2. Verify `NSApp.setActivationPolicy(.accessory)` is called
3. Check Console.app for crash logs
4. Ensure menu bar icon code is executed in `applicationDidFinishLaunching`

### Issue: Privacy Permissions Not Requested

**Solution**:
1. Add privacy descriptions to Info.plist
2. For Accessibility: Go to System Settings → Privacy & Security → Accessibility manually
3. For Notifications: Permission should be requested on first notification

---

## Verification Checklist

Before considering setup complete, verify:

- ✅ Project builds without errors
- ✅ App launches and shows menu bar icon
- ✅ App does not appear in Dock
- ✅ XPC service launches automatically
- ✅ Menu items are clickable and functional
- ✅ Settings window opens
- ✅ Console.app shows CausableConductor logs
- ✅ Activity Monitor shows NotaryXPCService process
- ✅ Keychain access works (check for dev.causable entries)
- ✅ Both targets have matching entitlements
- ✅ Code signing shows valid signature
- ✅ Hardened runtime is enabled

---

## Next Steps

After successful setup:

1. **Testing**: Follow the [TESTING.md](TESTING.md) guide
2. **Documentation**: Review [App Store Documentation](APPSTORE.md)
3. **Privacy Policy**: Review [PRIVACY_POLICY.md](PRIVACY_POLICY.md)
4. **Deployment**: Follow [DEPLOYMENT.md](DEPLOYMENT.md) for release process

---

## Additional Resources

- [Apple XPC Services Documentation](https://developer.apple.com/documentation/xpc)
- [App Sandbox Guide](https://developer.apple.com/documentation/security/app_sandbox)
- [Keychain Services](https://developer.apple.com/documentation/security/keychain_services)
- [Hardened Runtime](https://developer.apple.com/documentation/security/hardened_runtime)
- [Notarization Guide](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)

---

**Need Help?**

- Check existing issues: https://github.com/danvoulez/Causable-macOS/issues
- Create new issue with "xcode-setup" label
- Include Xcode version, macOS version, and error messages
