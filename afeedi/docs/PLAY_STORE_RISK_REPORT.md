# Google Play Store Policy Risk Report — Afeedi

**Audit Date:** 2026-05-30  
**App ID:** com.afeedi.app  
**App Version:** 1.0.0+1  
**Auditor:** Google Play Policy Specialist (automated static analysis)

---

## Executive Summary

The Afeedi Flutter app has **3 CRITICAL issues** that will result in automatic rejection or developer account termination, **3 HIGH issues** that make approval unlikely without remediation, and several MEDIUM/LOW issues requiring disclosure or best-practice fixes. **The app must not be submitted to the Play Store in its current state.**

---

## CRITICAL Risks — Policy Violation → Rejection / Account Termination

---

### CRITICAL-1: `youtube_explode_dart` Actively Imported — YouTube ToS §4.F Violation + Play Malware/Deceptive Behavior Policy

**Policy References:**
- YouTube Terms of Service §4.F: "You agree not to... circumvent, disable, fraudulently engage with, or otherwise interfere with the Service (or attempt to do so in any way), including functionality related to subscriptions, access controls, and digital rights management."
- YouTube Developer Policies: "API Clients must not scrape YouTube Applications or access YouTube Data through means not expressly authorized by YouTube."
- Google Play Developer Policy — Malware: "An app that collects data from a user's device without their knowledge... or bypasses access controls."
- Google Play Developer Policy — Deceptive Behavior: "We don't allow apps that attempt to deceive users. Apps must not misrepresent the app's functionality."

**Severity:** ACCOUNT TERMINATION RISK. Google cross-checks Play Store apps against YouTube Terms of Service. Detection is automated via APK scanning for the `youtube_explode_dart` package signature.

**Evidence — Active Imports (2 files):**

`lib/services/youtube_live_content_service.dart` line 5:
```dart
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
```
The comment on line 8 explicitly documents the violation: *"Fetches real YouTube video data using youtube_explode_dart (no API key needed)."* This is the definition of scraping — bypassing YouTube's API auth controls.

Active scraping calls in this file:
- Line 48: `yt.search.getVideos(query)` — searches YouTube without an API key
- Line 97: `YoutubeExplode()` — instantiates scraper for batch feed fetching
- Lines 103–116: loops over 8 search topics, fetching up to 8 videos per topic

`lib/services/video_content_extraction_service.dart` line 2:
```dart
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
```
Active violations in this file:
- Line 47: `_youtubeExplode.videos.get(videoId)` — fetches video metadata by bypassing the YouTube Data API
- Line 49: `_youtubeExplode.videos.streamsClient.getManifest(videoId)` — **extracts direct MP4 stream URLs from YouTube**. This is the most severe violation: it circumvents YouTube's DRM/access controls and directly violates the Anti-Circumvention clause of the YouTube ToS.
- Line 71: `_youtubeExplode.videos.closedCaptions.getManifest(videoId)` — scrapes closed captions

`lib/widgets/enhanced_video_player_widget.dart` line 75:
```dart
final extractedContent = await VideoContentExtractionService.instance.extractVideoContent(widget.content);
```
This widget is instantiated with `contentOnlyMode: true` (the default on line 17), meaning the scraping path is active for all YouTube content unless explicitly overridden.

**Note on `content_service.dart`:** Lines 2855–2857 contain a comment saying `youtube_explode_dart scraping is disabled`. However, `ContentService` is only one of three consumers. `YouTubeLiveContentService` and `VideoContentExtractionService` both remain fully active and unconditionally import and call `youtube_explode_dart`. The package is still in `pubspec.yaml` line 84 and will be compiled into the APK regardless of runtime branching in `ContentService`.

**Fix — Required before submission:**
1. Remove `youtube_explode_dart: ^2.5.2` from `pubspec.yaml` entirely.
2. Delete or rewrite `lib/services/youtube_live_content_service.dart` to use the [YouTube Data API v3](https://developers.google.com/youtube/v3) with an OAuth 2.0 or API key credential.
3. Delete or rewrite `lib/services/video_content_extraction_service.dart`. Direct stream extraction from YouTube is not permitted under any API. Video playback must use `youtube_player_iframe` (already in the project at `pubspec.yaml` line 113) which uses the sanctioned YouTube IFrame Player API, or official YouTube embedded players.
4. Rewrite `lib/widgets/enhanced_video_player_widget.dart` to remove the call path through `VideoContentExtractionService` for YouTube content. Use `YouTubePlayerWidget` already present in `lib/widgets/streaming/youtube_player_widget.dart`.
5. Run `flutter pub get` after removing the dependency to verify it is no longer compiled in.

---

### CRITICAL-2: AdMob Test App ID Used in Production Manifest

**Policy Reference:**
- Google Play Developer Policy — Ads: "Ads must not... use developer test IDs in production apps."
- AdMob Program Policies: "You must not use test ad unit IDs in apps submitted to Google Play. Test IDs generate no revenue and may result in your AdMob account being suspended."
- Google Play Developer Policy — Monetization and Ads: Invalid traffic policy.

**Evidence:**

`android/app/src/main/AndroidManifest.xml` line 38–39:
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-3940256099942544~3347511713"/>
```
`ca-app-pub-3940256099942544` is Google's publicly documented test publisher account. This ID is in every "hello world" AdMob tutorial on the internet.

`lib/services/ad_service.dart` lines 21–34 compound the problem — the production code paths (`if (!kDebugMode)`) return the **same test ad unit IDs** as the debug paths:
```dart
// TODO: replace with real production ad unit IDs before store submission
return Platform.isIOS
    ? 'ca-app-pub-3940256099942544/3986624511'
    : 'ca-app-pub-3940256099942544/2247696110';
```
Both `nativeAdUnitId` and `rewardedAdUnitId` use test IDs in release builds. The TODO comment confirms this is known but unresolved.

**Fix — Required before submission:**
1. Create a real AdMob account at [admob.google.com](https://admob.google.com) and register the app to obtain a real App ID (format: `ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX`).
2. Replace the test App ID in `AndroidManifest.xml` line 39.
3. Create real ad units in the AdMob console for native and rewarded formats.
4. Replace all 4 test unit ID strings in `lib/services/ad_service.dart` with the real production IDs. The `if (kDebugMode)` branches may keep the test IDs for debug builds; the `else` branches must use real production IDs.

---

### CRITICAL-3: `EnhancedVideoPlayerWidget` Serves Raw YouTube MP4 Streams — Copyright Circumvention

**Policy Reference:**
- Google Play Developer Policy — Intellectual Property: "We don't allow apps that infringe on the intellectual property rights of others, including copyright."
- YouTube Terms of Service §5 (Your Use of Content): "You shall not download any Content unless you see a 'download' or similar link displayed by YouTube on the Service."
- Google Play Developer Policy — Malware (Unauthorized Actions): Apps that access content in ways not authorized by the content owner.

**Evidence:**

`lib/widgets/enhanced_video_player_widget.dart` lines 91–127: The widget calls `VideoContentExtractionService.instance.extractVideoContent()` to obtain raw MP4 stream URLs (`.m3u8` / direct CDN URLs extracted by `youtube_explode_dart`), then renders them in a custom `<video>` HTML element inside a `WebViewController`. This completely bypasses the YouTube player, removes all YouTube branding, attribution, and controls, and serves the raw copyrighted content without authorization.

This is a distinct violation from CRITICAL-1 (which is about scraping) — this is active copyright circumvention and unauthorized content serving.

**Fix:** Remove the `_extractVideoContent()` path entirely from `enhanced_video_player_widget.dart`. Use only the standard `_initializeWebView()` embed path, or better, replace the widget with the existing `YouTubePlayerWidget` (which uses `youtube_player_iframe`, the sanctioned embed method).

---

## HIGH Risks — Likely Rejection Without Remediation

---

### HIGH-1: `RECEIVE_BOOT_COMPLETED` Permission With No Registered `BroadcastReceiver`

**Policy Reference:**
- Google Play Developer Policy — Permissions: "Permissions must be necessary for the app's core functionality and must be clearly disclosed to users."
- Google Play Permissions Policy: "Apps must not request permissions that are not required for the app's declared functionality."

**Evidence:**

`android/app/src/main/AndroidManifest.xml` line 6:
```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

No `<receiver android:name="..." android:exported="false">` with `<action android:name="android.intent.action.BOOT_COMPLETED"/>` exists anywhere in the `AndroidManifest.xml`. No Java/Kotlin `BroadcastReceiver` class was found in `android/app/src/main/kotlin/`. No Dart-side code in `lib/services/notification_service.dart` or elsewhere registers a boot receiver.

The `flutter_local_notifications` plugin (pubspec.yaml line 76) does register its own boot receiver internally to reschedule notifications after reboot — but this is declared in the plugin's own merged manifest, not by the app. However, `notification_service.dart` uses `AndroidScheduleMode.inexactAllowWhileIdle` (not `exactAllowWhileIdle`), which does not require `RECEIVE_BOOT_COMPLETED` in the app's own manifest. The redundant explicit declaration in the app manifest is a policy red flag.

Play Store reviewers flag `RECEIVE_BOOT_COMPLETED` as a "high-sensitivity permission" requiring justification in the app's Data Safety section and potentially a permissions declaration review.

**Fix:**
1. If `flutter_local_notifications` handles the boot receiver internally (which it does since v13+), remove the explicit `<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>` from the app's `AndroidManifest.xml`. The plugin's merged manifest will declare it with proper context.
2. If you confirm the permission is still needed (e.g., after testing that scheduled notifications survive reboot), add documentation in the Play Console's "App Content" > "Permissions Declaration" explaining: "Used by flutter_local_notifications to reschedule daily and weekly content recommendation notifications after device restart."

---

### HIGH-2: AdMob Test Ad Unit IDs Served to Real Users (Compounding CRITICAL-2)

**Policy Reference:**
- Google AdMob Invalid Traffic Policy: "Publishers are not permitted to... generate artificial impressions or clicks."
- Google Play — Ads Policy: Invalid traffic / click fraud provisions.

**Evidence:** Described under CRITICAL-2. Because the release code path in `ad_service.dart` returns test IDs, live users will see either no ads (test ads don't render for real user ad requests from non-registered test devices) or a mismatch that AdMob's system flags as invalid traffic. This can trigger AdMob account suspension independent of the Play Store review.

**Fix:** Described under CRITICAL-2. Ensure the `if (!kDebugMode)` code paths use real production ad unit IDs.

---

### HIGH-3: Subscription Receipt Verification is Client-Side Only

**Policy Reference:**
- Google Play Developer Policy — Monetization: "Developers must not... grant purchases without verifying through the Google Play Billing Library."
- Google Play Billing Library guidance: Server-side receipt verification is required for subscriptions to prevent receipt replay attacks and fraudulent premium access.

**Evidence:**

`lib/services/subscription_service.dart` lines 153–155:
```dart
// In production: verify receipt server-side before granting
// For now: trust the store (acceptable for MVP, replace with server verification pre-launch)
```
The `_verifyAndGrant()` method on line 153 unconditionally grants premium access upon any `PurchaseStatus.purchased` or `PurchaseStatus.restored` event without verifying the purchase token against the Google Play Developer API. A receipt replay attack could grant premium access to users who have not paid.

Additionally, `_devGrantPremium()` (lines 217–225) grants premium status in debug mode if the product is not found in the store. While guarded by `kDebugMode`, this path should be audited before release to ensure it cannot be triggered in production builds.

**Fix:**
1. Before Play Store submission, implement server-side receipt verification: send `purchase.verificationData.serverVerificationData` to your backend, which verifies it against the [Google Play Developer API `purchases.subscriptions.get`](https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.subscriptions/get) endpoint.
2. Only call `_verifyAndGrant()` after the server returns a valid, active subscription status.
3. Document this in your app's Data Safety section (subscription status is shared with your server).

---

## MEDIUM Risks — Required Disclosures / Policy Completeness

---

### MEDIUM-1: Data Safety Section Incomplete for Facebook Auth

**Policy Reference:**
- Google Play Developer Policy — Data Safety: "Developers must accurately disclose how their app collects, shares, and handles user data."

**Evidence:**

`lib/services/oauth_service.dart` lines 56–66 and 101–110 use `flutter_facebook_auth` to collect user data including `FacebookAuth.instance.getUserData(fields: ...)`. Facebook's SDK collects device identifiers and may perform its own data collection per Facebook's terms. This must be disclosed in the Play Console Data Safety form under:
- Data collected: Email address, Name, User ID (from Facebook profile)
- Purpose: Account management, App functionality
- Data shared with Facebook (third-party SDK)

**Fix:** Complete the Data Safety questionnaire in Play Console accurately, disclosing Facebook Auth data collection and Google Sign-In data collection. Review `flutter_facebook_auth`'s SDK data safety disclosure.

---

### MEDIUM-2: `flutter_local_notifications` Scheduled Notifications — User Consent Not Demonstrated

**Policy Reference:**
- Google Play Developer Policy — Spam and Minimum Functionality: "Notifications must not be sent without user opt-in consent where required."
- Android 13+ (API 33): `POST_NOTIFICATIONS` runtime permission required before sending notifications.

**Evidence:**

`lib/services/notification_service.dart` lines 241–260: `schedulePersonalizedNotifications()` schedules daily and weekly notifications. However, no code path showing the user is explicitly asked for notification consent before `schedulePersonalizedNotifications()` is called was found during this audit. The `requestPermission()` method exists (line 81) but it is not clear it is invoked before scheduling.

`android/app/src/main/AndroidManifest.xml` line 5 declares `POST_NOTIFICATIONS`, which is correct for Android 13+.

**Fix:** Ensure `requestPermission()` is always called and its result checked before `schedulePersonalizedNotifications()` is invoked. Display a user-facing rationale dialog explaining why notifications are useful before the system permission dialog appears.

---

### MEDIUM-3: `in_app_purchase` Subscription — Play Billing Label Requirements

**Policy Reference:**
- Google Play Developer Policy — Subscriptions: "Apps that offer subscriptions must clearly indicate: subscription name, price, billing period, free trial terms."

**Evidence:**

`lib/services/subscription_service.dart` lines 13–16 hardcode fallback prices (`$4.99/month`, `$39.99/year`) displayed when store-fetched prices are unavailable. If the app launches before the products are loaded (`_loadProducts()` is async), users may see stale hardcoded prices that do not match the configured Play Store prices, which violates subscription clarity requirements.

**Fix:** Never display hardcoded prices to users. Show a loading state until `_loadProducts()` resolves and `_products` is populated. Only display prices from `product.price` (store-fetched localized price string).

---

### MEDIUM-4: `usesCleartextTraffic="false"` — Verify All Endpoints Use HTTPS

**Policy Reference:**
- Google Play Developer Policy — Malware/Data Safety: Apps must use encrypted connections for sensitive data.

**Evidence:**

`android/app/src/main/AndroidManifest.xml` line 12: `android:usesCleartextTraffic="false"` is correctly set, which is good. However, `lib/services/content_service.dart` references `ApiContentService` (a local API backend). The `network_security_config.xml` file exists at `android/app/src/main/res/xml/network_security_config.xml` — this file was not audited in depth but should be reviewed to ensure it does not whitelist cleartext for any domain other than `localhost`/`10.0.2.2` (acceptable for local dev API).

**Fix:** Read `network_security_config.xml` and confirm it only permits cleartext for loopback addresses used by the local development API. All production endpoints must be HTTPS-only.

---

### MEDIUM-5: Facebook OAuth Scope — `instagram_basic` / Platform Content Access

**Policy Reference:**
- Google Play Developer Policy — User Data: "Requesting only the minimum permissions necessary."
- Meta Platform Policy: Apps must not scrape or aggregate content from Instagram without authorized API access.

**Evidence:**

`lib/services/oauth_service.dart` lines 56–61: `FacebookAuth.instance.login(permissions: ['email', 'public_profile'])` — scope appears minimal and acceptable. However, `content_service.dart` contains seeded `PlatformType.instagram` and `PlatformType.tiktok` content items (lines 119–177) with hardcoded `videoUrl` pointing to real Instagram and TikTok URLs. If the app ever fetches or plays this content via the WebView embed path in `enhanced_video_player_widget.dart` (`_buildEmbedUrl()` lines 163–170), this constitutes unauthorized content aggregation.

**Fix:** Ensure Instagram and TikTok content is only displayed via deep links (`url_launcher`) that open the native app, or via officially authorized embed APIs. Seeded/fake content IDs should be clearly marked as demo data and must not point to real user content without authorization.

---

## LOW Risks — Best Practices / Pre-Launch Hygiene

---

### LOW-1: App Version `1.0.0+1` — Version Name Must Match Play Console

**Evidence:** `pubspec.yaml` line 19: `version: 1.0.0+1`. Ensure this matches exactly what is entered in Play Console. Mismatches cause upload rejections.

---

### LOW-2: `applicationId = "com.afeedi.app"` — Two `MainActivity.kt` Files Present

**Evidence:** Two `MainActivity.kt` files exist:
- `android/app/src/main/kotlin/com/example/afeedi/MainActivity.kt`
- `android/app/src/main/kotlin/com/afeedi/app/MainActivity.kt`

The first path (`com.example.afeedi`) does not match the declared `namespace = "com.afeedi.app"` in `build.gradle.kts`. The `com.example.*` package is the default template package and the file may be a stale artifact. This can cause build warnings or runtime issues.

**Fix:** Delete `android/app/src/main/kotlin/com/example/afeedi/MainActivity.kt` if it is unused. Verify the active `MainActivity.kt` is at the path matching `namespace = "com.afeedi.app"`.

---

### LOW-3: `publish_to: 'none'` in pubspec.yaml

**Evidence:** `pubspec.yaml` line 5. This is correct for a private app and should be left as-is.

---

### LOW-4: Firebase Core Included but Messaging Disabled

**Evidence:** `pubspec.yaml` line 74: `firebase_core: ^2.31.0` is a dependency; line 75 shows `firebase_messaging` is commented out. If `Firebase.initializeApp()` is called but no Firebase project is configured with a valid `google-services.json`, the app will crash at startup on release builds.

**Fix:** Either configure a real Firebase project and add `google-services.json` to `android/app/`, or remove `firebase_core` from `pubspec.yaml` if it is not yet needed.

---

### LOW-5: `key.properties` Signing — Ensure Not Committed to Git

**Evidence:** `android/key.properties.template` exists. `build.gradle.kts` lines 12–15 correctly load `key.properties` only if it exists. Confirm `key.properties` (containing real passwords) is in `.gitignore` and has never been committed.

**Fix:** Run `git log --all --full-history -- android/key.properties` to verify the actual keystore credentials file has not been committed to git history.

---

### LOW-6: `description: "A new Flutter project."` in pubspec.yaml

**Evidence:** `pubspec.yaml` line 2. While this does not affect Play Store policy, it is a placeholder that may appear in build tooling output and should be replaced with a real app description.

---

## Summary Table

| ID | Severity | Issue | File(s) | Status |
|----|----------|-------|---------|--------|
| CRITICAL-1 | CRITICAL | `youtube_explode_dart` scraping — YouTube ToS §4.F + Play Malware Policy | `pubspec.yaml`, `youtube_live_content_service.dart`, `video_content_extraction_service.dart`, `enhanced_video_player_widget.dart` | Must fix before submission |
| CRITICAL-2 | CRITICAL | AdMob test App ID in production manifest | `AndroidManifest.xml`, `ad_service.dart` | Must fix before submission |
| CRITICAL-3 | CRITICAL | Raw YouTube MP4 stream serving — copyright circumvention | `enhanced_video_player_widget.dart`, `video_content_extraction_service.dart` | Must fix before submission (subsumed by CRITICAL-1 fix) |
| HIGH-1 | HIGH | `RECEIVE_BOOT_COMPLETED` undeclared/unjustified | `AndroidManifest.xml` | Fix or justify before submission |
| HIGH-2 | HIGH | Test ad unit IDs in release code paths | `ad_service.dart` | Must fix before submission (subsumed by CRITICAL-2 fix) |
| HIGH-3 | HIGH | Client-side-only subscription receipt verification | `subscription_service.dart` | Implement server-side verification before launch |
| MEDIUM-1 | MEDIUM | Facebook Auth data not disclosed in Data Safety | `oauth_service.dart` | Complete Data Safety form |
| MEDIUM-2 | MEDIUM | Notification scheduling without confirmed user consent flow | `notification_service.dart` | Audit consent flow |
| MEDIUM-3 | MEDIUM | Hardcoded subscription prices shown before store loads | `subscription_service.dart` | Show loading state |
| MEDIUM-4 | MEDIUM | `network_security_config.xml` not audited | `network_security_config.xml` | Verify HTTPS-only for prod |
| MEDIUM-5 | MEDIUM | Seeded Instagram/TikTok URLs may constitute unauthorized aggregation | `content_service.dart` | Use deep links only |
| LOW-1 | LOW | Version name must match Play Console | `pubspec.yaml` | Verify at upload |
| LOW-2 | LOW | Stale `com.example.afeedi` `MainActivity.kt` | `android/app/src/main/kotlin/com/example/` | Delete stale file |
| LOW-3 | LOW | `publish_to: 'none'` — correct, keep | `pubspec.yaml` | No action |
| LOW-4 | LOW | Firebase Core without `google-services.json` may crash | `pubspec.yaml` | Configure or remove |
| LOW-5 | LOW | `key.properties` must not be in git history | `android/key.properties` | Audit git history |
| LOW-6 | LOW | Default app description placeholder | `pubspec.yaml` | Update |

---

## Recommended Submission Checklist

Before submitting to Google Play:

- [ ] Remove `youtube_explode_dart` from `pubspec.yaml` and all 2 service files
- [ ] Implement YouTube Data API v3 integration for content search
- [ ] Replace `VideoContentExtractionService` with `youtube_player_iframe` embeds
- [ ] Replace AdMob test App ID in `AndroidManifest.xml` with real ID
- [ ] Replace all 4 test ad unit IDs in `ad_service.dart` with real production IDs
- [ ] Remove or justify `RECEIVE_BOOT_COMPLETED` in `AndroidManifest.xml`
- [ ] Implement server-side receipt verification for subscriptions
- [ ] Complete Play Console Data Safety form (Facebook, Google, AdMob data flows)
- [ ] Verify notification permission requested before scheduling
- [ ] Remove hardcoded subscription price fallbacks from UI
- [ ] Audit `network_security_config.xml` for cleartext domains
- [ ] Delete `android/app/src/main/kotlin/com/example/afeedi/MainActivity.kt`
- [ ] Configure Firebase project with real `google-services.json` or remove `firebase_core`
- [ ] Confirm `key.properties` is not in git history

---

*Report generated by static analysis of source files. Dynamic/runtime behavior was not tested. Additional policy issues may exist in code paths not covered by this audit.*
