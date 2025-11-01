# App Store Submission Guide

## Complete Guide for Submitting Causable Conductor to the macOS App Store

This document provides comprehensive instructions for preparing and submitting Causable Conductor to the macOS App Store.

---

## Prerequisites

Before starting the submission process, ensure you have:

- ✅ **Apple Developer Program Membership** ($99/year)
- ✅ **App Store Connect Access** with App Manager role or higher
- ✅ **Xcode 15.0+** with command line tools
- ✅ **macOS 13.0+** for building and testing
- ✅ **Completed Xcode project setup** (see [XCODE_SETUP.md](XCODE_SETUP.md))
- ✅ **All tests passing** (see [TESTING.md](TESTING.md))
- ✅ **Privacy Policy published** (see [PRIVACY_POLICY.md](PRIVACY_POLICY.md))

---

## Part 1: App Store Connect Setup

### 1.1 Create App Record

1. Log in to [App Store Connect](https://appstoreconnect.apple.com)
2. Go to **My Apps**
3. Click **+ (New App)**
4. Fill in the form:
   - **Platforms**: macOS
   - **Name**: Causable Conductor
   - **Primary Language**: English (U.S.)
   - **Bundle ID**: Select `dev.causable.CausableConductor`
   - **SKU**: `causable-conductor-macos` (unique identifier)
   - **User Access**: Full Access

### 1.2 App Information

Navigate to **App Information** section:

**Category**:
- **Primary Category**: Developer Tools
- **Secondary Category**: Productivity

**Licensing**:
- **Content Rights**: You own the content rights

**Age Rating**:
- Complete the age rating questionnaire
- Expected rating: 4+ (no concerning content)

---

## Part 2: Version Information

### 2.1 Version Details

Navigate to **1.0.0** (or your version) under macOS App:

**Basic Information**:
- **Version Number**: `1.0.0`
- **Copyright**: `2025 Causable`
- **Category**: Developer Tools

### 2.2 App Description

**Name**: (max 30 characters)
```
Causable Conductor
```

**Subtitle**: (max 30 characters)
```
Activity Observer & Notary
```

**Promotional Text**: (max 170 characters)
```
Privacy-first activity tracking and notarization for macOS. Observe your workflow, sign with Ed25519, and sync securely to LogLineOS Cloud.
```

**Description**: (max 4,000 characters)
```
Causable Conductor - Native Activity Observer for macOS

Transform your macOS into an intelligent observability platform. Causable Conductor is a lightweight, privacy-first menu bar application that tracks your development activity and securely notarizes it to the LogLineOS Cloud.

KEY FEATURES

• Passive Activity Observation
  Monitor your app usage and window focus with minimal system impact. Causable Conductor quietly observes your workflow without interrupting your work.

• Secure Ed25519 Signing
  Every activity span is cryptographically signed with Ed25519 keys stored securely in your macOS Keychain. Your private keys never leave your device.

• Offline-First Architecture
  Work anywhere, anytime. Activity spans are queued locally in a persistent SQLite database and automatically synced when you're back online.

• Privacy by Default
  All captured data defaults to private visibility. Sensitive window titles are automatically redacted. No source code or file contents are ever collected.

• XPC Security Boundary
  Cryptographic operations are isolated in a sandboxed XPC service, ensuring your keys are protected even if the main app is compromised.

• Menu Bar Simplicity
  Access all features from a clean, native macOS menu bar interface. Pause/resume tracking, check sync status, and manage settings with one click.

PERFECT FOR

- Developers tracking their workflow and context
- Teams building audit trails for compliance
- Anyone wanting privacy-focused activity logging
- Users of LogLineOS Cloud infrastructure

TECHNICAL HIGHLIGHTS

• Native SwiftUI and AppKit interface
• Fully sandboxed for maximum security
• Minimal resource usage (< 1% CPU idle, < 150MB RAM)
• Exponential backoff with intelligent retry logic
• Real-time status updates via Server-Sent Events (SSE)
• Policy-driven configuration from Cloud

PRIVACY & SECURITY

Causable Conductor is built with privacy as the foundation:
- App Sandbox enabled - restricted file system access
- No analytics or tracking
- No third-party SDKs
- Open architecture (source available)
- Transparent data collection
- Full user control over what's tracked

REQUIREMENTS

- macOS 13.0 (Ventura) or later
- Internet connection for sync (offline mode supported)
- LogLineOS Cloud account (enrollment included)

WHAT'S NOT COLLECTED

Causable Conductor does NOT collect:
- Source code or file contents
- Keystrokes
- Screenshots
- Network traffic
- Personal identifiable information beyond app names

SUPPORT

- Documentation: https://github.com/danvoulez/Causable-macOS
- Privacy Policy: https://causable.dev/privacy
- Support: support@causable.dev

Causable Conductor respects your privacy, secures your data, and stays out of your way. Experience the future of developer observability on macOS.
```

**Keywords**: (max 100 characters, comma-separated)
```
developer,productivity,logging,activity,tracker,observer,notary,privacy,security,workflow
```

**Support URL**:
```
https://github.com/danvoulez/Causable-macOS
```

**Marketing URL** (optional):
```
https://causable.dev
```

**Privacy Policy URL**:
```
https://causable.dev/privacy
```
*(Note: You must host this at a public URL. See [PRIVACY_POLICY.md](PRIVACY_POLICY.md))*

---

## Part 3: App Preview and Screenshots

### 3.1 Screenshot Requirements

**Required sizes** (at minimum, provide one of each):
- **2880 x 1800 pixels** (Retina 5K)
- **2560 x 1600 pixels** (Retina)

**Number of screenshots**: 
- Minimum: 1
- Maximum: 10
- Recommended: 5-7

### 3.2 What to Capture

Create screenshots showing:

1. **Menu Bar Icon & Menu**
   - Menu bar icon visible
   - Full menu expanded showing all options
   - Status indicators visible

2. **Settings Window**
   - Settings panel open
   - All sections visible
   - Status information showing

3. **Activity Observation**
   - Split screen showing app switching
   - Console.app or logs showing activity capture
   - (Use simulated data if needed)

4. **Status Dashboard**
   - Settings showing connection status
   - Pending spans count
   - Last sync timestamp

5. **Privacy Features**
   - Settings showing privacy controls
   - Redaction in action (if possible to demonstrate)

### 3.3 Screenshot Tips

- Use high-resolution display (Retina)
- Clean desktop background
- Light mode or dark mode (provide both if possible)
- No personal or sensitive information
- Professional appearance
- Clear, readable text
- Focus on app features

### 3.4 Taking Screenshots

```bash
# Take screenshot of entire screen
Command + Shift + 3

# Take screenshot of selected area
Command + Shift + 4

# Take screenshot of window (with shadow)
Command + Shift + 4, then Space, then click window

# Screenshots save to Desktop by default
```

### 3.5 App Preview Video (Optional but Recommended)

- **Length**: 15-30 seconds
- **Format**: .mov, .mp4, or .m4v
- **Resolution**: 1920x1080 or higher
- **Content**: 
  - App launch
  - Menu interaction
  - Settings panel
  - Key features demonstration

---

## Part 4: App Privacy Details

### 4.1 Privacy Questions

Apple requires detailed privacy information. Answer these:

**Does this app collect data?**
- **Yes** (we collect activity data)

**Data Types Collected**:

1. **Product Interaction** (Usage Data)
   - Purpose: App Functionality, Analytics
   - Collection Method: Collected from user's device
   - Linked to user: No
   - Used for tracking: No

2. **System Information**
   - Device ID: Yes
   - Purpose: App Functionality, Developer's Advertising
   - Linked to user: Yes
   - Used for tracking: No

### 4.2 Privacy Practices

**Data Collection**:
- App usage (app names, window titles)
- Device fingerprint (for enrollment)
- Timestamps

**Not Collected**:
- Source code
- File contents
- Keystrokes
- Screenshots
- Precise location
- Contacts
- Photos

**Data Usage**:
- App functionality only
- Not shared with third parties
- Not used for advertising
- Not used for analytics (except usage patterns)

**Data Retention**:
- Stored on LogLineOS Cloud
- Retained indefinitely unless user deletes
- User can request data deletion

**Data Security**:
- Encrypted in transit (HTTPS/TLS)
- Encrypted at rest (database encryption)
- End-to-end signed (Ed25519)

---

## Part 5: Pricing and Availability

### 5.1 Pricing

**Price**: 
- **Free** (recommended for v1.0.0)
- Or set price tier

**In-App Purchases**:
- None for v1.0.0
- Future: Could add premium features

### 5.2 Availability

**Countries/Regions**:
- Select **All Countries and Regions**
- Or limit to specific regions

**Pre-Order**:
- Not applicable for first release

---

## Part 6: App Review Information

### 6.1 Contact Information

Provide accurate contact details for App Review team:

**First Name**: Your first name
**Last Name**: Your last name
**Phone**: Your phone with country code
**Email**: Your support email (e.g., support@causable.dev)

### 6.2 Demo Account

If your app requires login or enrollment:

**Username**: `demo@causable.dev`
**Password**: `demo-password-123`

Provide a working demo account for reviewers.

### 6.3 Notes

Provide helpful information for reviewers:

```
TESTING INSTRUCTIONS:

1. Launch the app - it will appear in the menu bar (not in Dock)
2. Click the menu bar icon to open the menu
3. The app will request:
   - Notification permissions (optional)
   - Accessibility permissions (optional for window title tracking)

DEMO ACCOUNT:
- Username: demo@causable.dev
- Password: demo-password-123

FEATURES TO TEST:
1. Menu Bar Icon: Click to see menu options
2. Observer: Pause/Resume activity tracking
3. Settings: Click "Settings..." to open settings panel
4. Status: View connection and sync status
5. Outbox: Manual drain function

NOTES:
- The app operates as a menu bar utility (LSUIElement = true)
- XPC service auto-launches for security isolation
- Offline mode: Spans queue locally when cloud is unreachable
- Privacy: Window title redaction for sensitive patterns

PERMISSIONS:
- Notifications: Optional, for status updates
- Accessibility: Optional, for advanced window tracking
- Network: Required for cloud sync

The app is fully functional without any permissions granted.

DEMO SERVER:
We've configured the demo account to work with our staging server.
All data is mock/test data for review purposes.
```

### 6.4 Attachments (Optional)

Upload additional documents:
- Architecture diagram
- Privacy policy PDF
- Security whitepaper

---

## Part 7: Build and Upload

### 7.1 Archive the App

1. In Xcode, select **Product → Archive**
2. Wait for build to complete
3. Xcode Organizer opens automatically

### 7.2 Validate the Archive

Before uploading:

1. Select the archive
2. Click **Validate App**
3. Choose distribution method: **App Store Connect**
4. Select distribution options:
   - ✅ **Include bitcode**: No (not available for macOS)
   - ✅ **Upload your app's symbols**: Yes
   - ✅ **Manage version and build number**: Xcode-managed
5. Select signing certificate
6. Click **Validate**
7. Wait for validation to complete (1-5 minutes)
8. Fix any errors/warnings

### 7.3 Upload to App Store Connect

1. Click **Distribute App**
2. Choose **App Store Connect**
3. Choose **Upload**
4. Select same distribution options as validation
5. Select signing certificate
6. Review summary
7. Click **Upload**
8. Wait for upload (can take 5-30 minutes depending on size)

### 7.4 Processing

After upload:
1. Archive appears in App Store Connect (takes 5-15 minutes)
2. Processing begins automatically
3. You'll receive email when processing completes
4. Status changes from "Processing" to "Ready to Submit"

---

## Part 8: Submit for Review

### 8.1 Select Build

1. Return to App Store Connect
2. Go to your app → **1.0.0** version
3. Under **Build**, click **Select a build before you submit**
4. Choose the build you uploaded
5. Click **Done**

### 8.2 Export Compliance

**Does your app use encryption?**
- **Yes** (we use HTTPS/TLS)

**Does your app implement any encryption algorithms?**
- **No** (we only use Apple's system crypto)

This qualifies for exemption (standard HTTPS doesn't require export compliance documentation).

### 8.3 Content Rights

Confirm:
- ✅ You have the rights to distribute this app
- ✅ App complies with App Review Guidelines
- ✅ Privacy Policy is accurate and accessible

### 8.4 Submit

1. Review all information one final time
2. Click **Add for Review** (or **Submit for Review**)
3. Confirm submission

---

## Part 9: App Review Process

### 9.1 Timeline

Typical timeline:
- **Submission**: Immediate
- **Waiting for Review**: 1-3 days
- **In Review**: 1-2 days
- **Total**: 2-5 days on average

### 9.2 Status Updates

Monitor status:
1. App Store Connect dashboard
2. Email notifications
3. App Store Connect app (iOS/iPadOS)

**Possible statuses**:
- Waiting for Review
- In Review
- Pending Developer Release
- Ready for Sale
- Rejected
- Metadata Rejected

### 9.3 If Rejected

Common rejection reasons and fixes:

**2.1 - App Completeness**
- Ensure demo account works
- Test all features before submission
- Fix: Update demo account, resubmit

**2.3 - Accurate Metadata**
- Screenshots don't match functionality
- Description is misleading
- Fix: Update screenshots/description

**5.1.1 - Privacy**
- Missing privacy policy
- Incorrect privacy declarations
- Fix: Add/update privacy policy URL

**5.1.2 - Data Use and Sharing**
- Unclear what data is collected
- Fix: Clarify in app and description

**Guideline 4.0 - Design**
- Poor UI/UX
- Inconsistent with macOS guidelines
- Fix: Improve design, follow HIG

### 9.4 Responding to Rejection

1. Read rejection notes carefully
2. Fix all identified issues
3. Update version if needed (or resubmit same)
4. Reply to App Review in Resolution Center
5. Provide additional clarification if needed
6. Resubmit

---

## Part 10: Release

### 10.1 Manual Release

If approved with "Pending Developer Release":

1. Go to App Store Connect
2. Select your app
3. Click **Release This Version**
4. App goes live within 24 hours

### 10.2 Automatic Release

If configured for automatic release:
- App goes live immediately after approval
- No action needed

### 10.3 Phased Release

Enable phased release:
1. Reduces risk of bugs affecting all users
2. Gradually rolls out over 7 days
3. Can pause if issues detected
4. Recommended for first release

### 10.4 Post-Release

After release:
1. Monitor crash reports in App Store Connect
2. Check user reviews
3. Respond to user feedback
4. Plan updates for bug fixes

---

## Part 11: App Store Optimization (ASO)

### 11.1 Keywords Strategy

Choose keywords with:
- High search volume
- Low competition
- High relevance

**Primary keywords**:
- developer tools
- activity tracker
- productivity
- logging
- observer

**Long-tail keywords**:
- macOS activity tracker
- developer workflow
- secure logging

### 11.2 A/B Testing

Test different:
- App icons
- Screenshots
- Promotional text
- App preview videos

### 11.3 Monitoring

Track metrics:
- Impressions
- Product Page Views
- Downloads
- Conversion Rate
- Retention Rate

---

## Part 12: Compliance Checklist

Before submission, verify:

### Technical
- ✅ App builds without errors or warnings
- ✅ All features work as described
- ✅ No crashes during testing
- ✅ Hardened Runtime enabled
- ✅ App Sandbox enabled
- ✅ Code signing valid
- ✅ XPC service launches correctly
- ✅ Keychain access works
- ✅ Network connectivity tested
- ✅ Offline mode works

### Legal
- ✅ Privacy Policy published and accessible
- ✅ Terms of Service (if applicable)
- ✅ EULA (if custom, otherwise use Apple's standard)
- ✅ All third-party licenses included
- ✅ Trademark/copyright compliance

### App Store
- ✅ Screenshots representative of app
- ✅ Description accurate
- ✅ Keywords relevant
- ✅ Demo account works
- ✅ Contact information correct
- ✅ Privacy details accurate
- ✅ Age rating appropriate
- ✅ Category correct

### Testing
- ✅ Fresh install tested
- ✅ Upgrade path tested (future versions)
- ✅ All permissions tested
- ✅ Edge cases covered
- ✅ Performance acceptable
- ✅ No memory leaks

---

## Part 13: Post-Submission Maintenance

### 13.1 Monitoring

Monitor daily:
- Crash reports (App Store Connect)
- User reviews (respond within 48 hours)
- Support emails
- Download metrics

### 13.2 Updates

Plan regular updates:
- **Bug fixes**: As needed (expedited review)
- **Minor updates**: Every 2-4 weeks
- **Major updates**: Every 2-3 months

### 13.3 User Support

Respond to:
- App Store reviews (1-2 days)
- Support emails (24 hours)
- GitHub issues (1-3 days)

---

## Resources

### Apple Documentation
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/macos)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)

### Tools
- [App Store Connect](https://appstoreconnect.apple.com)
- [Apple Developer](https://developer.apple.com)
- [Xcode](https://developer.apple.com/xcode/)

### Support
- [App Review Support](https://developer.apple.com/contact/app-store/)
- [Technical Support](https://developer.apple.com/support/)

---

## Quick Reference: Review Guidelines

Most relevant guidelines for Causable Conductor:

- **2.1**: App must be complete and functional
- **2.3**: Metadata must be accurate
- **5.1.1**: Privacy Policy required
- **5.1.2**: Data Use and Sharing disclosure
- **4.0**: Design must follow macOS HIG
- **2.4.5(i)**: Apps that use background modes
- **1.2**: Safety - must not contain harmful content

---

**Questions or Issues?**

- Email: support@causable.dev
- GitHub: https://github.com/danvoulez/Causable-macOS/issues
- App Review: Use Resolution Center in App Store Connect
