# Security Audit Report
## Afeedi — v1.0 Release Security Review

**Prepared:** 2026-05-30  
**Branch:** claude/optimistic-hopper-PLQOv  
**Scope:** Client-side Flutter app, SharedPreferences storage, YouTube IFrame integration, authentication flows

---

## Executive Summary

The Afeedi codebase demonstrates a strong security baseline for a v1.0 consumer Flutter app. Critical authentication mechanisms (PBKDF2 password hashing, PIN brute-force lockout, avatar path-traversal guard) are correctly implemented. Two **HIGH** severity issues require remediation before public release: missing rate limiting on email/password login, and absent client-side input validation.

---

## CRITICAL — Fixed ✅

### CR-1: PBKDF2-HMAC-SHA256 Password Hashing
- **File:** `lib/services/local_auth_service.dart`
- **Status:** ✅ Implemented correctly
- **Detail:** Passwords are hashed using PBKDF2 with SHA-256, 100,000 iterations, and a random salt. This meets NIST SP 800-132 recommendations (minimum 10,000 iterations; 100,000 is conservative and appropriate). The `crypto` package is used for HMAC operations.
- **Compliance:** RFC 2898 §5.2 multi-block derivation confirmed.

### CR-2: Avatar Path Traversal Guard
- **File:** `lib/screens/profile_screen.dart`
- **Status:** ✅ Implemented
- **Detail:** User-supplied avatar file paths are validated before use, preventing `../` traversal attacks that could expose arbitrary file system paths on the device.

### CR-3: PIN Brute-Force Lockout
- **File:** `lib/services/local_auth_service.dart`
- **Status:** ✅ Implemented
- **Detail:** `_maxFailedAttempts = 5` and `_lockoutUntilKey` provide a 5-attempt lockout with a time-based cooldown. Failed attempts are persisted in SharedPreferences to survive app restarts.

### CR-4: youtube_explode_dart Disabled
- **Status:** ✅ Permanently disabled
- **Detail:** The `youtube_explode_dart` package, which would violate YouTube ToS by bypassing the IFrame API, is present as a dependency but all usage has been removed. YouTube content is served exclusively via the IFrame embed API.

---

## HIGH — Requires Fix Before Release

### H-1: No Rate Limiting on Email/Password Login
- **Severity:** HIGH
- **File:** `lib/services/local_auth_service.dart` — `signIn()` method
- **Issue:** The PIN login correctly enforces a 5-attempt lockout. The email/password `signIn()` path does **not** apply equivalent protection. An attacker can make unlimited login attempts with different passwords.
- **Recommendation:**
  ```dart
  // Add to signIn() before credential check:
  final attempts = prefs.getInt('email_failed_attempts_${email}') ?? 0;
  final lockoutUntil = prefs.getInt('email_lockout_until_${email}') ?? 0;
  if (DateTime.now().millisecondsSinceEpoch < lockoutUntil) {
    throw AuthException('Too many attempts. Try again in 15 minutes.');
  }
  if (attempts >= 5) {
    await prefs.setInt('email_lockout_until_${email}',
      DateTime.now().add(Duration(minutes: 15)).millisecondsSinceEpoch);
    await prefs.setInt('email_failed_attempts_${email}', 0);
    throw AuthException('Account locked for 15 minutes.');
  }
  ```
- **Target:** 5 attempts → 15-minute lockout, matching PIN behaviour.

### H-2: Client-Side Email Validation Missing
- **Severity:** HIGH (input hygiene)
- **File:** Auth and sign-up form screens
- **Issue:** The email field accepts any string without regex validation. While server-side validation would catch this in a production app, Afeedi's local auth has no server layer. Malformed emails can be stored and cause silent failures in email-dependent flows.
- **Recommendation:**
  ```dart
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  // In form validator:
  validator: (value) {
    if (value == null || !_emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  },
  ```

---

## MEDIUM — Should Fix

### M-1: Search Query Not Sanitised or Length-Limited
- **Severity:** MEDIUM
- **File:** Search screen / `ContentService`
- **Issue:** The search `TextField` has no `maxLength` constraint and does not sanitise input before passing to content queries. While there is no SQL backend to inject into, overly long queries can cause performance issues and unexpected API behaviour.
- **Recommendation:** Add `maxLength: 200` to the search `TextField` and trim/strip control characters before use.

### M-2: External URLs Not Validated Before `launchUrl`
- **Severity:** MEDIUM
- **Files:** Any screen calling `url_launcher`'s `launchUrl`
- **Issue:** External URLs from content metadata are passed to `launchUrl` without validating the scheme. A maliciously crafted content item could supply a `javascript:` or `file:` URI.
- **Recommendation:**
  ```dart
  Future<void> _launchSafe(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !['http', 'https'].contains(uri.scheme)) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
  ```

### M-3: Error Messages May Leak Stack Traces
- **Severity:** MEDIUM
- **Files:** Various screens using `SnackBar` for error display
- **Issue:** Some catch blocks pass `error.toString()` directly to SnackBar messages. In debug builds this is acceptable; in release builds it risks leaking internal class names, file paths, or implementation details to users.
- **Recommendation:** In release builds, show generic error messages. Use `kDebugMode` to gate verbose error display:
  ```dart
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(kDebugMode ? error.toString() : 'Something went wrong. Please try again.'),
  ));
  ```

---

## LOW — Accepted / Informational

### L-1: SharedPreferences Not Encrypted
- **Severity:** LOW (Accepted risk for v1.0)
- **Detail:** Auth tokens and user preferences are stored in SharedPreferences, which is not encrypted at rest on Android (stored as plaintext XML in the app's private data directory). This is only accessible if the device is rooted or physically compromised.
- **Accepted Risk:** v1.0 stores no financial or health data. Plan `flutter_secure_storage` migration for v1.1.
- **Status:** ACCEPTED RISK

### L-2: No SQL Injection Risk
- **Status:** ✅ Not applicable
- **Detail:** Afeedi uses SharedPreferences and Hive (key-value stores), not SQLite. No SQL injection surface exists.

### L-3: HTTPS for All External Requests
- **Status:** ✅ Confirmed
- **Detail:** YouTube IFrame API calls use HTTPS. All `CachedNetworkImage` thumbnail URLs use `https://img.youtube.com/`. The `android:usesCleartextTraffic` flag is not set (defaults to false on API 28+).

### L-4: No Hardcoded API Keys in Source
- **Status:** ✅ Confirmed
- **Detail:** No YouTube API keys or third-party credentials are embedded in the Dart source files. The YouTube IFrame player does not require an API key for embedded playback.

---

## Security Score Summary

| Category | Score | Notes |
|----------|-------|-------|
| Authentication | 8/10 | Strong PBKDF2; PIN lockout; email lockout missing (-2) |
| Input Validation | 5/10 | Email regex missing; search unsanitised; URL unvalidated |
| Data Storage | 6/10 | SharedPreferences unencrypted; no SQL risk; no key leaks |
| Network Security | 9/10 | HTTPS everywhere; no cleartext; ToS-compliant |
| Error Handling | 7/10 | Stack trace leakage risk in release builds |
| **Overall** | **7/10** | Ship-ready with H-1 and H-2 fixed |

---

## Release Recommendation

**Do not release without fixing H-1 (email rate limiting) and H-2 (email validation).** All other findings are medium/low severity and can be addressed in patch releases. With H-1 and H-2 fixed, the app meets the security bar for a v1.0 consumer release.

---

*Audit performed via static code analysis of the Afeedi Flutter source tree. No dynamic analysis or penetration testing was conducted.*
