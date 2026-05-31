# Security Report — Afeedi Flutter App

**Audit Date:** 2026-05-30  

---

## Findings Summary

| ID | Severity | Finding | Status |
|---|---|---|---|
| S-001 | Critical | OAuth access/ID tokens stored in unencrypted SharedPreferences | Open |
| S-002 | High | User email leaked into analytics payload (`oauth_signin_success`) | ✅ Fixed |
| S-003 | High | Raw search query stored in analytics (PII risk) | ✅ Fixed |
| S-004 | High | `signInWithOAuth` accepts caller-supplied auth data with no server validation | Architecture Limitation |
| S-005 | Medium | Analytics event log written to unencrypted on-device JSON file | Open |
| S-006 | Medium | User ID generated from millisecond timestamp (predictable, not cryptographically random) | Open |
| S-007 | Medium | `user_email` stored in plaintext SharedPreferences (PII at rest) | Open |
| S-008 | Low | `changePassword`/`resetPassword` are no-op stubs returning success | Open |
| S-009 | Low | Admin routes defined in navigation map with no auth guard | Open |
| S-010 | Low | `ConnectivityService` uses DNS probe to 8.8.8.8 — leaks network activity | Informational |

---

## Detailed Findings

### S-001: OAuth Tokens in Plaintext SharedPreferences (Critical)
**Location:** `lib/services/auth_service.dart` lines 213–218  
**Description:** `oauth_access_token_<provider>` and `oauth_id_token_<provider>` are written to `SharedPreferences`. On Android, this is backed by an unencrypted XML file readable via ADB backup or by any app with `READ_EXTERNAL_STORAGE`. On iOS, the Preferences plist is not in the Keychain.  
**Remediation:** Migrate all token writes to `flutter_secure_storage` which uses Android Keystore / iOS Keychain. Requires `flutter_secure_storage: ^9.x` dependency.

### S-002: Email in Analytics Payload (Fixed)
**Location:** `lib/services/auth_service.dart` — `signInWithOAuth()`  
**Fix Applied:** `email` field removed from `additionalData` in `oauth_signin_success` event. Event now contains only `provider` and `user_id`.

### S-003: Raw Search Query in Analytics (Fixed)
**Location:** `lib/services/analytics_service.dart` — `trackSearchQuery()`  
**Fix Applied:** Replaced `'query': query` with `'query_length': query.length`. No raw text is persisted.

### S-004: OAuth Auth Data Not Server-Validated (Architecture Limitation)
**Location:** `lib/services/auth_service.dart` — `signInWithOAuth()`  
**Description:** The method accepts a `Map<String, dynamic> oauthData` parameter. Any caller can construct a fake map and create a valid local session. This is acceptable in the current local-only phase but must be replaced with server-side token verification (ID token validation against Google/Apple public keys) before production.

### S-005: Unencrypted Analytics Log (Medium)
**Location:** `lib/services/analytics_service.dart` — events written to `analytics_events.json`  
**Description:** The file sits in the app's documents directory. On Android, it is accessible via `adb pull`. It contains `user_id` (persistent identifier) + behavioral event data.  
**Remediation:** Encrypt the file with `encrypt: ^5.x` or ship events to a server immediately and discard locally.

### S-006: Predictable User ID (Medium)
**Location:** `lib/services/local_auth_service.dart`  
**Description:** `userId = DateTime.now().millisecondsSinceEpoch.toString()` — predictable, 13-digit timestamp. Two users registering within the same millisecond get the same ID.  
**Remediation:** Use `const Uuid().v4()` from the `uuid` package.

---

## Input Validation

| Area | Status |
|---|---|
| Search query | ✅ — sanitized via Dart string; no SQL/API injection risk (in-memory only) |
| Onboarding text input | ✅ — never executed; stored as string |
| URL launch | ✅ — `Uri.tryParse()` before `launchUrl`; null-checked |
| SharedPreferences keys | ✅ — keys are programmer-defined constants, not user-controlled |

## Transport Security

All HTTP calls use HTTPS (`https://` schemes). `ConnectivityService` connects to `8.8.8.8` over HTTP only for connectivity probe — no sensitive data transmitted.

---

## Security Readiness Score: 4 / 10

The app is safe against injection attacks, XSS (no web views rendering user content), and CSRF (no backend). The primary exposure is PII storage in plaintext SharedPreferences. No user data is transmitted to any third party beyond the platform OAuth flows. Pre-production hardening requires secure token storage and server-side identity verification.
