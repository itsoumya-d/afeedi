# Afeedi — Compliance Gap Report

**Report Date:** 2026-05-30  
**App Version:** 1.0.0+1  
**App ID (Android):** com.afeedi.app  
**Bundle ID (iOS):** com.afeedi.app  
**Platforms:** iOS (App Store) · Android (Google Play)  
**Scope:** App Store Review Guidelines · Google Play Developer Policy · GDPR · COPPA · YouTube/Meta/TikTok Platform ToS · Security best practices  
**Status:** Post-fix audit — documents state AFTER the session fixes described in Section 2

---

## 1. Executive Summary

Twenty-one compliance issues have been remediated in this development session, resolving every previously identified Apple-mandatory-rejection blocker (account deletion, sign-out, privacy/ToS links, ATT integration, GADApplicationIdentifier, NSMicrophoneUsageDescription) and eliminating the most legally dangerous dependency (`youtube_explode_dart` and its associated stream-scraping code paths).

**Six CRITICAL gaps remain open** that will cause automatic rejection by Apple or Google, or expose the developer to financial/legal liability, if the app is submitted without resolution. The most urgent is the AdMob configuration: both `AndroidManifest.xml` and `AppDelegate.swift` still reference Google's public test App IDs, which will result in AdMob account suspension. Firebase is declared as a dependency but lacks its configuration files, which will crash iOS and Android release builds on first launch. TikTok OAuth returns hardcoded mock tokens that fabricate a "Connected" state — Apple reviewers explicitly test this flow.

**The app is not ready for store submission.** The critical items require real developer-account actions (AdMob console, Firebase console, TikTok developer program) that cannot be resolved by code changes alone.

**Submission readiness score: 5 / 10** — see Section 4 for the full breakdown.

---

## 2. Fixes Implemented This Session

The following issues were open at the start of this session and are now resolved. The table reflects the code state as of 2026-05-30.

| # | Fix | Files Changed | Original Risk | Status |
|---|-----|---------------|---------------|--------|
| 1 | `youtube_explode_dart` removed from `pubspec.yaml` and all import sites | `pubspec.yaml` | CRITICAL (YouTube ToS §4.F; Play Malware Policy — account termination risk) | ✅ Fixed |
| 2 | `youtube_live_content_service.dart` replaced with a stub (no scraping) | `lib/services/youtube_live_content_service.dart` | CRITICAL (active scraping without API key) | ✅ Fixed |
| 3 | `video_content_extraction_service.dart` replaced with embed-URL-only version (no stream extraction) | `lib/services/video_content_extraction_service.dart` | CRITICAL (MP4 stream extraction = copyright circumvention) | ✅ Fixed |
| 4 | `enhanced_video_player_widget.dart` rewritten to use WebView IFrame embed only | `lib/widgets/enhanced_video_player_widget.dart` | CRITICAL (raw stream serving to users) | ✅ Fixed |
| 5 | Account deletion button wired — calls `LocalAuthService.deleteAccount()` + `clearAllData()` + navigates to welcome | `lib/widgets/dashboard/settings_tab.dart` | CRITICAL (Apple 5.1.5; GDPR Art. 17 — dead button) | ✅ Fixed |
| 6 | Sign Out button wired — calls `LocalAuthService.signOut()` + navigates to welcome | `lib/widgets/dashboard/settings_tab.dart` | HIGH (App Completeness 2.1 — empty lambda) | ✅ Fixed |
| 7 | Privacy Policy link wired — navigates to in-app `PrivacyPolicyScreen` | `lib/widgets/dashboard/settings_tab.dart` | CRITICAL (Apple 5.1.1; Play Policy — dead TODO) | ✅ Fixed |
| 8 | Terms of Service link wired — navigates to in-app `TermsOfServiceScreen` | `lib/widgets/dashboard/settings_tab.dart` | CRITICAL (Apple 5.1.1; Play Policy — dead TODO) | ✅ Fixed |
| 9 | Privacy toggles persisted — saved/loaded from `SharedPreferences` | `lib/widgets/dashboard/settings_tab.dart` | HIGH (GDPR Art. 7 — cosmetic toggles with no effect) | ✅ Fixed (persistence only; observability by services remains open — see gap R-H-3) |
| 10 | "Download My Data" wired — calls `UserManagementService.exportUserData()` + copies to clipboard | `lib/widgets/dashboard/settings_tab.dart` | CRITICAL (GDPR Art. 20 — fake snackbar with no action) | ✅ Fixed |
| 11 | Profile navigation wired — navigates to `AppRoutes.profile` | `lib/widgets/dashboard/settings_tab.dart` | LOW (empty function — unresponsive UI) | ✅ Fixed |
| 12 | Subscription navigation wired — navigates to `AppRoutes.premium` | `lib/widgets/dashboard/settings_tab.dart` | LOW (empty function — unresponsive UI) | ✅ Fixed |
| 13 | `NSMicrophoneUsageDescription` removed from `Info.plist` (no recording feature exists) | `ios/Runner/Info.plist` | CRITICAL (Apple 5.3.4 / 2.3 — factually inaccurate permission string) | ✅ Fixed |
| 14 | `GADApplicationIdentifier` added to `Info.plist` (was missing — caused iOS crash at launch) | `ios/Runner/Info.plist` | HIGH (App Completeness 2.1 — hard crash at MobileAds init) | ✅ Fixed |
| 15 | `RECEIVE_BOOT_COMPLETED` justified with inline comment (`flutter_local_notifications` requirement) | `android/app/src/main/AndroidManifest.xml` | HIGH (Play Permissions Policy — undocumented sensitive permission) | ✅ Fixed |
| 16 | AdService test IDs guarded to `kDebugMode` only; production branches use env var or fail gracefully | `lib/services/ad_service.dart` | HIGH (AdMob policy — test IDs in release build) | ✅ Partially fixed (app-level guard improved; App IDs in manifest/plist still require developer action — see R-C-1) |
| 17 | Deprecated `modestbranding` YouTube parameter removed from 4 files | `lib/widgets/`, `lib/services/` | MODERATE (YouTube Branding Guidelines violation) | ✅ Fixed |
| 18 | Duplicate `com.example.afeedi/MainActivity.kt` removed | `android/app/src/main/kotlin/com/example/afeedi/` | LOW (stale artifact causing build warnings) | ✅ Fixed |
| 19 | `app_tracking_transparency ^2.0.7` added to `pubspec.yaml` and `AttService` wired before `MobileAds.initialize()` | `pubspec.yaml`, `lib/services/att_service.dart`, `lib/main.dart` | CRITICAL (Apple 5.1.2 — ATT declared but never requested) | ✅ Fixed |
| 20 | `deleteAccount()` now calls `clearAllData()` for complete GDPR data wipe | `lib/services/local_auth_service.dart` | HIGH (GDPR Art. 17 — partial deletion) | ✅ Fixed |
| 21 | Missing localization keys (`goodMorning`, `goodAfternoon`, `goodEvening`, `noNotifications`, `allCaughtUp`) added to all 12 locale ARB files | `lib/l10n/*.arb` | MEDIUM (broken UI strings in non-English locales) | ✅ Fixed |

---

## 3. Remaining Compliance Gaps

Issues are grouped by severity. Each entry includes the specific platform policy or legal regulation, the exact fix required, and a suggested owner.

---

### 3.1 CRITICAL — Must Fix Before Any Store Submission

Submitting the app with any of these gaps will result in automatic rejection (Apple/Google) or AdMob account suspension.

| ID | Gap | Platform | Guideline / Policy | Fix Required | Owner |
|----|-----|----------|--------------------|--------------|-------|
| R-C-1 | **AdMob production App IDs not configured.** `AndroidManifest.xml` still contains test App ID `ca-app-pub-3940256099942544~3347511713`. `AppDelegate.swift` still references the same test publisher prefix. Real revenue will not be generated; AdMob will flag the account for invalid traffic upon launch. | Both | AdMob Program Policies (test IDs in production); Google Play Ads Policy; Apple 2.1 | (1) Create a real AdMob account at admob.google.com. (2) Register both the Android and iOS apps. (3) Replace test App ID in `AndroidManifest.xml` line 39. (4) Replace in `AppDelegate.swift`. (5) Replace all 4 production branches in `lib/services/ad_service.dart` with real ad unit IDs from the AdMob console. Use `--dart-define=ADMOB_APP_ID_ANDROID=...` and `--dart-define=ADMOB_APP_ID_IOS=...` at build time rather than hard-coding. | Developer (requires AdMob account creation) |
| R-C-2 | **`firebase_core` declared in `pubspec.yaml` but `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are absent.** Firebase SDK calls `Firebase.initializeApp()` on launch; without the config files, this throws a `FirebaseException: Unable to load config` and the app crashes before the first frame renders on release builds. | Both | Apple 2.1 (App Completeness — crash at launch); Google Play Policy (crashing apps not accepted) | **Option A (preferred):** Create a Firebase project at console.firebase.google.com, register both app IDs, download `google-services.json` to `android/app/`, and download `GoogleService-Info.plist` to `ios/Runner/`. **Option B:** If Firebase is not yet used, remove `firebase_core` from `pubspec.yaml` entirely and remove any `Firebase.initializeApp()` call from `main.dart`. Do not ship a dependency that crashes the app. | Developer (requires Firebase project creation) |
| R-C-3 | **TikTok OAuth returns hardcoded mock tokens.** `lib/services/oauth_service.dart` `connectTikTok()` waits 2 seconds then returns `mock_tiktok_token_*` / `mock_tiktok_user_*`, setting TikTok to "Connected" in the UI with no real authentication. `lib/services/auth_service.dart` `getPlatformConnections()` returns static `token123` / `refresh123` for all platforms. Apple reviewers explicitly test all social-connect flows. | iOS | Apple 2.1 (App Completeness); Apple 5.5 (Developer Code of Conduct — deceptive to users) | **Option A (recommended):** Remove TikTok from the list of connectable platforms in the UI before submission. Hide or comment out the TikTok connect button until real TikTok OAuth (TikTok Login Kit) is implemented. **Option B:** Implement real TikTok OAuth — requires TikTok Developer account, app registration, and review. Also remove the static `token123`/`refresh123` map from `getPlatformConnections()` in `auth_service.dart`; replace with a real lookup from secure storage. | Developer |
| R-C-4 | **Subscription receipt verification is client-side only.** `lib/services/subscription_service.dart` `_verifyAndGrant()` grants premium status on any `PurchaseStatus.purchased` event without server-side verification. The comment in the code acknowledges this explicitly. On a compromised device, purchase receipts can be replayed or forged. | Both | Apple 3.1.1 (In-App Purchase); Google Play Monetization Policy (server-side verification requirement) | Implement a backend endpoint that calls Apple's StoreKit 2 `verifyTransaction` API (iOS) and Google Play Developer API `purchases.subscriptions.get` (Android) before calling `_verifyAndGrant()`. Alternatively, integrate a managed solution such as RevenueCat or Adapty that handles server-side verification transparently. Do not grant premium status from the client's `PurchaseDetails` object alone. | Developer + Backend |
| R-C-5 | **"Coming soon" features visible in production UI.** Comments button in feed shows `'Comments feature coming soon!'` snackbar. The Creator subscription tier card on `PremiumScreen` renders as a purchasable plan but opens a `'Creator Tier — Coming Soon'` dialog. `PlaceholderScreen` is routed from active navigation paths. Apple Guideline 2.1 explicitly forbids placeholder or unfinished UI visible to users. | iOS | Apple 2.1 (App Completeness — placeholder UI); also Play Policy (minimum functionality) | (1) Remove the comment button from `lib/widgets/feed/enhanced_feed_post_card.dart` or disable it via feature flag. (2) Remove the Creator tier plan card from `lib/screens/premium_screen.dart` entirely — do not display a plan that cannot be purchased. (3) Replace all `PlaceholderScreen` routes in `lib/core/navigation/navigation_service.dart` with real screens or remove those navigation options from the visible UI for this release. | Developer |
| R-C-6 | **Premium subscription paywall shows hardcoded prices before IAP products load.** `lib/services/subscription_service.dart` initialises with static fallback prices (`$4.99/month`, `$39.99/year`). If `_loadProducts()` has not completed when the Premium screen renders, these hardcoded values are displayed. Store prices can differ by country/currency; showing a hardcoded price that does not match the actual charge violates subscription clarity requirements on both platforms. | Both | Apple 3.1.2 (Auto-Renewable Subscriptions — must show price from StoreKit); Google Play Subscriptions Policy (price clarity) | Show a loading indicator on the PremiumScreen until `_loadProducts()` resolves and `_products` is populated. Only display `product.price` (the store-fetched, localized string). Remove all hardcoded `$4.99` / `$39.99` strings from the display path. | Developer |

---

### 3.2 HIGH — Strongly Recommended Before Submission

These gaps will not guarantee rejection on every review but represent significant legal, financial, or UX risk that reviewers frequently flag, and that could result in post-launch removal, regulatory action, or revenue loss.

| ID | Gap | Platform | Guideline / Policy | Fix Required | Owner |
|----|-----|----------|--------------------|--------------|-------|
| R-H-1 | **`oauth_service.dart` and `auth_service.dart` contain hardcoded mock tokens in non-debug code paths.** Even with the TikTok flow addressed in R-C-3, `auth_service.dart` `getPlatformConnections()` returns static `access_token: 'token123'` / `refresh_token: 'refresh123'` unconditionally. This value is used by any downstream code that reads platform tokens. | Both | Apple 5.5 (Developer Code of Conduct); Security best practice | Remove the static token map from `getPlatformConnections()` in `lib/services/auth_service.dart`. Replace with a real lookup from `flutter_secure_storage` keyed on platform + user ID. Return an empty map or throw `UnimplementedException` for platforms not yet supported rather than returning fake data. | Developer |
| R-H-2 | **Privacy toggles are now persisted but not observed by any service.** The session fixes saved toggle state to `SharedPreferences`, but `AnalyticsService.initialize()`, `AdService.initialize()`, and no other service reads those persisted values. A user who turns off "Data Collection" or "Personalized Ads" experiences no change in behavior — the app continues to collect analytics and serve ads as before. | Both | GDPR Art. 7 (consent must be operative, not cosmetic); CCPA; FTC Act §5 (deceptive trade practice) | (1) In `AnalyticsService.initialize()` and before each `trackEvent()` call, read `SharedPreferences` key `data_collection_enabled`; skip event queuing if `false`. (2) Gate `AdService.initialize()` on the `personalized_ads_enabled` key; if `false`, set `RequestConfiguration` to non-personalized ads. (3) On iOS, cross-check the `personalized_ads_enabled` flag with the ATT authorization status returned by `AttService` — whichever is more restrictive wins. | Developer |
| R-H-3 | **No UMP (User Messaging Platform) consent flow for EU/EEA users using AdMob.** Since January 2024, Google requires all apps using AdMob/Google Ad Manager to implement the UMP SDK to collect GDPR consent before showing personalised ads to users in the EEA/UK. The current implementation initialises AdMob unconditionally without geographic consent gating. | Android (primarily) | Google Play Developer Policy — EU User Consent Policy; GDPR Art. 6 | Integrate the `google_mobile_ads` UMP API: call `ConsentInformation.instance.requestConsentInfoUpdate()` and show the consent form if `ConsentInformation.instance.isConsentFormAvailable()`. Only call `MobileAds.instance.initialize()` after consent is collected (or if the user is outside the EEA). Reference: https://developers.google.com/admob/flutter/eu-consent | Developer |
| R-H-4 | **No COPPA age gate in onboarding.** The privacy policy states the app is "not directed to children under 13" but there is no age verification during sign-up. The `UserProfile` model has a `dateOfBirth` field but it is never collected. On both stores, a COPPA disclaimer without an enforcement mechanism is insufficient. | Both | COPPA (US — §312.5); GDPR Art. 8 (EU — under-16 age gate); UK Age Appropriate Design Code; Apple 5.1.4 | Implement one of: (A) Add a date-of-birth field to the onboarding flow and block users under 13 (US) / 16 (EU) from completing registration. (B) Add a binary age gate on first launch ("I am 13 or older") with a blocking screen for denied users. Select the correct minimum age by target market. Do not ship COPPA-governed app stores without enforcement. | Developer + Legal |
| R-H-5 | **`app_description` in `pubspec.yaml` is still the default Flutter template placeholder** (`"A new Flutter project"`). While this string does not appear verbatim in store listings, it appears in build tooling, crash reports, and internal review systems. It also signals to reviewers that the submission has not been thoroughly prepared. | Both | Apple 2.3 (Accurate Metadata); Google Play Policy (accurate app representation) | Update `description` in `pubspec.yaml` to a meaningful value, e.g.: `"Afeedi — personalized social media feed aggregator for YouTube, Instagram, TikTok, and Facebook content."` | Developer |
| R-H-6 | **Privacy policy requires a publicly accessible URL for store listing metadata.** The in-app `PrivacyPolicyScreen` satisfies the in-app link requirement (now wired — Fix #7), but App Store Connect and Play Console both require a hosted public URL in their metadata fields. This URL cannot be an in-app-only screen. | Both | Apple App Store Connect (Privacy Policy URL — required field); Google Play Console (Privacy policy URL — required field) | Host the privacy policy at a permanent public URL (e.g., `https://afeedi.com/privacy`). Enter that URL in App Store Connect under App Information > Privacy Policy URL, and in Play Console under Store Listing > Privacy Policy. The last-updated date in `lib/screens/privacy_policy_screen.dart` line 28 also reads "June 1, 2026" (future date) — update to the actual publication date. | Developer + Infrastructure |

---

### 3.3 MEDIUM — Address Before or Shortly After Launch

These items are compliance gaps or UX deficiencies that may trigger reviewer questions, draw user complaints, or create regulatory exposure if left unresolved post-launch.

| ID | Gap | Platform | Guideline / Policy | Fix Required | Owner |
|----|-----|----------|--------------------|--------------|-------|
| R-M-1 | **Privacy policy text is truncated in `PrivacyPolicyScreen`.** Each section body widget uses `maxLines: 10, overflow: TextOverflow.ellipsis`, silently cutting off sections longer than 10 lines (sections 10 and 12 are affected). Apple requires the policy to be "accessible and complete." | iOS | Apple 5.1.1 (accessible, complete privacy policy) | Remove `maxLines` and `overflow` from the section body `Text` widget in `lib/screens/privacy_policy_screen.dart`. The screen is already wrapped in `SingleChildScrollView`; text length is not a layout constraint. | Developer |
| R-M-2 | **DMCA takedown mechanism is a stub.** The "Report" option in the content card menu (`lib/widgets/feed/enhanced_feed_post_card.dart` line 705) executes `onTap: () => Navigator.pop(context)` with no backend call. The Terms of Service screen contains no DMCA agent designation or takedown procedure. As a content aggregator, Afeedi should qualify for DMCA safe harbor but only with a working notice-and-takedown process. | Both | 17 U.S.C. §512 (DMCA Safe Harbor) | (1) Implement the Report flow: collect reason, content ID, and submitter user ID; POST to a backend moderation endpoint. (2) Add a DMCA/Copyright Takedown section to `lib/screens/terms_of_service_screen.dart`. (3) Register a DMCA agent at copyright.gov/dmca-directory. (4) Ensure `legal@afeedi.com` (already in ToS) is actively monitored. | Developer + Legal |
| R-M-3 | **Content `contentRating` field exists in the model but is not enforced in the feed pipeline.** `content_service.dart` feed and search methods (`getFeedContent`, `getTrendingVideos`, `getVideos`) do not filter on `contentRating` or check `user.matureContentEnabled`. Age-restricted content would be served to all users. | Both | Apple 1.2 (Age ratings — content must match declared rating); Google Play Content Rating Policy | In `content_service.dart`, add a content rating filter to all feed-producing methods: exclude items where `contentRating` indicates mature/restricted content unless `currentUser.matureContentEnabled == true` and the user has been age-verified. Add `safeSearch: SafeSearch.strict` to any YouTube Data API v3 calls once those are implemented. | Developer |
| R-M-4 | **Fabricated Facebook/Instagram seed content IDs.** `content_service.dart` uses placeholder IDs such as `1234567890123456` for Facebook and `ig_reel_001` for Instagram. Generic sequential numeric IDs like `1234567890123456` are likely to match real Facebook content owned by real users. If displayed alongside invented titles and creator names, this constitutes false attribution and could expose the company to misleading-content claims. | Both | Apple 5.5 (Deceptive content); Platform ToS (Meta — unauthorized aggregation) | Replace all fabricated Facebook and Instagram content IDs with real, verified IDs obtained via official Meta Graph API, or mark those entries `isActive: false` until real data is in place. Also validate all YouTube seed video IDs against the YouTube Data API v3 `videos.list` endpoint before launch to confirm they still exist and the creator attribution is correct. | Developer |

---

### 3.4 LOW — Best Practice Improvements

These items do not pose an immediate rejection risk but represent security or quality gaps that should be addressed before or shortly after launch.

| ID | Gap | Platform | Guideline / Policy | Fix Required | Owner |
|----|-----|----------|--------------------|--------------|-------|
| R-L-1 | **Dart obfuscation disabled in release builds.** `ios/Flutter/Generated.xcconfig` sets `DART_OBFUSCATION=false`. Without `--obfuscate --split-debug-info`, the compiled app binary contains human-readable symbol names, making reverse engineering significantly easier. | Both | Security best practice (OWASP MASVS L2) | Add `--obfuscate --split-debug-info=build/symbols/` to the release build commands: `flutter build apk --release --obfuscate --split-debug-info=build/symbols/` and `flutter build ipa --release --obfuscate --split-debug-info=build/symbols/`. Store the generated `.symbols` files for crash symbolication. | Developer (build pipeline) |
| R-L-2 | **Subscription premium flag in `SharedPreferences` is bypassable on rooted devices.** `lib/services/subscription_service.dart` reads `is_premium` from unencrypted SharedPreferences as the sole gate for premium feature access. On a rooted device or via ADB, any user can flip this boolean to `true` without paying. | Both | Revenue integrity; Apple 3.1.1 (honor store transactions) | Either (A) always verify subscription status against a live server-side receipt on app launch (cross-references R-C-4), or (B) store the premium flag in `flutter_secure_storage` and sign it with a device-bound HMAC key so tampering is detectable. Do not rely on unencrypted SharedPreferences as the sole paywall gate. | Developer |
| R-L-3 | **Password PBKDF2 credential blob stored in unencrypted `SharedPreferences`.** `lib/services/local_auth_service.dart` stores the PBKDF2 hash, salt, and email address in plaintext SharedPreferences. The hash quality is good (100k iterations) but an attacker on a rooted device can extract the hash for offline brute-force. The code itself contains a comment recommending migration to `flutter_secure_storage`. | Both | GDPR Art. 25 & 32 (security of processing); OWASP MASVS L1 | Add `flutter_secure_storage: ^9.0.0` to `pubspec.yaml`. Migrate `user_credentials_*`, `current_user_id`, `user_email`, and `session_token` from `SharedPreferences` to `FlutterSecureStorage`. This also resolves the OAuth token storage issue noted in the privacy audit (CRIT-5 of `PRIVACY_LEGAL_REPORT.md`). | Developer |
| R-L-4 | **OAuth access tokens (YouTube, Facebook, Apple) stored unencrypted in Hive.** `PlatformConnection.toJson()` serializes `accessToken` and `refreshToken` into plain JSON in a Hive box (`platform_connections`). Hive boxes are unencrypted by default. On a rooted device or via backup extraction, all connected platform tokens are exposed. | Both | GDPR Art. 25 & 32; Platform ToS (access tokens must be stored securely) | Strip `accessToken` and `refreshToken` from `PlatformConnection.toJson()` / the Hive storage payload. Store token values exclusively in `flutter_secure_storage` keyed on `oauth_token_{userId}_{platform}`. Read from secure storage when tokens are needed for API calls. | Developer |
| R-L-5 | **Sign In with Apple button uses custom styling instead of the official `SignInWithAppleButton` widget.** `lib/screens/login_screen.dart` uses a custom `OutlinedButton.icon` with `Icons.apple` rather than the `SignInWithAppleButton` widget from the `sign_in_with_apple` package. Apple's HIG requires approved Sign In with Apple button styling. | iOS | Apple Human Interface Guidelines — Sign In with Apple design requirements | Replace the custom button with `SignInWithAppleButton(onPressed: _handleAppleSignIn)` from the `sign_in_with_apple` package. The package provides compliant styling and accessibility attributes. | Developer |
| R-L-6 | **`via.placeholder.com` used as fallback thumbnail URLs in 6 places.** `lib/services/content_aggregation_service.dart` uses the third-party placeholder service as a fallback image source. In production, this service may be unavailable, rate-limited, or render developer-style placeholder graphics to real users. | Both | Apple 2.1 (App Completeness — third-party dependency for core UI) | Replace `via.placeholder.com` URLs with a bundled fallback asset (add a generic thumbnail image to `assets/`). The app already uses a `_buildThumbnailFallback` gradient widget in other tabs — extend that pattern here. | Developer |
| R-L-7 | **Analytics `signOut` and `deleteAccount` events pass the real `user_id` in `additionalData`, bypassing the anonymous ID system.** `lib/services/local_auth_service.dart` sends the internal user ID in analytics payloads at sign-out and deletion. `AnalyticsService._getUserId()` correctly routes to a random anonymous ID; these calls bypass that anonymisation. | Both | GDPR Art. 5(1)(c) (data minimization) | Remove `'user_id': _currentUser!.id` from the `additionalData` map in the `trackUserInteraction` calls inside `signOut()` and `deleteAccount()`. The anonymous session ID provided by `_getUserId()` is sufficient for event correlation. | Developer |

---

## 4. Submission Readiness Score

### Overall Score: 5 / 10 — NOT READY FOR SUBMISSION

The app has made substantial progress this session. The four original Apple-hard-rejection blockers (account deletion, sign-out, ATT, GADApplicationIdentifier) are resolved, and the YouTube ToS violation that risked Play Store account termination has been eliminated. However, six CRITICAL gaps remain that will cause rejection or account-level consequences.

| Domain | Before Session | After Session | Notes |
|--------|---------------|---------------|-------|
| YouTube ToS compliance | 0 / 10 | 10 / 10 | `youtube_explode_dart` removed; all files rewritten to embed-only |
| iOS App Store compliance | 3 / 10 | 6 / 10 | Account deletion, sign-out, ATT, GADApplicationIdentifier fixed; AdMob IDs, Firebase, TikTok mock, IAP verification, "coming soon" UI remain |
| Google Play compliance | 4 / 10 | 6 / 10 | MainActivity duplicate removed, RECEIVE_BOOT_COMPLETED justified, ad service guarded; AdMob App ID in manifest, Firebase, receipt verification, UMP consent remain |
| GDPR / Privacy compliance | 3 / 10 | 6 / 10 | Account deletion wired + full data wipe, Download Data wired, Privacy/ToS links wired, ATT added; toggle observability, UMP, secure storage remain |
| Security | 4 / 10 | 5 / 10 | No change to storage encryption; mock tokens, unencrypted credentials remain |
| Content / Platform ToS | 2 / 10 | 8 / 10 | Scraping eliminated, modestbranding removed; fabricated seed IDs, DMCA stub, content rating enforcement remain |

**Blocking items before any submission attempt:** R-C-1 (AdMob IDs), R-C-2 (Firebase config), R-C-3 (TikTok mock tokens), R-C-4 (IAP server-side verification), R-C-5 (coming-soon UI), R-C-6 (hardcoded IAP prices).

---

## 5. Pre-Submission Checklist

Complete all items in the CRITICAL group before filing any review submission. Items in the HIGH group should be resolved before initial submission or addressed as P0 fixes immediately post-launch. Items in MEDIUM/LOW should be scheduled for the first post-launch update.

### CRITICAL — Required Before Submission

- [ ] **R-C-1** — Create AdMob account; replace test App ID in `AndroidManifest.xml` and `AppDelegate.swift`; replace all 4 production ad unit ID branches in `lib/services/ad_service.dart` with real console IDs
- [ ] **R-C-2** — Either (A) create Firebase project and add `google-services.json` + `GoogleService-Info.plist`, or (B) remove `firebase_core` from `pubspec.yaml` and all `Firebase.initializeApp()` calls
- [ ] **R-C-3** — Remove TikTok connect option from UI, or implement real TikTok Login Kit OAuth; remove static `token123`/`refresh123` map from `auth_service.dart` `getPlatformConnections()`
- [ ] **R-C-4** — Implement server-side receipt verification (Apple StoreKit 2 or Google Play Developer API) before `_verifyAndGrant()` grants premium access; alternatively, integrate RevenueCat/Adapty
- [ ] **R-C-5** — Remove comment button or hide behind feature flag; remove Creator tier card from PremiumScreen; replace all PlaceholderScreen routes with real screens or remove from visible navigation
- [ ] **R-C-6** — Show loading state on PremiumScreen until `_loadProducts()` resolves; display only store-fetched `product.price`; remove all hardcoded `$4.99` / `$39.99` display values

### HIGH — Complete Before Submission (or Treat as P0 Post-Launch)

- [ ] **R-H-1** — Remove static mock token map from `auth_service.dart`; implement real token lookup from secure storage
- [ ] **R-H-2** — Wire persisted privacy toggle values into `AnalyticsService` and `AdService` so user consent choices have actual effect on data collection behavior
- [ ] **R-H-3** — Integrate Google UMP SDK (`ConsentInformation.instance.requestConsentInfoUpdate`) before `MobileAds.initialize()` for EU/EEA users
- [ ] **R-H-4** — Add age gate or date-of-birth collection to onboarding flow; block under-13 users (US) / under-16 users (EU) from registering
- [ ] **R-H-5** — Update `description` in `pubspec.yaml` to a meaningful app description
- [ ] **R-H-6** — Host privacy policy at a permanent public URL; enter URL in App Store Connect and Play Console metadata; update "last updated" date in `PrivacyPolicyScreen`

### MEDIUM — Schedule for First Post-Launch Update

- [ ] **R-M-1** — Remove `maxLines: 10` / `overflow: TextOverflow.ellipsis` from privacy policy section bodies in `PrivacyPolicyScreen`
- [ ] **R-M-2** — Implement Report content flow with backend endpoint; add DMCA section to Terms of Service; register DMCA agent
- [ ] **R-M-3** — Add content rating filter to all feed methods in `content_service.dart`; add `safeSearch` parameter to YouTube API calls
- [ ] **R-M-4** — Replace fabricated Facebook/Instagram seed content IDs with real verified IDs or mark `isActive: false`; validate all YouTube seed IDs against Data API v3

### LOW — Best Practice / Next Development Cycle

- [ ] **R-L-1** — Enable `--obfuscate --split-debug-info` in release build commands for both Android and iOS
- [ ] **R-L-2** — Move subscription premium flag from SharedPreferences to server-verified or HMAC-signed storage
- [ ] **R-L-3 + R-L-4** — Add `flutter_secure_storage`; migrate password credential blob, `user_id`, `user_email`, and all OAuth tokens out of unencrypted SharedPreferences/Hive
- [ ] **R-L-5** — Replace custom Apple sign-in button with `SignInWithAppleButton` widget from `sign_in_with_apple` package
- [ ] **R-L-6** — Replace `via.placeholder.com` fallback thumbnail URLs with bundled app assets
- [ ] **R-L-7** — Remove `user_id` from analytics `additionalData` in `signOut()` and `deleteAccount()` analytics events

### Store Listing Prerequisites (Separate from Code)

- [ ] Prepare App Store screenshots (minimum 3 per device size: 6.7", 6.5", 5.5" for iPhone; iPad if supported)
- [ ] Write App Store description and keywords (App Store Connect metadata)
- [ ] Complete Google Play Data Safety questionnaire (declare: email address, name, user ID, device/app identifiers from AdMob, YouTube watch activity, Facebook auth data)
- [ ] Set correct content rating in App Store Connect and Play Console (Google PEGI/ESRB, Apple age band)
- [ ] Prepare app icon at all required resolutions (1024×1024 for App Store; 512×512 for Play Store)
- [ ] Set `android:versionCode` and `android:versionName` to match Play Console upload
- [ ] Confirm `android/key.properties` is not in git history: run `git log --all --full-history -- android/key.properties`
- [ ] Add `key.properties` and `*.jks` to `.gitignore` if not already present

---

## 6. Source Reports

This report synthesises findings from the following audit documents in `docs/`:

| Report | Focus |
|--------|-------|
| `APP_STORE_RISK_REPORT.md` | Apple App Store Review Guidelines compliance |
| `PLAY_STORE_RISK_REPORT.md` | Google Play Developer Policy compliance |
| `PRIVACY_LEGAL_REPORT.md` | GDPR, ATT, COPPA, consent, data rights |
| `CONTENT_MODERATION_REPORT.md` | Platform ToS, copyright, attribution, DMCA |
| `SECURITY_REVIEW_REPORT.md` | Credential storage, AdMob, mock tokens, obfuscation |

---

*This report documents compliance state after the session fixes described in Section 2. It reflects static code analysis only; dynamic/runtime behavior, actual store review outcomes, and legal sufficiency have not been independently verified. Consult qualified legal counsel before using this document as the basis for regulatory compliance decisions.*

*Generated: 2026-05-30*
