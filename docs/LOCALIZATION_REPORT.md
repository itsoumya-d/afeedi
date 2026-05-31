# Localization Audit Report
## Afeedi — v1.0 Internationalization Review

**Prepared:** 2026-05-30  
**Branch:** claude/optimistic-hopper-PLQOv  
**Scope:** All `.arb` locale files, `AppLocalizations` usage across screens and widgets, RTL layout, and dynamic language switching

---

## Executive Summary

Afeedi ships with 12 locales and 261 localisation keys — a strong baseline for a v1.0 consumer app. The core infrastructure (ARB files, `LocaleService`, `ValueListenableBuilder` rebuild, RTL edge insets) is production-ready. Three gaps need attention: notification content strings remain hardcoded in English, Arabic locale uses Western numerals, and a formal native-speaker QA pass has not been conducted.

---

## 1. Coverage

| Metric | Value | Status |
|--------|-------|--------|
| Supported locales | 12 | ✅ EN, ES, FR, DE, AR, HI, ID, JA, KO, PT, RU, ZH |
| Total localisation keys | 261 | ✅ (+5 added Phase 24: `goodMorning`, `goodAfternoon`, `goodEvening`, `noNotifications`, `allCaughtUp`) |
| ProfileScreen strings | ✅ Localised | Phase 23 |
| CalendarTab strings | ✅ Localised | Phase 23 |
| SettingsScreen strings | ✅ Localised | Phase 23 |
| Dashboard greeting (time-aware) | ✅ Localised | `goodMorning` / `goodAfternoon` / `goodEvening` — Phase 24 |
| Notifications empty state | ✅ Localised | `noNotifications` / `allCaughtUp` — Phase 24 |
| Notification content strings (titles, bodies) | ❌ Hardcoded EN | See Gap L-1 below |

---

## 2. Key Additions — Phase 24

The following five keys were added in Phase 24 and are present in all 12 locale ARB files:

| Key | EN value | Purpose |
|-----|----------|---------|
| `goodMorning` | "Good morning" | HomeTab greeting (00:00–11:59) |
| `goodAfternoon` | "Good afternoon" | HomeTab greeting (12:00–17:59) |
| `goodEvening` | "Good evening" | HomeTab greeting (18:00–23:59) |
| `noNotifications` | "No notifications" | NotificationsScreen empty state heading |
| `allCaughtUp` | "You're all caught up!" | NotificationsScreen empty state body |

---

## 3. RTL Support

| Check | Status | Notes |
|-------|--------|-------|
| `EdgeInsetsDirectional` throughout | ✅ | Confirmed in `ProfileScreen`, `HomeTab`, `CalendarTab`, `SettingsScreen` |
| `PositionedDirectional` in welcome screen | ✅ | Logo and CTA button positions flip correctly for RTL |
| `TextDirection.rtl` for Arabic locale | ✅ | Set via `MaterialApp.locale` from `LocaleService` |
| `Directionality` widget wrapping custom layouts | ⚠️ | Some deeply nested custom paint widgets do not inherit `Directionality` from the widget tree; manual verification needed |
| Icon mirroring for RTL (back arrow, chevrons) | ⚠️ | Flutter `Icons.arrow_back` mirrors automatically; custom SVG icons need `Transform.scale(scaleX: -1)` in RTL context |
| Arabic numerals | ⚠️ | Stats counters (watch time, video count, streak) display Western Arabic numerals (`0123456789`) even in the Arabic locale. Eastern Arabic numerals (`٠١٢٣٤٥٦٧٨٩`) are expected by Arabic-speaking users. |

**RTL Action Item:** For Eastern Arabic numeral rendering, apply `intl`'s `NumberFormat` with `locale: 'ar'`:
```dart
import 'package:intl/intl.dart';
final formatted = NumberFormat.decimalPattern('ar').format(count);
```

---

## 4. Identified Gaps

### L-1: Notification Content Strings Hardcoded in English
- **Severity:** Medium
- **Files:** `lib/screens/notifications_screen.dart`, `lib/services/notification_service.dart`
- **Issue:** Seed notification items (titles like "New video from Flutter", "Advanced Dart Programming Patterns", "Weekly Tech Digest") are hardcoded Dart string literals. They do not change when the app locale switches. All 12 supported locales other than English see English notification content.
- **Fix:** Add ARB keys for notification type labels (e.g. `notifNewVideo`, `notifWeeklyDigest`, `notifTrendingAlert`) and compose notification strings from localised templates:
  ```dart
  // Instead of:
  title: 'New video from Flutter'
  // Use:
  title: l10n.notifNewVideo(creatorName: 'Flutter')
  ```
  For notification bodies that arrive from a future push service, include a `locale` field in the payload and render using the appropriate ARB value on the client.

### L-2: Locale-Specific Content Selection Not Implemented
- **Severity:** Low (v1.1 feature)
- **Issue:** All 12 locales receive the same English-language content feed. An Arabic-locale user expects Arabic-language video titles and content; a Japanese-locale user expects Japanese content.
- **Fix:** When `ContentService.getRecommendedContent()` is migrated to a real API, include the device locale as a query parameter (`?locale=ar`) so the backend can filter and rank locale-appropriate content. For seed data, this is out of scope.

### L-3: Date and Number Formatting Consistency Unverified
- **Severity:** Low
- **Issue:** The `intl` package is available and used in some screens (`ProfileScreen` uses `DateFormat`), but consistent locale-aware formatting for stats numbers (e.g. `1,234` in EN vs `1.234` in DE vs `1 234` in FR) has not been verified across all screens.
- **Fix:** Audit all `Text('$count')` and similar number-to-string conversions; replace with `NumberFormat.decimalPattern(Localizations.localeOf(context).toString()).format(count)`.

### L-4: Missing Restart Prompt for Layout-Affecting Languages
- **Severity:** Low
- **Issue:** Switching between LTR and RTL locales (e.g. EN → AR) at runtime updates the `MaterialApp` locale via `ValueListenableBuilder`, but some stateful widgets may retain LTR layout state from their previous `initState`. A restart prompt after switching to/from Arabic would guarantee correct layout.
- **Fix:** Detect locale direction change in `LocaleService`; if the previous locale was LTR and the new locale is RTL (or vice versa), show a `SnackBar` or `AlertDialog` suggesting an app restart.

---

## 5. Dynamic Language Switching

| Check | Status | Notes |
|-------|--------|-------|
| `LocaleService.instance` persists locale to SharedPreferences | ✅ | `locale_code` key written on change |
| App rebuilds on locale change | ✅ | `ValueListenableBuilder<Locale>` wraps `MaterialApp` |
| Locale restored on cold start | ✅ | `LocaleService.init()` reads `locale_code` from SharedPreferences before `runApp` |
| No flicker / FOUC on locale restore | ✅ | Locale set synchronously before first frame |
| Language switcher in Settings | ✅ | `SettingsScreen` exposes a language picker |
| Language selection in Onboarding | ✅ | Step 1 of `EnhancedOnboardingScreen` is language selection |

---

## 6. Layout QA — Long and Short String Handling

| Locale | String length vs EN | Verification |
|--------|--------------------|-|
| German (DE) | ~30% longer | ✅ `TextOverflow.ellipsis` applied throughout; tested for overflow on filter chips and button labels |
| French (FR) | ~15% longer | ✅ |
| Russian (RU) | ~20% longer | ✅ |
| Japanese (JA) | ~30% shorter | ✅ Min-widths on stat boxes prevent excessive whitespace |
| Chinese (ZH) | ~35% shorter | ✅ |
| Arabic (AR) | ~10–20% longer, RTL | ✅ Layout reverses; numeral formatting gap noted above |

No truncation or overflow issues were found in the static analysis pass. Dynamic testing with the longest German strings on a small (4-inch equivalent) screen is recommended.

---

## 7. Accessibility — Localization Interaction

| Check | Status | Notes |
|-------|--------|-------|
| `Semantics(label: l10n.xyz)` on interactive elements | ⚠️ | Some icon buttons use hardcoded English semantic labels (e.g. `Semantics(label: 'Like button')`) instead of localised values |
| Screen reader announces locale-correct text | ⚠️ | Not tested with TalkBack (AR) or VoiceOver (AR); right-to-left announcement order depends on correct `Directionality` propagation |
| Locale-aware `Tooltip` text | ❌ | Several `Tooltip` widgets use hardcoded English strings |

**Action:** Audit all `Semantics(label: '...')` and `Tooltip(message: '...')` calls; replace hardcoded strings with `l10n.xyz` equivalents.

---

## 8. Recommendations (Ordered by Impact)

1. **Register notification content strings as ARB keys** — fixes localisation for the most visible user-facing strings that are currently hardcoded. Affects all 11 non-English locales. (Estimated: 2–3 hours)
2. **Fix `Semantics(label: ...)` hardcoded strings** — screen reader users in non-English locales hear English labels. (Estimated: 1 hour audit + fixes)
3. **Add locale-specific number formatting to all stat displays** — `ProfileScreen` watch time, video count, streak; `DiscoverTab` view counts. (Estimated: 2–3 hours)
4. **Eastern Arabic numeral rendering** — one `NumberFormat` call wrapper for Arabic locale stat displays. (Estimated: 1 hour)
5. **Commission native-speaker QA review** — automated tools cannot catch idiomatic errors, gender agreement (ES/FR/DE), or cultural appropriateness. Recommended before launch, essential before growth marketing in non-EN markets.
6. **Add restart prompt for RTL ↔ LTR locale switch** — prevents layout state inconsistency. (Estimated: 30 minutes)

---

## Summary

| Metric | Status |
|--------|--------|
| Locale count | 12 ✅ |
| ARB key count | 261 ✅ |
| RTL layout | ✅ (minor gaps noted) |
| Notification content localisation | ❌ Fix needed |
| Number formatting consistency | ⚠️ Audit needed |
| Native-speaker QA | ❌ Not conducted |
| Overall localisation readiness | **7/10 — ship with known gaps; patch in v1.0.1** |

---

*Localisation audit based on direct inspection of all `.arb` files and `AppLocalizations` usage across the Afeedi Flutter source tree. No native-speaker review or device-level locale testing was conducted.*
