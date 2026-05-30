# UX/UI Audit Report
## Afeedi — v1.0 Consumer App Review

**Prepared:** 2026-05-30  
**Branch:** claude/optimistic-hopper-PLQOv  
**Benchmarks:** TikTok 34.x, YouTube 19.x, Netflix 8.x, Instagram 323.x, Spotify 8.9.x

---

## Executive Summary

Afeedi's visual language is polished and consistent. The dark-purple-on-cyan palette, shimmer loading states, and animation timing are production-ready. The primary gaps are interaction patterns (double-tap like, swipe-to-dismiss player) and several screen-level features that benchmark apps use to drive engagement. No screen is embarrassing to ship; several need targeted additions to reach parity.

---

## Screen-by-Screen Audit

| Screen | Current State | Gap | Priority |
|--------|--------------|-----|----------|
| Welcome | Premium gradient (`0xFF0D0B1E` → `0xFF1A1A2E`), logo, Google/Apple/email CTAs, entry animations | None at v1.0 | ✅ |
| Onboarding | 8-step `PageView`, animated progress bar, confetti on completion, genre/platform/language selection | Missing per-step visual illustrations; steps feel text-heavy | P2 |
| Home Feed | Section headers, Continue Watching data model, trending chips, shimmer skeleton | Continue Watching row not rendered; story-style highlights row absent; new-posts banner not wired | P1–P2 |
| Discover | Time filters, rank badges (#1/#2/#3), section labels, trending grid | Missing geographic/map-based trending; search queries trending subset only | P2–P3 |
| Shorts | Vertical `PageView` scroll, tap-to-play, shimmer loading, IFrame player | Missing double-tap like animation; no sound-off-by-default on autoplay | P2 |
| Search | Platform + genre filter chips, sanitised input, recent searches, trending topics | Missing voice search input; search queries trending subset only (BUG-M-4) | P2–P3 |
| Player | Playback speed selector, fullscreen, related content, like/save overlay | Missing picture-in-picture / swipe-down-to-minimise; related list includes current video | P2 |
| Profile | Stats grid (watch time, streak, videos), tabbed content (liked/saved/history/achievements), avatar upload | Missing: banner/cover photo slot, follower count display, Top Genres stat, Shorts watch count (BUG-M-2) | P1–P2 |
| Bookmarks | Sort by recent / alphabetical / platform | Missing: collection folders / named playlists | P3 |
| History | Continue watching progress bars, thumbnail list | Missing: group-by-date headers; <5% progress items shown (BUG-M-5) | P2 |
| Calendar | Month / week / day view, Google Calendar connection UI, scheduled content display | OAuth not functional; Google Calendar events never load (BUG-H-2) | P1 |
| Notifications | All / Unread / For You tabs, localised empty state (`noNotifications`, `allCaughtUp`) | Notification content strings hardcoded in English (BUG-M-1) | P1 |
| Settings | Playback speed default, dark/light/system theme, language switcher, notification toggle, account | Missing: per-notification-type frequency control; missing: data export / account delete (GDPR) | P2–P3 |

---

## Typography Audit

All type scales are consistent and hierarchy is clear.

| Role | Spec | Status |
|------|------|--------|
| Screen headings | `fontSize: 24–28, fontWeight: w700` | ✅ Consistent across ProfileScreen, PlayerScreen, SettingsScreen |
| Section titles | `fontSize: 18–20, fontWeight: w600` | ✅ Used in HomeTab section headers, CalendarTab |
| Card titles | `fontSize: 14–16, fontWeight: w600` | ✅ `FeedPostCard` title text |
| Body / descriptions | `fontSize: 13–15, fontWeight: w400–w500` | ✅ Description fields, settings rows |
| Captions / metadata | `fontSize: 11–12, color: Colors.white54` | ✅ Duration, view count, upload time labels |
| CTA buttons | `fontSize: 16, fontWeight: w600` | ✅ Primary action buttons on Welcome, Onboarding |

**Recommendation:** Adopt `AppTextStyles` constants (similar to `AppTheme.colorScheme`) to enforce type scale at compile time and prevent one-off `TextStyle(fontSize: 13)` literals drifting over time.

---

## Color System Audit

The color palette is coherent, consistently applied, and achieves sufficient contrast on dark backgrounds.

| Token | Value | Usage | Status |
|-------|-------|-------|--------|
| `_accent` (cyan) | `Color(0xFF00D4FF)` | Primary CTAs, active filter chips, progress indicators, links | ✅ Consistent |
| `_accentPink` | `Color(0xFFFF006E)` / `Color(0xFFFF3C7E)` | Like icons, highlights, badge backgrounds | ⚠️ Two slightly different pink values used — normalise to one constant |
| `_bgPrimary` | `Color(0xFF0D0B1E)` | Screen backgrounds | ✅ Consistent |
| `_surface` | `Color(0xFF1A1A2E)` | Card and sheet backgrounds | ✅ Consistent |
| `_surfaceElevated` | `Color(0xFF252545)` | Elevated drawers, dialogs, bottom sheets | ✅ Consistent |
| Error/warning | `Color(0xFFFF5252)` | Error SnackBars, validation messages | ✅ Consistent |
| Success | `Color(0xFF4ECDC4)` (teal) | Achievement unlocks, success states | ✅ Used in ProfileScreen achievements |

**Action item:** Consolidate the two pink accent values (`0xFFFF006E` in `profile_screen.dart` vs `0xFFFF3C7E` referenced elsewhere) into a single `_accentPink` constant in `AppTheme`.

---

## Animation Audit

| Animation | Spec | Status |
|-----------|------|--------|
| Welcome screen entry | Fade + slide up, 1200–1500 ms staggered | ✅ |
| Onboarding page transitions | Slide + fade, 600 ms `PageView` | ✅ |
| Feed card shimmer loading | `LoadingShimmer` widget with looping gradient | ✅ |
| Like / Save button | `AnimatedScale` 1.0 → 1.3 → 1.0, 200 ms | ✅ |
| Filter chip selection | `AnimatedContainer` color transition, 200 ms | ✅ |
| Confetti on onboarding complete | `confetti` package, burst on step 8 | ✅ |
| Calendar month/week/day switch | Fade transition via `AnimationController` | ✅ |
| Double-tap like heart | Not implemented | ❌ P2 |
| Player swipe-to-minimise | Not implemented | ❌ P2 |
| New-posts banner slide-in | `_newPostCount` field exists; animation not wired | ❌ P2 |

---

## Accessibility Audit

| Check | Status | Notes |
|-------|--------|-------|
| `Semantics(label: '...', button: true)` on all icon buttons | ✅ | Confirmed on major actions |
| High-contrast text (white/cyan on dark backgrounds) | ✅ | Passes WCAG AA for large text throughout |
| `Semantics(liveRegion: true)` on loading states | ❌ | Screen readers do not announce when content finishes loading |
| Minimum 44×44 tap targets on all interactive elements | ⚠️ | Most buttons meet this; some small icon buttons (e.g. calendar filter icons) may be 32×32 |
| `ExcludeSemantics` on purely decorative images | ⚠️ | Thumbnail `CachedNetworkImage` widgets should be wrapped with `ExcludeSemantics` |
| Focus traversal order | ⚠️ | Not explicitly set; default Flutter traversal is correct in LTR; needs manual verification in RTL/Arabic |
| TalkBack / VoiceOver manual test | ❌ | Not conducted; required before App Store submission |

---

## Interaction Pattern Gaps vs. Benchmarks

| Pattern | Benchmark | Afeedi | Gap |
|---------|-----------|--------|-----|
| Double-tap to like | TikTok, YouTube Shorts, Instagram Reels | ❌ Missing | P2 |
| Swipe down to dismiss / minimise player | YouTube, Spotify | ❌ Missing | P2 |
| Long-press to preview | Instagram, TikTok | ❌ Missing | P3 |
| Haptic feedback on like/save | TikTok, Instagram | ⚠️ Unverified | P2 |
| Share sheet with copy-link option | All platforms | ⚠️ Share icon present; `share_plus` not wired | P2 |
| Pull-to-refresh with haptic | YouTube, Instagram | ⚠️ `RefreshIndicator` present; haptic unverified | P2 |
| Pinch-to-zoom on player | YouTube | ❌ Missing | P3 |
| Voice search | YouTube | ❌ Missing | P3 |
| Sound-off default on feed autoplay | TikTok, Instagram | ⚠️ Unverified | P2 |

---

## Recommendations — Ordered by Impact

1. **Wire the Continue Watching row** (BUG-H-3) — highest engagement lever already built, just needs a widget insertion.
2. **Fix time filter null passthrough** (BUG-H-1) — prevents stale content appearing as "Today".
3. **Add double-tap like** — most expected UX pattern; one `GestureDetector.onDoubleTap` + heart animation.
4. **Resolve Google Calendar OAuth** — turns a broken feature into a live one.
5. **Add `Semantics(liveRegion: true)` on shimmer loading states** — one-line accessibility fix.
6. **Consolidate pink accent values** — 30-minute cleanup, prevents future drift.
7. **Minimum tap target audit** — run a `debugPaintSizeEnabled = true` pass to identify sub-44 px targets.

---

*UX/UI audit based on direct inspection of all screen and widget files in the Afeedi Flutter source tree, benchmarked against published UX research for TikTok, YouTube, Netflix, Instagram, and Spotify.*
