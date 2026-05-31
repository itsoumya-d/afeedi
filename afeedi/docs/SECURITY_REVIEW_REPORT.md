# Afeedi Flutter App — Security Review Report

**Date:** 2026-05-30
**Reviewer:** Automated Security Audit
**Scope:** Flutter app at `/home/user/afeedi/afeedi`
**Platform targets:** Android, iOS

---

## Executive Summary

The Afeedi app demonstrates solid foundational security choices (PBKDF2 password hashing, cleartext traffic blocked on both platforms, no hardcoded API keys, proper OAuth delegation), but carries several HIGH and MEDIUM issues that must be resolved before a production Play Store / App Store submission. The two most urgent issues are: (1) user identity data and subscription state stored in unencrypted SharedPreferences, and (2) Google AdMob test IDs in production code paths.

---

## Findings

### 1. User Identity Stored in Unencrypted SharedPreferences — HIGH

**Files:** `lib/services/auth_service.dart` (lines 44–45, 139–141, 191–192), `lib/services/local_auth_service.dart` (line 36, 208)

**Detail:** `user_id` and `user_email` are written to `SharedPreferences`, which is backed by an unencrypted XML file on Android (`/data/data/<pkg>/shared_prefs/`). On a rooted device or via ADB backup on a debug build, any app or attacker with file-system access can read the logged-in user's email address and internal user ID. The code itself acknowledges this at `auth_service.dart:9–11`:

```dart
// NOTE: user_id and user_email are stored in SharedPreferences (unencrypted).
// In production, migrate these to flutter_secure_storage ...
```

**Risk:** Email address enumeration, session hijacking on rooted/compromised devices.

**Recommendation:** Add `flutter_secure_storage` to `pubspec.yaml` and migrate `user_id`, `user_email`, and `current_user_id` to it. The `crypto` package is already present so the dependency footprint is minimal.

---

### 2. PBKDF2 Password Hashes in SharedPreferences — MEDIUM

**File:** `lib/services/local_auth_service.dart` (lines 71–79)

**Detail:** Passwords are hashed with PBKDF2-HMAC-SHA256 (100,000 iterations, 32-byte random salt — correctly implemented). However, the resulting JSON blob (`kdf`, `iterations`, `salt`, `hash`) is stored under `user_credentials_<id>` in unencrypted `SharedPreferences`. The hash is not the raw password, so direct password exposure is mitigated, but on a rooted device an attacker can extract the PBKDF2 hash and attempt offline brute-force.

**Why MEDIUM, not CRITICAL:** The hash quality is good (industry-standard PBKDF2 with 100k iterations). Risk is limited to offline attacks on rooted devices.

**Recommendation:** Store the credentials JSON in `flutter_secure_storage` (same migration as finding 1). This eliminates the offline brute-force surface entirely.

---

### 3. Subscription Premium State Stored in Unencrypted SharedPreferences — HIGH

**File:** `lib/services/subscription_service.dart` (lines 27–28, 78–93, 163–164)

**Detail:** The premium/free subscription tier is cached as `is_premium = true/false` in `SharedPreferences` and read back on every app launch. The code comments indicate this is the authoritative source for gating premium features:

```dart
static const _prefKey = 'is_premium';
final isPremium = prefs.getBool(_prefKey) ?? false;
```

On a rooted device or via ADB, any user can flip this boolean to `true` and bypass the paywall entirely. This is a revenue integrity issue.

**Recommendation:** Do not use SharedPreferences as the sole gate for premium features. Options:
- Always verify against a live receipt / server-side purchase token on launch.
- At minimum, sign the cached premium state with a device-bound HMAC key stored in `flutter_secure_storage`, so tampering is detectable.
- The existing `_restoreSilently()` call via `in_app_purchase` is a good start — ensure premium status is set only from confirmed `PurchaseDetails` and not from the local cache when a live verification is possible.

---

### 4. Hardcoded Google AdMob Test IDs Reach Production Code Paths — HIGH

**Files:** `lib/services/ad_service.dart` (lines 14–35), `android/app/src/main/AndroidManifest.xml` (line 39), `ios/Runner/AppDelegate.swift`

**Detail:** Google's public test AdMob IDs (`ca-app-pub-3940256099942544~…`) are present in **both** the `kDebugMode` and `else` (production) branches:

```dart
static String get nativeAdUnitId {
  if (kDebugMode) {
    return 'ca-app-pub-3940256099942544/...'; // test
  }
  // TODO: replace with real production ad unit IDs before store submission
  return 'ca-app-pub-3940256099942544/...'; // STILL THE SAME TEST ID
}
```

Google's policy prohibits shipping test ad unit IDs to the Play Store / App Store. Apps using test IDs in production will have their AdMob account suspended and may be rejected during review.

The comment `<!-- AdMob App ID — replace with real ID before Play Store submission -->` in `AndroidManifest.xml` confirms this is a known pre-release gap.

**Recommendation:** Before submission, replace all `ca-app-pub-3940256099942544` values with real production IDs from the AdMob console. Consider using environment-specific build flavors or `--dart-define` to inject IDs at build time rather than hard-coding them.

---

### 5. Mock OAuth Token Data in Production Service Code — MEDIUM

**File:** `lib/services/oauth_service.dart` (lines 82–93), `lib/services/auth_service.dart` (lines 374–379)

**Detail:** Two locations contain hardcoded mock token values:

- `oauth_service.dart`: TikTok `connectTikTok()` returns `'mock_tiktok_token_...'` and `'mock_tiktok_user_...'` — a simulated OAuth flow that always succeeds.
- `auth_service.dart` (`getPlatformConnections()`): Returns static `'access_token': 'token123'` and `'refresh_token': 'refresh123'` values regardless of actual platform connection state.

If a production user connects TikTok or invokes `getPlatformConnections()`, the app silently returns fake tokens. Downstream code that acts on these tokens (API calls, data sync) will fail silently or behave incorrectly, and users may believe their accounts are connected when they are not.

**Recommendation:** Gate `connectTikTok()` behind a `kDebugMode` guard or remove it if TikTok OAuth is not ready. Replace the static token map in `getPlatformConnections()` with real data from persistent storage or throw explicitly to surface the gap in development.

---

### 6. Password Reset Stores Email in Plaintext SharedPreferences Without Expiry or Token — MEDIUM

**File:** `lib/services/local_auth_service.dart` (lines 361–379)

**Detail:** `sendPasswordReset()` writes `pending_reset_email` to `SharedPreferences` as a marker:

```dart
await prefs.setString('pending_reset_email', email);
```

There is no expiry timestamp, no cryptographic reset token, and no mechanism to invalidate the marker after use. An attacker with file-system access could observe which email is pending a reset or manipulate the field. Additionally, the reset flow does not generate or transmit any out-of-band verification — a user could potentially reset their password to anything without confirming ownership of the email.

**Recommendation:**
1. Generate a time-limited, cryptographically random token (e.g., 128-bit via `Random.secure()`) and store it with an expiry in `flutter_secure_storage`.
2. Validate the token before allowing a password change.
3. Delete the token immediately after successful reset.

---

### 7. Cleartext Traffic — PASS (Android and iOS both correctly blocked)

**Files:** `android/app/src/main/AndroidManifest.xml`, `android/app/src/main/res/xml/network_security_config.xml`, `ios/Runner/Info.plist`

**Android:** `android:usesCleartextTraffic="false"` is set on the `<application>` element, and `network_security_config.xml` enforces `<base-config cleartextTrafficPermitted="false">` with only system trust anchors. No custom CA entries.

**iOS:** `NSAllowsArbitraryLoads` is `false`. The exception domains (`youtube.com`, `googlevideo.com`, `ytimg.com`) have `NSExceptionAllowsInsecureHTTPLoads` set to `false` — these entries enforce HTTPS for those domains explicitly, which is correct.

**HTTP in Dart code:** The only `http://` references in `lib/` are `http://localhost:8888` and `http://10.0.2.2:8888` in `api_content_service.dart` — local-only addresses used for development backend connectivity. These are exempt from the cleartext ban and pose no production risk.

No cleartext traffic issues found.

---

### 8. API Keys / Hardcoded Credentials — PASS

No production API keys, secrets, or credentials were found hardcoded in any Dart source file. The `.env.example` file (committed intentionally as a template) contains only placeholder values. `key.properties` and actual `.env` files are not tracked by git — only `key.properties.template` and `.env.example` are present in the repository.

The YouTube integration in `youtube_live_content_service.dart` uses `youtube_explode_dart`, which operates without a personal API key. No `AIza...` Google API keys found in source.

---

### 9. SSL/Certificate Pinning — INFORMATIONAL (Not Implemented)

**Finding:** No certificate pinning is implemented. Network requests use the default system trust store.

**Context:** Neither the App Store nor Play Store requires certificate pinning. It is a defence-in-depth measure recommended for apps handling high-value financial or medical data. For a social media aggregation app, the risk is proportional.

**Recommendation (Low priority):** If the app introduces server-side account APIs in future, consider implementing certificate pinning via the `http_certificate_pinning` package or custom `HttpClient` + `SecurityContext`. Not blocking for current submission.

---

### 10. Debug Logging of Sensitive Values — PASS (with one caveat)

**Finding:** All `debugPrint` calls in the auth layer log generic error messages (`'Error during sign in: $error'`), not raw sensitive values. No passwords, tokens, or raw email addresses are logged.

**One caveat:** `debugPrint` in Flutter outputs to the system log in debug builds only (suppressed in release/profile mode via the `kDebugMode` guard inside the function). This is acceptable.

---

### 11. SQL Injection — NOT APPLICABLE

No raw SQL queries were found. The app uses Hive (a key-value NoSQL store) for local data persistence, which is not susceptible to SQL injection.

---

### 12. Input Validation — PASS

Form validators are present on login, registration, profile, and settings screens. The search screen implements `_sanitizeQuery()`. Input is validated using Flutter `Form`/`TextFormField` validators before being passed to services.

---

### 13. Key.properties and Firebase Config — PASS

- `android/key.properties` is **not** tracked by git (only the template `key.properties.template` is committed).
- No `google-services.json` or `GoogleService-Info.plist` found in the repository. The app does not currently use Firebase directly; it uses AdMob via `google_mobile_ads` which does not require these files.
- The `.gitignore` does not explicitly list `key.properties` — this should be added as a precaution (see recommendation below).

**Recommendation:** Add `key.properties` and `*.jks` to `.gitignore` explicitly to prevent accidental future commits.

---

### 14. Code Obfuscation Disabled — LOW

**Files:** `ios/Flutter/Generated.xcconfig`, `ios/Flutter/flutter_export_environment.sh`

**Finding:** `DART_OBFUSCATION=false` is set in the iOS build environment files. Dart obfuscation (`--obfuscate --split-debug-info`) should be enabled for production release builds to make reverse engineering harder.

**Recommendation:** Add `--obfuscate --split-debug-info=<path>` to the release build command:
```bash
flutter build apk --release --obfuscate --split-debug-info=build/symbols/
flutter build ipa --release --obfuscate --split-debug-info=build/symbols/
```
Store the generated `app.android-arm64.symbols` files securely for crash symbolication via Firebase Crashlytics or Sentry.

---

### 15. Dual Auth Service Architectural Risk — MEDIUM

**Files:** `lib/services/auth_service.dart`, `lib/services/local_auth_service.dart`

**Detail:** Two parallel auth services exist. `LocalAuthService` handles password hashing and credential storage. `AuthService` wraps it but also has its own session state (`_currentUser`) populated from `SharedPreferences` independently. Both independently store `user_id` / `user_email`, creating two independent sources of truth. A sign-out in one service does not guarantee state is cleared in the other (e.g., `AuthService.deleteAccount()` calls `prefs.clear()` — a blunt instrument that also wipes non-auth data like analytics counters).

**Risk:** Inconsistent session state, potential session residue after logout/deletion.

**Recommendation:** Consolidate to a single auth service. `LocalAuthService` should be the single source of truth for authentication. `AuthService` should delegate entirely to it without maintaining its own copy of session state in `SharedPreferences`.

---

## Severity Summary

| # | Finding | Severity |
|---|---------|----------|
| 1 | User identity (user_id, user_email) in unencrypted SharedPreferences | HIGH |
| 2 | PBKDF2 credential blob in unencrypted SharedPreferences | MEDIUM |
| 3 | Subscription premium flag bypassed via SharedPreferences tampering | HIGH |
| 4 | AdMob test IDs in production code paths | HIGH |
| 5 | Mock OAuth tokens in production service code | MEDIUM |
| 6 | Password reset has no token, no expiry, plaintext SharedPreferences marker | MEDIUM |
| 7 | Cleartext HTTP traffic | PASS |
| 8 | Hardcoded API keys / credentials | PASS |
| 9 | Certificate pinning absent | INFORMATIONAL |
| 10 | Debug logging of sensitive values | PASS |
| 11 | SQL injection | NOT APPLICABLE |
| 12 | Input validation | PASS |
| 13 | key.properties / Firebase config in git | PASS |
| 14 | Dart obfuscation disabled | LOW |
| 15 | Dual auth service session state inconsistency | MEDIUM |

---

## Pre-Submission Checklist (Blocking)

- [ ] Migrate `user_id`, `user_email`, `current_user_id`, and `user_credentials_*` from `SharedPreferences` to `flutter_secure_storage`
- [ ] Add server-side or HMAC-signed verification for `is_premium` flag; do not trust the SharedPreferences value alone
- [ ] Replace all AdMob test IDs (`ca-app-pub-3940256099942544~*`) with real production IDs in `ad_service.dart`, `AndroidManifest.xml`, and `AppDelegate.swift`
- [ ] Remove or guard TikTok mock OAuth flow behind `kDebugMode`
- [ ] Remove static `token123`/`refresh123` values from `getPlatformConnections()`
- [ ] Enable `--obfuscate --split-debug-info` in production release builds
- [ ] Add `key.properties` and `*.jks` to `.gitignore`
- [ ] Implement a proper password reset token (random, expiring, single-use) instead of `pending_reset_email` marker

---

*Report generated by automated security audit — 2026-05-30*
