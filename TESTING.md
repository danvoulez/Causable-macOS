# Testing Guide for Causable Conductor

This guide provides comprehensive testing procedures for the Causable Conductor macOS application.

## Unit Testing

### CausableSDK Tests

Run SDK unit tests:

```bash
cd CausableSDK
swift test
```

Expected tests:
- ✅ SpanEnvelope encoding/decoding
- ✅ Ed25519 signer generation
- ✅ Signing and verification
- ✅ Signer persistence
- ✅ Outbox enqueue/retrieve
- ✅ Outbox success marking
- ✅ Outbox failure backoff
- ✅ Outbox pending count
- ✅ Hex string conversion

## Integration Testing

### 1. First Launch / Enrollment

**Test**: Device enrollment on first launch

Steps:
1. Delete app support directory: `~/Library/Application Support/dev.causable.notary/`
2. Delete Keychain entry: Open Keychain Access, search for "dev.causable", delete all entries
3. Launch the app
4. Observe Console.app for enrollment logs
5. Check that:
   - Key is generated and stored in Keychain
   - Enrollment request is sent (may fail if server unavailable)
   - Device credentials are persisted

Expected logs:
```
NotaryXPCService: Signer initialized
NotaryXPCService: Enrollment successful. Device ID: <device-id>
```

**Pass criteria**:
- [ ] No crashes
- [ ] Key exists in Keychain after launch
- [ ] outbox.db file created in Application Support
- [ ] Health status shows enrolled: true

### 2. Activity Observation

**Test**: Activity spans are created when switching apps

Steps:
1. Launch the app
2. Enable Observer from menu (if not already enabled)
3. Switch between different applications
4. Check Console.app for activity logs
5. Verify spans are logged

Expected logs:
```
ActivityObserver: Recorded activity - App: Safari, Window: Google
ActivityObserver: Recorded activity - App: Xcode, Window: CausableConductor.swift
```

**Pass criteria**:
- [ ] Activity logged when switching apps
- [ ] Debouncing works (same app/window not logged twice)
- [ ] Window titles are redacted if sensitive
- [ ] No performance degradation

### 3. Privacy / Redaction

**Test**: Sensitive information is redacted from window titles

Steps:
1. Open a window with "password" in the title
2. Focus that window
3. Check logs for redaction

Expected:
```
ActivityObserver: Recorded activity - App: Chrome, Window: [REDACTED]
```

**Pass criteria**:
- [ ] "password" triggers redaction
- [ ] "credit card" triggers redaction
- [ ] "private" triggers redaction
- [ ] Normal titles are not redacted

### 4. XPC Communication

**Test**: Menu Bar app can communicate with XPC service

Steps:
1. Launch app
2. Click menu bar icon
3. Click "Drain Outbox"
4. Observe Console.app

Expected:
```
XPCConnection: Connected to Notary XPC service
```

**Pass criteria**:
- [ ] XPC connection established on launch
- [ ] Health check returns valid JSON
- [ ] Drain outbox command completes
- [ ] No XPC errors in Console

### 5. Offline / Outbox

**Test**: Spans queue when offline

Steps:
1. Disconnect from internet
2. Generate activity (switch apps)
3. Check menu bar - should show "X pending"
4. Reconnect to internet
5. Manually drain or wait for auto-drain
6. Verify pending count goes to 0

**Pass criteria**:
- [ ] Spans are queued when offline
- [ ] Pending count increases
- [ ] Pending count decreases when online
- [ ] No data loss during offline period
- [ ] Outbox survives app restart

### 6. Outbox Persistence

**Test**: Outbox survives crashes and restarts

Steps:
1. Disconnect from internet
2. Generate some activity
3. Force quit the app
4. Relaunch the app
5. Check pending count

**Pass criteria**:
- [ ] Pending spans persist across restarts
- [ ] No duplicate spans after restart
- [ ] Outbox drains correctly after restart

### 7. Exponential Backoff

**Test**: Failed uploads use exponential backoff

Steps:
1. Mock server that returns 500 errors
2. Generate activity
3. Watch retry timing in logs

Expected timing (approx):
- Attempt 1: immediate
- Attempt 2: ~60s
- Attempt 3: ~120s
- Attempt 4: ~240s
- Capped at 30 minutes

**Pass criteria**:
- [ ] Retry delays increase exponentially
- [ ] Jitter is applied
- [ ] Max delay is 30 minutes
- [ ] Successful upload resets backoff

### 8. Keychain Security

**Test**: Keys are stored securely

Steps:
1. Launch app (generates key)
2. Open Keychain Access
3. Search for "dev.causable"
4. Verify key properties

**Pass criteria**:
- [ ] Key is stored in default keychain
- [ ] Access control is appropriate
- [ ] Private key never appears in logs
- [ ] Key persists across app launches

### 9. Memory & CPU Usage

**Test**: Resource usage is minimal

Steps:
1. Launch app
2. Open Activity Monitor
3. Find CausableConductor process
4. Monitor for 10 minutes

**Pass criteria**:
- [ ] Idle CPU < 1%
- [ ] Memory < 150MB
- [ ] No memory leaks over time
- [ ] Energy impact is low

### 10. Menu Bar UI

**Test**: Menu bar interface works correctly

Steps:
1. Click menu bar icon
2. Verify menu items
3. Test each action

**Pass criteria**:
- [ ] Status shows correctly
- [ ] Pause/Resume toggles work
- [ ] Drain outbox triggers action
- [ ] Settings opens (if implemented)
- [ ] Quit terminates app cleanly

## End-to-End Testing

### Complete Flow Test

1. **Fresh Install**
   - Delete all app data
   - Delete Keychain entries
   - Launch app

2. **Enrollment**
   - App generates key
   - App enrolls with Cloud (or mock server)
   - Credentials stored

3. **Activity Collection**
   - Switch apps
   - Verify spans created
   - Check privacy redaction

4. **Offline Queueing**
   - Disconnect network
   - Generate activity
   - Verify queueing

5. **Online Sync**
   - Reconnect network
   - Verify outbox drains
   - Check Cloud received spans

6. **Persistence**
   - Restart app
   - Verify state restored
   - Verify no data loss

## Performance Testing

### Load Test

Generate 100 activities in quick succession:

```bash
# Create a test script
for i in {1..100}; do
    open -a Safari
    sleep 0.5
    open -a TextEdit
    sleep 0.5
done
```

**Pass criteria**:
- [ ] All activities recorded
- [ ] No crashes
- [ ] No memory spikes
- [ ] UI remains responsive

### Stress Test

Leave app running for 24 hours:

**Pass criteria**:
- [ ] No crashes
- [ ] No memory leaks
- [ ] Outbox doesn't grow unbounded
- [ ] All functionality still works

## Security Testing

### 1. Sandbox Validation

Verify app is sandboxed:

```bash
codesign -dvvv --entitlements - /path/to/CausableConductor.app
```

**Pass criteria**:
- [ ] com.apple.security.app-sandbox is true
- [ ] Only required entitlements present
- [ ] No unnecessary permissions

### 2. Network Security

Verify HTTPS is enforced:

**Pass criteria**:
- [ ] All API calls use HTTPS
- [ ] Certificate validation enabled
- [ ] No plaintext credentials in logs

### 3. Data Security

**Pass criteria**:
- [ ] Private keys never exported
- [ ] Credentials not in plain text
- [ ] SQLite database not world-readable
- [ ] No sensitive data in logs

## Failure Mode Testing

### 1. XPC Service Crash

Steps:
1. Force kill XPC service process
2. Generate activity
3. Verify auto-recovery

**Pass criteria**:
- [ ] XPC service restarts automatically
- [ ] No data loss
- [ ] Menu bar app shows disconnected state temporarily

### 2. Cloud Unavailable

Steps:
1. Block outbound connections
2. Generate activity
3. Verify graceful degradation

**Pass criteria**:
- [ ] App continues to function
- [ ] Spans queue locally
- [ ] No crashes or hangs
- [ ] User is not interrupted

### 3. Disk Full

Steps:
1. Fill disk to near capacity
2. Generate activity

**Pass criteria**:
- [ ] Graceful error handling
- [ ] User notification (if applicable)
- [ ] No crashes

### 4. Corrupt Database

Steps:
1. Corrupt outbox.db file
2. Launch app

**Pass criteria**:
- [ ] Database recreated
- [ ] App recovers automatically
- [ ] Corruption logged

## Regression Testing Checklist

Before each release:

- [ ] SDK unit tests pass
- [ ] Enrollment flow works
- [ ] Activity observation works
- [ ] Privacy redaction works
- [ ] Offline queueing works
- [ ] Outbox drains when online
- [ ] Persistence across restarts
- [ ] XPC communication works
- [ ] Menu bar UI functional
- [ ] CPU usage < 1% idle
- [ ] Memory usage < 150MB
- [ ] No crashes after 1 hour
- [ ] Keychain security verified
- [ ] Sandbox entitlements correct

## Manual Testing Scenarios

### Scenario 1: Developer Workflow

1. Launch Xcode
2. Work on a project
3. Switch to Safari for documentation
4. Return to Xcode
5. Build and run
6. Check activity timeline

Expected: All context switches captured

### Scenario 2: Privacy-Sensitive Work

1. Open password manager
2. Open banking app
3. Open confidential document

Expected: Sensitive titles redacted

### Scenario 3: Long-Running Session

1. Leave app running overnight
2. Computer sleeps
3. Wake computer
4. Continue working

Expected: App resumes normally, no missed activities

## Automated Testing

### CI/CD Integration

```yaml
# Example GitHub Actions workflow
name: Test

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v2
      - name: Build SDK
        run: cd CausableSDK && swift build
      - name: Test SDK
        run: cd CausableSDK && swift test
```

## Bug Reporting Template

When filing bugs, include:

1. **Environment**:
   - macOS version
   - App version
   - Hardware (Intel/Apple Silicon)

2. **Steps to Reproduce**:
   - Detailed step-by-step
   - Expected vs actual behavior

3. **Logs**:
   - Console.app output
   - Crash reports if applicable

4. **Additional Context**:
   - Screenshots
   - Video if relevant

## Known Limitations

Current implementation limitations:

1. **Linux Build**: SDK builds on Linux but XPC/Keychain features are macOS-only
2. **Accessibility**: May require Accessibility permissions for window title access
3. **SSE**: Simplified implementation on Linux (full streaming on macOS)
4. **Mock Server**: No mock server provided for testing (implement separately)

## Next Steps

After completing basic testing:

1. Implement mock Cloud server for integration tests
2. Add automated UI tests (XCTest UI)
3. Set up continuous testing in CI
4. Performance profiling with Instruments
5. Security audit
6. Beta testing program
