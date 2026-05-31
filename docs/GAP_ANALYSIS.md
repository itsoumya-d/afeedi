# Gap Analysis Report
## Afeedi vs. Best-in-Class Consumer Apps

**Prepared:** 2026-05-30  
**Branch:** claude/optimistic-hopper-PLQOv  
**Reference apps:** TikTok, YouTube, Netflix, Instagram, Spotify, Duolingo, Notion

---

## Methodology

Each gap is rated by **impact** (H/M/L) and **effort** (H/M/L). The rating combines business value (user retention, activation, engagement) with engineering complexity.

---

## 1. Onboarding Gaps

| # | Feature | Status | Impact | Effort | Notes |
|---|---------|--------|--------|--------|-------|
| O-1 | Language selection | ✅ Present | — | — | In chatbot onboarding; should move to page 1 of enhanced flow |
| O-2 | Genre / interest selection | ✅ Present | — | — | `InterestSelectionGrid` widget exists |
| O-3 | Platform selection | ✅ Present | — | — | `PlatformSelectionWidget` exists |
| O-4 | Goal-setting step (daily time commitment) | ❌ Missing | H | L | Duolingo pattern: 5/10/15/20 min/day. Drives habit loop and pacing personalisation |
| O-5 | Familiarity level selection | ❌ Missing | M | L | Beginner / Regular / Power user. Determines content complexity shown initially |
| O-6 | Try-before-register / guest mode | ❌ Missing | H | M | Duolingo's top activation lever (+40% D1). User sees feed value before account friction |
| O-7 | Activation in <2 minutes | ⚠️ Partial | H | M | Current 8-step flow exceeds 2-min window; collapsing steps O-4/O-5 into a single screen helps |

**Priority Actions:**
1. Add a "Skip for now" button at step 3+ that routes directly to a guest feed.
2. Insert a single goal-setting screen (daily minutes + familiarity) after language selection.
3. Move language selection to the very first screen of the enhanced flow.

---

## 2. Feed / Home Screen Gaps

| # | Feature | Status | Impact | Effort | Notes |
|---|---------|--------|--------|--------|-------|
| F-1 | Platform filter chips | ✅ Present | — | — | YouTube / TikTok / Instagram chips in HomeTab |
| F-2 | For You / Following tabs | ✅ Present | — | — | `_showFollowing` toggle exists |
| F-3 | "Continue Watching" horizontal row | ⚠️ Partial | H | L | `_continueWatching` field populated but row not rendered at feed top |
| F-4 | Netflix-style section rows ("Trending Now", "New Releases") | ❌ Missing | H | M | Single flat list currently; horizontal carousels dramatically increase session depth |
| F-5 | Thumbnail gradient overlay for text readability | ❌ Missing | M | L | Creator name / view count text often unreadable over bright thumbnails |
| F-6 | View count / upload time metadata on cards | ❌ Missing | M | L | YouTube-standard metadata; aids trust and freshness perception |
| F-7 | Trending topics row (horizontal hashtag scroll) | ⚠️ Partial | M | L | `_trendingTopics` list exists but not rendered as a clickable row |
| F-8 | Pull-to-refresh with haptic feedback | ⚠️ Unknown | L | L | Standard pattern; needs verification |
| F-9 | "New posts available" banner (Instagram pattern) | ⚠️ Partial | M | L | `_newPostCount` field exists but banner not implemented |

**Priority Actions:**
1. Render `_continueWatching` as a horizontal `ListView` row at position 2 in the feed (below category chips, above main list).
2. Wrap the main feed in a `CustomScrollView` with `SliverList` rows for "Trending Now" and "Based on Your Interests".
3. Add gradient overlay (`LinearGradient` from transparent to black) at bottom of thumbnail images.

---

## 3. Personalisation / Algorithm Gaps

| # | Feature | Status | Impact | Effort | Notes |
|---|---------|--------|--------|--------|-------|
| P-1 | Genre weights via implicit tracking | ✅ Present | — | — | `EnhancedRecommendationService` tracks genre preferences |
| P-2 | Interaction event tracking (like, save, share, follow) | ✅ Present | — | — | `UserInteractionService` phase 4 complete |
| P-3 | Watch time signal | ❌ Missing | H | M | Only interaction events tracked, not actual seconds watched. Watch time is TikTok/YouTube's #1 signal |
| P-4 | Completion rate tracking | ❌ Missing | H | M | Needed for TikTok-style cold-start promotion logic |
| P-5 | Rewatch detection | ❌ Missing | M | M | Replay = strong positive signal. Flag videos watched 2+ times |
| P-6 | Cold-start content diversity | ❌ Missing | H | M | New users receive same seed content. Needs genre-diverse basket for first 30 sessions |
| P-7 | Anti-gaming / engagement-bait detection | ❌ Missing | M | H | Instagram pattern; deprioritise content with "comment below" / "tag a friend" patterns |
| P-8 | Weekly curated "Your Picks" playlist | ❌ Missing | M | M | Spotify Discover Weekly pattern; Monday refresh cadence drives weekly habit loop |

**Priority Actions:**
1. Add `_watchStartTime` and `_watchEndTime` timestamps to `FeedPostCard` via video player callbacks.
2. Record completion percentage to `UserInteractionService` on video stop/exit.
3. Implement cold-start diversity basket: for users with <30 sessions, inject 1 item from each top-5 genre per page.

---

## 4. Performance Gaps

| # | Feature | Status | Impact | Effort | Notes |
|---|---------|--------|--------|--------|-------|
| PF-1 | CachedNetworkImage for thumbnails | ✅ Present | — | — | Avoids redundant network fetches |
| PF-2 | AutomaticKeepAliveClientMixin on HomeTab | ✅ Present | — | — | Preserves scroll position on tab switch |
| PF-3 | Shimmer loading states | ✅ Present | — | — | `LoadingShimmer` widget used |
| PF-4 | Lazy ListView.builder | ✅ Present | — | — | Only visible items rendered |
| PF-5 | Feed prefetching (next 5 items in background) | ❌ Missing | M | M | Load next page when user is 80% through current page |
| PF-6 | Progressive image loading (low-res → hi-res) | ❌ Missing | L | M | `CachedNetworkImage` `placeholder` can serve `mqdefault` before `maxresdefault` |
| PF-7 | `const` constructors on static feed widgets | ⚠️ Partial | M | L | Filter chips and header widgets likely rebuild on every setState |
| PF-8 | Video preloading in Shorts tab | ❌ Missing | M | H | Pre-buffer next Short while current plays |

---

## 5. Security Gaps

| # | Feature | Status | Impact | Effort | Notes |
|---|---------|--------|--------|--------|-------|
| S-1 | PBKDF2-HMAC-SHA256 (100k iterations) | ✅ Present | — | — | RFC 2898 compliant; strong baseline |
| S-2 | 5-attempt PIN lockout | ✅ Present | — | — | `_maxFailedAttempts = 5` in `LocalAuthService` |
| S-3 | Avatar path traversal guard | ✅ Present | — | — | Confirmed in audit |
| S-4 | Email/password login rate limiting | ❌ Missing | H | L | No lockout on email login. Add 5-attempt → 15-minute lockout |
| S-5 | Client-side email regex validation | ❌ Missing | M | L | Email field accepts any string; add `RegExp` before submit |
| S-6 | Search query length limit / sanitisation | ❌ Missing | M | L | No `maxLength` on search TextField |
| S-7 | External URL validation before `launchUrl` | ❌ Missing | M | L | Should validate scheme (`https://`) before opening |
| S-8 | Encrypted SharedPreferences for auth tokens | ⚠️ Accepted | M | H | Accepted risk for v1.0; plan `flutter_secure_storage` for v1.1 |

---

## 6. Localization Gaps

| # | Feature | Status | Impact | Effort | Notes |
|---|---------|--------|--------|--------|-------|
| L-1 | 12 locales with 256 keys | ✅ Present | — | — | EN/ES/FR/DE/AR/HI/ID/JA/KO/PT/RU/ZH |
| L-2 | No hardcoded strings in UI | ✅ Present | — | — | All user-facing strings use `AppLocalizations` |
| L-3 | RTL layout via `EdgeInsetsDirectional` | ✅ Present | — | — | Arabic RTL partially handled |
| L-4 | Locale-specific content selection | ❌ Missing | M | H | Same YouTube content shown regardless of locale; AR locale should surface Arabic-language content |
| L-5 | RTL full layout audit | ⚠️ Partial | M | M | `EdgeInsetsDirectional` used inconsistently; some widgets use `EdgeInsets` (non-RTL-safe) |
| L-6 | Locale-specific date/number formatting | ⚠️ Unknown | L | L | `intl` package available; needs verification on all screens |

---

## 7. Shorts / Video Gaps

| # | Feature | Status | Impact | Effort | Notes |
|---|---------|--------|--------|--------|-------|
| V-1 | Shorts tab with YouTube IFrame player | ✅ Present | — | — | `ShortsTab` exists |
| V-2 | Playback speed selector | ✅ Present | — | — | Confirmed in feature set |
| V-3 | Shorts progress persistence (resume on return) | ❌ Missing | M | M | Position not saved; user restarts from beginning |
| V-4 | Double-tap to seek ±10 s | ❌ Missing | M | L | Standard YouTube/TikTok pattern; `GestureDetector.onDoubleTap` |
| V-5 | Swipe-up for next Short | ✅ Present | — | — | `PageView` vertical scroll |
| V-6 | Like / share overlay on Shorts | ⚠️ Unknown | M | L | Needs verification; standard Reels/TikTok pattern |
| V-7 | Sound-off default in feed (autoplay muted) | ⚠️ Unknown | M | L | Autoplay muted is the accessibility and retention best practice |

---

## Overall Gap Priority Matrix

| Priority | Gap IDs | Rationale |
|----------|---------|-----------|
| **P0 — Release Blockers** | S-4, S-5 | Security requirements; must fix before public launch |
| **P1 — High Impact, Low Effort** | F-3, F-5, F-6, V-4, O-4 | Quick wins that match user expectations from competitor apps |
| **P2 — High Impact, Medium Effort** | P-3, P-4, O-6, F-4 | Core algorithm and activation improvements |
| **P3 — Medium Impact, Low/Medium Effort** | S-6, S-7, L-5, F-7, V-3 | Polish and security hardening |
| **P4 — Backlog** | P-7, P-8, PF-6, L-4 | Competitive differentiators for v1.2+ |

---

*Gap analysis based on direct code inspection of the Afeedi Flutter codebase and comparison against publicly documented patterns from TikTok, YouTube, Netflix, Instagram, Spotify, Duolingo, and Notion.*
