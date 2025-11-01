# Deployment and Notarization Guide

## Complete Guide for Deploying Causable Conductor Outside the App Store

This guide covers building, code signing, notarizing, and distributing Causable Conductor for users who prefer direct downloads.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Build for Distribution](#build-for-distribution)
3. [Code Signing](#code-signing)
4. [Notarization](#notarization)
5. [Create DMG Installer](#create-dmg-installer)
6. [Distribution](#distribution)
7. [Auto-Updates with Sparkle](#auto-updates-with-sparkle)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites

Before starting deployment:

- ✅ **Apple Developer Account** ($99/year)
- ✅ **Developer ID Application Certificate** (for distribution outside App Store)
- ✅ **Developer ID Installer Certificate** (optional, for PKG files)
- ✅ **Xcode 15.0+** with command line tools
- ✅ **macOS 13.0+** for building
- ✅ **Notarization credentials** (App Store Connect API key or app-specific password)

### Get Developer ID Certificates

1. Go to [Apple Developer Account](https://developer.apple.com/account)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Click **Certificates** → **+** (Add)
4. Select **Developer ID Application**
5. Follow prompts to generate certificate
6. Download and install certificate in Keychain Access

---

## Build for Distribution

### 1. Configure Release Build

1. Open Xcode project
2. Select **Product → Scheme → Edit Scheme**
3. Select **Run** → **Info** tab
4. Change **Build Configuration** to **Release**
5. Close scheme editor

### 2. Set Version and Build Number

1. Select **CausableConductor** target
2. Go to **General** tab
3. Set **Version**: `1.0.0`
4. Set **Build**: `1` (increment for each release)

### 3. Create Archive

```bash
# Clean build folder
xcodebuild clean -project CausableConductor.xcodeproj \
    -scheme CausableConductor

# Build and archive
xcodebuild archive \
    -project CausableConductor.xcodeproj \
    -scheme CausableConductor \
    -configuration Release \
    -archivePath build/CausableConductor.xcarchive \
    CODE_SIGN_IDENTITY="Developer ID Application: YOUR NAME (TEAMID)" \
    CODE_SIGN_STYLE=Manual
```

Or use Xcode GUI:
1. Select **Product → Archive**
2. Wait for build to complete
3. Organizer window opens with the archive

### 4. Export Application

```bash
# Export from archive
xcodebuild -exportArchive \
    -archivePath build/CausableConductor.xcarchive \
    -exportPath build/export \
    -exportOptionsPlist ExportOptions.plist
```

**ExportOptions.plist:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>signingCertificate</key>
    <string>Developer ID Application</string>
    <key>signingStyle</key>
    <string>manual</string>
</dict>
</plist>
```

Or use Xcode GUI:
1. In Organizer, select archive
2. Click **Distribute App**
3. Select **Developer ID**
4. Select **Export**
5. Choose signing certificate
6. Select **Export**

---

## Code Signing

### 1. Verify Code Signature

```bash
# Check main app signature
codesign -dvvv --deep build/export/CausableConductor.app

# Check XPC service signature
codesign -dvvv build/export/CausableConductor.app/Contents/XPCServices/NotaryXPCService.xpc

# Verify all signatures recursively
codesign --verify --deep --strict --verbose=2 build/export/CausableConductor.app
```

Expected output:
```
CausableConductor.app: valid on disk
CausableConductor.app: satisfies its Designated Requirement
```

### 2. Check Entitlements

```bash
# View app entitlements
codesign -d --entitlements :- build/export/CausableConductor.app

# View XPC service entitlements
codesign -d --entitlements :- build/export/CausableConductor.app/Contents/XPCServices/NotaryXPCService.xpc
```

Verify presence of:
- `com.apple.security.app-sandbox`: true
- `com.apple.security.network.client`: true
- `keychain-access-groups`: array with your team ID

### 3. Manual Code Signing (if needed)

```bash
# Sign XPC service first
# NOTE: Replace 'YOUR NAME (TEAMID)' with your actual Developer ID
# Example: "Developer ID Application: John Smith (ABC123XYZ)"
codesign --force --sign "Developer ID Application: YOUR NAME (TEAMID)" \
    --options runtime \
    --entitlements NotaryXPCService.entitlements \
    build/export/CausableConductor.app/Contents/XPCServices/NotaryXPCService.xpc

# Sign main app
# NOTE: Replace 'YOUR NAME (TEAMID)' with your actual Developer ID
codesign --force --sign "Developer ID Application: YOUR NAME (TEAMID)" \
    --options runtime \
    --entitlements CausableConductor.entitlements \
    --deep \
    build/export/CausableConductor.app
```

---

## Notarization

Apple requires all apps distributed outside the App Store to be notarized.

### 1. Create App Store Connect API Key

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to **Users and Access** → **Integrations**
3. Click **App Store Connect API** → **+** (Generate Key)
4. Name: `Notarization Key`
5. Access: **Developer**
6. Click **Generate**
7. Download the `.p8` file
8. Note the **Issuer ID** and **Key ID**

Save API key:
```bash
mkdir -p ~/private_keys
mv ~/Downloads/AuthKey_XXXXXXXXXX.p8 ~/private_keys/
chmod 600 ~/private_keys/AuthKey_XXXXXXXXXX.p8
```

### 2. Create Keychain Profile

```bash
xcrun notarytool store-credentials "causable-notarization" \
    --key ~/private_keys/AuthKey_XXXXXXXXXX.p8 \
    --key-id XXXXXXXXXX \
    --issuer XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
```

### 3. Create ZIP Archive for Notarization

```bash
# Create ZIP (preserves symlinks and code signatures)
cd build/export
ditto -c -k --keepParent CausableConductor.app CausableConductor.zip
```

### 4. Submit for Notarization

```bash
# Submit to Apple
xcrun notarytool submit CausableConductor.zip \
    --keychain-profile "causable-notarization" \
    --wait

# Alternative: submit and get submission ID
SUBMISSION_ID=$(xcrun notarytool submit CausableConductor.zip \
    --keychain-profile "causable-notarization" \
    --output-format json | jq -r '.id')

echo "Submission ID: $SUBMISSION_ID"
```

### 5. Check Notarization Status

```bash
# If using --wait, this is automatic
# Otherwise, check status manually:
xcrun notarytool info $SUBMISSION_ID \
    --keychain-profile "causable-notarization"
```

**Expected timeline**: 5-60 minutes

**Possible statuses**:
- `In Progress`: Being processed
- `Accepted`: Notarization successful ✅
- `Invalid`: Notarization failed ❌

### 6. Get Notarization Log (if failed)

```bash
xcrun notarytool log $SUBMISSION_ID \
    --keychain-profile "causable-notarization" \
    notarization-log.json

# View log
cat notarization-log.json | jq .
```

Common rejection reasons:
- Unsigned code
- Missing hardened runtime
- Invalid entitlements
- Malware detected

### 7. Staple Notarization Ticket

After successful notarization:

```bash
# Staple ticket to app
xcrun stapler staple build/export/CausableConductor.app

# Verify stapling
xcrun stapler validate build/export/CausableConductor.app
```

Expected output:
```
The staple and validate action worked!
```

**Why staple?**
- Allows app to run offline
- Faster Gatekeeper verification
- Better user experience

---

## Create DMG Installer

### 1. Using create-dmg Tool

Install tool:
```bash
brew install create-dmg
```

Create DMG:
```bash
create-dmg \
    --volname "Causable Conductor" \
    --volicon "Assets/AppIcon.icns" \
    --background "Assets/dmg-background.png" \
    --window-pos 200 120 \
    --window-size 800 400 \
    --icon-size 100 \
    --icon "CausableConductor.app" 200 190 \
    --hide-extension "CausableConductor.app" \
    --app-drop-link 600 185 \
    "CausableConductor-1.0.0.dmg" \
    "build/export/CausableConductor.app"
```

### 2. Manual DMG Creation

```bash
# Create temporary folder
mkdir dmg-staging
cp -R build/export/CausableConductor.app dmg-staging/

# Create alias to Applications
ln -s /Applications dmg-staging/Applications

# Create DMG
hdiutil create -volname "Causable Conductor" \
    -srcfolder dmg-staging \
    -ov -format UDZO \
    CausableConductor-1.0.0.dmg

# Clean up
rm -rf dmg-staging
```

### 3. Sign DMG

```bash
codesign --sign "Developer ID Application: YOUR NAME (TEAMID)" \
    CausableConductor-1.0.0.dmg
```

### 4. Notarize DMG

```bash
# Submit DMG
xcrun notarytool submit CausableConductor-1.0.0.dmg \
    --keychain-profile "causable-notarization" \
    --wait

# Staple ticket
xcrun stapler staple CausableConductor-1.0.0.dmg

# Verify
xcrun stapler validate CausableConductor-1.0.0.dmg
spctl -a -t open --context context:primary-signature -v CausableConductor-1.0.0.dmg
```

---

## Distribution

### 1. Upload to Server

```bash
# Upload to your server
scp CausableConductor-1.0.0.dmg user@server:/var/www/downloads/

# Or use S3
aws s3 cp CausableConductor-1.0.0.dmg s3://your-bucket/releases/
```

### 2. Create Download Page

Example HTML:
```html
<!DOCTYPE html>
<html>
<head>
    <title>Download Causable Conductor</title>
</head>
<body>
    <h1>Causable Conductor for macOS</h1>
    <h2>Version 1.0.0</h2>
    
    <a href="/downloads/CausableConductor-1.0.0.dmg" class="download-btn">
        Download for macOS
    </a>
    
    <h3>System Requirements</h3>
    <ul>
        <li>macOS 13.0 (Ventura) or later</li>
        <li>Apple Silicon or Intel processor</li>
        <li>50 MB disk space</li>
    </ul>
    
    <h3>Installation</h3>
    <ol>
        <li>Download the DMG file</li>
        <li>Open the DMG</li>
        <li>Drag Causable Conductor to Applications</li>
        <li>Launch from Applications folder</li>
    </ol>
</body>
</html>
```

### 3. Generate Checksums

```bash
# SHA256 checksum
shasum -a 256 CausableConductor-1.0.0.dmg > CausableConductor-1.0.0.dmg.sha256

# MD5 (legacy)
md5 CausableConductor-1.0.0.dmg > CausableConductor-1.0.0.dmg.md5
```

Publish checksums on download page for verification.

---

## Auto-Updates with Sparkle

### 1. Add Sparkle Framework

1. Download [Sparkle](https://sparkle-project.org/)
2. Drag `Sparkle.framework` into Xcode project
3. Add to **Frameworks, Libraries, and Embedded Content**
4. Ensure it's set to **Embed & Sign**

### 2. Configure Info.plist

Add to `Info.plist`:
```xml
<key>SUFeedURL</key>
<string>https://causable.dev/appcast.xml</string>

<key>SUPublicEDKey</key>
<string>YOUR_PUBLIC_EDDSA_KEY</string>

<key>SUEnableAutomaticChecks</key>
<true/>

<key>SUAutomaticallyUpdate</key>
<false/>
```

### 3. Generate EdDSA Key Pair

```bash
# Sparkle includes generate_keys tool
./Sparkle.framework/Resources/generate_keys

# Output:
# Public key: ...
# Private key: ... (keep secret!)
```

Save private key securely (e.g., 1Password, keychain).

### 4. Create Appcast Feed

**appcast.xml:**
```xml
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
    <channel>
        <title>Causable Conductor Changelog</title>
        <link>https://causable.dev/appcast.xml</link>
        <description>Most recent changes with links to updates.</description>
        <language>en</language>
        
        <item>
            <title>Version 1.0.0</title>
            <sparkle:releaseNotesLink>
                https://causable.dev/release-notes/1.0.0.html
            </sparkle:releaseNotesLink>
            <pubDate>Mon, 01 Nov 2025 10:00:00 +0000</pubDate>
            <enclosure 
                url="https://causable.dev/downloads/CausableConductor-1.0.0.dmg"
                sparkle:version="1.0.0"
                sparkle:shortVersionString="1.0.0"
                length="15728640"
                type="application/octet-stream"
                sparkle:edSignature="SIGNATURE_HERE"
            />
            <sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
        </item>
    </channel>
</rss>
```

### 5. Sign Update

```bash
# Generate signature for DMG
./Sparkle.framework/Resources/sign_update \
    CausableConductor-1.0.0.dmg \
    --ed-key-file path/to/private_key

# Output: edSignature="..."
```

Add signature to appcast.xml.

### 6. Implement in App

In `AppDelegate`:
```swift
import Sparkle

class AppDelegate: NSObject, NSApplicationDelegate {
    private var updaterController: SPUStandardUpdaterController!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize Sparkle
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }
}
```

Add menu item:
```swift
let updateItem = NSMenuItem(
    title: "Check for Updates...",
    action: #selector(checkForUpdates),
    keyEquivalent: ""
)
updateItem.target = self
menu?.addItem(updateItem)

@objc func checkForUpdates() {
    updaterController.checkForUpdates(nil)
}
```

---

## Deployment Checklist

Before releasing:

### Pre-Release
- ✅ All tests pass
- ✅ Version/build numbers updated
- ✅ Code signing certificates valid
- ✅ Entitlements correct
- ✅ Info.plist configured
- ✅ Privacy policy published
- ✅ Release notes written

### Build
- ✅ Release build created
- ✅ Archive successful
- ✅ Code signature valid
- ✅ Hardened runtime enabled
- ✅ XPC service embedded
- ✅ All resources included

### Notarization
- ✅ Submitted to Apple
- ✅ Notarization accepted
- ✅ Ticket stapled
- ✅ Verification passed

### Distribution
- ✅ DMG created
- ✅ DMG signed and notarized
- ✅ Checksums generated
- ✅ Uploaded to server
- ✅ Download page updated
- ✅ Appcast updated (if using Sparkle)

### Testing
- ✅ Fresh install on clean Mac
- ✅ Gatekeeper accepts app
- ✅ All features work
- ✅ Update mechanism works (if applicable)
- ✅ Uninstall works cleanly

---

## Troubleshooting

### Gatekeeper Blocks App

**User sees**: "CausableConductor.app cannot be opened because the developer cannot be verified"

**Causes**:
- App not notarized
- Signature invalid
- Quarantine attribute set

**Solutions**:
```bash
# Check notarization
spctl -a -vv /Applications/CausableConductor.app

# Remove quarantine (for testing only!)
xattr -d com.apple.quarantine /Applications/CausableConductor.app

# For users: Right-click → Open (first launch only)
```

### Notarization Fails

**Check log**:
```bash
xcrun notarytool log $SUBMISSION_ID \
    --keychain-profile "causable-notarization"
```

**Common issues**:
- Missing hardened runtime: Add `--options runtime` to codesign
- Unsigned code: Sign all binaries and frameworks
- Invalid entitlements: Match sandbox requirements

### XPC Service Not Found

**Symptom**: App launches but XPC connection fails

**Check**:
```bash
# Verify XPC service is embedded
ls -la /Applications/CausableConductor.app/Contents/XPCServices/

# Check signature
codesign -vv /Applications/CausableConductor.app/Contents/XPCServices/NotaryXPCService.xpc
```

### Auto-Update Fails

**Check**:
1. Appcast URL accessible
2. EdDSA signature valid
3. DMG downloadable
4. Version number higher than current

---

## Resources

- [Apple Notarization Guide](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [Sparkle Documentation](https://sparkle-project.org/documentation/)
- [Code Signing Guide](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/)

---

**Questions?**

Email: support@causable.dev  
GitHub: https://github.com/danvoulez/Causable-macOS/issues
