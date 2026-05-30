# Backend Report — Afeedi Flutter App

**Audit Date:** 2026-05-30  

---

## Architecture Overview

The app currently runs in **local-only mode** — all content is served from an in-memory seed dataset in `ContentService`. No real backend server, database, or external API is called for video content. Authentication flows exist as local stubs preparing for a future backend phase.

---

## Authentication

| Area | Status | Notes |
|---|---|---|
| Auth mechanism | Local + OAuth stubs | `LocalAuthService` for email/pass; `OAuthService` for Google/Apple/Facebook |
| Token generation | ❌ Predictable | User ID = `DateTime.now().millisecondsSinceEpoch.toString()` |
| Token storage | ⚠️ Unencrypted | OAuth tokens in plain `SharedPreferences`; `flutter_secure_storage` migration tracked |
| PKCE / state param | ❌ Not visible | OAuth state parameter not validated |
| Session persistence | ✅ | `user_id`/`user_email` in SharedPreferences; loaded on app start |
| Sign out | ✅ | Clears all pref keys correctly |

## Authorization

| Area | Status | Notes |
|---|---|---|
| Route guards | ⚠️ Partial | Dashboard/player require no explicit auth gate; admin routes exist but unreachable from UI |
| Content access control | N/A | All content is public seed data; no per-user ACL |

## APIs

| Area | Status | Notes |
|---|---|---|
| Real HTTP calls | ✅ Connectivity check | DNS probe to 8.8.8.8 in `ConnectivityService` |
| Content API | ❌ In-memory seed | `ContentService.getFeedContent()` returns static list, no HTTP |
| Search indexing | ❌ In-memory | `searchVideos()` does string matching on seed data |
| Rate limiting | N/A | No external API calls to rate-limit |
| Retry logic | ✅ Push only | Git push retried with backoff; no HTTP retry needed (no HTTP) |
| Error handling | ✅ Wrapped | All async service calls wrapped in try/catch with graceful fallback |

## Database Schema

| Table / Store | Type | Fields |
|---|---|---|
| User auth | SharedPreferences | `user_id`, `user_email`, `user_name`, `oauth_access_token_*` |
| Content interactions | SharedPreferences | `liked_<id>` (bool), `saved_<id>` (bool), `follow_<creatorId>` |
| Watch progress | SharedPreferences | `watch_progress_<id>` (double 0.0–1.0), `watched_ids` (JSON list) |
| Stats | SharedPreferences | `stat_videos_watched` (int), `stat_watch_minutes` (int) |
| Notifications | SharedPreferences | `has_unread_notifications` (bool) |
| Onboarding | SharedPreferences | `onboarding_completed`, `onboarding_selected_genres`, `app_locale` |
| Analytics | Local JSON file | `analytics_events.json` in app documents dir (unencrypted) |

## Caching

| Area | Status | Notes |
|---|---|---|
| Image caching | ✅ | `cached_network_image: ^3.3.1` — disk + memory cache for all thumbnails/avatars |
| Embed cache | ✅ | `_embedCache` Map in `SocialMediaStreamingService` (in-memory, per session) |
| IFrame cache | ✅ | `_iframeCache` Map in `UniversalPlatformPlayerService` |
| Interaction cache | ✅ | Like/save/follow state in `UserInteractionService` memory + SharedPreferences |
| Feed content cache | ❌ | No persistent feed cache; lost on app restart |

## Logging & Monitoring

| Area | Status | Notes |
|---|---|---|
| Error logging | ✅ | `debugPrint` throughout service layer; `ErrorReportingService` exists |
| Analytics events | ✅ | `AnalyticsService` queues events to local JSON file |
| Crash reporting | ❌ | No Sentry/Crashlytics integration |
| Performance monitoring | ❌ | No Firebase Performance or custom timing |
| Health checks | ❌ | No uptime monitoring; no backend to monitor |

## Security

| Finding | Severity | Status |
|---|---|---|
| OAuth tokens in plain SharedPreferences | Critical | Open — `flutter_secure_storage` migration planned |
| User email removed from analytics payload | High | ✅ Fixed |
| Raw search query replaced with query_length | High | ✅ Fixed |
| Predictable user ID (millisecond timestamp) | Medium | Open — requires backend UUID |
| Analytics events file unencrypted on-device | Medium | Open — acceptable for local-only phase |
| Admin routes with no auth guard | Low | Open — routes unreachable from any UI |

## Rate Limiting

Not applicable in the current phase — no external API calls are made by the app. Rate limiting will be required when a real backend is introduced.

---

## Backend Readiness Score: 3 / 10 (local-only phase)

The app is architecturally prepared for a backend: service layer is cleanly separated, all data fetching goes through service singletons, auth flows are stubbed with correct interfaces. The primary work for a production backend is:
1. Replace `ContentService.getFeedContent()` with real API calls
2. Migrate token storage to `flutter_secure_storage`
3. Add server-side user IDs (UUID v4)
4. Wire `ErrorReportingService` to Sentry or Firebase Crashlytics
5. Add `FirebaseMessaging` for push (core is already imported)
