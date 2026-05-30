# Rejection Risk Report — Afeedi Flutter App

**Report Date:** 2026-05-30  
**App Version:** 1.0.0+1  
**Bundle ID (iOS):** com.afeedi.app  
**Package ID (Android):** com.afeedi.app  
**Based On:** Static source analysis of `/home/user/afeedi/afeedi`  
**Scope:** Pre-submission simulation of Apple App Store and Google Play Store review processes

---

## 1. Executive Summary

**DO NOT SUBMIT without addressing 7 items.**

Ten previously reported rejection risks have been resolved. However, **7 items remain that will cause rejection or post-launch account action** across one or both stores. Of these, **4 are hard REJECTs** (automatic rejection or near-certain rejection on first review), **2 are LIKELY rejections** (visible to every reviewer), and **1 is POSSIBLE** (depends on reviewer depth and store configuration).

| Category | Apple App Store | Google Play | Combined |
|---|---|---|---|
| REJECT (automatic / near-certain) | 4 | 2 | **4 unique** |
| LIKELY rejection | 3 | 2 | **3 unique** |
| POSSIBLE rejection | 1 | 1 | **1 unique** |
| **Submittable today?** | **NO** | **NO** | **NO** |

**Estimated time to unblock all items: 3–5 developer-days** (see Section 6).

### Fixed items confirmed (do not re-audit)

The following risks from the previous APP_STORE_RISK_REPORT and PLAY_STORE_RISK_REPORT have been verified as resolved in the current codebase:

1. `youtube_explode_dart` removed from `pubspec.yaml` — Play Store YouTube ToS §4.F violation resolved.
2. Account deletion dialog now calls `LocalAuthService.instance.deleteAccount()` and navigates to welcome — Apple Guideline 5.1.5 resolved.
3. `NSMicrophoneUsageDescription` removed from `Info.plist` — Apple Guideline 5.3.4 resolved.
4. Privacy Policy and Terms of Service links navigate to in-app screens (`AppRoutes.privacyPolicy`, `AppRoutes.termsOfService`) — resolved.
5. Sign Out button calls `LocalAuthService.instance.signOut()` and navigates to `AppRoutes.welcome` — resolved.
6. `GADApplicationIdentifier` added to `Info.plist` — iOS crash on AdMob init resolved.
7. AdMob test ad unit IDs now guarded to `kDebugMode` only; production paths use `String.fromEnvironment` — resolved.
8. ATT (`app_tracking_transparency`) implemented: `AttService.requestTrackingIfNeeded()` called in `main.dart` before `AdService.instance.initialize()` — Apple ATT requirement resolved.
9. `LocalAuthService.deleteAccount()` calls `_storage.clearAllData()` — GDPR complete wipe resolved.
10. Privacy settings loaded from and saved to `SharedPreferences` via `_loadSettings()` / `_saveSetting()` — resolved.

---

## 2. Apple App Store Rejection Simulation

> This section simulates the review as it would appear to an Apple reviewer. Reviews are conducted on a physical device running the release build.

---

### Step 1 — Binary Upload / Pre-Review Automated Checks

**REJECT — firebase_core present in pubspec.yaml with no GoogleService-Info.plist**

`firebase_core: ^2.31.0` appears in `pubspec.yaml` line 74. No `GoogleService-Info.plist` exists anywhere in `ios/Runner/`. If `Firebase.initializeApp()` is called at any point (even indirectly via a plugin that depends on `firebase_core`), the app will throw a fatal exception on the first launch before the reviewer even sees the UI:

```
FIRApp named '__FIRAPP_DEFAULT' does not exist.
Thread 1: Fatal error: 'try!' expression unexpectedly raised an error
```

Static analysis confirms `Firebase.initializeApp()` is not called in `main.dart` directly, but `firebase_core` will still be linked into the binary. If any transitive dependency calls it, the crash surfaces. App Store Review's automated binary checks will detect a linked Firebase SDK without a valid `GoogleService-Info.plist` bundle resource.

**Acceptance criteria to pass:** Either add a real `ios/Runner/GoogleService-Info.plist` (obtained from Firebase Console) or remove `firebase_core` from `pubspec.yaml` entirely and remove all Firebase imports.

---

### Step 2 — First Launch

**REJECT — TikTok "Connect" returns `mock_tiktok_token_*` creating a fake Connected state**

`oauth_service.dart` lines 78–93 return a fake success after a 2-second delay whenever a user taps "Connect TikTok". The reviewer will:

1. Open Settings > Connected Platforms.
2. Tap "Connect TikTok."
3. See a 2-second spinner, then a "Connected" badge appear next to TikTok.
4. Navigate to the feed expecting TikTok content — none appears.

Apple Guideline 2.1 (App Completeness) and Guideline 5.5 (Developer Code of Conduct — no deceptive content) both apply. A connected platform badge with no actual connection is misrepresentation of app functionality. This is a consistent, reliable rejection trigger.

The mock code is unconditional — there is no build flag guarding it:

```dart
// lib/services/oauth_service.dart lines 84–92
return {
  'platform': 'tiktok',
  'authCode': 'mock_tiktok_code_${DateTime.now().millisecondsSinceEpoch}',
  'accessToken': 'mock_tiktok_token_${DateTime.now().millisecondsSinceEpoch}',
  ...
};
```

**Acceptance criteria to pass:** Remove TikTok from the connectable platforms list before submission OR implement real TikTok Login Kit OAuth (significant scope — requires TikTok developer registration and their own review).

---

### Step 3 — Ad Display

**REJECT — AdMob production App ID is still Google's public test App ID**

`Info.plist` line 56 contains `ca-app-pub-3940256099942544~1458002511`. `ca-app-pub-3940256099942544` is Google's publicly documented test publisher account, present in every AdMob tutorial. A comment on the same line says "replace with real iOS App ID before App Store submission." It was not replaced.

While Apple's automated checks may not reject for this specifically, the AdMob production code path in `ad_service.dart` returns an empty string (via `String.fromEnvironment('ADMOB_NATIVE_IOS', defaultValue: '')`) when no environment variable is set at build time — which means ads will silently fail to load in the release build and the ad space will be blank. A blank ad widget on a reviewer's device will be noted as broken UI.

**Acceptance criteria to pass:** Register the app in the AdMob Console, obtain a real iOS App ID, replace the value in `Info.plist`, and supply real production ad unit IDs via `--dart-define=ADMOB_NATIVE_IOS=...` at build time (or embed them via a secrets manager).

---

### Step 4 — Premium Screen / In-App Purchases

**REJECT (production-complete check) — AdMob ad unit IDs not configured; ad widgets fail silently**

As detailed above, the `String.fromEnvironment` default is an empty string. When `nativeAdUnitId` returns `''`, `AdService.initialize()` skips `MobileAds.instance.initialize()` entirely (`ad_service.dart` lines 51–57). Any `NativeAd` or `RewardedAd` widget in the UI will fail to load and will display nothing. Blank ad spaces are an app completeness failure under Guideline 2.1.

---

### Step 5 — Content and UI Completeness

**LIKELY — "Comments feature coming soon!" and Creator tier card visible to reviewer**

Two separate "coming soon" messages are present:

1. `enhanced_feed_post_card.dart` line 635: Tapping the comment button on any feed post shows a SnackBar reading `'Comments feature coming soon!'`. This button is visible on the app's primary screen. Every reviewer will tap it within the first 30 seconds.

2. `premium_screen.dart` line 500: The "Creator" pricing tier card is displayed with a fully styled, purchasable-looking layout and a "Start 7-Day Free Trial" button. Tapping it shows `'Creator Tier — Coming Soon'`. A pricing card that cannot be purchased is classified as incomplete functionality under Guideline 2.1.

Apple has consistently rejected apps with "coming soon" placeholders on user-facing screens, particularly in the primary navigation flow.

---

### Step 6 — Store Metadata Review

**LIKELY — `app_description` is Flutter template placeholder "A new Flutter project"**

`pubspec.yaml` line 2: `description: "A new Flutter project."` This string surfaces in App Store Connect's build metadata view. While it does not directly appear in the storefront, it signals to reviewers that the submission is incomplete, and it can trigger Guideline 2.3 (Accurate Metadata) scrutiny of all other metadata fields.

---

### Step 7 — Privacy Policy URL in App Store Connect

**POSSIBLE — No hosted privacy policy URL for the App Store Connect listing field**

Apple requires a publicly accessible privacy policy URL in the App Store Connect "Privacy Policy URL" field before submission. The in-app `PrivacyPolicyScreen` satisfies the in-app disclosure requirement (Guideline 5.1.1) but cannot be entered as a URL in the App Store Connect field, which requires an `https://` link to an external page.

Status: The Settings screen now correctly navigates to `AppRoutes.privacyPolicy` (an in-app screen). No hosted URL at `https://afeedi.com/privacy` or similar exists in the codebase. This is a submission-form blocker, not a binary rejection, but the submission cannot be filed without it.

---

### Step 8 — Google Sign-In OAuth Configuration

**POSSIBLE — `google_sign_in` configured with no OAuth client ID; sign-in will fail**

`oauth_service.dart` instantiates `GoogleSignIn(scopes: [...])` with no `clientId` parameter. For iOS, `google_sign_in` requires either a `REVERSED_CLIENT_ID` URL scheme in `Info.plist` (from `GoogleService-Info.plist`) or an explicit `clientId` passed to the constructor. Neither is present. A reviewer who attempts to sign in with Google will encounter an OAuth failure. No `GoogleService-Info.plist` exists to supply the `REVERSED_CLIENT_ID` URL scheme automatically.

---

## 3. Google Play Store Rejection Simulation

> Play Store review uses automated policy scanners plus human reviewers. Some checks happen post-publication.

---

### Step 1 — APK/AAB Upload Validation

**REJECT — firebase_core in pubspec.yaml with no google-services.json**

`firebase_core: ^2.31.0` is declared in `pubspec.yaml`. No `android/app/google-services.json` file exists. The `google-services` Gradle plugin is not applied in `android/app/build.gradle.kts`. However, `firebase_core` will still be compiled into the AAB. Any runtime call to Firebase APIs (even by a transitive dependency) will throw:

```
Default FirebaseApp is not initialized. Make sure to call
FirebaseApp.initializeApp(Context) first.
```

Google Play's pre-launch report (run on real devices in Firebase Test Lab as part of the review pipeline) will surface this crash. A crash on first launch is an automatic policy failure.

**Acceptance criteria to pass:** Same as iOS — add `google-services.json` to `android/app/` and apply the `com.google.gms.google-services` plugin in `build.gradle.kts`, OR remove `firebase_core` from `pubspec.yaml` entirely.

---

### Step 2 — Ads Policy Check (Automated Scanner)

**REJECT — AdMob production App ID is Google's test App ID `ca-app-pub-3940256099942544~3347511713`**

`android/app/src/main/AndroidManifest.xml` line 40:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-3940256099942544~3347511713"/>
```

Google's APK scanner recognizes `ca-app-pub-3940256099942544` as its own internal test publisher account. Shipping an app with this App ID violates AdMob Program Policies (Invalid Traffic) and Google Play Developer Policy — Monetization and Ads. This triggers an automated rejection with the message "Invalid AdMob configuration."

**Acceptance criteria to pass:** Register the app in AdMob Console, obtain a real Android App ID, replace the value in `AndroidManifest.xml`.

---

### Step 3 — Human Reviewer: Functionality Check

**LIKELY — TikTok mock token creates fake Connected state**

Same as Apple review Step 2. The reviewer will connect TikTok, see a "Connected" badge, navigate to the feed, and find no TikTok content. Deceptive functionality is flagged under Play Developer Policy — Deceptive Behavior.

---

### Step 4 — Store Listing Review

**LIKELY — App description is template text "A new Flutter project."**

Play Console's listing quality checker flags placeholder descriptions. The short description and full description fields in Play Console are separate from `pubspec.yaml`, but the template `pubspec.yaml` description signals the entire submission is incomplete.

---

### Step 5 — Data Safety Form

**LIKELY — No Data Safety form values configured; privacy policy URL required**

Play Console requires a completed Data Safety form before any app can be published. This form requires:
- A publicly accessible privacy policy URL (same gap as the App Store).
- Disclosure of all data collected, shared, and its purpose.

The app collects: email, user ID, OAuth tokens (Google, Facebook), content preferences, notification tokens, and device analytics. None of this is disclosed in a completed Data Safety form. Play Console will block submission until this form is submitted and a privacy policy URL is entered.

---

### Step 6 — Subscription and Billing

**POSSIBLE — Subscription receipts validated client-side only**

`subscription_service.dart` lines 153–155 acknowledge that server-side receipt verification is not implemented:

```dart
// In production: verify receipt server-side before granting
// For now: trust the store
```

Google Play Developer Policy requires that subscriptions be verified against the Google Play Developer API before premium access is granted. While this is less likely to cause a first-submission rejection (Play review does not test purchase flows in depth), it is a policy violation that can result in post-publication enforcement action and is trivially exploitable by users.

---

### Step 7 — EU Consent (GDPR)

**POSSIBLE — No UMP (User Messaging Platform) consent flow for EU users**

Google AdMob requires apps distributed in the EU to implement the Google User Messaging Platform SDK to collect consent before showing personalized ads to EU residents. No UMP integration (`google_mobile_ads` UMP APIs or `user_messaging_platform` package) is present in the codebase. Play Store does not reject for this during initial review, but post-publication AdMob policy enforcement will flag it.

---

## 4. Risk Matrix

Probability scale: **High** (reviewer will find it), **Medium** (reviewer may find it depending on test path), **Low** (requires specific conditions).  
Impact scale: **BLOCK** (submission rejected or store removal), **SEVERE** (account action risk), **HIGH** (likely rejection), **MEDIUM** (reviewer note / metadata hold).

| # | Risk | Platform | Probability | Impact | Net Risk |
|---|---|---|---|---|---|
| R-1 | `firebase_core` without config files — crash on launch | Both | **High** | **BLOCK** | Critical |
| R-2 | TikTok mock token — fake Connected state | Both | **High** | **BLOCK** | Critical |
| R-3 | AdMob test App ID in `AndroidManifest.xml` | Play | **High** | **BLOCK** | Critical |
| R-4 | AdMob test App ID in `Info.plist` (iOS) | App Store | **High** | **BLOCK** | Critical |
| R-5 | Production ad unit IDs not configured (empty string) | Both | **High** | **BLOCK** | Critical |
| R-6 | "Comments coming soon" SnackBar in primary feed | App Store | **High** | **HIGH** | High |
| R-7 | Creator tier pricing card — non-purchasable but displayed | App Store | **High** | **HIGH** | High |
| R-8 | `pubspec.yaml` description is Flutter template text | Both | **High** | **MEDIUM** | Medium |
| R-9 | No hosted privacy policy URL | Both | **Medium** | **HIGH** | High |
| R-10 | `google_sign_in` with no OAuth client ID — sign-in fails | App Store | **Medium** | **HIGH** | High |
| R-11 | No Data Safety form / privacy policy URL in Play Console | Play | **High** | **BLOCK** | Critical |
| R-12 | Subscription receipt verified client-side only | Play | **Low** | **SEVERE** | High |
| R-13 | No UMP consent flow for EU AdMob compliance | Play | **Low** | **SEVERE** | High |

---

## 5. Pre-Submission Blocker Checklist

The following items must all be checked before filing with either store. Items are ordered by dependency (config infrastructure first, then feature work, then store metadata).

---

### BLOCKER 1 — Firebase Configuration (Both Stores)
**Risk refs:** R-1

- [ ] **Decision:** Keep Firebase or remove it.
  - **Option A (Remove):** Delete `firebase_core: ^2.31.0` from `pubspec.yaml`. Run `flutter pub get`. Verify no remaining import of `package:firebase_core` in `lib/`. Remove the Firebase SDK from `ios/Podfile` if it was added manually.
  - **Option B (Configure):** Create a Firebase project at `console.firebase.google.com`. Register both iOS (`com.afeedi.app`) and Android (`com.afeedi.app`) apps. Download `GoogleService-Info.plist` → place at `ios/Runner/GoogleService-Info.plist`. Download `google-services.json` → place at `android/app/google-services.json`. Apply the `com.google.gms.google-services` plugin in `android/app/build.gradle.kts`.
- [ ] **Acceptance criteria:** `flutter build ios --release` and `flutter build appbundle --release` complete without Firebase initialization errors. Test a cold launch on a physical device.

---

### BLOCKER 2 — AdMob Production App IDs (Both Stores)
**Risk refs:** R-3, R-4, R-5

- [ ] Register the app in AdMob Console (`admob.google.com`). Create separate iOS and Android app entries.
- [ ] Obtain real iOS App ID (format `ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY`). Replace line 56 of `ios/Runner/Info.plist`.
- [ ] Obtain real Android App ID. Replace `android:value` at `android/app/src/main/AndroidManifest.xml` line 40.
- [ ] Create native ad units and rewarded ad units in the AdMob Console for both platforms. Record the 4 resulting ad unit IDs.
- [ ] Supply the 4 ad unit IDs as `--dart-define` flags at release build time:
  - `ADMOB_NATIVE_IOS=ca-app-pub-.../...`
  - `ADMOB_NATIVE_ANDROID=ca-app-pub-.../...`
  - `ADMOB_REWARDED_IOS=ca-app-pub-.../...`
  - `ADMOB_REWARDED_ANDROID=ca-app-pub-.../...`
- [ ] **Acceptance criteria:** Release build on a real device shows actual ads (not test ads, not blank spaces). AdMob dashboard shows impression events.

---

### BLOCKER 3 — Remove or Replace TikTok Mock OAuth (Both Stores)
**Risk refs:** R-2

- [ ] **Option A (Recommended for v1.0):** In `oauth_service.dart`, remove `'tiktok'` from the list of connectable platforms. Remove or guard the `connectTikTok()` method body with a compile-time flag. Remove TikTok from any platform-picker UI in `create_content_screen.dart` and settings. Replace with a "TikTok — Coming in a future update" informational message that does NOT show a Connect button.
- [ ] **Option B (Full implementation):** Implement TikTok Login Kit. Register at `developers.tiktok.com`, complete TikTok's own app review, and implement the OAuth PKCE flow. This is a 2–3 week effort and is out of scope for v1.0.
- [ ] **Acceptance criteria:** No TikTok Connect button is visible in the release build, OR tapping Connect launches a real TikTok OAuth screen in a browser/WebView with a valid client_id.

---

### BLOCKER 4 — Remove "Coming Soon" Visible to Reviewers (App Store)
**Risk refs:** R-6, R-7

- [ ] `enhanced_feed_post_card.dart` line 635: Remove the Comments button from the card widget, OR replace the SnackBar with a proper comments UI before submission.
- [ ] `premium_screen.dart` line 495–514: Remove the Creator tier card from the plan list entirely. Do not display a plan card for a tier that cannot be purchased.
- [ ] **Acceptance criteria:** No user-visible "coming soon" text or non-functional buttons appear anywhere in the primary navigation flow (feed, premium, settings, profile). Reviewer's path through the app has no dead ends.

---

### BLOCKER 5 — Privacy Policy Hosted URL (Both Stores)
**Risk refs:** R-9, R-11

- [ ] Host the privacy policy at a stable public URL, e.g., `https://afeedi.com/privacy` (or a GitHub Pages / Notion link as a temporary measure).
- [ ] Enter that URL in the App Store Connect "Privacy Policy URL" field before filing.
- [ ] Enter that URL in the Play Console "Store listing > Privacy policy" field before publishing.
- [ ] Update the Privacy Policy dialog in `settings_tab.dart` (the "Open" action navigates to the in-app screen, which is acceptable) — also add a `url_launcher` call to open the hosted URL from the in-app screen's app bar or footer for completeness.
- [ ] **Acceptance criteria:** Navigating to `https://afeedi.com/privacy` returns a valid, readable privacy policy page without authentication. Both store submission forms accept the URL without error.

---

### BLOCKER 6 — App Description Metadata (Both Stores)
**Risk refs:** R-8

- [ ] `pubspec.yaml` line 2: Replace `"A new Flutter project."` with a real description, e.g., `"Afeedi — personalized social media feed aggregator for YouTube, Instagram, and Facebook content."`.
- [ ] Write the App Store Connect short description (30 chars) and full description (4000 chars max) before filing.
- [ ] Write the Play Console short description (80 chars) and full description (4000 chars max) before publishing.
- [ ] **Acceptance criteria:** No placeholder text appears in any store listing metadata field.

---

### BLOCKER 7 — Play Console Data Safety Form (Play Store)
**Risk refs:** R-11

- [ ] Complete the Data Safety questionnaire in Play Console. Minimum required disclosures:
  - **Data collected:** Email address, User ID, Approximate location (if applicable), Crash logs, App interactions.
  - **Data shared:** Email + User ID shared with Google (Firebase/Google Sign-In), Facebook (via `flutter_facebook_auth`), AdMob (device identifiers).
  - **Security practices:** Data encrypted in transit (HTTPS enforced); no end-to-end encryption for user content.
- [ ] **Acceptance criteria:** Play Console "Data safety" section shows "Approved" status. No red warnings on the listing.

---

### RECOMMENDED (High Severity, Not Submission-Blockers for v1.0)

The following items will not block the first submission but represent high-severity risks for production stability and post-publication enforcement:

- **Google Sign-In OAuth client ID** (R-10): Add `REVERSED_CLIENT_ID` URL scheme to `Info.plist` by generating `GoogleService-Info.plist` from Firebase Console (satisfies both Blocker 1 Option B and this). Without it, Google Sign-In fails silently on iOS.
- **Subscription server-side receipt verification** (R-12): Implement a backend endpoint that calls the Google Play Developer API and Apple's `/verifyReceipt` (or use RevenueCat/Adapty). Required before meaningful revenue accrues.
- **UMP consent for EU AdMob** (R-13): Integrate `google_mobile_ads` UMP APIs. Required for EU distribution under GDPR / TCF 2.0.

---

## 6. Estimated Time to Fix Remaining Items

| Blocker | Description | Effort | Skill Required |
|---|---|---|---|
| BLOCKER 1 | Firebase config or removal | 2–4 hours | DevOps / Firebase console |
| BLOCKER 2 | AdMob real App IDs + ad units | 2–4 hours | AdMob console + build config |
| BLOCKER 3 (Option A) | Remove TikTok Connect button | 1–2 hours | Flutter frontend |
| BLOCKER 4 | Remove coming soon UI elements | 2–3 hours | Flutter frontend |
| BLOCKER 5 | Host privacy policy + update store listings | 2–4 hours | Webmaster / legal |
| BLOCKER 6 | Write store metadata | 2–3 hours | Copywriting |
| BLOCKER 7 | Complete Play Data Safety form | 1–2 hours | Product / legal |
| **Total (blockers)** | | **12–22 hours** | |
| Google Sign-In fix | Add `REVERSED_CLIENT_ID` (if Firebase added) | 0 additional | Included in Blocker 1 |
| Subscription server-side | Implement backend receipt verification | 3–5 days | Backend engineer |
| UMP consent | EU GDPR ad consent flow | 1–2 days | Flutter frontend |
| **Total (all recommended)** | | **3–5 developer-days** | |

---

## 7. Recommended Go / No-Go Decision

**VERDICT: NO-GO for submission today.**

### Minimum Viable Submission Path

The fastest path to a submittable build requires completing Blockers 1–7 in this order:

1. **Day 1 (morning):** Decide Firebase keep vs. remove (Blocker 1). If removing, delete the dependency and clean the build. If keeping, set up Firebase project and download config files. This decision unblocks Google Sign-In as a side-effect.

2. **Day 1 (afternoon):** Set up AdMob Console, obtain real App IDs and ad unit IDs, update `Info.plist`, `AndroidManifest.xml`, and build config (Blocker 2).

3. **Day 2 (morning):** Remove TikTok Connect button from the UI (Blocker 3, Option A — 1–2 hours). Remove Creator tier card and Comments button "coming soon" (Blocker 4).

4. **Day 2 (afternoon):** Host privacy policy, write App Store and Play Store metadata descriptions (Blockers 5 and 6).

5. **Day 3:** Complete Play Console Data Safety form (Blocker 7). Perform a full regression test of the release build on physical devices (iOS and Android). Verify: cold launch does not crash, Sign In with Google works, ads load, no coming-soon text visible, account deletion works end-to-end.

6. **Day 3 (end):** File both submissions.

**After v1.0 ships (high priority post-launch):**
- Implement server-side subscription receipt verification before significant revenue volume.
- Implement UMP consent flow before EU ad revenue is meaningful.
- Implement real TikTok OAuth if TikTok integration is a product priority.

### Risk if Submitted in Current State

| If submitted now | App Store | Play Store |
|---|---|---|
| Likely outcome | **Rejected** — TikTok fake token + coming-soon UI + AdMob test ID will be caught by reviewer | **Rejected** — AdMob test App ID triggers automated scanner |
| Secondary risk | Firebase crash if `Firebase.initializeApp()` is reached | Firebase crash in pre-launch report |
| Time cost of rejection | 1–7 days re-review after fix | 3–7 days re-review after fix |
| Account risk | None (first-time submission, no history) | Low — test AdMob ID may flag account for monitoring |

A rejection adds 4–14 cumulative days of delay (fix + re-review cycle for each store). All Blockers 1–7 can be completed in 3 working days. **Investing 3 days now avoids a likely 4–14 day rejection cycle.**

---

*Report generated: 2026-05-30. Based on static analysis only; runtime behavior on reviewer devices may reveal additional issues not captured here. Re-audit after all blockers are resolved before filing.*
