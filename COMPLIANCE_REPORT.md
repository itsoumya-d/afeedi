# Afeedi — App Store & Play Store Compliance Report

**Generated:** 2026-05-30  
**Audited by:** Compliance Agent Team (App Store Review Specialist, Google Play Policy Specialist, Privacy & Legal Reviewer, Content Moderation Specialist, Security Reviewer)

---

## Summary

| Category | Fixed in This PR | Remaining Action Required |
|---|---|---|
| Critical violations | 4 / 4 fixed | — |
| High-risk issues | 5 / 7 fixed | 2 items need backend work |
| Medium-risk issues | 3 / 5 fixed | 2 items pre-launch |
| iOS permission strings | All added | — |
| Android permissions | All added | — |
| Security issues | 3 / 4 fixed | 1 (password hashing) |
| Privacy issues | 4 / 5 fixed | 1 (GDPR consent UI) |
| Content compliance | Documented | Platform agreements needed |

---

## CRITICAL VIOLATIONS (App Store / Play Store WILL reject)

### ✅ CV-01 — youtube_explode_dart: YouTube ToS violation [FIXED]
**Policy:** YouTube ToS §5.1.H; Apple App Store Review Guideline 5.3.4  
**Description:** `youtube_explode_dart` bypasses the YouTube API to extract direct video stream URLs. Apple and Google treat this as circumventing platform restrictions.  
**Fix applied:** Package removed from `pubspec.yaml`. `VideoContentExtractionService` now throws `UnsupportedError`. Mobile playback uses `url_launcher` to the YouTube app; web uses the official YouTube IFrame embed.

### ✅ CV-02 — Missing INTERNET permission in Android Manifest [FIXED]
**Policy:** Google Play Developer Policy — App must declare all permissions it uses  
**Description:** The app makes HTTP requests but had no `android.permission.INTERNET` declaration. This causes a crash on Android.  
**Fix applied:** Added to `android/app/src/main/AndroidManifest.xml`.

### ✅ CV-03 — Missing iOS permission usage descriptions [FIXED]
**Policy:** Apple App Store Review Guideline 5.1.1  
**Description:** `image_picker` accesses camera and photos; no `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, or `NSMicrophoneUsageDescription` were present. Apple rejects apps that access protected resources without a purpose string.  
**Fix applied:** All required usage strings added to `ios/Runner/Info.plist`.

### ✅ CV-04 — Mock TikTok OAuth returning fake tokens [FIXED]
**Policy:** Apple App Store Review Guideline 4.2 (Minimum Functionality), 5.3.4  
**Description:** `OAuthService.connectTikTok()` returned hardcoded mock tokens. If a reviewer tests this, the app appears to work but doesn't actually connect to TikTok. This is treated as deceptive functionality.  
**Fix applied:** Replaced with real TikTok Login Kit OAuth flow via `flutter_web_auth_2`. Requires `YOUR_TIKTOK_CLIENT_KEY` to be populated before release.

---

## HIGH-RISK ISSUES

### ✅ HR-01 — OAuth tokens stored in SharedPreferences (plain text) [FIXED]
**Policy:** Apple App Store Review Guideline 5.1.1; Google Play Data Safety  
**Description:** Access tokens and ID tokens were written to `SharedPreferences` which is unencrypted on both platforms.  
**Fix applied:** Added `flutter_secure_storage` (iOS Keychain / Android Keystore with `encryptedSharedPreferences: true`). `SecureStorageService` now wraps all sensitive reads/writes.

### ✅ HR-02 — Analytics collecting PII without consent [FIXED]
**Policy:** GDPR Art. 6 & 7; Apple App Store Privacy Nutrition Label; Google Play Data Safety  
**Description:** `AnalyticsService` was recording email addresses in event payloads and writing to local storage before the user granted consent.  
**Fix applied:** (a) All analytics events now check `_consentGranted` before persisting. (b) Email, name, phone fields are stripped from every event. (c) `PrivacyConsentService` controls the consent flag.

### ✅ HR-03 — No ATT (App Tracking Transparency) request [FIXED — partial]
**Policy:** Apple App Store Review Guideline 5.1.2; iOS 14.5+ requirement  
**Description:** Apps that track users across apps/websites must request ATT permission before tracking begins.  
**Fix applied:** `app_tracking_transparency: ^2.0.4` added to `pubspec.yaml`. `PrivacyConsentService.requestTrackingAuthorization()` wraps the ATT prompt. **Action required:** Call `PrivacyConsentService.instance.requestTrackingAuthorization()` in `main.dart` before analytics initializes. Wire up ATT in `ios/Runner/AppDelegate.swift`.  
**Note:** `NSUserTrackingUsageDescription` added to `Info.plist`.

### ✅ HR-04 — Delete Account dialog was a no-op [FIXED]
**Policy:** Apple App Store Review Guideline 5.1.1(v); Google Play Account Deletion Policy (Dec 2023)  
**Description:** Both the App Store and Play Store now **require** that apps supporting account creation also provide a working in-app account deletion flow. The Delete Account button previously only closed the dialog.  
**Fix applied:** `_deleteAccount()` in `SettingsTab` now calls `LocalAuthService.instance.deleteAccount()` which clears all local data, and then navigates back to the welcome screen.

### ✅ HR-05 — instagram_content_publish scope requested without Meta approval [FIXED]
**Policy:** Instagram Graph API; Meta Platform Policy  
**Description:** `instagram_content_publish` requires Meta App Review approval. Requesting it without approval causes the OAuth flow to fail for all real users.  
**Fix applied:** Scope changed to `instagram_basic` only.

### ⚠️ HR-06 — Subscription "Upgrade to Premium" shows placeholder dialog [ACTION REQUIRED]
**Policy:** Apple App Store Review Guideline 3.1.1; Google Play Billing Policy  
**Description:** If the app advertises paid features, they must use Apple/Google in-app purchase APIs — not stubs.  
**Action required:** Either implement `in_app_purchase` plugin with real products, or remove all premium/paid feature references before submission.

### ⚠️ HR-07 — "Offline Downloads" advertised but not implemented [ACTION REQUIRED]
**Policy:** Apple App Store Review Guideline 4.2 (Minimum Functionality)  
**Description:** The settings and profile screens show "Offline Downloads" as a premium feature. Advertising unimplemented features causes rejection.  
**Action required:** Implement the feature or remove all mentions from the UI before submission.

---

## MEDIUM-RISK ISSUES

### ✅ MR-01 — Privacy Policy / Terms of Service dialogs had TODO stubs [FIXED]
**Description:** `_showTermsDialog` and `_showPrivacyDialog` in `SettingsTab` had `// TODO: Open URL` comments — the buttons did nothing.  
**Fix applied:** Buttons now call `launchUrl` to open `https://afeedi.com/terms` and `https://afeedi.com/privacy`.

### ✅ MR-02 — iOS Privacy Manifest missing (required for App Store submissions) [FIXED]
**Policy:** Apple Privacy Manifest requirement (effective May 1 2024)  
**Description:** Apps and third-party SDKs that access "required reasons" APIs (NSUserDefaults, file timestamps, disk space) must declare them in a `PrivacyInfo.xcprivacy` file.  
**Fix applied:** `ios/Runner/PrivacyInfo.xcprivacy` created with correct API reason codes.

### ✅ MR-03 — PII leaking in analytics events [FIXED]
**Description:** Email addresses were passed as `additionalData` in `trackUserInteraction` calls across `auth_service.dart` and `local_auth_service.dart`.  
**Fix applied:** Email fields removed from all analytics payloads.

### ⚠️ MR-04 — Password hashing without salt [ACTION REQUIRED]
**Description:** `LocalAuthService._hashPassword()` uses raw SHA-256 with no salt. This is vulnerable to rainbow table attacks.  
**Action required:** Replace with `bcrypt` or use `argon2` via `dart_bcrypt` / `cryptography` package. Alternatively, migrate to a proper backend auth system (Supabase Auth, Firebase Auth).

### ⚠️ MR-05 — GDPR consent UI not yet shown to EU users [ACTION REQUIRED]
**Description:** The settings page has privacy toggles but no consent banner is shown on first launch to EU/EEA users, as required by GDPR Art. 7.  
**Action required:** Add a first-launch consent screen (or use a CMP package such as `usercentrics_cmp`) before enabling analytics or data collection.

---

## CONTENT AGGREGATION & VIDEO COMPLIANCE

| Platform | API Used | Attribution | Compliance Status |
|---|---|---|---|
| YouTube | url_launcher (opens YouTube app) | YouTube badge shown on thumbnails | ✅ Safe — no content scraped |
| YouTube (web) | Official IFrame Embed | YouTube branding visible | ✅ Safe — permitted use |
| Instagram | Instagram oEmbed API (read-only) | Author name from oEmbed response | ⚠️ Requires approved Meta app |
| TikTok | TikTok oEmbed API | Author name from oEmbed response | ✅ oEmbed is publicly permitted |
| Facebook | Facebook Video Plugin embed | Facebook branding via iframe | ⚠️ Requires approved Facebook app |

**Note:** For Instagram and Facebook embeds you must have an approved Meta app. The app currently supports these platforms but the app registration must be completed on the Meta developer portal before the OAuth flows will work for real users.

---

## PERMISSION AUDIT

### iOS (Info.plist) — all required strings now present
| Permission | Usage String | Necessity |
|---|---|---|
| NSCameraUsageDescription | ✅ Added | image_picker profile photo |
| NSPhotoLibraryUsageDescription | ✅ Added | image_picker photo selection |
| NSPhotoLibraryAddUsageDescription | ✅ Added | saving thumbnails |
| NSMicrophoneUsageDescription | ✅ Added | video playback audio |
| NSUserTrackingUsageDescription | ✅ Added | analytics ATT |

### Android (AndroidManifest.xml) — all required permissions now present
| Permission | Status | Necessity |
|---|---|---|
| INTERNET | ✅ Added | all network requests |
| CAMERA | ✅ Added | image_picker |
| READ_EXTERNAL_STORAGE (maxSdk 32) | ✅ Added | image_picker (legacy) |
| READ_MEDIA_IMAGES | ✅ Added | Android 13+ |
| READ_MEDIA_VIDEO | ✅ Added | Android 13+ |
| POST_NOTIFICATIONS | ✅ Added | push notifications on Android 13+ |

---

## SECURITY CHANGES

| Item | Before | After |
|---|---|---|
| OAuth access tokens | SharedPreferences (plain text) | flutter_secure_storage (Keychain/Keystore) |
| OAuth ID tokens | SharedPreferences (plain text) | flutter_secure_storage |
| Analytics PII | Email logged | All PII fields stripped |
| Analytics consent | No check | Gated behind `_consentGranted` |
| TikTok auth | Mock tokens | Real OAuth code flow |

---

## PRE-RELEASE CHECKLIST

Before submitting to App Store or Play Store:

- [ ] Replace `YOUR_TIKTOK_CLIENT_KEY` in `oauth_service.dart` with real client key
- [ ] Register TikTok callback URI `afeedi://tiktok/callback` in TikTok developer portal
- [ ] Register Facebook/Instagram app and complete Meta App Review
- [ ] Call `PrivacyConsentService.instance.requestTrackingAuthorization()` in `main.dart`
- [ ] Complete ATT integration in `ios/Runner/AppDelegate.swift`
- [ ] Implement or remove "Offline Downloads" feature
- [ ] Implement or remove "Upgrade to Premium" / in-app purchase flow
- [ ] Replace `bcrypt`-less password hashing in `LocalAuthService`
- [ ] Add GDPR consent banner for first-launch EU users
- [ ] Publish actual Privacy Policy at `https://afeedi.com/privacy`
- [ ] Publish actual Terms of Service at `https://afeedi.com/terms`
- [ ] Remove `.backup` and `.backup2` files from `lib/screens/`
- [ ] Set minimum iOS deployment target to 14.0 (required by `app_tracking_transparency`)
- [ ] Complete Meta App Review for Instagram and Facebook OAuth scopes
- [ ] Add Google Services JSON (`google-services.json`) for Android Firebase
- [ ] Add `GoogleService-Info.plist` for iOS Firebase
- [ ] Fill in real App Store metadata (screenshots, age rating, privacy nutrition labels)
- [ ] Set age rating appropriately (social media content — likely 12+ or 17+)
- [ ] Run `flutter pub get` after pubspec.yaml changes
- [ ] Run `pod install` in `ios/` after pubspec changes
