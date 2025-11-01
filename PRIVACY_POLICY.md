# Privacy Policy for Causable Conductor

**Last Updated**: November 1, 2025  
**Effective Date**: November 1, 2025

---

## Introduction

Causable ("we", "our", or "us") operates the Causable Conductor macOS application (the "App"). This Privacy Policy explains how we collect, use, store, and protect your information when you use our App.

We are committed to protecting your privacy and being transparent about our data practices. This policy applies to all users of Causable Conductor.

---

## Information We Collect

### 1. Activity Data

When you use Causable Conductor with activity observation enabled, we collect:

- **Application Names**: The names of applications you use
- **Window Titles**: The titles of windows you focus on (with redaction for sensitive patterns)
- **Timestamps**: When each activity occurred
- **Duration**: How long you focused on each application/window

**Purpose**: To create an activity timeline and provide observability into your workflow.

**Collection Method**: Automatically collected from your device when the Observer is active.

### 2. Device Information

We collect:

- **Device Identifier**: A unique identifier for your device (generated on first launch)
- **Device Fingerprint**: Basic system information for enrollment
- **macOS Version**: Your operating system version

**Purpose**: For device enrollment, authentication, and service functionality.

**Collection Method**: Automatically collected during enrollment.

### 3. Account Information

When you enroll your device, we collect:

- **Tenant ID**: Your LogLineOS Cloud account identifier
- **Owner ID**: Your user identifier
- **Device Token**: Authentication token for API access

**Purpose**: To associate your device with your LogLineOS Cloud account.

**Collection Method**: Provided during enrollment process.

### 4. Technical Data

We automatically collect:

- **Span Metadata**: Technical metadata about uploaded spans (IDs, digests, signatures)
- **Sync Status**: Information about sync operations and outbox state
- **Error Logs**: Technical error information (only when failures occur)

**Purpose**: To ensure data integrity, reliability, and troubleshooting.

**Collection Method**: Automatically collected during normal operation.

---

## What We Do NOT Collect

Causable Conductor is designed with privacy as a core principle. We explicitly **DO NOT** collect:

- ❌ Source code or file contents
- ❌ Keystrokes or input events
- ❌ Screenshots or screen recordings
- ❌ Clipboard contents
- ❌ Network traffic contents
- ❌ File system data (beyond app/window names)
- ❌ Personal identifiable information (names, emails, phone numbers) beyond what you provide during enrollment
- ❌ Location data (precise or coarse)
- ❌ Contact information
- ❌ Photos or media files
- ❌ Health or fitness data
- ❌ Financial information
- ❌ Browser history (beyond focused window titles)

---

## Privacy Features

### Automatic Redaction

Causable Conductor automatically redacts window titles containing sensitive patterns:

- "password" → `[REDACTED]`
- "credit card" → `[REDACTED]`
- "ssn" / "social security" → `[REDACTED]`
- "private" → `[REDACTED]`
- "confidential" → `[REDACTED]`

You can configure additional redaction patterns in settings.

### Default Privacy

- **Visibility**: All captured spans default to `private` visibility
- **Promotion**: You must explicitly promote spans to `tenant` or `public` visibility
- **Control**: You can pause/resume observation at any time

### Local Storage

- **Outbox**: Spans are stored locally in an encrypted SQLite database until uploaded
- **Keys**: Your Ed25519 private key is stored in macOS Keychain and never transmitted
- **Cache**: Minimal caching of manifest data for offline functionality

---

## How We Use Your Information

We use collected information for:

1. **Service Functionality**
   - Creating and maintaining your activity timeline
   - Synchronizing data to LogLineOS Cloud
   - Authenticating your device
   - Managing offline/online state

2. **Security**
   - Cryptographically signing spans with your device key
   - Verifying data integrity with Blake3 digests
   - Ensuring secure communication with Cloud API

3. **Service Improvement**
   - Understanding usage patterns (aggregated, anonymized)
   - Debugging technical issues
   - Improving reliability and performance

4. **Compliance**
   - Meeting audit and compliance requirements (if applicable to your account)
   - Providing audit trails as configured

We do **NOT** use your information for:
- ❌ Advertising or marketing
- ❌ Selling or sharing with third parties (except service providers)
- ❌ Tracking across other apps or websites
- ❌ Building user profiles for other purposes

---

## Data Sharing and Disclosure

### Service Providers

We share data with:

- **LogLineOS Cloud**: Our backend service that stores your activity timeline
  - Provider: Causable infrastructure
  - Purpose: Core service functionality
  - Data: All collected activity and device data
  - Security: TLS encryption, Ed25519 signatures

We do **NOT** share data with:
- ❌ Advertisers
- ❌ Analytics companies (beyond basic service metrics)
- ❌ Social media platforms
- ❌ Data brokers
- ❌ Any third party for purposes other than service operation

### Legal Requirements

We may disclose information if required by:
- Valid legal process (subpoena, court order)
- To protect our rights or property
- To prevent harm or illegal activity
- As required by law

We will notify you of such requests unless legally prohibited.

### Business Transfers

If Causable is involved in a merger, acquisition, or sale of assets, your information may be transferred. We will notify you and ensure the same privacy protections apply.

---

## Data Security

### Encryption

- **In Transit**: All data transmitted to LogLineOS Cloud uses TLS 1.2+
- **At Rest**: Data stored in LogLineOS Cloud is encrypted at rest
- **Signatures**: All spans are signed with Ed25519 for integrity verification

### Access Control

- **Private Keys**: Your Ed25519 private key never leaves your device
- **Keychain**: Keys are stored in macOS Keychain with restricted access
- **XPC Isolation**: Cryptographic operations isolated in sandboxed XPC service
- **App Sandbox**: Main app runs with restricted file system access

### Infrastructure Security

- Regular security audits
- Vulnerability scanning
- Access logging
- Incident response procedures

### Breach Notification

In the unlikely event of a data breach, we will:
1. Notify affected users within 72 hours
2. Provide details of the breach
3. Explain steps taken to address it
4. Offer guidance on protecting your information

---

## Data Retention

### Active Data

- **Activity Spans**: Retained indefinitely in LogLineOS Cloud unless you delete them
- **Device Information**: Retained while your device is enrolled
- **Authentication Tokens**: Valid until device is unenrolled or tokens are revoked

### Local Data

- **Outbox**: Cleared automatically after successful upload
- **Cache**: Periodically refreshed, old data discarded
- **Logs**: Rotated and deleted after 7 days (local only)

### Deletion

You can request deletion of your data by:
1. Unenrolling your device (deletes device association)
2. Contacting support to delete all account data
3. Using LogLineOS Cloud data management features

We will delete your data within 30 days of request, except:
- Data required for legal compliance
- Data in backups (deleted per backup retention schedule)
- Anonymized/aggregated data that cannot identify you

---

## Your Rights

### Access

You have the right to:
- View all data we've collected about you
- Export your data in machine-readable format
- Request details about how we process your data

### Control

You can:
- Pause/resume activity observation at any time
- Configure redaction patterns
- Set span visibility (private/tenant/public)
- Manage which data is uploaded

### Deletion

You can:
- Delete specific spans via LogLineOS Cloud
- Unenroll your device (removes device data)
- Request complete account deletion

### Portability

You can:
- Export your activity data in JSON format
- Transfer data to another service
- Access data via LogLineOS Cloud API

### Correction

You can:
- Request correction of inaccurate data
- Update device information
- Modify account details

To exercise these rights, contact us at privacy@causable.dev

---

## Children's Privacy

Causable Conductor is not intended for users under 13 years of age. We do not knowingly collect information from children. If we become aware we've collected data from a child under 13, we will delete it promptly.

---

## International Users

### Data Transfer

LogLineOS Cloud infrastructure may be located in various countries. By using Causable Conductor, you consent to transfer of your data to these locations.

We ensure appropriate safeguards are in place:
- EU-U.S. Privacy Shield compliance (where applicable)
- Standard contractual clauses
- Adequacy decisions

### GDPR Compliance (EU Users)

If you are in the European Economic Area (EEA):

**Legal Basis for Processing**:
- Contract performance (service delivery)
- Legitimate interests (service improvement, security)
- Consent (for optional features)

**Your Additional Rights**:
- Right to object to processing
- Right to restrict processing
- Right to data portability
- Right to lodge a complaint with supervisory authority

**Data Protection Officer**: dpo@causable.dev

### CCPA Compliance (California Users)

If you are a California resident:

**Your Rights**:
- Right to know what data we collect
- Right to delete your data
- Right to opt-out of sale (we don't sell data)
- Right to non-discrimination

**Categories Collected**: As described in "Information We Collect"

**Do Not Sell**: We do not sell personal information.

---

## Cookies and Tracking

Causable Conductor does **NOT**:
- Use cookies
- Use web beacons
- Use tracking pixels
- Track you across websites or apps
- Use analytics SDKs

The app operates independently without browser-based tracking technologies.

---

## Changes to This Policy

We may update this Privacy Policy from time to time. Changes will be:

1. Posted on this page with updated "Last Updated" date
2. Notified via email (if we have your email)
3. Announced in-app (for significant changes)
4. Effective 30 days after posting (unless urgent security reasons)

Continued use of Causable Conductor after changes constitutes acceptance.

---

## Third-Party Services

### LogLineOS Cloud

Our backend service. See their privacy policy at: https://loglineos.dev/privacy

### Apple Services

We use Apple's native macOS APIs:
- Keychain (for secure key storage)
- Notifications (for status updates)
- Accessibility (for window title access, optional)

These are governed by Apple's privacy policies.

---

## Contact Us

For privacy-related questions, concerns, or requests:

**Email**: privacy@causable.dev  
**Support**: support@causable.dev  
**Mail**: 
```
Causable Privacy Team
[TODO: Replace with your actual mailing address]
[City, State ZIP]
[Country]
```

**Note**: You must provide a valid mailing address before publishing this privacy policy.

**Response Time**: We aim to respond within 2 business days.

---

## Transparency Report

We believe in transparency. We will publish annual reports detailing:
- Number of legal requests received
- Number of accounts affected
- Types of data requested
- Our responses

First report: January 2026

---

## Open Source

Causable Conductor's architecture is open for inspection:
- Source code: https://github.com/danvoulez/Causable-macOS
- Technical documentation available
- Security audits welcome

---

## Specific Disclosures

### macOS Permissions

**Accessibility**: 
- **Purpose**: To read window titles of focused applications
- **Optional**: You can use the app without granting this permission
- **Impact**: Without permission, only app names (not window titles) are tracked

**Notifications**:
- **Purpose**: To show status updates and alerts
- **Optional**: You can deny this permission
- **Impact**: You won't receive visual notifications

**Network**:
- **Purpose**: To sync data with LogLineOS Cloud
- **Required**: App cannot sync without network access
- **Impact**: Without network, app operates in offline mode only

---

## Security Best Practices for Users

We recommend:

1. **Keep macOS Updated**: For latest security patches
2. **Strong Account Passwords**: For LogLineOS Cloud account
3. **Enable FileVault**: For disk encryption
4. **Review Permissions**: Periodically check what permissions are granted
5. **Monitor Activity**: Review your activity timeline regularly
6. **Report Issues**: Contact us immediately if you notice suspicious activity

---

## Compliance Certifications

Causable Conductor and LogLineOS Cloud maintain:

- ✅ SOC 2 Type II (in progress)
- ✅ GDPR compliance
- ✅ CCPA compliance
- ✅ Apple App Store requirements

---

## Effective Date

This Privacy Policy is effective as of November 1, 2025 and applies to all users of Causable Conductor version 1.0.0 and later.

---

## Acceptance

By downloading, installing, or using Causable Conductor, you acknowledge that you have read and understood this Privacy Policy and agree to its terms.

If you do not agree with this Privacy Policy, please do not use Causable Conductor.

---

**Causable** – Privacy-first observability for macOS.

---

*This Privacy Policy is provided in English. Translations may be available but the English version governs in case of discrepancies.*
