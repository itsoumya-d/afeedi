# Afeedi — Privacy & Legal Compliance Audit Report

**Prepared by:** Privacy & Legal Review  
**Date:** 2026-05-30  
**Scope:** GDPR, Apple App Store guidelines, Google Play requirements, iOS ATT, COPPA, secure storage  
**App version audited:** 1.0.0 (Build 1)  
**Files reviewed:**
- `lib/services/local_auth_service.dart`
- `lib/services/analytics_service.dart`
- `lib/services/user_management_service.dart`
- `lib/widgets/dashboard/settings_tab.dart`
- `lib/screens/profile_screen.dart`
- `lib/screens/privacy_policy_screen.dart`
- `lib/models/platform_connection_model.dart`
- `lib/core/storage/local_storage_service.dart`
- `ios/Runner/Info.plist`
- `ios/Runner/PrivacyInfo.xcprivacy`
- `ios/Runner/AppDelegate.swift`
- `pubspec.yaml`

---

## Executive Summary

The app has a solid structural foundation — password hashing, an in-app privacy policy screen, a GDPR export function, and a privacy manifest — but contains **five critical blockers** that would prevent App Store / Play Store approval, expose the company to GDPR enforcement, and endanger users. These must be resolved before any public release. Seven additional medium-severity issues require attention before or shortly after launch.

| Severity | Count | Description |
|----------|-------|-------------|
| CRITICAL | 5 | App Store blocker / active legal violation |
| HIGH | 4 | Significant legal or security risk |
| MEDIUM | 3 | Non-compliant but lower-risk |
| LOW / INFO | 3 | Best practice recommendations |

---

## CRITICAL Findings

---

### CRIT-1 — Account Deletion Dialog Is a Dead Button (GDPR Art. 17 / Apple Guideline 5.1.5)

**File:** `lib/widgets/dashboard/settings_tab.dart`, lines 504–538  
**Severity:** CRITICAL

#### Finding

The Settings screen shows a "Delete Account" dialog with a "Delete" button. When tapped, the button closes the dialog and does nothing:

```dart
onPressed: () {
  Navigator.pop(context);
  // TODO: Implement account deletion
},
```

`LocalAuthService.deleteAccount()` exists and is fully implemented (lines 264–294 of `local_auth_service.dart`), but it is **never called** from the UI. The same dead pattern is replicated in the Account section's "Sign Out" button, which has an empty `onTap: () {}` callback (line 297 of `settings_tab.dart`).

#### Legal Exposure

- **GDPR Article 17 (Right to erasure):** Users must be able to delete their accounts and all associated data. A button that silently no-ops is a direct violation. Maximum fine: €20 million or 4% of global annual turnover.
- **Apple App Store Guideline 5.1.5:** Since June 2022, apps with account creation must provide in-app account deletion. Apple will reject the submission outright during review.
- **Google Play Policy (Data deletion):** Same requirement; the app will be removed from the store.

#### Required Fix

Wire the "Delete" button to `LocalAuthService.instance.deleteAccount()`, handle the result, clear remaining SharedPreferences keys not covered by `deleteAccount()`, then navigate back to the sign-in screen. Also wire the "Sign Out" button to `LocalAuthService.instance.signOut()`.

```dart
// In _showDeleteAccountDialog, replace the TODO:
onPressed: () async {
  Navigator.pop(context);
  final success = await LocalAuthService.instance.deleteAccount();
  if (success && context.mounted) {
    // Clear remaining app state (watch history, cached genres, etc.)
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.auth, (_) => false);
  }
},
```

---

### CRIT-2 — "Download My Data" Is a Snackbar That Submits Nothing (GDPR Art. 20)

**File:** `lib/widgets/dashboard/settings_tab.dart`, lines 463–502  
**Severity:** CRITICAL

#### Finding

Tapping "Request" in the Download Data dialog shows a snackbar: *"Data request submitted. A download link will be sent to your email within 24 hours."* No API call is made, no email is sent, and no download link will ever arrive. `UserManagementService.exportUserData()` exists and is fully implemented but is never called from this UI path.

#### Legal Exposure

- **GDPR Article 20 (Right to data portability):** Controllers must provide personal data in a machine-readable format within one month of request. Telling users an email is coming and then never sending one is fraudulent and a direct violation.
- **Privacy policy section 12** states data deletion requests are processed within 30 days, implying a real pipeline exists — but none does.

#### Required Fix

Replace the snackbar implementation with a real data export:

```dart
onPressed: () async {
  Navigator.pop(context);
  final result = await UserManagementService.instance.exportUserData();
  if (result.success && context.mounted) {
    // Option A: Save the JSON to device Downloads and show share sheet
    // Option B: Email the JSON to the user's registered email address
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Your data has been prepared and saved.')),
    );
  }
},
```

At minimum, call `exportUserData()` and either (a) save the returned JSON to the device documents directory and open a system share sheet, or (b) send it to the user's email via the backend. A snackbar promise with no action is both legally and functionally broken.

---

### CRIT-3 — ATT Permission Is Declared But Never Requested (iOS App Tracking Transparency)

**Files:** `ios/Runner/Info.plist` (line 54–55), `ios/Runner/AppDelegate.swift`, `pubspec.yaml`  
**Severity:** CRITICAL

#### Finding

`NSUserTrackingUsageDescription` is present in `Info.plist`:

> *"Afeedi uses analytics to improve app performance and personalize your content feed. No personal data is shared with third parties for advertising."*

However:
1. **The `AppTrackingTransparency` framework is never imported or called** anywhere in the codebase (confirmed by grep across all Dart files and `AppDelegate.swift`).
2. **No Flutter ATT plugin** (`app_tracking_transparency` or similar) appears in `pubspec.yaml`.
3. `AppDelegate.swift` initialises AdMob (`GADMobileAds`) at launch **before** any ATT request could be made.
4. The privacy policy (section 9) claims *"You may be asked to allow or deny tracking when you first launch the app"* — this will never happen without the code.

#### Legal Exposure

- **Apple App Store Review Guideline 5.1.2:** If the app uses data for tracking (and AdMob does), `ATTrackingManager.requestTrackingAuthorization` **must** be called before any tracking-enabled SDKs make network calls. AdMob must not initialise until the user responds (or on `notDetermined`).
- The privacy policy is also false advertising — it promises an ATT dialog that never appears.

#### Required Fix

Add `app_tracking_transparency` to `pubspec.yaml` and request permission before initialising AdMob:

```dart
// In main.dart, before AdService.instance.initialize():
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

final status = await AppTrackingTransparency.requestTrackingAuthorization();
if (status == TrackingStatus.authorized || status == TrackingStatus.notDetermined) {
  await AdService.instance.initialize();
}
```

Move `GADMobileAds.sharedInstance().start()` in `AppDelegate.swift` to occur **after** the ATT callback, or remove it from there entirely and initialise from Dart.

---

### CRIT-4 — Privacy Policy and Terms of Service Links Are Dead TODOs

**File:** `lib/widgets/dashboard/settings_tab.dart`, lines 725–758  
**Severity:** CRITICAL

#### Finding

Both "Privacy Policy" and "Terms of Service" menu items show a dialog explaining the user will be redirected to the website, then execute:

```dart
onPressed: () {
  Navigator.pop(context);
  // TODO: Open privacy URL
},
```

The app has a built-in `PrivacyPolicyScreen` and navigation routes registered for both (`/privacy-policy`, `/terms`), yet the settings menu points to an external URL that is never launched — and the TODO means it never will be with the current code.

#### Legal Exposure

- **Apple App Store Guideline 5.1.1:** "Apps must include a link to their privacy policy in the app and on the App Store Connect listing." A dialog that promises to open a URL and then does nothing fails this requirement.
- **Google Play Developer Program Policy:** Privacy policy must be accessible at a working URL from within the app and on the Play Store listing.
- Without a working in-app privacy policy link, neither store will approve the submission.

#### Required Fix

Either navigate to the in-app screens already built, or launch the real URLs. The in-app screens are the better UX:

```dart
// For privacy policy:
onPressed: () {
  Navigator.pop(context);
  Navigator.pushNamed(context, AppRoutes.privacyPolicy);
},

// For terms of service:
onPressed: () {
  Navigator.pop(context);
  Navigator.pushNamed(context, AppRoutes.termsOfService);
},
```

Alternatively, if a web-hosted version is preferred, replace the `// TODO` with:

```dart
await launchUrl(Uri.parse('https://afeedi.com/privacy'), mode: LaunchMode.externalApplication);
```

---

### CRIT-5 — OAuth Access Tokens Stored Unencrypted in Hive (Critical Security / GDPR Art. 25)

**Files:** `lib/models/platform_connection_model.dart` (lines 9, 46–47, 68–69), `lib/core/storage/local_storage_service.dart` (line 152)  
**Severity:** CRITICAL

#### Finding

`PlatformConnection` includes `accessToken` and `refreshToken` fields. These are serialised to plain JSON via `toJson()` and stored in a Hive box (`platform_connections`) via:

```dart
await _platformConnectionsBoxInstance.put(
    '${connection.userId}_${connection.platform}', connection.toJson());
```

Hive does **not** encrypt its boxes by default. On Android, the Hive database is stored in the app's internal storage, which is accessible on rooted devices. On iOS, it is not covered by the Keychain. The result is that live OAuth tokens for YouTube, Instagram, Facebook, and Apple are stored in cleartext on disk.

Additionally, `session_token` (if set in `local_storage_service.dart` line 241) is stored in `SharedPreferences`, which is always plaintext.

#### Legal Exposure

- **GDPR Article 25 (Data protection by design and by default):** Access tokens are effectively authentication credentials. Storing them unencrypted violates the principle of data protection by design.
- **GDPR Article 32 (Security of processing):** Controllers must implement appropriate technical measures including encryption.
- In the event of device compromise or backup extraction, all connected platform accounts would be exposed.

#### Required Fix

Use `flutter_secure_storage` for all credential material:

```yaml
# pubspec.yaml
flutter_secure_storage: ^9.0.0
```

```dart
// Wrap all token storage:
const storage = FlutterSecureStorage();
await storage.write(key: 'oauth_token_${userId}_${platform}', value: accessToken);
```

If keeping Hive for non-credential platform connection metadata, strip `accessToken` and `refreshToken` from `toJson()` / the stored payload and store only in `flutter_secure_storage`.

---

## HIGH Severity Findings

---

### HIGH-1 — Password Credentials Stored in Unencrypted SharedPreferences

**File:** `lib/services/local_auth_service.dart`, lines 66–79  
**Severity:** HIGH

#### Finding

The code's own comment (line 66–69) correctly identifies the problem:

> *"NOTE: SharedPreferences is unencrypted on Android/iOS. The stored value here is a PBKDF2 hash — not the raw password — so exposure is limited. However, for production, migrate user_credentials_* and current_user_id to flutter_secure_storage..."*

The PBKDF2 hash with 100,000 iterations is good practice and mitigates the risk of immediate password recovery. However:
- The stored credential blob includes the **email address in plaintext** (`'email': email`).
- On Android, `shared_preferences.xml` is accessible on any rooted device or via ADB on debug builds.
- A malicious app with `READ_EXTERNAL_STORAGE` or an Android backup extraction can read this file.
- The `salt` + `hash` pair enables offline dictionary attacks without rate limiting.

#### Required Fix

Migrate `user_credentials_*`, `current_user_id`, and `session_token` to `flutter_secure_storage` as the existing comment recommends. The PBKDF2 implementation itself is correct — only the storage layer needs to change.

---

### HIGH-2 — Privacy Setting Toggles Are Cosmetic (Not Wired to Any Service)

**File:** `lib/widgets/dashboard/settings_tab.dart`, lines 16–20, 139–180  
**Severity:** HIGH

#### Finding

The Privacy & Data section presents four toggles:
- Data Collection (`_dataCollection`, default: `true`)
- Personalized Ads (`_personalizedAds`, default: `false`)
- Analytics Sharing (`_analyticsSharing`, default: `true`)
- Location Tracking (`_locationTracking`, default: `false`)

None of these toggles are persisted to `SharedPreferences` or `UserPreferences`. None of them gate `AnalyticsService`, `AdService`, or any other service. Changing them has zero effect on app behaviour — the state lives only in the widget's ephemeral `setState`.

#### Legal Exposure

- **GDPR Article 7 (Conditions for consent):** Where processing is consent-based, the controller must be able to demonstrate consent was given — and withdrawing it must be equally easy. Toggles that don't actually stop data collection are deceptive.
- **ePrivacy Directive:** Analytics cookies / equivalent local tracking must be opt-in in the EU unless strictly necessary.
- **FTC Act Section 5:** In the US, claiming users can control data collection via a toggle that does nothing constitutes a deceptive trade practice.

#### Required Fix

1. Persist all toggle values to `SharedPreferences` on change.
2. Read the values at `AnalyticsService.initialize()` and gate event queuing on `_dataCollection` / `_analyticsSharing`.
3. Gate AdMob initialisation on `_personalizedAds` and, on iOS, on ATT status (see CRIT-3).
4. Since `_locationTracking` is `false` by default and the app does not appear to use location, either remove the toggle or wire it to a real `PermissionHandler` request.

---

### HIGH-3 — `deleteUserData()` Does Not Remove Analytics Events or Watch History

**File:** `lib/services/user_management_service.dart`, lines 406–438  
**Severity:** HIGH

#### Finding

`UserManagementService.deleteUserData()` calls `_storage.deleteUser(userId)` and removes the profile key. `LocalAuthService.deleteAccount()` removes `user_credentials_*` and `current_user_id`. However, the following data is **not deleted** in either path:

| Data | Location |
|------|----------|
| Analytics events file (`analytics_events.json`) | `getApplicationDocumentsDirectory()` |
| Watch history (`watched_ids`, `watch_progress_*`, `watched_at_*`) | SharedPreferences |
| Liked / saved content IDs (`saved_*`, interactions Hive box) | SharedPreferences / Hive |
| Engagement stats (`stat_videos_watched`, `stat_streak_days`, etc.) | SharedPreferences |
| Onboarding data (`selected_genres`, `onboarding_user_name`, etc.) | SharedPreferences |
| Avatar file path (`user_avatar_path`) and the file itself | SharedPreferences + filesystem |
| Genre weights (`genre_implicit_weights`) | SharedPreferences |
| Install date and active days (`install_date`, `active_days`) | SharedPreferences |
| Subscription state (`subscription_is_premium`, etc.) | SharedPreferences |
| Anonymous analytics ID (`analytics_anonymous_id`) | SharedPreferences |
| Session token (if set) | SharedPreferences |

`LocalStorageService.clearAllData()` does exist and clears all Hive boxes plus `prefs.clear()`, but it is never called from the delete account flow.

#### Legal Exposure

- **GDPR Article 17:** Right to erasure requires deletion of **all** personal data, not just the user record. Partial deletion constitutes non-compliance.

#### Required Fix

Call `LocalStorageService.instance.clearAllData()` and `AnalyticsService.instance.clearAnalyticsData()` from the account deletion path, then sign the user out:

```dart
// In LocalAuthService.deleteAccount(), after existing deletions:
await LocalStorageService.instance.clearAllData();
await AnalyticsService.instance.clearAnalyticsData();
```

---

### HIGH-4 — User ID Is Passed in Analytics Events at Signout (PII Leak)

**File:** `lib/services/local_auth_service.dart`, lines 183–189  
**Severity:** HIGH

#### Finding

The `signOut()` method tracks an analytics event with the user's internal `user_id` as `additionalData`:

```dart
await AnalyticsService.instance.trackUserInteraction(
  action: 'user_signout',
  screen: 'auth',
  additionalData: {
    'user_id': _currentUser!.id,
  },
);
```

Similarly, `deleteAccount()` (line 271–277) sends `user_id` in the analytics payload **before** deleting data. `AnalyticsService._getUserId()` routes to `_getAnonymousId()` (line 421), which is the correct privacy-preserving approach. However, passing the internal `user_id` as `additionalData` bypasses this anonymisation entirely and links a real user account identifier to analytics events that may be flushed to a remote endpoint.

#### Required Fix

Remove `user_id` from `additionalData` in all `trackUserInteraction` calls. The anonymous ID from `_getUserId()` is sufficient for session correlation without linking to a real account.

---

## MEDIUM Severity Findings

---

### MED-1 — COPPA: No Age Gate and Privacy Policy Does Not Address Children Under 13 Adequately

**File:** `lib/screens/privacy_policy_screen.dart`, lines 53–57; no age gate found in codebase  
**Severity:** MEDIUM

#### Finding

The privacy policy (section 7) states the app is "not directed to children under 13" and does not "knowingly collect personal information from children under 13." However:
- There is no age gate during sign-up.
- There is no mechanism to verify user age.
- The app allows sign-up with just an email, which a child could provide.
- `UserProfile` has a `dateOfBirth` field in `UserManagementService.updateUserProfile()`, but it is never collected during onboarding.

The statement in the privacy policy is insufficient to satisfy COPPA (US) or the UK's Age Appropriate Design Code (AADC) if the app is accessible to children.

#### Required Fix

Choose one:
1. **Add a date-of-birth field during sign-up** and block users who are under 13 (or under 16 for GDPR Art. 8 compliance in the EU).
2. **Add a binary age gate** ("Are you 13 or older?") with a blocking screen for minors.
3. If the app is genuinely intended only for adults, add explicit age restriction text on App Store / Play Store listings and implement at least a DOB confirmation during onboarding.

---

### MED-2 — Privacy Policy Is Displayed With `overflow: TextOverflow.ellipsis` — Text Is Truncated

**File:** `lib/screens/privacy_policy_screen.dart`, lines 130–136  
**Severity:** MEDIUM

#### Finding

Each section body is rendered with:

```dart
maxLines: 10,
overflow: TextOverflow.ellipsis,
```

Sections longer than 10 lines will be silently cut off mid-sentence. Section 10 (Google AdMob & Advertising) and section 12 (Data Deletion) are both likely to exceed this limit at typical font sizes. This means users cannot read the complete policy even though the screen exists.

#### Legal Exposure

Apple Guideline 5.1.1 requires the privacy policy to be "accessible and complete." A policy that truncates its own text may fail review or be flagged by users.

#### Required Fix

Remove `maxLines` and `overflow` from the section body `Text` widget, or replace both with `overflow: TextOverflow.visible` (the default). The screen already wraps in a `SingleChildScrollView`, so text length is not a layout problem.

---

### MED-3 — `google_mobile_ads` Is Active for All Users Without Consent Check

**File:** `lib/main.dart` (line 97), `lib/services/ad_service.dart`  
**Severity:** MEDIUM

#### Finding

AdMob is initialised unconditionally at app startup. Google's own documentation states that `MobileAds.instance.initialize()` should only be called after ATT consent is obtained on iOS (see CRIT-3). There is no check of the `_personalizedAds` setting (which is not persisted — see HIGH-2) before initialisation.

Per Google Play Policy (effective January 2024), apps must obtain consent before showing personalised ads to users in the EEA/UK using the User Messaging Platform (UMP) SDK.

#### Required Fix

1. Integrate the [Google UMP SDK](https://pub.dev/packages/google_mobile_ads#user-messaging-platform-ump) for GDPR consent before initialising AdMob.
2. Gate `AdService.instance.initialize()` on both ATT (iOS) and UMP consent (Android/EU).
3. If consent is denied, either hide all ad widgets or request non-personalised ads only.

---

## LOW / Informational Findings

---

### LOW-1 — Privacy Manifest Missing `NSPrivacyTracking: true` for AdMob

**File:** `ios/Runner/PrivacyInfo.xcprivacy`, line 5  
**Severity:** LOW

#### Finding

`NSPrivacyTracking` is set to `false`, but the app uses Google AdMob which collects device identifiers for ad personalisation — this qualifies as "tracking" under Apple's definition (cross-app data use for advertising). If AdMob is enabled, this should be `true` and the AdMob domain should appear in `NSPrivacyTrackingDomains`.

If, post ATT implementation, all users deny tracking and the app only uses non-personalised ads, then `false` is correct. The manifest should be updated after the ATT / consent flow decision is finalised (CRIT-3).

---

### LOW-2 — Privacy Policy Last Updated Date Is in the Future

**File:** `lib/screens/privacy_policy_screen.dart`, line 28  
**Severity:** LOW

The privacy policy shows "Last updated: June 1, 2026." Today's date is May 30, 2026. This is a minor inconsistency but will look odd to reviewers. Update to the actual publication date when the policy is finalised.

---

### LOW-3 — Analytics Flush Uses No Authentication / Bearer Token

**File:** `lib/services/analytics_service.dart`, lines 43–50  
**Severity:** LOW / Informational

The remote analytics endpoint (`_endpointUrl`) is an unauthenticated HTTP POST with no `Authorization` header. If a real endpoint is configured, it should require a bearer token or HMAC signature to prevent spoofed events from third parties. This is an operational security concern rather than a privacy violation.

---

## Summary Table

| ID | Severity | Regulation/Guideline | Finding | Fix Required Before |
|----|----------|---------------------|---------|---------------------|
| CRIT-1 | CRITICAL | GDPR Art. 17, Apple 5.1.5, Play Policy | Delete Account button is a dead TODO | App Store submission |
| CRIT-2 | CRITICAL | GDPR Art. 20 | Data download shows fake confirmation snackbar | App Store submission |
| CRIT-3 | CRITICAL | Apple ATT / iOS 14.5+ | ATT declared but never requested; AdMob initialises without consent | App Store submission |
| CRIT-4 | CRITICAL | Apple 5.1.1, Play Policy | Privacy policy and ToS links are dead TODOs | App Store submission |
| CRIT-5 | CRITICAL | GDPR Art. 25 & 32 | OAuth tokens stored unencrypted in Hive | App Store submission |
| HIGH-1 | HIGH | GDPR Art. 25 & 32 | Password credential blob (including email) in unencrypted SharedPreferences | Before public launch |
| HIGH-2 | HIGH | GDPR Art. 7, ePrivacy | Privacy toggles are cosmetic, no actual effect on data collection | Before public launch |
| HIGH-3 | HIGH | GDPR Art. 17 | Account deletion does not remove analytics, watch history, or cached data | Before public launch |
| HIGH-4 | HIGH | GDPR Art. 5(1)(c) | Internal user_id passed in analytics events, bypassing anonymisation | Before public launch |
| MED-1 | MEDIUM | COPPA, GDPR Art. 8, UK AADC | No age gate; COPPA disclaimer alone is insufficient | Before public launch |
| MED-2 | MEDIUM | Apple 5.1.1 | Privacy policy text is truncated by maxLines constraint | Before App Store submission |
| MED-3 | MEDIUM | Google Play Consent Policy | AdMob active without UMP consent flow for EU/EEA users | Before Play Store submission |
| LOW-1 | LOW | Apple Privacy Manifest | NSPrivacyTracking: false inconsistent with AdMob use | After ATT decision finalised |
| LOW-2 | LOW | — | Privacy policy "last updated" date is 2 days in the future | Before launch |
| LOW-3 | LOW | Security best practice | Analytics flush endpoint has no authentication | Before connecting real endpoint |

---

## What Is Compliant (Positive Findings)

The following areas are implemented correctly and should be maintained:

1. **PBKDF2-SHA256 password hashing** with 100,000 iterations and a 32-byte random salt (`local_auth_service.dart`). The legacy SHA-256 upgrade path on next login is also correctly implemented.
2. **Account lockout after 5 failed attempts** (5-minute lockout) is correctly implemented.
3. **Analytics anonymisation**: `_getUserId()` routes to `_getAnonymousId()` which is a random install-scoped ID, never an email or real user ID. Search queries are logged as `query_length` only, not the query text itself.
4. **Privacy manifest (`PrivacyInfo.xcprivacy`)** is present and declares UserID, EmailAddress, OtherUserContent, and ProductInteraction data types with correct purposes.
5. **`NSAppTransportSecurity`** is configured with `NSAllowsArbitraryLoads: false`, enforcing HTTPS.
6. **In-app privacy policy screen** exists and covers all required topics (ATT, AdMob, Calendar, data deletion, COPPA).
7. **`UserManagementService.exportUserData()`** is structurally correct and excludes sensitive tokens from the export payload (`platform_connections` export strips `accessToken`/`refreshToken`).
8. **`LocalStorageService.clearAllData()`** exists and clears all Hive boxes plus SharedPreferences — it just needs to be called from the deletion flow (HIGH-3).
9. **`privacyPolicyAcceptedAt` field in `User` model** shows intent to track policy acceptance timestamps.

---

## Recommended Fix Priority Order

1. CRIT-1: Wire Delete Account button → `LocalAuthService.instance.deleteAccount()` + `clearAllData()`
2. CRIT-1 (companion): Wire Sign Out button → `LocalAuthService.instance.signOut()`
3. CRIT-4: Replace both TODO URL openers with `Navigator.pushNamed` to in-app policy/ToS screens
4. HIGH-3: Call `clearAllData()` + `clearAnalyticsData()` from deletion flow
5. CRIT-2: Wire Download Data to `UserManagementService.exportUserData()` + share sheet
6. HIGH-2: Persist all privacy toggles and gate `AnalyticsService` + `AdService` on them
7. CRIT-5 + HIGH-1: Add `flutter_secure_storage`; migrate credentials and OAuth tokens
8. CRIT-3 + MED-3: Add ATT plugin + UMP SDK; gate AdMob initialisation on consent
9. HIGH-4: Remove `user_id` from analytics `additionalData` in `signOut()` and `deleteAccount()`
10. MED-1: Add DOB/age gate to sign-up flow
11. MED-2: Remove `maxLines` constraint from privacy policy body text

---

*End of report. This document should be reviewed by qualified legal counsel before use as the basis for compliance decisions.*
