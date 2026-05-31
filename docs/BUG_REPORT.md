# Bug Report
## Afeedi — v1.0 Release Triage

**Prepared:** 2026-05-30  
**Branch:** claude/optimistic-hopper-PLQOv  
**Scope:** Static analysis of Flutter source; no dynamic/instrumented testing conducted  
**Method:** Full source inspection of all screens, widgets, and services

---

## Executive Summary

No critical (ship-blocking) bugs remain in the current codebase following Phase 22–24 fixes. Three **HIGH** severity issues require resolution before or shortly after launch. Five **MEDIUM** issues should be addressed in the first patch release. Three **LOW** issues are cosmetic or edge-case and can be deferred to v1.2+.

---

## CRITICAL — Must Fix Before Ship

**None.** All critical bugs identified in Phases 22–24 have been resolved. The Phase 24 audit confirmed:
- PBKDF2 single-block derivation flaw ✅ Fixed
- Shorts tap-to-play conflict ✅ Fixed
- Calendar mock data causing crashes ✅ Fixed
- Avatar path traversal ✅ Fixed
- Search platform injection ✅ Fixed
- Onboarding minimum genre selection enforcement ✅ Fixed

---

## HIGH — Fix Before or Immediately After Launch

### BUG-H-1: `_applyTimeFilter` passes null `publishedAt` content as "Today"
- **File:** `lib/widgets/dashboard/discover_tab.dart` (or equivalent location of `_applyTimeFilter`)
- **Symptom:** When the user selects the "Today" time filter in the Discover tab, all seed content items with a `null` value for `publishedAt` pass the filter and appear in results. This means stale demo content is shown as "Today", which is misleading.
- **Root Cause:** The filter predicate `p.publishedAt == null || p.publishedAt!.isAfter(cutoff)` treats `null` as a wildcard pass-through. The same pattern appears in `HomeTab._filteredPosts` at line 71 where `p.publishedAt == null` causes null-dated items to always show.
- **Fix:**
  ```dart
  // Change the null guard from a pass to a fail for time-filtered views:
  posts = posts.where((p) =>
    p.publishedAt != null && p.publishedAt!.isAfter(cutoff)
  ).toList();
  ```
- **Impact:** Users see incorrect "fresh today" content that may be months old. Trust and retention risk.

### BUG-H-2: Google Calendar events never load — OAuth is mock
- **File:** `lib/widgets/dashboard/calendar_tab.dart`, `lib/services/google_calendar_service.dart`
- **Symptom:** `CalendarTab` presents a "Connect Google Calendar" button and a `_gcalEvents` list, but the underlying `GoogleCalendarService` uses a stubbed token exchange. Real user calendar events are never fetched; `_gcalEvents` remains empty after OAuth appears to succeed.
- **Root Cause:** `GoogleCalendarService` does not make real API calls to `https://www.googleapis.com/calendar/v3/`. The OAuth redirect returns a mock token that is stored in SharedPreferences but never sent to the Calendar API.
- **Fix:** Integrate the `googleapis` Dart package, implement real token exchange, and handle `401 Unauthorized` with a refresh flow. This is tracked as P1-4 in IMPLEMENTATION_PLAN.md.
- **Impact:** Documented feature does not work. Shipping with this as-is constitutes misrepresentation of functionality.

### BUG-H-3: `_continueWatching` row is never rendered in Home feed
- **File:** `lib/widgets/dashboard/home_tab.dart` (line 38)
- **Symptom:** `HomeTab` state declares `List<({Content content, double progress})> _continueWatching` and populates it from SharedPreferences `watch_progress_*` keys on init, but no widget in the `build()` tree renders this list. The "Continue Watching" horizontal row is absent from the feed even when the user has in-progress videos.
- **Root Cause:** The data model is complete but the UI widget was not wired. The `build()` method builds the feed without inserting a `SliverToBoxAdapter` or `ListView` row for `_continueWatching`.
- **Fix:** In `HomeTab.build()`, after the category chip row and before the main `SliverList`, insert:
  ```dart
  if (_continueWatching.isNotEmpty)
    SliverToBoxAdapter(child: _buildContinueWatchingRow()),
  ```
- **Impact:** On first install the row is correctly absent (no history); once the user has watched content, the row should appear. This is a gap that reduces engagement and session re-entry.

---

## MEDIUM — Fix in First Patch Release (v1.0.1)

### BUG-M-1: Notification titles hardcoded in English
- **File:** `lib/screens/notifications_screen.dart`
- **Symptom:** Notification content strings such as "New video from Flutter", "Advanced Dart Programming Patterns", and similar are hardcoded English strings in the notification list. These do not change when the user switches locale to Arabic, Japanese, or any other supported language.
- **Root Cause:** Notification seed data is generated with static Dart string literals instead of `AppLocalizations` keys.
- **Fix:** Register notification content strings as localisation keys, or at minimum ensure the `NotificationService` can receive pre-localised strings from the calling context. See LOCALIZATION_REPORT.md recommendation 3.
- **Impact:** Breaks the localisation contract for 11 of 12 supported locales.

### BUG-M-2: `stat_videos_watched` not incremented from Shorts tab
- **File:** `lib/screens/profile_screen.dart`, `lib/widgets/dashboard/shorts_tab.dart`
- **Symptom:** The `videosWatched` counter on the Profile screen (key: `stat_videos_watched` in SharedPreferences) only increments when content is opened via `PlayerScreen`. Watching a Short via `ShortsTab` never triggers the increment, so a user who exclusively uses the Shorts tab sees `0 videos watched` on their profile regardless of actual usage.
- **Root Cause:** The increment logic lives in `PlayerScreen._recordView()` and is not called from `ShortsTab._InlineYouTubeShort`.
- **Fix:** Call the same `prefs.setInt('stat_videos_watched', count + 1)` increment from `ShortsTab` when a Short is played for more than 3 seconds (to avoid counting accidental plays).
- **Impact:** Profile stats are incorrect. Achievements tied to video-watch counts will never unlock for Shorts-only users.

### BUG-M-3: Multiple Shorts may autoplay simultaneously
- **File:** `lib/widgets/dashboard/shorts_tab.dart`
- **Symptom:** When the user scrolls quickly through the Shorts feed, multiple `_InlineYouTubeShort` widgets may be in the viewport simultaneously during the scroll animation. Each attempts to autoplay, causing overlapping audio and WebView resource contention.
- **Root Cause:** The `PageView.builder` approach means only one page should be visible, but during a fast page-change animation both the current and next page can briefly overlap. The WebView in each Short does not check whether it is the active page before autoplaying.
- **Fix:** Pass the current page index from `PageController` to each Short widget and call `_controller.pause()` on all pages except the active one in the `PageController` listener.
- **Impact:** Audible double-playback is a significant UX regression that will generate 1-star reviews.

### BUG-M-4: Discover tab search queries trending content only, not full library
- **File:** `lib/screens/search_screen.dart` (line 22: `_trendingContent` vs `_allContent`)
- **Symptom:** The search bar in the Discover tab filters against `_trendingContent` (the top-ranked subset) rather than `_allContent` (the full content library). Searching for a specific creator or video title that is not in the trending subset returns zero results even when the content exists.
- **Root Cause:** `SearchScreen` loads both `_allContent` and `_trendingContent` but the search predicate filters `_trendingContent`. The `_allContent` field is populated but unused in the search path.
- **Fix:** Change the search predicate source from `_trendingContent` to `_allContent`. Reserve `_trendingContent` for the "Trending" section display only.
- **Impact:** Search appears broken for any non-trending content. Users searching by creator name will report search as non-functional.

### BUG-M-5: History screen shows progress for videos with <5% completion
- **File:** `lib/screens/history_screen.dart`
- **Symptom:** The watch history screen shows a progress bar and "started" indicator for any video where a `watch_progress_*` key exists in SharedPreferences, even if the recorded progress is 1–4%. A video the user accidentally opened for 2 seconds appears as an in-progress item.
- **Root Cause:** No minimum progress threshold is applied before rendering the progress indicator.
- **Fix:** Apply a 5% minimum threshold before rendering the progress bar:
  ```dart
  if (progress >= 0.05) _buildProgressBar(progress),
  ```
- **Impact:** History screen is cluttered with accidental opens; users report watch history as inaccurate.

---

## LOW — Deferred to v1.2

### BUG-L-1: `_loadRelatedContent()` in PlayerScreen does not exclude current video
- **File:** `lib/screens/player_screen.dart`
- **Symptom:** The "Related Content" section below the player can display the video currently being watched as the first related result, since `_loadRelatedContent()` fetches by genre/tag match without excluding `content.id`.
- **Fix:** Add `.where((c) => c.id != widget.content.id)` to the related content query.

### BUG-L-2: Search TextField has no maxLength constraint
- **File:** `lib/screens/search_screen.dart`
- **Symptom:** The search input has no `maxLength` property. A user or automated test can paste an arbitrarily long string, which is passed unsanitised to the content filter predicate.
- **Fix:** Add `maxLength: 200` and `inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'[\x00-\x1F]'))]` to the search `TextField`. Noted in SECURITY_REPORT.md as M-1.

### BUG-L-3: `_trendingTopics` row in HomeTab not rendered as clickable chips
- **File:** `lib/widgets/dashboard/home_tab.dart` (line 40)
- **Symptom:** The `_trendingTopics` list (`['#Trending', '#ForYou', '#New']`) is declared in state but no widget renders it. The trending topics horizontal scroll row is absent from the feed.
- **Fix:** Insert a `SliverToBoxAdapter` containing a horizontal `ListView` of filter chips above the main feed list.

---

## Fixed in Recent Phases

| Bug | Phase Fixed | Status |
|-----|------------|--------|
| PBKDF2 single-block password derivation | Phase 22 | ✅ |
| Shorts tap-to-play WebView conflict | Phase 23 | ✅ |
| Calendar mock data causing null-reference crash | Phase 23 | ✅ |
| Avatar image path traversal | Phase 23 | ✅ |
| Search input platform injection | Phase 24 | ✅ |
| Onboarding skipping genre selection minimum | Phase 24 | ✅ |
| Email login missing rate limit | Phase 24 | ✅ |
| Auth error messages leaking stack traces | Phase 24 | ✅ |
| Content load failure showing no retry button | Phase 24 | ✅ |

---

*Bug triage based on static code analysis of the Afeedi Flutter source tree. Severity ratings follow a standard consumer app risk model: CRITICAL = data loss or security breach, HIGH = documented feature non-functional or significant user trust impact, MEDIUM = incorrect behaviour with workaround, LOW = cosmetic or edge case.*
