# Content Moderation & Platform ToS Compliance Report

**App:** Afeedi  
**Audit Date:** 2026-05-30  
**Auditor:** Content Moderation Specialist  
**Scope:** Platform ToS compliance, copyright risk, attribution, content filtering, DMCA mechanisms

---

## Executive Summary

The Afeedi app aggregates content from YouTube, Instagram, TikTok, and Facebook. The audit found **three critical violations** that carry legal and platform-ban risk, alongside several moderate and minor issues. The most serious finding is the active use of `youtube_explode_dart` to extract YouTube stream URLs — this is a direct violation of YouTube's Developer ToS §4.F regardless of whether results are cached or exposed to users.

**Risk Level: HIGH — requires remediation before any production release.**

---

## 1. YouTube Data API ToS — §4.F Stream Extraction

### Finding: CRITICAL VIOLATION

**File:** `/home/user/afeedi/afeedi/lib/services/video_content_extraction_service.dart`

The `VideoContentExtractionService` imports `youtube_explode_dart` and calls:

```dart
final video = await _youtubeExplode.videos.get(videoId);
final streamManifest = await _youtubeExplode.videos.streamsClient.getManifest(videoId);
```

This extracts raw stream URLs (MP4 video/audio/muxed) directly from YouTube's internal infrastructure, bypassing the official IFrame Player and the YouTube Data API. This is an explicit violation of the [YouTube API Services Developer Policies §4.F](https://developers.google.com/youtube/terms/developer-policies):

> "API Clients must not use any API Services to access or display YouTube Applications in any manner other than through YouTube's official embed mechanisms."

**File:** `/home/user/afeedi/afeedi/lib/services/youtube_live_content_service.dart`

`YouTubeLiveContentService` also imports and actively uses `youtube_explode_dart` for content discovery (search) and metadata scraping:

```dart
final yt = YoutubeExplode();
final videos = await yt.search.getVideos(query);
```

This is still a ToS violation even though it only retrieves metadata (not stream URLs), because `youtube_explode_dart` scrapes YouTube HTML/internal APIs without authorization.

**Note:** `content_service.dart` lines 2855–2858 and 2875 include comments acknowledging this violation and showing the scraping path as "disabled." However, `VideoContentExtractionService` is imported by `enhanced_video_player_widget.dart` and called when `contentOnlyMode = true` (the default), meaning it **is** reachable at runtime. `YouTubeLiveContentService` is imported by `content_service.dart` and fully active.

### Required Fix

1. Remove `youtube_explode_dart: ^2.5.2` from `pubspec.yaml`.
2. Delete `video_content_extraction_service.dart` entirely.
3. Remove the `contentOnlyMode` extraction path from `enhanced_video_player_widget.dart`; the embed fallback at `_initializeWebView()` is ToS-compliant.
4. Refactor `youtube_live_content_service.dart` to use the **YouTube Data API v3** with an official API key (search, videos.list endpoints). Cache responses per the API quota requirements.
5. Delete or gate `YouTubeLiveContentService` so it only runs when a valid API key is configured.

---

## 2. YouTube IFrame Embed — Branding Compliance

### Finding: MODERATE VIOLATION

**File:** `/home/user/afeedi/afeedi/lib/widgets/streaming/youtube_player_widget.dart`  
**File:** `/home/user/afeedi/afeedi/lib/widgets/enhanced_video_player_widget.dart`  
**File:** `/home/user/afeedi/afeedi/lib/services/browser_streaming_service.dart`  
**File:** `/home/user/afeedi/afeedi/lib/services/youtube_player_service.dart`

YouTube's [Branding Guidelines](https://developers.google.com/youtube/branding_guidelines) and IFrame Player ToS require that YouTube branding remain visible in the player. Multiple files include `modestbranding=1` in embed URLs:

```dart
return 'https://www.youtube.com/embed/$videoId?autoplay=1&controls=1&modestbranding=1&rel=0';
```

The `modestbranding` parameter removes the YouTube logo from the player control bar. As of 2023, YouTube deprecated this parameter (it no longer functions as intended), but its presence signals intent to suppress branding. More importantly, the `youtube_player_iframe` package used in `youtube_player_widget.dart` renders the official YouTube IFrame — that player itself retains YouTube branding (the YouTube logo is preserved in the IFrame). So this finding applies specifically to the raw embed URLs in `enhanced_video_player_widget.dart` and service files.

### Required Fix

1. Remove `modestbranding=1` from all embed URLs — it is deprecated and attempting to suppress it violates the spirit of YouTube branding requirements.
2. Do not override or CSS-hide any YouTube player chrome, controls, or logo in WebView.
3. The `youtube_player_iframe` path (`youtube_player_widget.dart`) is compliant as-is; keep using it as the primary YouTube player.

---

## 3. Instagram Embedding

### Finding: COMPLIANT (conditional)

**File:** `/home/user/afeedi/afeedi/lib/widgets/streaming/social_media_video_player.dart`

The `SocialMediaStreamingService` uses Instagram's official oEmbed endpoint (`https://graph.facebook.com/v23.0/instagram_oembed`) to retrieve embed HTML. The `SocialMediaVideoPlayer` renders a "Tap to view on Instagram" deep-link card rather than injecting raw embed HTML into a WebView — this is the ToS-compliant approach.

**Conditional Risk:** The `_getInstagramEmbed` method fetches oEmbed data and returns `embedHtml` from Instagram's API. On the web (`kIsWeb`), the method `_buildWebEmbedPlayer()` redirects to `_buildMobileEmbedPlayer()`, which shows a tap-to-open CTA. If a future developer changes `_buildWebEmbedPlayer()` to inject `_embedResult!.embedHtml` directly into a WebView, that would re-introduce a potential violation because Instagram oEmbed HTML is only licensed for display on the page identified in the API request. The current implementation avoids this.

**Instagram oEmbed requires an approved Facebook App token.** The code at line 135 checks for the token but the `_loadStoredTokens()` method is a TODO. If the token is absent, the API returns a 401. The app currently falls back gracefully to the deep-link CTA, so user-facing behavior remains ToS-compliant at all times.

### Required Fix (low priority)

- Implement `_loadStoredTokens()` with a valid Facebook App access token to enable the oEmbed flow.
- Add a code comment explicitly warning future developers not to inject `embedHtml` into a WebView.

---

## 4. TikTok Embedding and API Terms

### Finding: COMPLIANT

**File:** `/home/user/afeedi/afeedi/lib/services/social_media_streaming_service.dart`

The app uses TikTok's official oEmbed endpoint (`https://www.tiktok.com/oembed`), which is the only TikTok-approved method for third-party embedding. No scraping or direct stream URL extraction is performed. When the oEmbed call fails, the fallback renders a branded CTA that deep-links to TikTok.

**Note on Seed Data:** Several TikTok entries in `content_service.dart` use `platformContentId` values like `'tiktok_viral_001'` (non-numeric) and `videoUrl: null`. These will never produce a valid oEmbed response. They do not introduce a ToS violation (the fallback handles it gracefully), but they will always show the fallback card rather than real content.

---

## 5. Facebook Video Embedding

### Finding: MODERATE CONCERN

**File:** `/home/user/afeedi/afeedi/lib/services/social_media_streaming_service.dart` lines 388–431

The `_getFacebookEmbed` method constructs a Facebook Video Plugin embed URL:

```dart
final embedUrl = 'https://www.facebook.com/plugins/video.php?href=${Uri.encodeComponent(url)}&width=500&show_text=false';
```

Facebook's [Video Plugin](https://developers.facebook.com/docs/plugins/embedded-video-player/) is an officially supported embed mechanism for publicly shared Facebook videos. Using this URL format is compliant **for publicly shared videos only**. The seed data in `content_service.dart` contains Facebook video IDs like `1234567890123456` (generic/fabricated), which are effectively untested.

**Risk:** Facebook's Video Plugin requires that the video is public and that the embedding domain is registered in your Facebook App settings. Failure to register the app's domain will result in "X-Frame-Options: DENY" errors in production WebViews.

### Required Fix

1. Register the app's domain (or `app://` scheme for mobile WebView) in the Facebook App Dashboard.
2. Validate Facebook video IDs in seed data before launch.

---

## 6. Copyright Risk: Video Download and Local Storage

### Finding: MODERATE RISK

**File:** `/home/user/afeedi/afeedi/lib/core/config/supabase_config.dart` lines 97–98

```dart
static const String contentDownloadsTable = 'content_downloads';
static const String userDownloadsTable = 'user_downloads';
```

**File:** `/home/user/afeedi/afeedi/lib/widgets/dashboard/settings_tab.dart` lines 167–199

The Settings UI exposes a "Download on WiFi only" toggle and a Downloads section. The existence of `content_downloads` and `user_downloads` Supabase tables strongly suggests a video download feature is planned or partially implemented.

Downloading video content from YouTube, Instagram, TikTok, or Facebook is explicitly prohibited by each platform's ToS:

- YouTube ToS §5.H: "You shall not download any Content unless a download button or link is shown by YouTube on the Service for that content."
- Instagram Platform Policy: Prohibits downloading or storing content.
- TikTok ToS §2(h): "You may not copy, download or store User Content."
- Facebook ToS: Prohibits downloading content not intended for offline use.

**No active download implementation was found in the codebase during this audit** — the tables and UI element appear to be stubs. However, the infrastructure is in place to add this feature.

### Required Fix

1. Remove the `content_downloads` and `user_downloads` Supabase tables from the schema (or never create them).
2. Remove the "Download on WiFi only" toggle from `settings_tab.dart` unless the feature is explicitly scoped to user-generated content the user has rights to download.
3. Add a code comment and architectural decision record documenting that platform-hosted video download is permanently out of scope.

---

## 7. Content Filtering and Age Restriction

### Finding: INCOMPLETE

**File:** `/home/user/afeedi/afeedi/lib/models/user_model.dart` line 380  
**File:** `/home/user/afeedi/afeedi/lib/models/content_model.dart` line 45

The data model includes `contentRating` on `Content` and `matureContentEnabled` on the user model. These fields exist but are not enforced anywhere in the content delivery pipeline.

In `content_service.dart`, none of the feed/search/trending methods filter by `contentRating` or check `matureContentEnabled`. Any content tagged with a content rating will be served to all users regardless of age or preference settings.

YouTube IFrame API embeds enforce YouTube's own age-gating (users must sign in to view age-restricted content), so the YouTube path has implicit protection. However, for live/search content discovered via `YouTubeLiveContentService`, no age-restriction check is applied before adding to the feed.

### Required Fix

1. In `content_service.dart`, all feed methods (`getFeedContent`, `getTrendingVideos`, `getVideos`, etc.) must filter out content where `contentRating` indicates adult/restricted content unless `user.matureContentEnabled == true`.
2. Integrate YouTube Data API's `safeSearch` parameter when fetching live content.
3. For the TikTok oEmbed path, add keyword filtering on returned content titles/descriptions for potentially age-inappropriate material.

---

## 8. DMCA Safe Harbor Mechanism

### Finding: ABSENT

**File:** `/home/user/afeedi/afeedi/lib/widgets/feed/enhanced_feed_post_card.dart` line 705

A "Report" option exists in the content card menu but it does nothing — `onTap: () => Navigator.pop(context)`. There is no reporting flow, no backend endpoint for takedown requests, and the Terms of Service screen contains no DMCA agent designation or takedown procedure.

To qualify for DMCA safe harbor (17 U.S.C. §512), an online service provider must:

1. Designate a registered DMCA agent with the U.S. Copyright Office.
2. Publish a notice-and-takedown procedure.
3. Promptly respond to valid takedown notices.
4. Implement a repeat-infringer policy.

Since Afeedi aggregates third-party content (even via embeds), it is prudent to implement these protections regardless of whether the app qualifies as a hosting provider.

### Required Fix

1. Implement the "Report" flow: collect a reason (copyright infringement, spam, inappropriate), content ID, and user ID; submit to a backend endpoint.
2. Add a DMCA/Copyright Takedown section to `terms_of_service_screen.dart` or create a dedicated `dmca_screen.dart`.
3. Register a DMCA agent at copyright.gov/dmca-directory.
4. Add `legal@afeedi.com` (already present in ToS) as the contact for takedown notices and ensure it is actively monitored.

---

## 9. Attribution Visibility

### Finding: PARTIALLY COMPLIANT

**File:** `/home/user/afeedi/afeedi/lib/widgets/streaming/social_media_video_player.dart`  
**File:** `/home/user/afeedi/afeedi/lib/widgets/streaming/platform_branding_widget.dart`

The `SocialMediaVideoPlayer` and `CompactSocialMediaVideoPlayer` both render a `PlatformBrandingWidget` overlay. `content_service.dart` populates `creatorName` for all seed items.

**Gaps identified:**

- `thumbnailUrl` is `null` for all Instagram, TikTok, Facebook, and several extra seed items. These items render a blank/icon placeholder with no creator credit visible.
- The `creatorId` field (used to link to a creator's channel page) is only auto-generated from `creatorName` via string normalization — there is no verified creator URL or channel link.
- No visual indicator shows the source platform URL (e.g., a "Watch on YouTube" link) on the video card for YouTube content rendered via the IFrame player.

### Required Fix

1. Ensure every content card renders at minimum: the platform icon, the `creatorName`, and a tap-through link to the original content URL on the source platform.
2. For YouTube IFrame embeds, the player itself shows the YouTube logo — this is sufficient. For non-YouTube embeds rendered as a tap-to-open card, the creator's handle and platform attribution must be visible on the card (not hidden behind the tap).
3. Populate `thumbnailUrl` for all content items via the respective platform APIs before production launch.

---

## 10. Seed Data Quality — YouTube Video IDs

### Finding: SEVERAL LIKELY-VALID, SOME UNVERIFIABLE

The following YouTube video IDs in `content_service.dart` are well-known public videos that are reliably active:

| ID | Title | Status |
|----|-------|--------|
| `dQw4w9WgXcQ` | Rick Astley - Never Gonna Give You Up | Valid (iconic) |
| `jNQXAC9IVRw` | Me at the zoo | Valid (YouTube's first video) |
| `9bZkp7q19f0` | PSY - GANGNAM STYLE | Valid |
| `JGwWNGJdvx8` | Ed Sheeran - Shape of You | Valid |
| `kJQP7kiw5Fk` | Luis Fonsi - Despacito | Valid |

The following IDs are claimed to be specific videos but cannot be independently verified without API calls. They may be fabricated or incorrect:

| ID | Title in Seed | Risk |
|----|---------------|------|
| `1ukSR1GRtMU` | Flutter Tutorial | Unverified — may be any video |
| `X8ipUgXH6jw` | React Native vs Flutter | Unverified |
| `UrfTFk6YIUA` | Top 50 Football Goals 2024 | Unverified |
| `gdZLi9oWNZg` | Best Live Concerts 2024 | Unverified |
| `CZKc5-SMxm8` | Gordon Ramsay Ultimate Burger | Unverified |
| `HluANRwPyNo` | How to Learn Anything 10x Faster | Unverified |

**Mismatched creator attribution risk:** The seed data assigns creator names like "Gordon Ramsay" and "Thomas Frank" to specific video IDs, but if those IDs point to different videos (or are now removed), the app will display the wrong creator name against the wrong content — a reputational and attribution risk.

**Duplicate IDs:** `jNQXAC9IVRw` appears twice (`yt_short_2` and `yt_extra_010`). While harmless for display, it causes `getVideoById` to always return the first match and the second entry is unreachable.

### Required Fix

1. Validate all seed YouTube video IDs against the YouTube Data API v3 `videos.list` endpoint before shipping.
2. Remove duplicate `jNQXAC9IVRw`.
3. Use the API-returned `snippet.channelTitle` as `creatorName` rather than hard-coded strings.

---

## 11. Facebook/Instagram Seed Data — Fabricated Content IDs

### Finding: HIGH RISK FOR MISATTRIBUTION

All Facebook (`fb_*`) and most Instagram (`ig_*`) seed entries use fabricated content IDs:

- Facebook IDs: `1234567890123456`, `4100000000000001` through `4100000000000017`, `fb_watch_001` through `fb_watch_010`
- Instagram IDs: `C8vQJ2nL9Kx`, `ig_reel_001` through `ig_reel_010`, `Cbeauty0001`, etc.

Generic fabricated IDs like `1234567890123456` are likely to match real Facebook videos owned by real users (Facebook auto-assigns numeric IDs sequentially). If displayed to users with invented titles and creator names, this constitutes false attribution and could expose the app to defamation or misleading content claims.

### Required Fix

1. Replace all fabricated Facebook and Instagram IDs with real, verified content IDs before launch.
2. Until real IDs are in place, disable Facebook and Instagram content in the seed data by filtering on `isActive = false` for those entries.

---

## Summary Table

| Issue | Severity | Files Affected | Status |
|-------|----------|----------------|--------|
| `youtube_explode_dart` stream extraction (ToS §4.F) | CRITICAL | `video_content_extraction_service.dart`, `youtube_live_content_service.dart`, `enhanced_video_player_widget.dart` | NOT FIXED |
| `modestbranding=1` YouTube branding suppression | MODERATE | `enhanced_video_player_widget.dart`, `browser_streaming_service.dart`, `youtube_player_service.dart` | NOT FIXED |
| Content download infrastructure (copyright) | MODERATE | `supabase_config.dart`, `settings_tab.dart` | NOT FIXED |
| DMCA mechanism absent | MODERATE | `enhanced_feed_post_card.dart`, `terms_of_service_screen.dart` | NOT FIXED |
| Content rating enforcement absent | MODERATE | `content_service.dart` | NOT FIXED |
| Fabricated Facebook/Instagram IDs (misattribution) | MODERATE | `content_service.dart` | NOT FIXED |
| Facebook Video Plugin domain registration | LOW | `social_media_streaming_service.dart` | NOT FIXED |
| Attribution gaps (null thumbnails, no source links) | LOW | `content_service.dart`, player widgets | NOT FIXED |
| Duplicate YouTube seed ID (`jNQXAC9IVRw`) | LOW | `content_service.dart` | NOT FIXED |
| Unverified YouTube video IDs | LOW | `content_service.dart` | NOT FIXED |
| Instagram oEmbed token not implemented | LOW | `social_media_streaming_service.dart` | NOT FIXED |

---

## Recommended Remediation Order

1. **Immediately:** Remove `youtube_explode_dart` from `pubspec.yaml` and delete `video_content_extraction_service.dart`. Gate `YouTubeLiveContentService` behind a `YOUTUBE_API_KEY` check so it never runs without official API credentials.
2. **Before beta:** Replace fabricated Facebook/Instagram seed IDs with real, verified content or mark those entries `isActive: false`.
3. **Before beta:** Implement the Report content flow with a backend endpoint and add a DMCA section to the Terms of Service screen.
4. **Before launch:** Integrate YouTube Data API v3 for live content discovery and enforce `contentRating` filtering in all feed methods.
5. **Before launch:** Validate all YouTube seed video IDs against the Data API v3.
6. **Post-launch:** Register DMCA agent with the U.S. Copyright Office.

---

*Report generated by static code analysis. No dynamic/runtime testing was performed. Platform API responses and actual video availability require live validation.*
