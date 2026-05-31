# Implementation Plan
## Afeedi — Prioritised Roadmap to v1.0 and Beyond

**Prepared:** 2026-05-30  
**Branch:** claude/optimistic-hopper-PLQOv  
**Methodology:** Items are ranked P0–P3. Each phase has explicit acceptance criteria so "done" is unambiguous.

---

## Phase 1 — Release Blockers (Complete Before Submission)

These items block app store submission or are security requirements. All P0 work should complete before any Phase 2 work begins.

| # | Item | Status | Owner | ETA |
|---|------|--------|-------|-----|
| P0-1 | Email login rate limiting (5 attempts → 15-min lockout) | ✅ Done | Engineering | — |
| P0-2 | Input validation on signup (email regex, password min-length) | ✅ Done | Engineering | — |
| P0-3 | Privacy Policy screen (`PrivacyPolicyScreen`) | ✅ Done | Engineering | — |
| P0-4 | Terms of Service screen (`TermsOfServiceScreen`) | ✅ Done | Engineering | — |
| P0-5 | 8-step onboarding with language selection as first step | ✅ Done | Engineering | — |
| P0-6 | Google Play data safety form (manual submission task) | ❌ Pending | Product/Legal | 1 day |

**Acceptance Criteria — Phase 1 complete when:**
- `signIn()` in `LocalAuthService` rejects after 5 failed attempts and stores lockout timestamp in SharedPreferences.
- Signup form rejects any email that does not match `^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`.
- `PrivacyPolicyScreen` and `TermsOfServiceScreen` are reachable from the signup flow and the Settings screen.
- `EnhancedOnboardingScreen` renders all 8 steps; step 1 is language selection; progress bar advances correctly.
- Google Play Console data safety questionnaire is submitted and approved.

---

## Phase 2 — Core Quality (Week 1 After Phase 1)

These items directly affect recommendation quality, feed freshness, and calendar utility. They are the first things power users notice.

### P1-1: Watch-Time Signal
**What:** Record seconds watched per video, not merely a binary "started" flag.  
**Where:** `FeedPostCard` and `PlayerScreen` — capture `_watchStartTime` on play, compute elapsed seconds on pause/exit, write to `UserInteractionService.recordWatchTime(contentId, seconds)`.  
**Why:** Watch time is TikTok/YouTube's primary ranking signal. The current model only tracks interaction events (like, save, share), which are far sparser. Even coarse bucketing (watched <25%, 25–50%, 50–75%, 100%) dramatically improves next-session recommendations.

### P1-2: Cold-Start Content Diversity
**What:** For users with fewer than 30 completed sessions, inject one item from each of the top 5 genres per feed page, rather than repeating seed-data results.  
**Where:** `ContentService.getRecommendedContent()` — check `OnboardingService.sessionCount < 30`; if true, assemble a diverse basket using genre weights rather than pure ranking score.  
**Why:** New users who see only one content type in the first session have 40% higher churn. Diversity in the first 5 sessions dramatically increases D7 retention.

### P1-3: Feed Prefetching
**What:** When the user scrolls to 80% of the current content page, silently fetch the next 5 items in the background.  
**Where:** `HomeTab._scrollController` listener — when `offset / maxScrollExtent >= 0.8` and `!_isPrefetching`, call `ContentService.prefetchNextPage()`.  
**Why:** The current pattern only fetches on reaching the end of the list, causing a visible loading gap. Prefetching eliminates this and is a standard practice in Netflix and YouTube mobile feeds.

### P1-4: Calendar Google Calendar OAuth Full Integration
**What:** Complete the OAuth flow so that real Google Calendar events appear in `CalendarTab`; the current implementation is a mock (`_gcalEvents` list is populated from a stub, not the real API).  
**Where:** `GoogleCalendarService` — replace mock token exchange with real `googleapis` package calls; handle token refresh, revocation, and write-back (create/delete events from within the app).  
**Why:** `CalendarTab` lists Google Calendar connectivity as a feature; shipping with a mock integration is misleading and breaks a documented capability.

### P1-5: Profile "Top Genres" Stat
**What:** Compute and display the user's top 3 genres on the Profile screen, derived from implicit genre weights in `EnhancedRecommendationService`.  
**Where:** `ProfileScreen` stats section — read `EnhancedRecommendationService.instance.genreWeights`, sort descending, render the top 3 as labelled chips or a ranked list.  
**Why:** A personalised "You love Tech, Music, Gaming" stat drives engagement with the profile screen and reinforces the app's personalisation value proposition.

**Acceptance Criteria — Phase 2 complete when:**
- `UserInteractionService` exposes `recordWatchTime(String contentId, int seconds)` and persists data to SharedPreferences under the `watch_time_*` key prefix.
- `ContentService.getRecommendedContent()` returns a genre-diverse basket for users with `sessionCount < 30`.
- `HomeTab` scroll listener triggers a background fetch at 80% scroll depth and the feed renders the new items without a loading gap.
- `CalendarTab` displays at least one real event from the authenticated user's Google Calendar when signed in with Google OAuth.
- `ProfileScreen` stats section shows a "Top Genres" row derived from live genre weights.

---

## Phase 3 — Premium Experience (Week 2)

These items match or exceed competitor UX patterns and increase session depth and share rates.

### P2-1: Double-Tap to Like
Implement `GestureDetector.onDoubleTap` on `FeedPostCard` and the Shorts player overlay. Animate a heart icon at the tap position (scale 0 → 1.5 → 0, 600 ms). Mirror YouTube Shorts and TikTok behaviour.

### P2-2: Swipe Down to Dismiss Player
Add a `DraggableScrollableSheet` or `GestureDetector` vertical drag handler to `PlayerScreen`. When the user drags down more than 120 px at velocity > 300 px/s, minimise the player to a mini-player bar at the bottom of the screen (picture-in-picture stub).

### P2-3: Share Sheet Integration
Wire `Share.shareUri(Uri.parse(content.sourceUrl))` from the `share_plus` package to the share icon on `FeedPostCard`, `PlayerScreen`, and `ShortsTab`. Include a pre-filled message: "Watch '[title]' on Afeedi".

### P2-4: Push Notification Service Integration
Replace the current local-only `NotificationService` with a real push notification channel (Firebase Cloud Messaging recommended). Retain local notifications as a fallback for offline scenarios. Register a device token on login and deregister on logout.

### P2-5: Admin Analytics Dashboard
Implement role-based access control on `/admin/*` routes. Add `_requireAdmin()` guard in `AppRoutes` that checks `UserService.instance.isAdmin`; redirect non-admin users to the home feed. Build a basic analytics dashboard showing DAU, content engagement rates, and error counts sourced from the local `AnalyticsService` store.

**Acceptance Criteria — Phase 3 complete when:**
- Double-tapping any feed card or Short triggers an animated heart and increments the like count.
- Dragging `PlayerScreen` downward by 120+ px at speed collapses to a persistent mini-player.
- The share sheet opens with a populated message on all content surfaces.
- A real FCM push notification is received on a test device after the backend sends a message.
- `/admin/analytics` route is inaccessible to non-admin accounts (returns to feed); accessible to admin accounts showing real data.

---

## Phase 4 — Growth Features (Month 1)

These items are competitive differentiators that drive virality, session depth, and long-term retention.

### P3-1: Creator Profiles
Tapping a creator's name or avatar opens a `CreatorProfileScreen` showing their bio, subscriber count (from metadata), and all their content in the Afeedi library. Include a Follow/Unfollow button that writes to `UserInteractionService`.

### P3-2: Content Saving to Playlists
Allow users to save content to named playlists beyond the single "Saved" collection. The `BookmarksScreen` renders playlists as folders. Playlists are persisted under the `playlist_*` key prefix in SharedPreferences.

### P3-3: "Because You Watched X" Recommendation Rows
In the Home feed, after the main list, add a horizontal section row labelled "Because you watched [last-watched title]". Source recommendations from `EnhancedRecommendationService` filtered to the same genre and creator as the last-watched item.

### P3-4: Social Sharing with Deep Links
Generate deep links of the form `afeedi://content/{contentId}` using `flutter_branch_io` or Firebase Dynamic Links. When a recipient opens the link, route directly to `PlayerScreen` for that content. Include Open Graph metadata for rich preview cards in messaging apps.

### P3-5: A/B Testing Framework
Integrate a lightweight flag service (e.g. Firebase Remote Config) to toggle features per user cohort. Initial flags: `enable_double_tap_like`, `feed_prefetch_threshold` (0.7–0.9), `cold_start_diversity_session_limit` (20–40). Log flag assignments to `AnalyticsService` for cohort analysis.

**Acceptance Criteria — Phase 4 complete when:**
- Tapping any creator name navigates to a `CreatorProfileScreen` with real content.
- Users can create, rename, and delete named playlists; content saves to the selected playlist.
- Home feed renders at least one "Because you watched X" row when watch history is non-empty.
- Shared deep links open the correct `PlayerScreen` on a fresh app install.
- Firebase Remote Config controls at least two live feature flags with no code change required to toggle them.

---

## Summary Timeline

| Phase | Target | Blockers Removed |
|-------|--------|-----------------|
| Phase 1 | Pre-submission | App store blockers, security H-1/H-2 |
| Phase 2 | Week 1 post-launch | Algorithm quality, calendar parity |
| Phase 3 | Week 2 post-launch | UX parity with TikTok/YouTube |
| Phase 4 | Month 1 post-launch | Virality and growth loops |

---

*Plan derived from SECURITY_REPORT.md, GAP_ANALYSIS.md, RELEASE_READINESS.md, and direct inspection of the Afeedi Flutter source tree.*
