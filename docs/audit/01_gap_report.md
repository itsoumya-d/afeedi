# Feature Gap Report — Afeedi vs. Top Apps

**Audit Date:** 2026-05-30  
**App Version:** 1.0.0+1  
**Audited By:** Automated parallel agent analysis  

---

## Benchmark: TikTok

| Feature | Afeedi | Status | Priority |
|---|---|---|---|
| Vertical swipe short-form feed | ✅ ShortsTab PageView | Implemented | — |
| For You / Following split | ✅ Home tab toggle | Implemented | — |
| Platform/content-type filters | ✅ YouTube/TikTok/Instagram/Facebook chips | Implemented | — |
| Real-time collaborative signal (social graph watch time) | ❌ Local ranking only | Missing | Critical |
| Trending sounds / audio pages | ❌ | Missing | High |
| Comments bottom sheet | ✅ Implemented in ShortsTab | Implemented | — |
| Duet / Stitch / UGC creation | ❌ | Missing | Medium |
| "Not interested" / feed feedback signal | ❌ | Missing | Medium |
| Hashtag challenge pages | ❌ | Missing | Low |

## Benchmark: Instagram Reels

| Feature | Afeedi | Status | Priority |
|---|---|---|---|
| Native in-app playback (YouTube) | ✅ EnhancedYouTubePlayer IFrame | Implemented | — |
| Native in-app playback (TikTok/Instagram) | ❌ External browser only (ToS constraint) | Architecture limit | — |
| Creator profile page (tap avatar) | ✅ CreatorProfileSheet wired to feed cards | Implemented | — |
| Native OS share sheet | ❌ URL launch only | Missing | High |
| Collab tag / remix | ❌ | Missing | Medium |

## Benchmark: YouTube Shorts / YouTube

| Feature | Afeedi | Status | Priority |
|---|---|---|---|
| Watch-time telemetry → server ranking | ❌ Progress local only, never ranked upstream | Missing | Critical |
| Subscriptions / bell per creator | ❌ Follow is in-memory only | Missing | High |
| Chapters / timestamps | ❌ | Missing | Medium |
| Playlist / queue building | ❌ | Missing | Medium |
| Offline download | ❌ | Missing | Medium |
| Speed control / quality selector | ❌ | Missing | Low |
| Fullscreen with orientation rotate | ✅ SystemChrome + WidgetsBindingObserver | Implemented | — |
| Auto-play | ✅ autoPlay: true passed to players | Implemented (web) | — |
| Continue Watching | ✅ Home tab strip + watch_progress persistence | Implemented | — |

## Benchmark: Netflix

| Feature | Afeedi | Status | Priority |
|---|---|---|---|
| Thumbs up/down rating → recommendations | ❌ Like exists, dislike missing | Missing | High |
| Offline download with DRM | ❌ | Missing | Medium |
| Multi-profile / user accounts | ❌ | Missing | Medium |
| "Because you watched X" explainability | ❌ Reason string in model, never displayed | Missing | Medium |
| Skip intro / recap | ❌ | Missing | Low |

## Benchmark: Spotify (discovery model)

| Feature | Afeedi | Status | Priority |
|---|---|---|---|
| Daily/weekly curated recommendations | ✅ getTimeBasedRecommendations + daily notifications | Implemented | — |
| Push notifications for followed-creator content | ✅ NotificationService scheduled notifications | Implemented | — |
| Cross-session collaborative filtering | ❌ No server-side CF | Missing | Critical |
| "Not for me" explicit dislike in UI | ❌ | Missing | High |
| Cold-start diversity | ✅ getColdStartRecommendations (2×5 genres) | Implemented | — |

## Benchmark: Duolingo (gamification)

| Feature | Duolingo | Afeedi | Priority |
|---|---|---|---|
| Daily streaks with freeze shields | ✅ | ❌ No streak system | Critical |
| XP per action / weekly leaderboard | ✅ | ❌ | High |
| Badges / achievements | 50+ types | ❌ | High |
| Adaptive difficulty algorithm | ✅ SM-2 | ❌ Flag UI-only | High |
| Progress visualization dashboard | ✅ | ⚠️ Watch-progress bar only | Medium |
| Celebration animations on milestone | ✅ | ❌ | Medium |
| Streak-sensitive notification cadence | ✅ | ⚠️ Fixed schedule only | Low |

## Benchmark: Notion (content organization)

| Feature | Notion | Afeedi | Priority |
|---|---|---|---|
| Offline sync (read/write) | ✅ Full conflict resolution | ❌ | Critical |
| Content tagging / properties on saved items | ✅ | ❌ Bookmarks flat list only | High |
| Rich content types (text, embed, kanban) | ✅ | ❌ Video feed only | High |
| Database views (table/board/gallery/timeline) | ✅ | ❌ Filter-only genres | Medium |
| Templates | ✅ | ❌ | Medium |
| Nested content hierarchy / breadcrumbs | ✅ | ❌ Flat list | Medium |
| Collaborative editing | ✅ | ❌ Single-user | Low |

---

## Summary: Top 5 Actionable Priorities

1. **Critical** — Server-side watch-signal loop (progress data is local; add backend event endpoint)
2. **Critical** — Streak / gamification system (XP, daily streak counter, achievement badges)
3. **Critical** — Offline content fallback (cache last-fetched feed items for offline display)
4. **High** — Explicit dislike / "Not for me" signal surfaced in feed card action row
5. **High** — Bookmark tagging (allow user to tag/group saved content by category)
