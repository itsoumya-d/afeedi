# Performance Report — Afeedi Flutter App

**Audit Date:** 2026-05-30  
**Performance Score: 7.0 / 10**

---

## Metrics

| Metric | Value | Target | Status |
|---|---|---|---|
| `const` widget uses in `/lib/widgets/` | 1,217 | > 500 | ✅ Excellent |
| `ListView.builder` / `GridView.builder` | 45 total | All lists lazy | ✅ Good |
| `CachedNetworkImage` uses | 18 | All remote images | ✅ (3 fixed this PR) |
| `RepaintBoundary` uses | 8 (surgical) | Per-card in feeds | ✅ Correct |
| `AutomaticKeepAliveClientMixin` tabs | 5 | All major tabs | ✅ |
| `dispose()` calls | 118+ | All controllers | ✅ Adequate |
| Non-builder `ListView(children:[])` | 10 | 0 for long lists | ⚠️ Review needed |
| Raw `NetworkImage` (bypasses cache) | 0 | 0 | ✅ Fixed this PR |

---

## Const Widget Usage

**1,217 const constructor uses** in widget files. This is the strongest performance signal — const widgets are never rebuilt unless their parent explicitly requests it. Key const patterns:

- `const SizedBox`, `const Divider`, `const Icon` throughout
- Static text labels as `const Text(...)` 
- `const EdgeInsets.symmetric(...)` in padding
- `const TextStyle(...)` definitions

No `const` added to widget constructors that depend on runtime data (correct — only truly static widgets are marked const).

---

## Lazy Loading

**45 lazy list implementations:**
- `ListView.builder` (33 uses) — main feed, search results, shorts action list, history, bookmarks, notification list
- `GridView.builder` (12 uses) — discover category grid, trending grid
- `SliverList` / `SliverGrid` (inside CustomScrollView in profile)

**⚠️ 10 non-builder `ListView(children: [])` found** — these render all children immediately regardless of viewport. Most are used for short, static lists (settings sections, filter options, onboarding steps) where the list length is bounded at ≤10 items. However, confirm no unbounded dynamic list uses this pattern.

---

## Image Caching

**Previously:** 3 locations used uncached `NetworkImage` / `Image.network` for creator avatars, bypassing the disk cache.  
**Fixed this PR:**
- `creator_profile_sheet.dart`: `NetworkImage` → `CachedNetworkImageProvider`
- `platform_branding_widget.dart`: `NetworkImage` → `CachedNetworkImageProvider`
- `creator_profile_sheet.dart` thumbnail: `Image.network` → `CachedNetworkImage`

**Current state:** All 18 remote image loads go through `cached_network_image` (3.3.1) with disk + memory caching. Network requests for the same thumbnail never repeat within a session and survive across sessions via disk cache.

---

## Memory Management

**118+ `dispose()` calls** across the codebase.

Key verified disposals:
- `PageController` in `DashboardScreen`
- `TextEditingController` in `SearchScreen`
- `TabController` in `SearchScreen`, `NotificationsScreen`
- `PageController` in `ShortsTab`
- 5 resources in `ChatController.dispose()` block
- `WidgetsBindingObserver` removed in `PlayerScreen.dispose()`

**New this PR:** `PlayerScreen` now also calls `SystemChrome.setPreferredOrientations([portraitUp])` on dispose, preventing stuck landscape state.

---

## Rebuild Optimization

- `RepaintBoundary` applied **per feed card** in home_tab — prevents the feed list from triggering repaints on adjacent cards when one updates
- `AutomaticKeepAliveClientMixin` on 5 tab widgets — tab scroll position preserved across tab switches
- `AnimatedContainer` with `duration: 200ms` for platform chip selection — GPU-composited, no layout thrash
- `ListenableBuilder` for `LocaleService` — rebuilds MaterialApp only when locale changes, not on every frame

---

## Auto-play & Player Performance

| Area | Status | Notes |
|---|---|---|
| YouTube IFrame | ✅ | Web: native IFrame, browser-handled buffering |
| Mobile YouTube | ⚠️ | Shows thumbnail; taps to external YouTube app |
| App lifecycle pause | ✅ | `WidgetsBindingObserver` in PlayerScreen; saves progress on background |
| Fullscreen | ✅ | `SystemChrome` orientation toggle in `_toggleFullscreen()` |

---

## Recommendations

1. **Audit the 10 non-builder ListView uses** — convert any with dynamic or potentially long children to `ListView.builder`
2. **Add `RepaintBoundary` to Shorts PageView pages** — full-screen pages are expensive to repaint together
3. **Add locale-aware date/number formatting** — `DateFormat` and `NumberFormat` from `intl: ^0.20.2` are already available but not yet applied to displayed values
4. **Consider `flutter_cache_manager` for feed content** — currently feed is reloaded fresh each session; a 15-minute TTL cache would improve perceived speed
