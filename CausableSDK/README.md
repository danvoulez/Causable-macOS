# CausableSDK

Swift SDK for the Causable macOS application providing core networking, cryptography, and persistence capabilities.

## Overview

CausableSDK is the foundation of the LogLineOS Core for macOS. It provides:

- **SpanEnvelope**: Canonical data structures for representing spans
- **SpanSigner**: Ed25519 cryptographic signing using Swift Crypto
- **OutboxStore**: SQLite-backed persistent queue for offline resilience
- **CausableClient**: Network client for the LogLineOS Cloud API
- **SSEClient**: Server-Sent Events client (placeholder, to be completed in PR-MAC-301)

## Requirements

- macOS 13.0+
- Swift 5.9+

## Installation

Add as a Swift Package dependency:

```swift
dependencies: [
    .package(url: "https://github.com/danvoulez/Causable-macOS.git", from: "1.0.0")
]
```

## Usage

### Creating and Signing a Span

```swift
import CausableSDK

// Create a signer
let signer = Ed25519Signer()

// Create a span
let metadata = SpanMetadata(
    tenantId: "tenant-123",
    ownerId: "owner-456",
    deviceId: "device-789",
    ts: "2025-10-31T18:00:00Z"
)

var span = SpanEnvelope(
    id: "span-001",
    entityType: "activity",
    who: "observer:menubar@1.0.0",
    did: "focused",
    this: "device:test-device",
    status: "complete",
    metadata: metadata,
    visibility: "private"
)

// Sign the span
let encoder = JSONEncoder.causableCanonical
let canonical = try encoder.encode(span)
let digestBytes = DigestUtils.computeDigestBytes(canonical)
let sig = try signer.sign(digestBytes)
let pubkey = try signer.publicKeyHex()

span.digest = DigestUtils.computeDigest(canonical)
span.signature = Signature(
    algo: "ed25519",
    pubkey: pubkey,
    sig: sig.hexString
)
```

### Using the Outbox

```swift
// Initialize outbox
let outbox = try OutboxStore(path: "/path/to/database.db")

// Enqueue a span
try outbox.enqueue(span: span)

// Get next span to send
if let entry = try outbox.nextAttempt() {
    // Send span...
    
    // Mark as sent
    try outbox.markSent(id: entry.id)
}
```

### Using the Client

```swift
// Initialize client
let client = CausableClient(
    baseURL: URL(string: "https://api.causable.dev")!,
    tokenProvider: { return deviceToken },
    signer: signer,
    outbox: outbox
)

// Ingest a span
let spanId = try await client.ingest(span: span)

// Fetch a manifest
let manifest = try await client.fetchManifest(name: "loglineos_core_manifest@v1")
```

## Architecture

The SDK follows the architecture defined in the Blueprint:

- **Canonical JSON Encoding**: All spans are encoded with sorted keys for deterministic hashing
- **Ed25519 Signatures**: Uses Swift Crypto (cross-platform CryptoKit) for signing
- **Offline Resilience**: Outbox pattern with exponential backoff
- **Idempotency**: Uses HMAC-based idempotency keys

## Testing

Run tests with:

```bash
swift test
```

## Security

- Private keys are managed securely and never leave the device
- All spans are signed before transmission
- Digest computation uses SHA256 (BLAKE3 in production)

## License

Copyright © 2025 Causable

## Roadmap

This SDK implements **PR-MAC-101** of the Causable macOS roadmap.

Next steps:
- PR-MAC-102: Notary XPC Service and Enrollment
- PR-MAC-201: Menu Bar App and Activity Sampling
- PR-MAC-301: Full SSE Client Implementation
