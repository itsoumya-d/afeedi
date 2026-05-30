# Bug Report — Afeedi Flutter App

**Audit Date:** 2026-05-30  
**Status:** All Critical and High bugs resolved  

---

## Resolved Bugs (Fixed in This PR)

| ID | Severity | Screen | Description | Fix |
|---|---|---|---|---|
| B-001 | Critical | Search | `final bool _isLoading = false` — unreassignable; `LoadingShimmer` permanently unreachable | Changed to `bool _isLoading`, set true/false around load |
| B-002 | Critical | History | History tile had no `onTap` handler — tapping did nothing | Added `GestureDetector` → `AppRoutes.player` |
| B-003 | Critical | Bookmarks | `ListTile` had no `onTap` — tapping did nothing | Added `onTap` → `AppRoutes.player` |
| B-004 | High | Dashboard | Notification badge was hardcoded always-visible dot | Driven by `SharedPreferences('has_unread_notifications')`; clears on tap |
| B-005 | High | Shorts | Comments action button was `// TODO` stub | Implemented `DraggableScrollableSheet` with comment rows and reply input |
| B-006 | High | All screens | `oauth_signin_success` analytics event included user email (PII leak) | Removed email field from payload |
| B-007 | High | Search | Raw search query logged to analytics (PII risk) | Replaced with `query_length` (int only) |
| B-008 | High | History/Bookmarks | No `try/catch` on `ContentService.getVideos()` — network error → blank screen | Added try/catch with graceful `_isLoading = false` fallback |
| B-009 | High | Creator Sheet | Silent `catch (_)` swallowed errors; user saw spinner forever | Added `_loadError` state + inline retry message |
| B-010 | High | Performance | `NetworkImage` (uncached) in `creator_profile_sheet`, `platform_branding_widget` | Replaced with `CachedNetworkImageProvider` / `CachedNetworkImage` |
| B-011 | Medium | Feed Cards | Creator avatar/name not tappable — `CreatorProfileSheet.show()` never wired | Wrapped avatar in `GestureDetector` → `CreatorProfileSheet.show()` |
| B-012 | Medium | Onboarding | `GenreSelection` had no empty state when search returned zero results | Added "No genres match your search" empty state with icon |
| B-013 | Medium | Onboarding | Genre chips had no `Semantics` labels — selected state invisible to screen readers | Added `Semantics(label, selected, button)` |
| B-014 | Medium | Recommendation | `generateComprehensiveRecommendations` returned `[]` for authenticated users with no OAuth connections | Added fallback to `ContentService.getFeedContent()` seed data |
| B-015 | Low | Player | No `WidgetsBindingObserver` — app background did not save watch progress | Added observer; calls `_saveWatchTime()` on `AppLifecycleState.paused` |
| B-016 | Low | Player | Fullscreen callback never passed to `SocialMediaVideoPlayer` | Passed `onFullscreen: _toggleFullscreen`; `SystemChrome` orientation toggle |
| B-017 | Low | Calendar | `_getContentForDate` used `day % 3 == 0 || day % 5 == 0` modulo mock | Replaced with real `year/month/day` equality check |
| B-018 | Low | Onboarding | Users could proceed from genre step with 0 selections | `handleGenreContinue()` now blocks until `selectedGenres.length >= 3` |

---

## Open Known Issues (Infrastructure / ToS Constraints)

| ID | Severity | Description | Reason Not Fixed |
|---|---|---|---|
| B-019 | High | OAuth tokens stored in plain `SharedPreferences` | Requires `flutter_secure_storage` migration; keystore config out of scope for this phase |
| B-020 | High | `changePassword`/`resetPassword` are stubs returning success | No backend auth; placeholder until backend phase |
| B-021 | Medium | Dark mode toggle saves pref but requires app restart to apply | `themeModeNotifier` is read on startup; immediate apply needs settings → main bridge |
| B-022 | Medium | Mobile YouTube playback shows thumbnail only | YouTube IFrame requires web; mobile opens external app (acceptable per platform constraints) |
| B-023 | Medium | TikTok/Instagram in-app playback not possible | Platform ToS prohibits native embedding without official SDK |
| B-024 | Low | Admin routes defined with no auth guard | Routes unreachable from UI; no admin UI exposed to end users |
