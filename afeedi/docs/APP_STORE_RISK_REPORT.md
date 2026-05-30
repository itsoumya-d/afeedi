# App Store Risk Report — Afeedi
**Audit Date:** 2026-05-30  
**Auditor:** App Store Review Specialist  
**App Version:** 1.0.0+1  
**Platform:** iOS (Flutter)  
**Scope:** Apple App Store Review Guidelines

---

## Executive Summary

The Afeedi app has **3 CRITICAL risks** that would cause automatic rejection, **7 HIGH risks** that make rejection likely, **5 MEDIUM risks** that may trigger reviewer questions, and **5 LOW risks** that represent best-practice improvements. The most severe issues are: (1) the account deletion dialog contains a TODO stub — pressing "Delete" does nothing; (2) production AdMob ad unit IDs are still Google's public test IDs (ca-app-pub-3940256099942544); and (3) the NSMicrophoneUsageDescription describes "video recording features" which do not exist in this video-aggregator app. These must be fixed before submission.

---

## CRITICAL Risks (Automatic Rejection)

---

### C-1: Account Deletion Is a Non-Functional Stub

**Guideline:** 5.1.5 — Account Deletion  
**Severity:** CRITICAL — Apple will reject any app with account creation that lacks a working, in-app account deletion path. This has been a hard requirement since June 2022.

**Location:** `/lib/widgets/dashboard/settings_tab.dart`, lines 504–537 (`_showDeleteAccountDialog`)

**Evidence:**
```dart
TextButton(
  onPressed: () {
    Navigator.pop(context);
    // TODO: Implement account deletion
  },
  child: const Text('Delete', style: TextStyle(color: Colors.red)),
),
```
The "Delete" button in Settings > Privacy & Data > Delete Account dismisses the dialog and does nothing. `LocalAuthService` has a `deleteAccount()` method (line 264 of `local_auth_service.dart`) and `AuthService` has one too, but neither is wired to the dialog.

**Fix Required:**
1. Call `LocalAuthService.instance.deleteAccount()` (and `AuthService.instance.deleteAccount()`) inside the confirmation handler.
2. After deletion completes, navigate the user to the welcome/login screen and clear all local state.
3. Add a second confirmation step ("Type DELETE to confirm") to prevent accidental deletion, as Apple reviewers explicitly test this path.
4. The Privacy Policy mentions `privacy@afeedi.com` for data deletion requests — this email-only path is insufficient on its own; the in-app button must work.

---

### C-2: Production AdMob Ad Unit IDs Are Google Public Test IDs

**Guideline:** 2.1 — App Completeness  
**Severity:** CRITICAL — Submitting an app using Google's public test ad IDs (`ca-app-pub-3940256099942544/...`) means the app will show test ads (or no ads) in production. Apple reviewers may not reject on this alone, but Google's AdMob policy will suspend the AdMob account, and the app as submitted is not production-complete.

**Location:**  
- `/lib/services/ad_service.dart`, lines 17–34 — both `nativeAdUnitId` and `rewardedAdUnitId` in both `kDebugMode` and production branches return identical Google test IDs.
- `/ios/Runner/AppDelegate.swift`, line 12 — comment reads "replace ca-app-pub-3940256099942544~1458002511 with real iOS App ID before App Store submission." The test App ID is still hardcoded.
- `Info.plist` — `GADApplicationIdentifier` key is absent entirely. AdMob requires this key; its absence causes a crash on iOS 14+ at MobileAds init time.

**Fix Required:**
1. Register the app in the AdMob console and obtain a real iOS App ID (format: `ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY`).
2. Add `GADApplicationIdentifier` with that value to `Info.plist`.
3. Replace both production branches in `ad_service.dart` with real ad unit IDs. The `kDebugMode` branches may retain the test IDs.
4. Update `AppDelegate.swift` to use the real App ID.

---

### C-3: NSMicrophoneUsageDescription Is Factually Inaccurate for This App

**Guideline:** 5.3.4 — VoIP / Microphone; also 2.3 — Accurate Metadata  
**Severity:** CRITICAL — Apple will reject an app whose permission usage string does not accurately describe an actual feature, and will also reject if a permission is requested with no corresponding feature.

**Location:** `/ios/Runner/Info.plist`, line 52–53

**Evidence:**
```xml
<key>NSMicrophoneUsageDescription</key>
<string>Afeedi needs microphone access for video recording features.</string>
```

No code anywhere in `/lib` accesses the microphone or provides a video recording feature. A search for `record`, `microphone`, `AVAudioSession`, `AVCaptureDevice`, and camera-recording APIs across all Dart files returns zero results relevant to recording. The app is a video aggregator/player; it lets users pick a profile picture from the gallery or camera, but that only requires `NSCameraUsageDescription` (already present) — not microphone.

**Fix Required:**
- **Option A (preferred):** Remove `NSMicrophoneUsageDescription` entirely from `Info.plist` if no microphone feature exists or is planned for this version.
- **Option B:** If voice search or video recording is a planned feature gated by premium, do not include the key until the feature is actually in the submitted build. Apple requires the feature to exist in the submitted binary.

---

## HIGH Risks (Likely Rejection)

---

### H-1: ATT Framework Not Called at Runtime Despite NSUserTrackingUsageDescription Present

**Guideline:** 5.1.2 — Data Use and Sharing  
**Severity:** HIGH — Apple requires that any app with `NSUserTrackingUsageDescription` in `Info.plist` actually calls `ATTrackingManager.requestTrackingAuthorization()` before accessing the IDFA. Failing to do so means the string is misleading metadata. Additionally, Google AdMob on iOS 14+ requires the ATT prompt to be shown before `MobileAds.instance.initialize()` or the request context must be set.

**Location:**  
- `NSUserTrackingUsageDescription` is declared in `Info.plist` (lines 54–55).
- A search across all Dart files, Swift files, and podspec files for `AppTrackingTransparency`, `requestTrackingAuthorization`, `ATTrackingManager`, and `att_plugin` returns zero results.
- `AdService.initialize()` calls `MobileAds.instance.initialize()` without a prior ATT request.
- The Privacy Policy (`privacy_policy_screen.dart`, line 63) states "You may be asked to allow or deny tracking when you first launch the app" — but this prompt is never shown.

**Fix Required:**
1. Add `app_tracking_transparency` Flutter plugin to `pubspec.yaml`.
2. In `main.dart` or `AdService.initialize()`, call `AppTrackingTransparency.requestTrackingAuthorization()` on iOS 14+ before calling `MobileAds.instance.initialize()`.
3. Pass the ATT status to `MobileAds.instance.updateRequestConfiguration()` to set `ConsentDebugSettings` / non-personalized ads when the user denies.

---

### H-2: IAP Subscriptions Use `buyNonConsumable` Instead of `buySubscription`

**Guideline:** 3.1.1 — In-App Purchase  
**Severity:** HIGH — Auto-renewable subscriptions must be purchased via the `buyNonConsumable` API in the `in_app_purchase` plugin (this is actually acceptable in the plugin's abstraction layer), but the more critical issue is that subscription transactions are not completed correctly: there is no server-side receipt validation before granting access, and the purchase confirmation is purely local/optimistic.

**Location:** `/lib/services/subscription_service.dart`, lines 153–168 (`_verifyAndGrant`)

**Evidence:**
```dart
// In production: verify receipt server-side before granting
// For now: trust the store (acceptable for MVP, replace with server verification pre-launch)
```
The app grants premium status by writing to `SharedPreferences` and adds 31 or 365 days to the current date manually rather than reading actual subscription expiry from StoreKit. This comment explicitly acknowledges it is not production-ready.

**Additional issue:** The "Creator" tier (index 2) on the premium screen is marked "Coming Soon" and explicitly has no IAP product ID. When a user taps "Start 7-Day Free Trial" with Creator selected, they see a dialog saying "Creator tier — Coming Soon." This is a broken purchase flow for a displayed tier.

**Fix Required:**
1. Implement server-side receipt verification (call Apple's `/verifyReceipt` endpoint or use RevenueCat/Adapty). This is not optional for production.
2. Either remove the Creator tier from `PremiumScreen` before submission, or add a real IAP product ID for it. Do not show a purchasable-looking plan card for a feature that cannot be purchased.
3. The `buyNonConsumable` call is technically correct for the `in_app_purchase` plugin's subscription flow, but confirm this is mapped to `SKProductTypeAutoRenewableSubscription` in App Store Connect.

---

### H-3: Sign Out Button Is Non-Functional

**Guideline:** 2.1 — App Completeness  
**Severity:** HIGH — A Settings screen with a "Sign Out" button that does nothing is incomplete app functionality. Apple reviewers test authentication flows.

**Location:** `/lib/widgets/dashboard/settings_tab.dart`, lines 291–299

**Evidence:**
```dart
_buildActionItem(
  title: 'Sign Out',
  subtitle: 'Sign out of your Afeedi account',
  icon: Icons.logout,
  iconColor: Colors.redAccent,
  isDangerous: true,
  onTap: () {},    // <-- empty lambda, does nothing
),
```

**Fix Required:**
Wire the Sign Out button to `LocalAuthService.instance.signOut()` (and `AuthService.instance.signOut()`), then navigate to `AppRoutes.welcome`. The `settings_screen.dart` has a separate settings screen — verify it also has a functional sign out if it is shown to users.

---

### H-4: Multiple TODO-Stub Navigation/Action Buttons Visible to Users

**Guideline:** 2.1 — App Completeness  
**Severity:** HIGH — Apple reviewers will discover dead actions and reject for incomplete functionality.

**Location:** `/lib/widgets/dashboard/settings_tab.dart`

**Evidence (7 unimplemented handlers):**
- Line 528: `// TODO: Implement account deletion` (see C-1)
- Line 564: `// TODO: Implement cache clearing` — Clear Cache dialog button does nothing
- Line 600: `// TODO: Navigate to password change` — Change Password dialog button does nothing
- Line 713: `// TODO: Open terms URL` — Terms of Service "Open" button does nothing
- Line 749: `// TODO: Open privacy URL` — Privacy Policy "Open" button does nothing  
- Line 763: `// TODO: Navigate to profile screen` — `_navigateToProfile()` is empty
- Line 767: `// TODO: Navigate to subscription screen` — `_navigateToSubscription()` is empty

**Fix Required:**
Each of these must be wired to a real implementation before submission:
- Cache clearing: call `DefaultCacheManager().emptyCache()` or equivalent.
- Terms/Privacy: call `launchUrl(Uri.parse('https://afeedi.com/terms'))` and `https://afeedi.com/privacy`.
- Profile navigation: `Navigator.pushNamed(context, AppRoutes.profile)`.
- Subscription navigation: `Navigator.pushNamed(context, AppRoutes.premium)`.

---

### H-5: TikTok OAuth Connection Returns Hardcoded Mock Tokens

**Guideline:** 2.1 — App Completeness; 5.5 — Developer Code of Conduct  
**Severity:** HIGH — Shipping mock/fake OAuth tokens that create a fraudulent "Connected" state is deceptive to users and violates App Store guidelines.

**Location:** `/lib/services/oauth_service.dart`, lines 78–96 (`connectTikTok`)

**Evidence:**
```dart
// Simulate OAuth flow with mock data for development
return {
  'platform': 'tiktok',
  'authCode': 'mock_tiktok_code_${...}',
  'accessToken': 'mock_tiktok_token_${...}',
  'userId': 'mock_tiktok_user_${...}',
  'displayName': 'TikTok User',
  ...
};
```
Tapping "Connect TikTok" in settings will wait 2 seconds then return a fake success. The UI will show TikTok as "connected" but no actual TikTok content will load.

**Fix Required:**
- **Option A:** Remove TikTok from the list of connectable platforms before submission.
- **Option B:** Implement real TikTok OAuth using TikTok's official Login Kit (requires TikTok developer account and app review). This is a significant undertaking.
- Do not ship fake/mock authentication that creates a false "connected" state visible to users.

---

### H-6: "Comments feature coming soon!" and Other User-Facing "Coming Soon" Strings

**Guideline:** 2.1 — App Completeness  
**Severity:** HIGH — User-facing "coming soon" messages indicate the app is not complete. Apple reviewers will flag features advertised in the UI that show placeholder text.

**Locations:**
- `/lib/widgets/feed/enhanced_feed_post_card.dart`, line 635: `'Comments feature coming soon!'` shown to users who tap a comment button.
- `/lib/screens/premium_screen.dart`, line 500: Dialog shown to users who tap "Creator" plan: `'Creator Tier — Coming Soon'` with a clearly purchasable-looking plan card.
- `/lib/screens/create_content_screen.dart`, line 40: Platform connection "coming soon" message.
- `/lib/screens/placeholder_screen.dart`, line 27: Generic `'$title coming soon'` shown for player, onboarding, and admin routes (lines 146, 148, 160, 166, 172, 178 in `navigation_service.dart`).

**Fix Required:**
- Remove the Creator tier plan card entirely or hide it until the IAP product is live.
- Either implement the comments feature or remove the comment button from the UI.
- Replace `PlaceholderScreen` routes with real screens or remove those navigation paths from the live build.

---

### H-7: GADApplicationIdentifier Missing from Info.plist (Crash Risk)

**Guideline:** 2.1 — App Completeness (crash at launch)  
**Severity:** HIGH — Google Mobile Ads SDK for iOS will crash at `MobileAds.initialize()` if `GADApplicationIdentifier` is not present in `Info.plist`. This is a hard crash before the app UI loads.

**Location:** `/ios/Runner/Info.plist` — key absent entirely; `/ios/Runner/AppDelegate.swift`, line 12

**Fix Required:** Add to `Info.plist`:
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY</string>
```
Use the real iOS App ID from AdMob console, not the test publisher ID.

---

## MEDIUM Risks (May Trigger Review Questions)

---

### M-1: `pubspec.yaml` description is the Default Flutter Placeholder

**Guideline:** 2.3 — Accurate Metadata  
**Severity:** MEDIUM — The `pubspec.yaml` description reads `"A new Flutter project."` (line 2). While this does not directly appear in App Store metadata, it may be flagged internally and suggests an incomplete submission.

**Location:** `/home/user/afeedi/afeedi/pubspec.yaml`, line 2

**Fix Required:** Update `description` to something meaningful: `"Afeedi — personalized social media feed aggregator for YouTube, Instagram, TikTok, and Facebook content."`

---

### M-2: IAP Subscription Uses `buyNonConsumable` — Should Use `buySubscription`

**Guideline:** 3.1.1 — In-App Purchase  
**Severity:** MEDIUM — The `in_app_purchase` Flutter plugin wraps both consumable and non-consumable products under `buyNonConsumable`; however, for auto-renewable subscriptions the correct underlying StoreKit product type must be `SKProductTypeAutoRenewableSubscription`. This must be configured correctly in App Store Connect, not just in code. If it is configured as non-consumable in App Store Connect, Apple will reject the product.

**Location:** `/lib/services/subscription_service.dart`, line 194

**Fix Required:** Confirm in App Store Connect that product IDs `afeedi_pro_monthly` and `afeedi_pro_yearly` are created as **Auto-Renewable Subscriptions**, not Non-Consumable In-App Purchases. The Flutter plugin handles both through `buyNonConsumable`, but the App Store Connect configuration controls the actual product type.

---

### M-3: Privacy Policy Is Bundled In-App But No External Hosted URL

**Guideline:** 5.1.1 — Data Collection and Storage  
**Severity:** MEDIUM — Apple requires a link to a hosted privacy policy URL in App Store Connect metadata at submission time. The in-app `PrivacyPolicyScreen` is good supplementary content, but cannot substitute for the App Store Connect URL field. Additionally, the Settings > Privacy Policy "Open" button has a TODO stub and currently opens a dialog saying it will redirect to the website — but no URL is implemented.

**Location:** `settings_tab.dart` lines 724–758 (`_showPrivacyDialog`), `privacy_policy_screen.dart`

**Fix Required:**
1. Host the privacy policy at a public URL (e.g., `https://afeedi.com/privacy`).
2. Enter that URL in App Store Connect under "Privacy Policy URL" before submission.
3. Implement the "Open" button in the Privacy Policy dialog to call `launchUrl(Uri.parse('https://afeedi.com/privacy'))`.

---

### M-4: `via.placeholder.com` Images Used as Fallback Thumbnails in Content Feed

**Guideline:** 2.1 — App Completeness  
**Severity:** MEDIUM — The content aggregation service uses `https://via.placeholder.com/...` as fallback thumbnail URLs in 6 places. `via.placeholder.com` is a third-party public placeholder service that may be unavailable, rate-limited, or show developer-style placeholder graphics to real users.

**Location:** `/lib/services/content_aggregation_service.dart`, lines 144, 182, 190, 427, 464, 472

**Fix Required:** Replace `via.placeholder.com` URLs with app-bundled fallback assets (include a generic thumbnail image in `assets/`) or use a platform-appropriate gradient fallback (as already done elsewhere in the app, e.g., `_buildThumbnailFallback` in `shorts_tab.dart`).

---

### M-5: Simulated Password Change and Password Reset Functions

**Guideline:** 2.1 — App Completeness  
**Severity:** MEDIUM — `AuthService.changePassword()` and `AuthService.resetPassword()` both contain comments `// Simulate password change` and `// Simulate password reset` — they return `AuthResult(success: true)` without performing any action. The "Change Password" dialog button in settings is a TODO (see H-4), but if a reviewer reaches the LocalAuthService password reset path (via the Login screen "Forgot Password?" flow), `LocalAuthService.sendPasswordReset()` is at least partially implemented.

**Location:** `/lib/services/auth_service.dart`, lines 327–346

**Fix Required:** Either implement real password change/reset functionality against your backend, or remove the "Change Password" option from the settings UI until it is implemented.

---

## LOW Risks (Suggestions)

---

### L-1: Hardcoded Sample Comments Displayed as Real User Comments

**Guideline:** 2.1 / 5.5 — Deceptive content  
**Severity:** LOW — The Shorts tab shows 8 hardcoded "sample comments" (usernames: `Alex_M`, `riya.codes`, `TechWithJordan`, etc.) in the comments bottom sheet for every video. Users may believe these are real comments from real people.

**Location:** `/lib/screens/tabs/shorts_tab.dart`, lines 1204–1213 (`_sampleComments`)

**Fix Required:** Either replace with real comments from a backend API, or add a clear UI label "Sample comments — sign in to see real comments" to avoid deception. Do not ship fake social proof as real.

---

### L-2: Hardcoded Mock `_mockShortsData` Fallback Is User-Visible

**Guideline:** 2.1 — App Completeness  
**Severity:** LOW — The `_mockShortsData` list (Rick Astley, Gangnam Style, etc.) is shown to users when `ContentService` returns zero results. Interaction buttons on this mock content show a SnackBar saying "Tap a short from your personalized feed to interact." This looks like broken functionality to a first-time user.

**Location:** `/lib/screens/tabs/shorts_tab.dart`, lines 93–154

**Fix Required:** Replace the mock fallback with the `_buildEmptyState()` widget that already exists in the file (lines 293–337). The empty state ("No Shorts available") is cleaner and does not show non-interactive fake content.

---

### L-3: Sensitive Credentials May Be in SharedPreferences (Unencrypted)

**Guideline:** 5.1.1 — Data Collection and Storage  
**Severity:** LOW — `user_id` and `user_email` are stored in `SharedPreferences` (unencrypted on-disk storage). A comment in `auth_service.dart` (line 9) explicitly flags this:

> "NOTE: user_id and user_email are stored in SharedPreferences (unencrypted). In production, migrate these to flutter_secure_storage to prevent exposure on non-encrypted or rooted devices."

**Location:** `/lib/services/auth_service.dart`, lines 9–11, 139–141, 190–191

**Fix Required:** Migrate `user_id`, `user_email`, and any OAuth identity data to `flutter_secure_storage` before production. Add `flutter_secure_storage: ^9.x.x` to `pubspec.yaml`.

---

### L-4: `_navigateToSubscription()` and `_navigateToProfile()` in `settings_tab.dart` Are Empty Functions

**Guideline:** 2.1 — App Completeness  
**Severity:** LOW (overlaps with H-4, listed separately for completeness)  
**Location:** `/lib/widgets/dashboard/settings_tab.dart`, lines 762–768

These are empty method bodies. Users who tap "Subscription" or "Edit Profile" in the Account section of settings get no response. This creates a confusing, unresponsive UI.

**Fix Required:** Wire to `Navigator.pushNamed(context, AppRoutes.premium)` and `Navigator.pushNamed(context, AppRoutes.profile)` respectively.

---

### L-5: Missing Apple Sign In Button Branding Compliance

**Guideline:** 4.8 — Sign In with Apple Design Guidelines  
**Severity:** LOW — Sign In with Apple is implemented (`sign_in_with_apple: ^6.1.1` in `pubspec.yaml`, `OAuthService.connectApple()` in `oauth_service.dart`). However, the login screen uses a custom-styled `OutlinedButton.icon` with `Icons.apple` and white text instead of the official `SignInWithAppleButton` widget provided by the `sign_in_with_apple` package. Apple's Human Interface Guidelines require the Sign In with Apple button to use specific approved styling.

**Location:** `/lib/screens/login_screen.dart`, lines 513–548

**Fix Required:** Replace the custom Apple button with `SignInWithAppleButton` from the `sign_in_with_apple` package, which provides compliant styling and accessibility attributes automatically:
```dart
SignInWithAppleButton(
  onPressed: _handleAppleSignIn,
);
```

---

## Summary Table

| ID | Severity | Guideline | Issue | Files |
|----|----------|-----------|-------|-------|
| C-1 | CRITICAL | 5.1.5 | Account deletion is a non-functional TODO stub | `settings_tab.dart` |
| C-2 | CRITICAL | 2.1 | Production AdMob IDs are Google public test IDs; GADApplicationIdentifier missing | `ad_service.dart`, `AppDelegate.swift`, `Info.plist` |
| C-3 | CRITICAL | 5.3.4 / 2.3 | NSMicrophoneUsageDescription references non-existent recording feature | `Info.plist` |
| H-1 | HIGH | 5.1.2 | ATT framework never called despite NSUserTrackingUsageDescription present | `main.dart`, `ad_service.dart` |
| H-2 | HIGH | 3.1.1 | No server-side receipt verification; Creator tier shown but non-purchasable | `subscription_service.dart`, `premium_screen.dart` |
| H-3 | HIGH | 2.1 | Sign Out button is an empty lambda that does nothing | `settings_tab.dart` |
| H-4 | HIGH | 2.1 | Seven TODO-stub action buttons visible to users | `settings_tab.dart` |
| H-5 | HIGH | 2.1 / 5.5 | TikTok OAuth returns hardcoded mock tokens creating fake connected state | `oauth_service.dart` |
| H-6 | HIGH | 2.1 | Multiple user-visible "coming soon" messages in Comments, Creator tier, Placeholder routes | multiple |
| H-7 | HIGH | 2.1 | GADApplicationIdentifier missing from Info.plist — crash at launch | `Info.plist`, `AppDelegate.swift` |
| M-1 | MEDIUM | 2.3 | pubspec description is default "A new Flutter project." | `pubspec.yaml` |
| M-2 | MEDIUM | 3.1.1 | Subscription product type must be Auto-Renewable in App Store Connect | `subscription_service.dart` |
| M-3 | MEDIUM | 5.1.1 | Privacy policy not hosted at a URL; App Store Connect URL field will be empty | `settings_tab.dart` |
| M-4 | MEDIUM | 2.1 | via.placeholder.com used as fallback thumbnails in content feed | `content_aggregation_service.dart` |
| M-5 | MEDIUM | 2.1 | Password change/reset functions are simulated stubs | `auth_service.dart` |
| L-1 | LOW | 5.5 | Hardcoded sample comments displayed as real user comments in Shorts | `shorts_tab.dart` |
| L-2 | LOW | 2.1 | Mock shorts fallback data (_mockShortsData) shown as interactive content | `shorts_tab.dart` |
| L-3 | LOW | 5.1.1 | User credentials in unencrypted SharedPreferences | `auth_service.dart` |
| L-4 | LOW | 2.1 | _navigateToSubscription and _navigateToProfile are empty functions | `settings_tab.dart` |
| L-5 | LOW | 4.8 | Sign In with Apple uses custom styling instead of official SignInWithAppleButton widget | `login_screen.dart` |

---

## Pre-Submission Checklist (Must Complete Before Filing)

- [ ] C-1: Wire `Delete Account` dialog to `LocalAuthService.instance.deleteAccount()` and navigate to welcome screen
- [ ] C-2: Register app in AdMob console, add `GADApplicationIdentifier` to `Info.plist`, replace test ad unit IDs with real production IDs
- [ ] C-3: Remove `NSMicrophoneUsageDescription` from `Info.plist` (no recording feature exists)
- [ ] H-1: Integrate `app_tracking_transparency` plugin and call `requestTrackingAuthorization()` before AdMob init
- [ ] H-2: Implement server-side receipt verification OR remove from store submission until ready; remove/hide Creator tier
- [ ] H-3: Wire Sign Out button to `LocalAuthService.instance.signOut()` and navigate to welcome
- [ ] H-4: Implement all 7 stubbed action buttons (cache clear, Terms URL, Privacy URL, profile nav, subscription nav, password change)
- [ ] H-5: Remove TikTok "Connect" option or implement real TikTok OAuth
- [ ] H-6: Remove "coming soon" messages and `PlaceholderScreen` from user-facing routes
- [ ] H-7: (same as C-2) Add `GADApplicationIdentifier` to `Info.plist`
- [ ] M-3: Host privacy policy at public URL and enter it in App Store Connect
- [ ] L-1: Replace hardcoded sample comments or label them clearly as samples

---

*Report generated: 2026-05-30*
