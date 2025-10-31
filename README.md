# Causable Conductor for macOS

A macOS-native core system that interacts with LogLineOS (Postgres) Cloud for observability and notarization.

## Project Structure

```
.
├── CausableSDK/              # Swift Package - Core SDK
│   ├── Sources/
│   │   └── CausableSDK/
│   │       ├── Client.swift      # Network client for Cloud API
│   │       ├── Envelope.swift    # SpanEnvelope data structures
│   │       ├── Outbox.swift      # SQLite-based outbox for offline support
│   │       └── Signer.swift      # Ed25519 signing with Keychain support
│   ├── Tests/
│   └── Package.swift
│
├── CausableConductor/        # Main macOS Application
│   ├── CausableConductor/    # Menu Bar App (Observer)
│   │   ├── CausableConductorApp.swift
│   │   ├── MenuBarController.swift
│   │   ├── ActivityObserver.swift
│   │   └── XPCConnection.swift
│   └── NotaryXPCService/     # XPC Service (Notary Core)
│       ├── NotaryXPCService.swift
│       ├── NotaryXPCProtocol.swift
│       └── EnrollmentManager.swift
│
└── README.md
```

## Implementation Status

### ✅ EPIC-MAC-001: Foundation - Core Services, SDK and Outbox

#### PR-MAC-101: Swift SDK Implementation
- ✅ Created CausableSDK Swift package
- ✅ Implemented SpanEnvelope with full Codable support
- ✅ Implemented Ed25519 signing with Keychain integration
- ✅ Implemented SQLite-based OutboxStore with:
  - Persistent queue for offline support
  - Exponential backoff with jitter
  - Retry logic with configurable limits
- ✅ Implemented CausableClient with:
  - Enrollment endpoint support
  - Span ingest with idempotency
  - Manifest fetching
  - SSE streaming (with platform-specific implementation)
- ✅ SDK builds successfully
- ✅ Basic unit tests created

#### PR-MAC-102: Notary XPC Service
- ✅ Defined XPC service structure
- ✅ Created NotaryXPC protocol definition
- ✅ Implemented enrollment flow
- ✅ Implemented span enqueuing logic
- ✅ Created service launchd plist

### ✅ EPIC-MAC-002: Observer - Menu Bar App

#### PR-MAC-201: Menu Bar App Implementation  
- ✅ Created menu bar application structure
- ✅ Implemented ActivityObserver with NSWorkspace integration
- ✅ Added polling fallback with CGWindowListCopyWindowInfo
- ✅ Implemented privacy-focused window title redaction
- ✅ Created SwiftUI menu interface

#### PR-MAC-202: XPC Integration
- ✅ Implemented XPC connection from menu bar to Notary
- ✅ Created span transformation logic
- ✅ Integrated outbox status display
- ✅ Implemented pause/resume controls

## Architecture

### Components

1. **CausableSDK** (Swift Package)
   - Pure Swift library for cryptography, networking, and persistence
   - Platform-independent where possible (Linux + macOS support)
   - Uses Apple's swift-crypto for Ed25519 signatures
   - SQLite for outbox persistence

2. **Menu Bar App** (Observer)
   - Lightweight SwiftUI-based menu bar presence
   - Monitors user activity with consent
   - Low CPU usage (< 1% idle)
   - Privacy-first design with local redaction

3. **XPC Service** (Notary Core)
   - Sandboxed security boundary
   - Exclusive key access
   - Manages signing and upload queue
   - Handles enrollment and policy updates

### Security Model

- **Sandboxed**: Full App Sandbox enabled
- **Keys**: Ed25519 keys stored in macOS Keychain
  - Preference for Secure Enclave where available
  - Never exported from device
- **Privacy**: All spans default to `visibility=private`
- **Idempotency**: Digest-based deduplication

## Building the Project

### Prerequisites

- macOS 13.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later

### Building the SDK

```bash
cd CausableSDK
swift build
swift test
```

### Building the macOS App

**Note**: The macOS app requires Xcode to build as it includes:
- XPC services
- Keychain entitlements
- App Sandbox configuration
- Code signing requirements

To build in Xcode:
1. Open `CausableConductor.xcodeproj`
2. Select the CausableConductor scheme
3. Build and run (⌘R)

## Configuration

### Environment Variables

- `CAUSABLE_CLOUD_URL`: Base URL for LogLineOS Cloud (default: production)
- `CAUSABLE_LOG_LEVEL`: Logging verbosity (debug, info, warn, error)

### First Run

On first launch, the app will:
1. Generate Ed25519 key pair in Keychain
2. Prompt for enrollment with Cloud
3. Request necessary permissions (Accessibility for window title sampling)
4. Start observing activity

## Testing

### SDK Tests

```bash
cd CausableSDK
swift test
```

### Manual Testing Checklist

- [ ] Menu bar icon appears and is responsive
- [ ] Activity sampling detects app/window changes
- [ ] Spans are created with correct structure
- [ ] Offline mode: spans queue in outbox
- [ ] Online mode: outbox drains successfully
- [ ] Enrollment flow completes
- [ ] Keys are stored securely in Keychain
- [ ] Privacy: sensitive titles are redacted
- [ ] CPU usage remains < 1% when idle

## API Endpoints

The SDK communicates with these Cloud endpoints:

- `POST /api/enroll` - Device enrollment
- `POST /api/spans` - Span ingest with idempotency
- `GET /manifest/{name}` - Fetch policy manifests
- `GET /api/timeline/stream` - SSE event stream

## Privacy & Data Collection

### What is Collected

- Foreground application name
- Window titles (with redaction of sensitive patterns)
- Activity timestamps
- Device fingerprint (for enrollment)

### What is NOT Collected

- Source code
- File contents
- Keystrokes
- Screenshots
- Network traffic content

### Redaction Patterns

The following patterns are redacted from window titles:
- Password fields
- Credit card numbers
- Social security numbers
- Email subjects containing "private" or "confidential"

Users can configure additional redaction patterns in preferences.

## Entitlements

Required entitlements for the app:

```xml
<key>com.apple.security.app-sandbox</key>
<true/>
<key>com.apple.security.network.client</key>
<true/>
<key>com.apple.security.device.usb</key>
<false/>
<key>keychain-access-groups</key>
<array>
    <string>$(AppIdentifierPrefix)dev.causable.mac</string>
</array>
```

## License

(Add your license here)

## Support

For issues and questions, please contact:
- Email: support@causable.dev
- GitHub Issues: https://github.com/danvoulez/Causable-macOS/issues
