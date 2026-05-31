# Afeedi — Release Prerequisites

This document lists every step the developer must complete before submitting to
the App Store or Google Play. All **code-level** compliance fixes have been
implemented. The items below require **account registration, configuration, or
key replacement** and cannot be done in code alone.

---

## CRITICAL — Must complete before any store submission

### 1. Replace AdMob App IDs

| File | Location | Current (test) | Action |
|------|----------|---------------|--------|
| `android/app/src/main/AndroidManifest.xml` | line 39 | `ca-app-pub-3940256099942544~3347511713` | Replace with real Android App ID from AdMob console |
| `ios/Runner/Info.plist` | `GADApplicationIdentifier` key | `ca-app-pub-3940256099942544~1458002511` | Replace with real iOS App ID from AdMob console |
| `ios/Runner/AppDelegate.swift` | comment on line 12 | test ID in comment | Remove comment, confirm real ID is in Info.plist |
| `lib/services/ad_service.dart` | `nativeAdUnitId` / `rewardedAdUnitId` | env-var backed | Set `ADMOB_NATIVE_IOS`, `ADMOB_NATIVE_ANDROID`, `ADMOB_REWARDED_IOS`, `ADMOB_REWARDED_ANDROID` in your CI/build environment |

**How to create AdMob IDs:**
1. Sign in to [admob.google.com](https://admob.google.com)
2. Apps → Add App → iOS / Android
3. Copy the App ID into the files above
4. Create Ad Units for native and rewarded formats; copy unit IDs into env vars

---

### 2. Configure Firebase / Google Sign In

Currently `firebase_core` and `google_sign_in` are in `pubspec.yaml` but have no
Firebase project config files. Google Sign In will silently fail without them.

**Option A — Keep Google Sign In (recommended):**
1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Add Android app with package `com.afeedi.app` → download `google-services.json` → place in `android/app/`
3. Add iOS app with bundle ID → download `GoogleService-Info.plist` → add to `ios/Runner/` in Xcode
4. Add the `google-services` Gradle plugin to `android/app/build.gradle.kts`:
   ```kotlin
   plugins { id("com.google.gms.google-services") }
   ```
5. Add `GoogleService-Info.plist` to `ios/Runner/` and add to Xcode target

**Option B — Remove Google Sign In:**
Remove `firebase_core`, `google_sign_in`, `flutter_facebook_auth` from `pubspec.yaml` and remove the OAuth buttons from `lib/screens/login_screen.dart`.

---

### 3. Register TikTok Developer Account

TikTok OAuth is currently disabled (returns `null`) to prevent fake "Connected" badges.

To enable:
1. Register at [developers.tiktok.com](https://developers.tiktok.com)
2. Create an app and request approval for Login Kit
3. Add your `client_key` to `lib/services/oauth_service.dart` `connectTikTok()` method
4. Implement the actual OAuth PKCE flow (see TikTok Login Kit docs)

---

### 4. Host Privacy Policy and Terms of Service

Both stores require a **publicly accessible URL** for the privacy policy.

1. Publish `lib/screens/privacy_policy_screen.dart` content to `https://afeedi.com/privacy`
2. Publish Terms of Service to `https://afeedi.com/terms`
3. Update `lib/core/constants/app_urls.dart` with the real URLs
4. Enter the privacy policy URL in:
   - App Store Connect → App Information → Privacy Policy URL
   - Google Play Console → Store listing → Privacy policy

---

## HIGH — Complete before submission for best results

### 5. Server-Side IAP Receipt Verification

Currently `lib/services/subscription_service.dart` validates purchases client-side
only. On rooted devices this can be bypassed.

Before launch:
1. Set up a server endpoint that calls Apple's `/verifyReceipt` API and Google
   Play's `purchases.subscriptions.get` API
2. Update `SubscriptionService._verifyPurchase()` to POST the receipt to your server
3. Gate premium features on server-confirmed status, not just local `is_premium` flag

---

### 6. Replace App Store Screenshots

Placeholder screenshots are not accepted. Create real device screenshots for:
- **iPhone 6.9" (Pro Max)** — required
- **iPhone 6.5" (Plus / Max)** — required  
- **iPad 13" (Pro)** — required if iPad is supported
- **Android phone (16:9)** — required for Play Store

Use real app content in screenshots; show the feed, player, and personalization steps.

---

### 7. Complete App Store Connect / Play Console Metadata

| Field | Required | Action |
|-------|----------|--------|
| App name | Both | "Afeedi" |
| Subtitle (iOS) | App Store | "Your Personalized Video Feed" |
| Short description (Android) | Play Store | 80-char summary |
| Full description | Both | Replace template text |
| Keywords (iOS) | App Store | video, shorts, feed, YouTube, TikTok, personalized, trending |
| Category | Both | Entertainment (iOS) / Video Players & Editors (Android) |
| Age rating | Both | 12+ / Teen (content from social platforms) |
| Privacy policy URL | Both | `https://afeedi.com/privacy` (see item 4) |
| Support URL | Both | `https://afeedi.com/support` |
| Data Safety (Android) | Play Store | Fill in Data Safety form — see COMPLIANCE_GAP_REPORT.md |
| App Privacy (iOS) | App Store | Fill in privacy nutrition labels in App Store Connect |

---

## MEDIUM — Recommended before public launch

### 8. Enable UMP Debug Testing (EU Consent)

UMP consent is wired (`lib/services/ump_service.dart` called in `main.dart`).
Test it against real EU geography:
```dart
// In debug builds only, force EU geography for testing:
final params = ConsentRequestParameters(
  tagForUnderAgeOfConsent: false,
  consentDebugSettings: ConsentDebugSettings(
    debugGeography: DebugGeography.debugGeographyEea,
    testIdentifiers: ['YOUR_HASHED_DEVICE_ID'],
  ),
);
```

### 9. Enable Dart Obfuscation for Release Builds

Add to your release build command:
```bash
flutter build apk --release --obfuscate --split-debug-info=build/debug-info/
flutter build ipa --release --obfuscate --split-debug-info=build/debug-info/
```

### 10. Migrate Sensitive Data to flutter_secure_storage

`lib/services/local_auth_service.dart` stores the PBKDF2 password hash in
unencrypted SharedPreferences. Before launch, add `flutter_secure_storage: ^9.0.0`
and migrate password hashes and OAuth tokens to the secure keychain.

---

## Signing Keys

- Android: `android/key.properties.template` shows the required format. Copy to
  `android/key.properties` (never commit this file — it is in `.gitignore`).
- iOS: Configure signing in Xcode with your Apple Developer account.

---

## Estimated Effort

| Item | Effort |
|------|--------|
| AdMob ID replacement | 30 minutes |
| Firebase config files | 1–2 hours |
| TikTok OAuth | 2–4 hours |
| Privacy policy hosting | 1–2 hours |
| IAP server verification | 1–2 days |
| Screenshots | 2–4 hours |
| Store metadata | 1–2 hours |
| **Total** | **~3 developer-days** |
