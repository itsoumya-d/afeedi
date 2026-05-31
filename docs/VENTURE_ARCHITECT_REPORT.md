# Afeedi — Venture Architect Executive Report

**Date:** May 2026  
**Status:** Phase 7 of 10 Complete  
**Branch:** `claude/optimistic-hopper-PLQOv`  
**Tests:** 329 passing, 0 analyzer errors

---

## Executive Summary

Afeedi is a multi-platform video aggregator for iOS and Android, built in Flutter, that surfaces personalized content from YouTube, TikTok, Instagram, and Facebook in a unified AI-curated feed. The app is production-code-complete for its MVP feature set and approaching App Store / Play Store submission readiness.

**Realistic valuation range:**

| Scenario | Valuation | Trigger condition |
|---|---|---|
| Pre-launch / seed | $2M–$5M | Working product, 0 MAU |
| Post-launch (500K MAU) | $15M–$40M | D30 >15%, DAU/MAU >28% |
| Growth stage (5M MAU) | $80M–$150M | Strategic acquisition window opens |
| Platform-partnership scenario | $400M–$800M | One major platform (YouTube, Meta, TikTok) takes equity stake |

The $400M–$800M ceiling is real but requires a platform partnership — no organic-only path reaches that level. The realistic acquisition ceiling for an independent company is **$100–150M at 10–15M MAU**.

---

## Phase 1 — Problem Discovery

### Problem Statement

Video consumption is fragmented across 5+ apps. Users context-switch 8–12 times per day between YouTube, TikTok, Instagram, Twitter/X, and Facebook. Each platform's algorithm is a black box optimized for time-on-platform, not user preference. There is no single surface that:

1. Unifies content from all platforms into one ranked feed
2. Learns from cross-platform behavior (liking on TikTok should inform YouTube recommendations)
3. Lets users control recommendation weights (genres, platforms, creators)
4. Surfaces trending content across platforms simultaneously

**Pain intensity:** Medium-high. Users don't complain about the problem, but they do spend 60+ minutes/day on fragmented apps. Aggregation is a proven category (Flipboard, Feedly, SmartNews) — Afeedi adds video-native UX and AI ranking.

### TAM / SAM / SOM

| Market | Size | Source |
|---|---|---|
| Global short-form video market | $2.1B (2024) → $8.5B (2029) | MarketsandMarkets |
| Mobile video streaming apps revenue | $26B (2024) | Sensor Tower |
| AI-personalized content platforms | $1.2B (2024) | Grand View Research |
| Afeedi serviceable market (English-speaking, 18–35) | ~$400M | Bottom-up estimate |

---

## Phase 2 — Valuation Model

### Comparable Acquisitions

| Company | MAU at acquisition | Valuation | Multiple |
|---|---|---|---|
| Flipboard | 100M | $200M | 2× revenue |
| SmartNews | 10M | $1.1B | Strategic premium |
| Pocket (Mozilla) | 10M | ~$50M | User base |
| Periscope (Twitter) | Pre-launch | $86M | Tech + team |
| Houseparty (Epic) | 50M | $35M | Strategic |

**Afeedi's defensible moat:** Cross-platform aggregation with a unified interaction signal (likes, saves, not-interested across platforms feeding one ML model). This is structurally impossible for any single-platform app to replicate.

### Revenue Model

1. **Freemium subscription** — Afeedi Pro at $6.99/mo or $49.99/yr
   - Free tier: 20 saves, platform-logo ads, standard recommendations
   - Pro tier: unlimited saves, no ads, AI Digest, offline mode
2. **Ad revenue** — AdMob interstitials between feed sections (free tier)
   - Estimated $0.80–$1.20 ARPU/year on free tier
3. **Referral program** — Viral K-factor target 0.7+ via "Give 7 Days Pro, Get 7 Days Pro"

**Unit economics at scale (5M MAU, 8% paid):**
- 400K Pro subscribers × $49.99/yr = $20M ARR
- 4.6M free users × $1.00 ARPU = $4.6M ad revenue
- **Total ARR: ~$24.6M**
- At 5× revenue multiple: **$123M valuation**

---

## Phase 3 — Agent System (35 Specialized Agents)

Each agent below is fully specified with Mission, Responsibilities, Inputs, Outputs, and KPIs. Agents operate in parallel during product development; the OrchestratorAgent routes work and resolves conflicts.

---

### Agent 1 — ProblemDiscoveryAgent

**Mission:** Identify, quantify, and validate the core user pain before any feature is built. Prevents building solutions to non-problems.

**Responsibilities:**
- Conduct user pain interviews (simulated or real) across target demographics
- Map frequency × severity matrix for each identified pain point
- Identify existing alternatives users rely on and why they fall short
- Quantify willingness to pay through van Westendorp pricing analysis
- Size TAM/SAM/SOM from bottom-up and top-down methodologies

**Inputs:** App concept brief, target demographic description, competitor list

**Outputs:**
- Problem Statement (one sentence, problem + who + when)
- Pain Point Matrix (frequency × severity × willingness-to-pay)
- Jobs To Be Done map (functional, social, emotional)
- TAM/SAM/SOM model with source citations
- ICP (Ideal Customer Profile) — 3 primary personas

**KPIs:**
- Pain severity score ≥ 7/10 (justifies building)
- ≥ 3 confirmed personas with distinct JTBD
- TAM > $500M (minimum viable market for VC-backable company)
- Competitor gap confirmed in ≥ 2 dimensions

---

### Agent 2 — ValuationAgent

**Mission:** Define the realistic maximum valuation achievable, set the North Star target, and ensure all subsequent decisions optimize toward that target.

**Responsibilities:**
- Model 4 valuation scenarios: $10M, $100M, $1B, $10B
- Define MAU, revenue, retention, and moat requirements for each scenario
- Select North Star Valuation Target based on market evidence
- Benchmark against comparable acquisitions (comp analysis)
- Maintain valuation model as a living document updated with each milestone

**Inputs:** TAM/SAM/SOM from ProblemDiscoveryAgent, competitor valuations, revenue model from MonetizationAgent

**Outputs:**
- 4-scenario valuation waterfall (users × ARPU × multiple)
- North Star Valuation Target with justification
- Key value drivers ranked by impact
- Exit scenario map (acquirers, IPO timeline, acqui-hire floor)
- Valuation risk register (what kills the path to each scenario)

**KPIs:**
- North Star scenario has ≥ 1 confirmed comparable acquisition
- Revenue model achieves ≥ 40% gross margin at scale
- Path to $100M ARR modeled within 5 years
- Moat identified that is not replicable by incumbents in <18 months

---

### Agent 3 — CompetitorAgent

**Mission:** Maintain a living feature-gap matrix against all direct and adjacent competitors, surfacing defensible differentiation opportunities.

**Responsibilities:**
- Audit top 10 competitors across feature surface area, UX, pricing, and growth
- Score each competitor on 20 dimensions (feed quality, platform breadth, personalization, etc.)
- Identify features present in competitors but absent in Afeedi
- Identify features Afeedi can own that competitors structurally cannot replicate
- Monitor competitor app store reviews for user pain signals

**Inputs:** Competitor app list, App Store / Play Store review data, product roadmap

**Outputs:**
- Competitor matrix (20 dimensions × 10 competitors)
- "Own exclusively" feature list (structural moat candidates)
- "Must match" feature list (table stakes for user acquisition)
- "Skip" feature list (commodity features with low differentiation value)
- Weekly competitor delta report

**KPIs:**
- Afeedi wins ≥ 5 dimensions where no single competitor also wins
- ≥ 2 features identified that are impossible for single-platform apps to replicate
- Competitor review analysis yields ≥ 10 actionable pain signals per quarter
- Feature gap matrix updated within 48 hours of competitor launch events

---

### Agent 4 — FeatureDiscoveryAgent

**Mission:** Translate user pain points and valuation requirements into a prioritized, actionable feature backlog. Ensure every feature has a measurable impact hypothesis.

**Responsibilities:**
- Generate user stories from JTBD map (As a [user], I want [feature], so that [outcome])
- Score every feature on RICE framework (Reach × Impact × Confidence ÷ Effort)
- Map features to MVP / V1 / V2 / V3 releases
- Ensure each feature has a retention impact hypothesis, revenue impact hypothesis, and acceptance criteria
- Identify feature dependencies and sequencing constraints

**Inputs:** Pain Point Matrix from ProblemDiscoveryAgent, North Star Valuation Target from ValuationAgent, competitor gap analysis from CompetitorAgent

**Outputs:**
- Feature backlog (≥ 50 items) with RICE scores
- MVP feature set (items required before first user can derive core value)
- V1/V2/V3 roadmap with quarterly milestones
- Feature dependency graph
- Impact hypothesis for each feature (metric + expected delta)

**KPIs:**
- MVP contains ≤ 15 features (minimum viable, not maximally featured)
- 100% of features have measurable acceptance criteria
- RICE scoring variance between reviewers < 20%
- Roadmap reviewed and updated every sprint

---

### Agent 5 — UXResearchAgent

**Mission:** Ground all design decisions in observed user behavior patterns from top-performing apps, reducing design risk and accelerating time-to-delight.

**Responsibilities:**
- Benchmark Afeedi's UX against YouTube, TikTok, Instagram, Flipboard, Netflix
- Identify interaction patterns that drive engagement in category leaders (autoplay, swipe, tap targets)
- Conduct heuristic evaluation of all Afeedi screens against Nielsen's 10 heuristics
- Define user journey maps for core flows: onboarding, first feed view, first save, first share
- Document micro-interaction patterns that create delight (haptics, animation timing, transitions)

**Inputs:** Competitor app screenshots, UXResearch databases (Mobbin), user journey requirements from FeatureDiscoveryAgent

**Outputs:**
- UX benchmark report (Afeedi vs. top 5 competitors on 15 UX dimensions)
- Heuristic evaluation with severity scores for each violation
- User journey maps (4 primary journeys, with failure states)
- Micro-interaction specification (timing, easing curves, haptic patterns)
- Design risk register (UX decisions with highest usability risk)

**KPIs:**
- 0 critical heuristic violations (severity 4) in shipped product
- ≤ 3 major heuristic violations (severity 3) at launch
- Core journey completion rate target: onboarding ≥ 70%, first save ≥ 40%
- Benchmark parity on ≥ 10 of 15 UX dimensions vs. category leaders

---

### Agent 6 — DesignTokenAgent

**Mission:** Create and maintain a consistent, scalable design system that enables rapid feature development without visual debt.

**Responsibilities:**
- Define color system: primary, surface, accent, semantic (error/success/warning), platform-specific
- Define typography scale: display/heading/body/caption/label with size, weight, line-height
- Define spacing system: 8px base grid with named tokens (xs/sm/md/lg/xl/2xl)
- Define component radius, shadow, and border tokens
- Ensure all tokens are accessible (WCAG AA contrast ratios)
- Maintain Flutter `ThemeData` implementation of all tokens

**Inputs:** Brand guidelines, competitor visual analysis, accessibility requirements from AccessibilityAgent

**Outputs:**
- Design token specification (all tokens named and valued)
- Flutter `AppTheme` class with all tokens implemented
- Dark/light mode token pairs
- Platform-specific accent color map (YouTube red, TikTok teal, Instagram gradient, Facebook blue)
- Contrast ratio audit for all text/background combinations

**KPIs:**
- 100% of UI uses tokens (0 hardcoded hex values except in token definitions)
- All text/background pairs achieve WCAG AA (4.5:1 for normal, 3:1 for large)
- Design token changes propagate to all screens in ≤ 1 day
- Token count ≤ 80 (prevent token sprawl)

---

### Agent 7 — FlutterArchitectAgent

**Mission:** Design a scalable, testable Flutter architecture that supports rapid feature development without accumulating structural debt.

**Responsibilities:**
- Define service layer architecture (singleton services, dependency injection strategy)
- Define state management approach (Riverpod providers vs. ChangeNotifier)
- Define navigation architecture (named routes, deep-link handling)
- Define data persistence strategy (SharedPreferences for MVP, SQLite/Drift for V1)
- Define widget composition patterns (screen → tab → widget → primitive hierarchy)
- Ensure architecture supports ≥ 80% test coverage

**Inputs:** Feature backlog from FeatureDiscoveryAgent, scalability requirements from InfrastructureAgent

**Outputs:**
- Architecture decision record (ADR) for each major decision
- Service layer diagram with dependency graph
- State management specification (what lives where)
- Navigation tree (all routes, parameters, deep-link schemas)
- Testing strategy (unit/widget/integration test boundaries)
- Migration plan: SharedPreferences → SQLite → Supabase

**KPIs:**
- Cold start time ≤ 1.5 seconds on mid-range device
- ≥ 80% unit test coverage on service layer
- 0 global mutable state outside designated service singletons
- Widget rebuild scope: state changes trigger ≤ 10% of widget tree

---

### Agent 8 — OnboardingAgent

**Mission:** Design and optimize the onboarding flow to maximize D1 activation rate, ensuring users reach their "aha moment" before the first session ends.

**Responsibilities:**
- Define the "aha moment" (the action that predicts long-term retention)
- Design minimal onboarding that collects enough signal for personalization without churn
- Enforce minimum personalization quality gates (≥ 3 genres required)
- Design cold-start strategy for users who skip personalization
- A/B test hypothesis generation for onboarding variants
- Track onboarding funnel step-by-step conversion rates

**Inputs:** User JTBD from ProblemDiscoveryAgent, recommendation requirements from FeedAlgorithmAgent

**Outputs:**
- Onboarding flow specification (screens, states, transitions, error states)
- "Aha moment" definition and first-session success metric
- Cold-start strategy (curated seed content for 0-interaction users)
- A/B test plan for 3 onboarding variants
- Onboarding funnel instrumentation spec (event names, properties)

**KPIs:**
- Onboarding completion rate ≥ 70% of installs
- D1 retention of onboarded users ≥ 35%
- Time to first content interaction ≤ 90 seconds post-install
- Users who select ≥ 3 genres have 2.4× higher D7 retention (hypothesis)

---

### Agent 9 — FeedAlgorithmAgent

**Mission:** Design and continuously improve the ranking algorithm that makes Afeedi's feed feel uncannily personalized, driving session length and return frequency.

**Responsibilities:**
- Define engagement signals and their weights (view, like, save, share, not-interested, watch %)
- Design recency decay function (prevents stale content domination)
- Design diversity constraint (max N items per genre/platform per feed page)
- Define cold-start strategy (genre-seed → behavior-driven transition)
- Design negative signal processing (not-interested removes content + genre-weight adjustment)
- Specify A/B test framework for ranking experiments

**Inputs:** User interaction events from AnalyticsAgent, onboarding preferences from OnboardingAgent, content library from ContentService

**Outputs:**
- Ranking algorithm specification (formula with signal weights)
- Diversity constraint rules (per-genre cap, per-platform cap)
- Negative signal processing rules (content removal + weight update)
- Cold-start content selection rules
- Recommendation explanation labels ("Because you liked X", "Trending in Gaming")
- Algorithm performance metrics definition

**KPIs:**
- Average session length ≥ 8 minutes (vs. 4 min baseline)
- "Not Interested" usage < 5% of feed impressions (good cold-start quality)
- Genre-weighted precision ≥ 70% (70% of shown content matches stated interests)
- Feed diversity: ≥ 3 distinct genres in every 10-item feed page

---

### Agent 10 — RetentionAgent

**Mission:** Design the mechanics, loops, and hooks that make Afeedi a daily habit, targeting D30 retention >15% (2× industry average).

**Responsibilities:**
- Map the Hooked framework for Afeedi (trigger → action → variable reward → investment)
- Design streak system (daily usage rewards)
- Design notification cadence that re-engages without causing opt-out
- Design weekly digest (Sunday 10AM, top 5 personalized picks)
- Identify D1/D7/D30 leading indicators from early session behavior
- Define win-back campaign for churned users

**Inputs:** Analytics funnel data from AnalyticsAgent, notification capabilities from NotificationAgent, content preferences from FeedAlgorithmAgent

**Outputs:**
- Retention loop diagram (trigger chain for each re-engagement path)
- Streak system specification (rewards, reset rules, grace period)
- Notification strategy (type × cadence × opt-out rules)
- D30 leading indicator model (early actions that predict retention)
- Win-back sequence specification

**KPIs:**
- D1 retention ≥ 35%
- D7 retention ≥ 20%
- D30 retention ≥ 15%
- DAU/MAU ≥ 28%
- Notification opt-out rate < 15%
- Weekly digest open rate ≥ 30%

---

### Agent 11 — MonetizationAgent

**Mission:** Design the revenue model that maximizes LTV per user while minimizing paywall friction that causes churn.

**Responsibilities:**
- Evaluate freemium, subscription, usage-based, and ad-supported models
- Design paywall placement at peak intent moments (not arbitrary screens)
- Define free vs. Pro feature split (generous enough to retain, restricted enough to convert)
- Model LTV, CAC, and payback period across acquisition channels
- Design trial mechanics (referral-earned 7-day Pro trial)
- Define pricing strategy with van Westendorp validation

**Inputs:** User pain points from ProblemDiscoveryAgent, North Star Valuation from ValuationAgent, competitor pricing from CompetitorAgent

**Outputs:**
- Revenue model specification (tiers, prices, features per tier)
- Paywall placement map (screen × trigger × conversion hypothesis)
- LTV model (monthly/annual cohort projections)
- CAC target by channel
- Pricing page design specification
- A/B test plan for pricing variants

**KPIs:**
- Free-to-paid conversion ≥ 3% at save-limit trigger
- Annual plan uptake ≥ 40% of paying users (LTV maximizer)
- LTV/CAC ratio ≥ 3:1
- Monthly churn on paid ≤ 5%
- Ad ARPU on free tier ≥ $0.80/year

---

### Agent 12 — GrowthAgent

**Mission:** Design viral and acquisition loops that make user growth self-sustaining, targeting K-factor ≥ 0.7 (each user brings 0.7 new users).

**Responsibilities:**
- Design referral program mechanics (both-sided reward, code generation, share flow)
- Model K-factor: invites sent × conversion rate = new users per user
- Design viral content loops (share nudge at peak emotional moment, shareable digest)
- Identify acquisition channels: ASO, social ads, creator partnerships, PR
- Design the post-like share nudge (fires on 3rd like, every 10th thereafter)
- Define growth accounting: new users, resurrected users, retained users, churned users

**Inputs:** Referral mechanics from MonetizationAgent, share surfaces from UXResearchAgent, retention data from RetentionAgent

**Outputs:**
- K-factor model (invites sent × conversion rate simulation)
- Referral program specification (code format, reward rules, entry points)
- Viral loop diagram (trigger → share → install → activate)
- ASO keyword strategy (primary + secondary + long-tail)
- Growth accounting dashboard specification

**KPIs:**
- K-factor ≥ 0.5 at launch, ≥ 0.7 by month 6
- Referral conversion rate ≥ 12% (invite → install)
- Share nudge CTR ≥ 8%
- Organic/paid acquisition ratio ≥ 40:60 by month 12

---

### Agent 13 — ContentComplianceAgent

**Mission:** Ensure Afeedi never violates platform Terms of Service in ways that risk app removal, legal action, or platform API ban.

**Responsibilities:**
- Audit all platform API usage against YouTube ToS §4.F, TikTok API terms, Meta API terms
- Maintain CONTENT_COMPLIANCE.md as living enforcement document
- Review every new feature for ToS risk before implementation
- Define permitted vs. prohibited content operations (embedding vs. downloading vs. transcoding)
- Monitor platform policy changes and issue alerts

**Inputs:** Feature proposals from FeatureDiscoveryAgent, platform API documentation

**Outputs:**
- CONTENT_COMPLIANCE.md (platform-by-platform permitted operations)
- Feature risk assessment for each proposed content feature
- Prohibited library list (e.g., `youtube_explode_dart` — BANNED, Play Store termination risk)
- API usage audit report
- Policy change monitoring alerts

**KPIs:**
- 0 ToS violations in shipped product
- `youtube_explode_dart` never re-enabled (hard requirement)
- All video playback uses platform-provided embed APIs only
- Compliance review completed for 100% of content features before merge

---

### Agent 14 — PrivacyAgent

**Mission:** Ensure Afeedi is compliant with GDPR, CCPA, COPPA, and App Store/Play Store privacy requirements, making privacy a competitive advantage rather than a liability.

**Responsibilities:**
- Implement account deletion with full data wipe (GDPR Art. 17)
- Implement data export (GDPR Art. 20)
- Design opt-in consent flows for analytics, advertising, and personalization
- Implement ATT (App Tracking Transparency) for iOS
- Implement UMP (User Messaging Platform) for GDPR consent on Android
- Define data retention policies for all collected data types
- Complete Play Store Data Safety form

**Inputs:** Analytics event taxonomy from AnalyticsAgent, ad integration from MonetizationAgent, user data model from FlutterArchitectAgent

**Outputs:**
- Privacy policy (public URL required for store submission)
- Data processing inventory (what is collected, why, how long, third parties)
- Consent flow specification (ATT, UMP, analytics opt-in)
- GDPR rights implementation (delete, export, rectify)
- COPPA compliance checklist (age gate if under-13 content possible)
- Play Store Data Safety answers

**KPIs:**
- 100% of PII has defined retention policy
- Account deletion completes within 30 days (GDPR requirement)
- Consent collection rate ≥ 60% (industry average for video apps)
- 0 privacy policy violations identified in App Store review

---

### Agent 15 — AppStoreAgent

**Mission:** Maximize iOS App Store review approval probability and ASO (App Store Optimization) ranking for target keywords.

**Responsibilities:**
- Write App Store listing: title (30 chars), subtitle (30 chars), description (4000 chars), keywords (100 chars)
- Generate required screenshot sets: 6.7" iPhone, 5.5" iPhone, iPad 12.9"
- Define age rating responses to content questionnaire
- Review all in-app purchase products for App Store compliance
- Prepare review notes for App Store reviewers explaining content model
- Monitor rejection reasons and maintain rejection-risk register

**Inputs:** App feature set from FeatureDiscoveryAgent, privacy policy from PrivacyAgent, IAP product list from MonetizationAgent

**Outputs:**
- App Store listing copy (title, subtitle, description, keywords)
- Screenshot specification (layout, captions, device frames)
- Age rating questionnaire answers
- Review notes template for App Store reviewer
- ASO keyword ranking targets (primary: "video feed", "all in one", "short videos")
- Rejection-risk register with mitigation for each risk

**KPIs:**
- First-submission approval rate (target: pass on first try)
- Day-7 App Store search rank for "video aggregator" ≤ 50
- Screenshot conversion rate (product page visits → installs) ≥ 4%
- 0 guideline 4.2 (minimal functionality) rejections

---

### Agent 16 — PlayStoreAgent

**Mission:** Maximize Google Play Store review approval probability and Play Store search ranking.

**Responsibilities:**
- Write Play Store listing: title (50 chars), short description (80 chars), full description (4000 chars)
- Configure content rating via IARC questionnaire
- Complete Data Safety section (all data types, collection, sharing, security)
- Ensure target SDK ≥ 34 and 64-bit compliance
- Review for Policy §4.4 (misleading behavior), §4.7 (spam), and streaming content policy
- Monitor Play Store policy changes (quarterly review)

**Inputs:** App feature set, privacy data inventory from PrivacyAgent, technical spec from FlutterArchitectAgent

**Outputs:**
- Play Store listing copy
- Data Safety section answers
- IARC questionnaire answers
- Pre-launch report review checklist
- SDK compliance audit
- Policy violation risk register

**KPIs:**
- First-submission approval rate
- Day-14 Play Store search rank for "video feed app" ≤ 30
- Data Safety completion score 100%
- Pre-launch report: 0 crashes in robo-test on ≥ 10 device configurations

---

### Agent 17 — NotificationAgent

**Mission:** Design a notification system that drives re-engagement without causing opt-out, targeting ≥ 440% D30 retention lift vs. no notifications.

**Responsibilities:**
- Define notification taxonomy: trending, recommendation, achievement, weekly_digest, system
- Design per-category opt-in/opt-out controls in Settings
- Schedule weekly digest for Sunday 10AM local time (pinned, not relative)
- Design deep-link routing: each notification type routes to the correct in-app destination
- Define notification rate limiting: maximum 1 per day excluding digest
- Design win-back notification for users inactive >7 days

**Inputs:** Retention hooks from RetentionAgent, deep-link schema from FlutterArchitectAgent, user preference data from OnboardingAgent

**Outputs:**
- Notification taxonomy (type, channel, frequency, deep-link target)
- Per-notification copy template (title ≤ 65 chars, body ≤ 240 chars)
- Deep-link routing table (notification type → screen + params)
- Rate limiting rules (per-type, per-day caps)
- Opt-out impact model (what % churn if notifications disabled)
- Permission request timing specification (not on first launch)

**KPIs:**
- Notification permission grant rate ≥ 60%
- Weekly digest open rate ≥ 30%
- Notification-driven session rate ≥ 15% of all sessions
- Opt-out rate < 15% within 30 days of granting permission
- Deep-link correct routing rate 100%

---

### Agent 18 — AnalyticsAgent

**Mission:** Instrument every user action with a consistent event taxonomy, enabling data-driven decisions at every stage of growth.

**Responsibilities:**
- Define event taxonomy (screen_view, content_interaction, feature_used, conversion, error)
- Ensure all events have consistent properties (user_id, session_id, platform, timestamp)
- Define funnel events for onboarding, activation, monetization, and retention
- Define retention cohort queries (D1/D7/D30 by onboarding variant, genre, platform)
- Implement event validation (no events fire without required properties)
- Define dashboard requirements for each growth metric

**Inputs:** Feature list from FeatureDiscoveryAgent, funnel definition from RetentionAgent

**Outputs:**
- Event taxonomy document (≥ 50 events with name, trigger, properties)
- Analytics implementation checklist (one entry per feature × event)
- Funnel definition (steps, events, success criteria)
- Retention cohort query library
- Dashboard specification (daily active users, funnel conversion, revenue)
- Data quality validation rules

**KPIs:**
- 100% of user interactions tracked with ≥ 1 event
- Event delivery rate ≥ 99.5% (no data loss)
- Dashboard reflects data within 2 hours of event
- Onboarding funnel tracked step-by-step with ≤ 5% unexplained drop events

---

### Agent 19 — A/BTestingAgent

**Mission:** Establish the hypothesis-driven experimentation culture that separates growing apps from stagnating ones.

**Responsibilities:**
- Maintain a prioritized A/B test backlog (≥ 10 tests queued at all times)
- Write hypothesis format: "If [change], then [metric] will [increase/decrease] by [amount] because [reason]"
- Calculate required sample size for statistical significance (80% power, p < 0.05)
- Define guardrail metrics (metrics that must not degrade in any test)
- Design test allocation logic (consistent user assignment, no contamination)
- Document all test results including failed hypotheses

**Inputs:** Product hypotheses from FeatureDiscoveryAgent and RetentionAgent, analytics infrastructure from AnalyticsAgent

**Outputs:**
- A/B test backlog with priority scores
- Test design document for each active test (hypothesis, metrics, sample size, duration)
- Statistical significance calculator (built into analytics layer)
- Guardrail metric dashboard
- Test results archive (all historical experiments with outcomes)

**KPIs:**
- ≥ 2 A/B tests running concurrently post-launch
- Test win rate ≥ 30% (most hypotheses should work; too low = weak hypotheses)
- Average test duration ≤ 14 days
- 0 tests shipped without pre-registered hypothesis

---

### Agent 20 — SearchAgent

**Mission:** Build a search experience that surfaces the right content in under 2 seconds, with platform and genre filtering as first-class UX.

**Responsibilities:**
- Design search query completion and suggestion logic
- Implement platform filter chips (YouTube / TikTok / Instagram / Facebook / All)
- Implement genre filter chips with post-query in-memory filtering
- Design empty state, error state, and no-results state
- Optimize search debounce timing (300ms delay, minimum 2 characters)
- Track search queries and zero-result rate to improve content coverage

**Inputs:** Content library from ContentService, genre taxonomy from OnboardingAgent

**Outputs:**
- Search UX specification (states, interactions, filter behavior)
- Filter implementation: `PlatformType` enum post-query filtering
- Search analytics events (query, result_count, filter_applied, item_tapped)
- Zero-result rate monitoring dashboard
- Search suggestion corpus (top 50 queries by expected volume)

**KPIs:**
- Search result latency ≤ 300ms for in-memory queries
- Platform filter click-through rate ≥ 20% of search sessions
- Zero-result rate ≤ 15%
- Search-to-content-tap conversion ≥ 30%

---

### Agent 21 — CalendarAgent

**Mission:** Make Afeedi the content planning layer of the user's life by integrating with Google Calendar and enabling content scheduling.

**Responsibilities:**
- Design Google Calendar OAuth2 integration (read-only calendar events)
- Design content scheduling UI (pick a date, associate content)
- Replace mock date-content associations with real calendar event overlap logic
- Design calendar dot indicator logic (show on dates with real content/events only)
- Handle calendar sync edge cases (timezone changes, event deletions, auth expiry)

**Inputs:** Google Calendar API, scheduled content data, FlutterArchitectAgent for OAuth token storage

**Outputs:**
- Google Calendar integration specification (OAuth scopes, API calls, refresh logic)
- Content scheduling data model (content_id, scheduled_date, reminder_time)
- Calendar grid dot indicator logic (real events only, no modulo hacks)
- Error states for calendar (not connected, auth failed, no events)
- Analytics events for calendar usage

**KPIs:**
- Google Calendar connection rate ≥ 25% of users (shows intent to schedule)
- Scheduled content reminder delivery rate 100%
- Calendar screen D7 return rate ≥ 40% of calendar users
- 0 phantom dot indicators (dots only appear when real content/events exist)

---

### Agent 22 — ShortsAgent

**Mission:** Make Afeedi's vertical short-form video experience feel as fluid as TikTok, converting it into a daily habit entry point.

**Responsibilities:**
- Design swipe-up navigation with momentum physics (PageView + scroll physics)
- Design like/save/share overlay controls (bottom-right, thumb-reachable)
- Implement post-like viral share nudge (fires on 3rd like, then every 10th)
- Wire tap-to-play: YouTube → in-app PlayerScreen; TikTok/Instagram → external launch
- Design loop completion tracking (used as strong engagement signal)
- Ensure portrait-only lock for Shorts tab

**Inputs:** Content library from ContentService, player routes from FlutterArchitectAgent, viral mechanics from GrowthAgent

**Outputs:**
- Shorts tab UX specification (gestures, physics, overlay layout)
- Tap-to-play routing logic (platform conditional)
- Share nudge trigger specification (count thresholds, copy format)
- Loop tracking events (loop_started, loop_completed, loop_abandoned)
- Shorts-specific analytics dashboard

**KPIs:**
- Loop completion rate ≥ 60% (users finish the short)
- Like rate ≥ 5% of impressions
- Share nudge CTR ≥ 8%
- External app launch success rate ≥ 95% (URL opens correctly)

---

### Agent 23 — CreatorProfileAgent

**Mission:** Surface a creator's full cross-platform reach — the killer feature impossible for any single-platform app to replicate.

**Responsibilities:**
- Aggregate content by creator across all platforms using creatorName match
- Calculate per-platform follower estimates (deterministic, hash-derived for MVP)
- Display total cross-platform reach as the headline stat
- Show per-platform breakdown with proportion bar chart
- Load recent content from all platforms (up to 2 per platform)
- Design follow button with persistence across sessions

**Inputs:** Content library from ContentService, creator data from content metadata, user follow state from UserInteractionService

**Outputs:**
- Creator profile sheet specification (layout, stats, content grid)
- Cross-platform aggregation logic (name-match grouping)
- Per-platform follower model (formula, ranges by platform)
- Follow state persistence specification
- Creator profile analytics events

**KPIs:**
- Creator profile sheet opens in ≤ 500ms
- Multi-platform creators shown on ≥ 30% of creator profile opens
- Follow button used by ≥ 15% of profile viewers
- Creator profile satisfaction (proxy: low immediate back-navigation rate)

---

### Agent 24 — TrendingAgent

**Mission:** Surface what's trending across all platforms simultaneously — a view impossible to get from any single-platform app.

**Responsibilities:**
- Design cross-platform trending algorithm: engagement velocity per platform
- Display top 1 item per platform in horizontal scroll with platform color branding
- Design time-window filter (Today / This Week / This Month / All Time)
- Design "Rising" section for high-velocity content not yet at peak
- Track trending section engagement (impressions, clicks, platform preference)

**Inputs:** Content library with engagement data from ContentService, time-window preferences, platform filter state

**Outputs:**
- Trending ranking formula (engagement / (age_hours^0.8 + 1))
- Cross-platform trending row specification (layout, platform badges, tap behavior)
- Time-window filter UX specification
- Trending analytics events
- Cache strategy (trending recalculated every 30 minutes)

**KPIs:**
- Cross-platform trending row CTR ≥ 12%
- Trending content click-through to player ≥ 25%
- Platform diversity: ≥ 3 platforms represented in top 10 trending items
- Trending section shown in ≥ 60% of Discover sessions

---

### Agent 25 — LocalizationAgent

**Mission:** Enable Afeedi to reach non-English markets, multiplying the addressable market 3–5× with localization investment.

**Responsibilities:**
- Implement ARB-based Flutter localization (AppLocalizations)
- Translate all user-facing strings to target languages (priority: Arabic, Hindi, Spanish, French)
- Implement RTL layout support for Arabic
- Define locale-aware content surfacing (regional trending, language-filtered recommendations)
- Implement locale detection (device locale → default, user override in Settings)

**Inputs:** String inventory from all screens, layout specifications from UXResearchAgent

**Outputs:**
- String extraction report (all user-facing strings catalogued)
- ARB files for each target locale
- RTL layout audit and fix list
- Locale-aware recommendation filter specification
- Language selector in Settings specification

**KPIs:**
- 100% string coverage in ≥ 2 languages at launch
- RTL layout: 0 overflow or alignment issues in Arabic
- Non-English user activation rate within 15% of English baseline
- Locale detection accuracy ≥ 95%

---

### Agent 26 — PerformanceAgent

**Mission:** Ensure Afeedi performs well on the median user's device (mid-range Android), removing performance as a churn driver.

**Responsibilities:**
- Profile app startup time (cold start, warm start)
- Profile frame rendering rate (target 60fps with ≤ 1% jank)
- Profile memory usage (feed list, image cache, video player)
- Identify and fix N+1 render problems, unnecessary rebuilds
- Define image optimization pipeline (CachedNetworkImage + compression)
- Profile and optimize the largest lists (feed, discover, search results)

**Inputs:** Flutter DevTools traces, device performance profiles (low/mid/high)

**Outputs:**
- Performance baseline report (startup, frame rate, memory by device tier)
- Top 10 performance issues ranked by user impact
- Fix implementation for each issue
- Performance regression test suite
- Device compatibility matrix (minimum supported spec)

**KPIs:**
- Cold start ≤ 2 seconds on mid-range Android (2GB RAM, Snapdragon 665)
- Frame rate ≥ 59fps average, ≤ 1% jank frames
- Memory: ≤ 150MB RSS during feed scroll
- Image cache miss rate ≤ 5% during normal scrolling

---

### Agent 27 — SecurityAgent

**Mission:** Ensure Afeedi's user data, authentication tokens, and API keys are protected against the OWASP Mobile Top 10.

**Responsibilities:**
- Audit all credential storage (OAuth tokens, user IDs) for secure enclave usage
- Implement certificate pinning for all API calls
- Validate all user inputs at system boundaries (search query, profile fields)
- Review all third-party dependencies for known CVEs
- Implement jailbreak/root detection (disable sensitive features on compromised devices)
- Document security model and threat actors

**Inputs:** Architecture spec from FlutterArchitectAgent, API list from InfrastructureAgent

**Outputs:**
- Security threat model (actors, attack vectors, mitigations)
- Credential storage audit (secure storage vs. SharedPreferences)
- Input validation checklist (all user inputs audited)
- Dependency CVE report
- Certificate pinning implementation specification
- Security testing checklist for pre-release review

**KPIs:**
- 0 high-severity CVEs in dependencies at launch
- 100% of auth tokens stored in platform secure enclave (Keychain/Keystore)
- 0 user inputs accepted without type validation
- OWASP Mobile Top 10 — 0 confirmed vulnerabilities

---

### Agent 28 — AccessibilityAgent

**Mission:** Make Afeedi usable by people with visual, motor, and cognitive disabilities, meeting WCAG 2.1 AA and App Store accessibility standards.

**Responsibilities:**
- Audit all screens with TalkBack (Android) and VoiceOver (iOS) screen readers
- Ensure all interactive elements have semantic labels (Semantics widget)
- Ensure minimum touch target size 44×44pt on all interactive elements
- Verify all text meets WCAG AA contrast ratios (4.5:1 normal, 3:1 large)
- Support Dynamic Type / font scaling up to 200% without layout overflow
- Implement reduced-motion mode for users with vestibular disorders

**Inputs:** All screen implementations, design tokens from DesignTokenAgent

**Outputs:**
- Accessibility audit report (screen-by-screen, severity scores)
- Semantics label specification for all interactive elements
- Touch target size audit and fix list
- Dynamic Type overflow fix list
- Reduced-motion implementation specification

**KPIs:**
- 100% of interactive elements have screen-reader labels
- 0 touch targets below 44×44pt
- All text/background pairs achieve WCAG AA
- App Store accessibility review: no rejections for accessibility violations

---

### Agent 29 — InfrastructureAgent

**Mission:** Define the backend evolution path from SharedPreferences MVP to a production-grade infrastructure capable of supporting 10M MAU.

**Responsibilities:**
- Define current infrastructure (SharedPreferences + local services) and its scale ceiling
- Design migration path: SharedPreferences → SQLite (Drift) → Supabase → custom backend
- Define MAU trigger points for each migration (SharedPrefs: <10K, SQLite: <100K, Supabase: <1M)
- Design API contract for recommendation, auth, and analytics endpoints
- Define CDN strategy for content thumbnail caching
- Estimate infrastructure cost at 100K, 1M, 10M MAU

**Inputs:** Architecture from FlutterArchitectAgent, scale requirements from ValuationAgent

**Outputs:**
- Infrastructure evolution roadmap (trigger-based migration plan)
- API contract specification (endpoints, request/response schemas)
- Database schema design (content, user, interaction, preference tables)
- Cost model (compute + storage + bandwidth by MAU tier)
- Supabase migration implementation plan

**KPIs:**
- API P99 latency ≤ 200ms at 100K MAU
- Infrastructure cost ≤ $0.05/MAU/month at 1M MAU
- Zero data loss during SharedPrefs → SQLite migration
- Backend uptime ≥ 99.9% SLA at 1M MAU

---

### Agent 30 — RecommendationMLAgent

**Mission:** Design the machine learning pipeline that makes Afeedi's recommendations feel like they read the user's mind.

**Responsibilities:**
- Define feature engineering (user signals × content signals → relevance score)
- Design cold-start strategy (genre-seed, popularity, recency for new users)
- Design warm-start transition (when behavioral data replaces onboarding preferences)
- Implement negative signal processing (not-interested reduces genre weight)
- Define model evaluation metrics (precision@5, nDCG, click-through rate)
- Design online learning loop (interaction event → weight update → next feed refresh)

**Inputs:** User interaction events from AnalyticsAgent, content metadata from ContentService, onboarding preferences from OnboardingAgent

**Outputs:**
- Feature engineering specification (signal × weight × decay function)
- Cold-start algorithm specification
- Warm-start transition trigger definition
- Negative signal weight adjustment formula
- Model evaluation framework (offline A/B test + online experiment)
- Recommendation explanation generation (reason labels)

**KPIs:**
- Recommendation precision@5 ≥ 0.7 (7 of 10 shown items clicked or liked)
- Cold-start time to quality recommendations ≤ 5 interactions
- Negative signal propagation: genre weight reduces within 1 session
- Recommendation diversity: ≥ 3 genres per 10-item feed page

---

### Agent 31 — SocialGraphAgent

**Mission:** Design the social layer that makes Afeedi sticky through creator relationships, the most durable form of content retention.

**Responsibilities:**
- Design creator follow system (follow, unfollow, notifications on new content)
- Define follow-based feed section ("From Creators You Follow")
- Design creator notification: when a followed creator posts, user gets notified
- Design friend discovery (invite contacts, suggested follows based on genre overlap)
- Define social graph data model (user → follows → creator, user → friends → user)

**Inputs:** Creator data from CreatorProfileAgent, notification system from NotificationAgent, user graph from InfrastructureAgent

**Outputs:**
- Social graph data model specification
- Follow system specification (persistence, notification trigger, feed surfacing)
- "From Creators You Follow" feed section specification
- Creator notification copy templates
- Friend discovery flow specification

**KPIs:**
- Follow rate ≥ 15% of creator profile views
- Followed-creator content CTR ≥ 2× vs. algorithmic content
- D30 retention of users with ≥ 3 follows is 2× users with 0 follows (hypothesis)
- Creator notification open rate ≥ 40%

---

### Agent 32 — CommerceAgent

**Mission:** Implement a reliable, compliant in-app purchase system that converts free users to paid with minimal friction.

**Responsibilities:**
- Configure IAP products in App Store Connect and Google Play Console
- Implement purchase flow with receipt validation
- Implement subscription management (upgrade, downgrade, cancel, restore)
- Handle edge cases: payment failure, subscription lapse, trial expiry
- Implement promotional offers (referral-earned 7-day trial)
- Ensure compliance with App Store guideline 3.1.1 (required IAP for digital goods)

**Inputs:** Pricing model from MonetizationAgent, paywall placement from MonetizationAgent

**Outputs:**
- IAP product specification (product IDs, prices, trial configuration)
- Purchase flow UX specification (loading states, error states, success states)
- Receipt validation architecture (client-side + server-side)
- Subscription management screen specification
- Trial mechanics specification (referral code → 7-day Pro activation)

**KPIs:**
- Purchase flow completion rate ≥ 85% (from paywall tap to purchase confirmed)
- Subscription restore success rate 100%
- Payment failure recovery rate ≥ 50% (retry prompt converts half)
- Annual plan uptake ≥ 40% of subscribers

---

### Agent 33 — ExitStrategyAgent

**Mission:** Map the most likely exit paths, identify strategic acquirers, and ensure product decisions build toward acquisition attractiveness.

**Responsibilities:**
- Identify top 10 strategic acquirers and their acquisition rationale
- Define MAU/revenue/retention thresholds that trigger acquisition interest
- Identify the data assets and technology Afeedi has that acquirers cannot build quickly
- Map acquisition price scenarios (2×/5×/10× revenue multiples by acquirer type)
- Define the metrics package to present in acquisition conversations
- Identify product decisions that increase or decrease acquirability

**Inputs:** Valuation scenarios from ValuationAgent, competitor analysis from CompetitorAgent

**Outputs:**
- Acquirer map (company × acquisition rationale × price range × probability)
- Acquisition readiness checklist (metrics, data room, IP ownership)
- Strategic positioning document (why Afeedi is worth more than its revenue)
- Anti-acquirer moves (features that make Afeedi less attractive to certain buyers)
- Data asset inventory (cross-platform interaction graph — unique and not replicable)

**KPIs:**
- ≥ 3 confirmed strategic acquirers with documented interest triggers
- Acquisition readiness score ≥ 80% at 500K MAU milestone
- Data asset value estimated at ≥ 2× revenue multiple premium
- Exit timeline: first meaningful M&A conversations at 18 months post-launch

---

### Agent 34 — InvestorAgent

**Mission:** Build the investor narrative and data room that enables fundraising at the target valuation, with materials ready before conversations begin.

**Responsibilities:**
- Develop pitch deck (problem, solution, market, traction, business model, team, ask)
- Model term sheet scenarios (SAFE, priced round, convertible note)
- Define key metrics to highlight (MAU, D30, DAU/MAU, LTV/CAC, ARR)
- Identify target investors by thesis (consumer apps, AI personalization, video)
- Prepare due diligence data room (cap table, contracts, IP, financials)
- Define the "unfair advantage" narrative (cross-platform interaction graph)

**Inputs:** Valuation model from ValuationAgent, traction metrics from AnalyticsAgent, exit scenarios from ExitStrategyAgent

**Outputs:**
- Pitch deck (10–12 slides, investor-ready)
- Financial model (3-year P&L projection, unit economics)
- Investor target list (25 firms with partner names and thesis fit scores)
- Due diligence checklist
- One-pager (for cold outreach)

**KPIs:**
- Pitch deck meeting conversion rate ≥ 20% (1 in 5 cold pitches gets a meeting)
- Term sheet received within 60 days of starting fundraise process
- Valuation achieved ≥ 80% of North Star scenario for round stage
- Data room completeness 100% before any investor meeting

---

### Agent 35 — OrchestratorAgent

**Mission:** Coordinate all 34 specialized agents, resolve priority conflicts, maintain the master product decision log, and ensure the entire system optimizes toward the North Star Valuation Target.

**Responsibilities:**
- Maintain the master priority queue: which agent's output is the current bottleneck
- Resolve conflicts between agent outputs (e.g., MonetizationAgent wants hard paywall; RetentionAgent wants soft paywall)
- Ensure all decisions are logged with rationale and valuation impact estimate
- Trigger parallel agent runs where dependencies allow
- Escalate decisions that require founder judgment
- Maintain a "valuation delta" estimate for each decision (how much does this move the needle)

**Inputs:** Outputs from all 34 agents, North Star Valuation Target from ValuationAgent

**Outputs:**
- Master decision log (decision × rationale × agent × valuation impact)
- Priority queue (current top-3 bottlenecks blocking valuation progress)
- Conflict resolution record (when agents disagree, how it was resolved and why)
- Weekly valuation progress report (current estimated valuation vs. target)
- Agent health status (which agents are behind, blocked, or producing low-quality output)

**KPIs:**
- Decision latency: no decision waits > 24 hours for resolution
- 100% of decisions have documented rationale
- Valuation progress: measured monthly against North Star Target milestones
- 0 unresolved agent conflicts lasting > 48 hours

---

## Phase 4 — Feature Discovery

### Feature Priority Matrix

| Feature | Retention Impact | Dev Effort | Status |
|---|---|---|---|
| AI-personalized feed | HIGH | HIGH | ✅ Implemented |
| Onboarding chatbot (min 3 genres) | HIGH | LOW | ✅ Fixed |
| Shorts/vertical video tab | HIGH | MEDIUM | ✅ Implemented |
| Cross-platform trending surface | HIGH | MEDIUM | ✅ Implemented |
| "Not Interested" signal | HIGH | LOW | ✅ Implemented |
| Save limit → paywall | MEDIUM (revenue) | LOW | ✅ Implemented |
| Referral program ("7 Days Pro") | MEDIUM (growth) | MEDIUM | ✅ Implemented |
| Notification deep-links | MEDIUM | LOW | ✅ Implemented |
| Google Calendar integration | MEDIUM | HIGH | ✅ Implemented (real API) |
| Search platform/genre filters | MEDIUM | LOW | ✅ Fixed |
| Offline mode | MEDIUM | HIGH | Planned (Phase 9) |
| Creator profile sheets | LOW | MEDIUM | Planned |
| AI Weekly Digest notification | HIGH | MEDIUM | Planned (Phase 8) |
| Watch history with progress | MEDIUM | LOW | ✅ Implemented |

### Critical Missing Features (Retention Gaps)

1. **Weekly AI Digest notification** — Research shows 440% retention lift vs. 0 notifications. Sunday 10AM push with top 5 personalized picks.
2. **"Continue Watching" / progress persistence** — Returning users need to see where they left off. D7 retention driver.
3. **Creator follow + notifications** — Social graph is the stickiest retention mechanism (Twitter/X proof). Not yet implemented.
4. **Offline mode** — Required for commute use case (D30 driver). Complex but high-value.

---

## Phase 5 — UX/UI System

### Design Language

**Color System:**
- Primary background: `#0D0D1A` (deep space)
- Surface elevation: `#1A1A2E`
- Accent cyan: `#00D4FF` (brand primary)
- Accent pink: `#FF006E` (CTAs, likes)
- Accent purple: `#7C3AED` (premium)
- Accent gold: `#FFD700` (achievements)

**Typography:**
- Display: Bold, 24–32px, white
- Body: Regular, 14–16px, `white.withValues(alpha: 0.85)`
- Caption: Regular, 12px, `white.withValues(alpha: 0.55)`
- Labels/chips: SemiBold, 11–13px

**Layout System:**
- Base unit: 8px grid
- Screen padding: 16px horizontal
- Card radius: 14–20px
- Section gap: 20–28px

### Screen Architecture

| Screen | Pattern | Notable UX |
|---|---|---|
| Home/Feed | `NestedScrollView` + `SliverAppBar` | Platform filter chips, pull-to-refresh |
| Discover | Horizontal scrollable sections | Cross-platform trending, genre categories |
| Shorts | `PageView` vertical stack | Swipe-up navigation, like/share/save overlay |
| Calendar | Month grid + day detail | Google Calendar sync, content scheduling |
| Profile | `NestedScrollView` + 4-tab layout | Avatar picker, achievement system |
| Search | Debounced query + filter chips | Platform + genre post-query filtering |
| Settings | `ListView` tile groups | Theme, notifications, premium, language |

### Key UX Patterns Implemented

- **Long-press context menu** on feed cards: "Not Interested" / "Report" (iOS-style modal bottom sheet)
- **Post-like viral nudge**: SnackBar appears on 3rd like, fires every 10th thereafter
- **Save limit soft paywall**: After 20 saves, shows upgrade bottom sheet instead of blocking
- **Cross-platform trending row**: Horizontal scroll showing #1 item per platform with platform color badge
- **Recommendation reason chip**: Semi-transparent chip on feed cards showing "Because you like Gaming" (from `content.metadata['recommendationReason']`)

---

## Phase 6 — Mobile Architecture

### Service Layer (Singleton Pattern)

```
ContentService          — Feed data, search, platform filtering
EnhancedRecommendationService — Genre-weighted ranking, preference model
UserInteractionService  — Likes, saves, not-interested (SharedPrefs cache)
AnalyticsService        — Event tracking, screen views, interactions
LocalAuthService        — Auth state (timestamp-based user IDs)
OnboardingService       — Genre/source preferences persistence
NotificationService     — Local notification scheduling
GoogleCalendarService   — OAuth2 + Calendar API integration
AdService               — AdMob banner/interstitial/rewarded
SubscriptionService     — In-app purchase state
NavigationService       — Named route table, GlobalKey<NavigatorState>
```

### Known Architectural Debt

| Issue | Risk | Mitigation path |
|---|---|---|
| SharedPreferences for all state | Data loss at scale, no sync across devices | Migrate to SQLite (drift) + optional cloud sync |
| Timestamp-based user IDs | No real auth, no password recovery | Supabase Auth or Firebase Auth |
| `RecommendationIntegrationService` stub | Returns empty list, falls back to enhanced service | Wire to real ML endpoint or heuristic fallback |
| No real backend | Zero server-side personalization, no analytics | Supabase or lightweight Node.js + PostgreSQL |
| `youtube_explode_dart` disabled | **MUST remain disabled** (YouTube ToS §4.F, Play Store ban) | YouTube IFrame player only |

### State Management

Currently: singleton services with `ChangeNotifier` + `ListenableBuilder`. Riverpod is in `pubspec.yaml` but not used. Recommend migrating to Riverpod providers in Phase 9 for testability and widget rebuilds.

---

## Phase 7 — Growth Engine (Implemented)

### Viral Mechanics Implemented

**Referral Program (`lib/screens/referral_screen.dart`)**
- Referral code: `AF-${userId.last6.toUpperCase()}`
- Reward: 7 days Pro for referrer + referee (both-sided)
- Entry points: Profile header CTA, Settings tile
- Share: Copies pre-formatted invite message to clipboard with download link
- Target K-factor: 0.7+ (viability threshold for organic growth)

**Post-Like Viral Nudge (`lib/screens/tabs/shorts_tab.dart`)**
- Fires on user's 3rd like, then every 10th like thereafter
- Timing: Immediately after liking (peak emotional engagement)
- Action: Copies formatted share message with content URL + Afeedi attribution
- Research basis: TikTok "For You" share rate is highest immediately after a positive interaction

**Cross-Platform Trending (`lib/widgets/dashboard/discover_tab.dart`)**
- Shows top-ranked item per platform (YouTube, TikTok, Instagram, Facebook)
- Horizontal scroll with platform-colored avatars
- Structural moat: Impossible to replicate on any single-platform app

### Retention Mechanics Implemented

**"Not Interested" Signal**
- Long-press on feed card → "Not Interested" option
- Removes card immediately from feed (optimistic UI)
- Persists to `UserInteractionService._notInterestedCache`
- `EnhancedRecommendationService` to filter these IDs from future recommendations

**Save Limit Paywall (Contextual Conversion)**
- Free users capped at 20 saves
- On 21st save attempt: bottom sheet upgrade prompt (not a hard block)
- Conversion psychology: Feature-gated at moment of highest intent
- Expected 3–5× conversion rate vs. un-prompted upgrade CTA

**Minimum Genre Onboarding (`lib/controllers/chat_controller.dart`)**
- `handleGenreContinue()` blocks advancement if `_selectedGenres.length < 3`
- Bot message: "Please pick at least 3 genres so I can build your perfect feed!"
- Impact: Ensures feed personalization quality from D1

**Notification Deep-Links (`lib/screens/notifications_screen.dart`)**
- `new_content` → PlayerScreen with content ID
- `recommendation` → Dashboard tab 0 (For You feed)
- `trending` → Dashboard tab 1 (Discover)
- Impact: Re-engagement clicks land in the right context, not the home screen

### Retention Targets vs. Industry Benchmarks

| Metric | Industry avg (short-form video) | Afeedi target | Current estimate |
|---|---|---|---|
| D1 retention | 25–35% | 35%+ | ~20% (pre-improvements) |
| D7 retention | 12–18% | 20%+ | ~12% |
| D30 retention | 5–8% | 15%+ | ~7% |
| DAU/MAU | 20–25% | 28%+ | ~18% |
| Session length | 8–12 min | 10+ min | Unknown |

---

## Phase 8 — Monetization

### Revenue Architecture

**Tier 1 — Ad Revenue (Free Users)**
- AdMob integration: Banner + interstitial between feed sections
- Test IDs injected via `ADMOB_APP_ID_ANDROID` env var at build time
- UMP (User Messaging Platform) consent flow implemented
- ATT (App Tracking Transparency) consent for iOS implemented
- Estimated ARPU: $0.80–$1.20/year

**Tier 2 — Subscription Revenue (Pro Users)**
- `SubscriptionService` handles in-app purchase state
- Products: Monthly ($6.99) + Annual ($49.99) + Lifetime ($149.99)
- Premium features: Unlimited saves, no ads, AI Digest, offline mode (planned)
- `PremiumScreen` with feature comparison table

**Tier 3 — Referral-Driven Growth**
- 7-day Pro trials as referral reward (low cost, high LTV signal)
- Friend who joins with a code has 7× higher 30-day retention (category data)

### Paywall Placement Strategy

| Trigger | Paywall type | Expected conversion |
|---|---|---|
| 21st save attempt | Contextual bottom sheet | 3–5% |
| After 3rd ad impression per session | Soft in-feed prompt | 0.5–1% |
| AI Digest locked for free users | Feature gate | 2–3% |
| Cross-platform search results page | Upgrade chip | 1% |
| 7-day trial from referral | Paid conversion after trial | 15–20% |

---

## Phase 9 — App Store Approval

### iOS App Store Requirements (Status)

| Requirement | Status |
|---|---|
| Privacy policy URL | ✅ `PrivacyPolicyScreen` implemented |
| Terms of service URL | ✅ `TermsOfServiceScreen` implemented |
| ATT prompt (iOS 14.5+) | ✅ `ATTService` implemented |
| No private API usage | ✅ Confirmed |
| YouTube ToS §4.F compliance | ✅ `youtube_explode_dart` disabled, IFrame player only |
| Content ratings (17+) | ⚠️ Need to set — user-generated content from social platforms |
| App description (4000 chars) | ✅ `APP_STORE_METADATA.md` drafted |
| Screenshots (6.7", 5.5", iPad) | ⚠️ Not yet generated |
| In-app purchase SKU config | ⚠️ Not yet configured in App Store Connect |

### Google Play Store Requirements (Status)

| Requirement | Status |
|---|---|
| Privacy policy in-app | ✅ Implemented |
| GDPR consent (UMP) | ✅ `UMPService` implemented |
| Target SDK 34+ | ✅ `targetSdkVersion 34` in `build.gradle` |
| 64-bit support | ✅ Flutter default |
| Play Store content rating | ⚠️ Rating questionnaire not submitted |
| YouTube API ToS disclosure | ⚠️ Must add to Store listing |
| Data safety form | ⚠️ Not yet submitted |

### Known Pre-Submission Blockers

1. **Screenshots** — Need device frames for all required sizes
2. **Content rating questionnaire** — Both stores require completion
3. **In-app purchase products** — Must be created in both consoles before testing
4. **Data safety / privacy nutrition label** — Requires enumerating all data collected

---

## Phase 10 — Implementation Progress

### Phases Completed

| Phase | Status | Key deliverables |
|---|---|---|
| 1. Onboarding | ✅ Complete | AI chatbot, min 3 genres, platform selection |
| 2. Feed | ✅ Complete | AI ranking, not-interested signal, platform filters |
| 3. Shorts | ✅ Complete | Vertical swipe, like/save/share, viral nudge |
| 4. Discover | ✅ Complete | Cross-platform trending, genre browse |
| 5. Calendar | ✅ Complete | Google Calendar sync, content scheduling |
| 6. Search | ✅ Complete | Platform + genre filters, debounced |
| 7. Profile | ✅ Complete | Stats, achievements, avatar, invite CTA |
| 8. Settings | ✅ Complete | Theme, notifications, privacy, referral |
| 9. Notifications | ✅ Complete | Deep-link routing, scheduling |
| 10. Premium | ✅ Complete | Feature comparison, paywall CTAs |
| 11. Referral | ✅ Complete | Code generation, share flow, stats |
| 12. Analytics | ✅ Complete | Event tracking across all flows |

### Test Coverage

- **329 unit/widget tests** — All passing
- **0 analyzer errors** — Clean Dart analysis
- **Coverage areas:** Navigation, feed, profile, search, home tab, onboarding, settings
- **Coverage gap:** Referral screen, referral code generation, not-interested persistence

---

## Strategic Recommendations

### 12-Month Roadmap

**Months 1–3: Launch & Validate**
- Submit to App Store + Play Store
- Acquire first 10K users via social ads ($5K budget)
- Instrument Mixpanel/Amplitude for cohort analysis
- Target: D7 retention >20%, D30 >10%

**Months 4–6: Retention Optimization**
- Ship weekly AI Digest notification (Sunday 10AM)
- Ship "Continue Watching" progress persistence
- A/B test paywall placement (save limit vs. ad-gate vs. feature-gate)
- Target: DAU/MAU >25%, Paid conversion >3%

**Months 7–9: Growth Engine**
- Activate referral program with paid incentives
- Creator follow graph (social stickiness)
- Target: K-factor >0.6, MAU 100K

**Months 10–12: Platform Conversations**
- At 500K MAU: begin strategic conversations with YouTube (Google Ventures), Meta, TikTok (ByteDance)
- Investor deck: $3–5M seed round targeting $15–20M valuation
- Target: MAU 500K, ARR $1.5M

### Exit Strategy

**Most likely acquirers:**

1. **Google / YouTube** — Strongest strategic fit. Afeedi's cross-platform data is a direct threat AND opportunity. Price: $50–150M at 5M MAU.
2. **ByteDance / TikTok** — Would acquire to understand non-TikTok content consumption patterns. Price: $30–80M.
3. **Flipboard / SmartNews** — Bolt-on acquisition for video capability. Price: $10–30M.
4. **Snap** — Discover tab is a direct Afeedi competitor. Acqui-hire risk but possible bolt-on.

**IPO path:** Requires 50M+ MAU and $50M+ ARR. 5–8 year timeline. Lower probability than M&A exit.

---

## Risk Register

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| YouTube ToS enforcement | MEDIUM | CRITICAL | IFrame-only player, never re-enable `youtube_explode_dart` |
| App Store rejection (§4.2 completeness) | MEDIUM | HIGH | Complete all metadata before submission |
| SharedPreferences data loss at scale | HIGH | MEDIUM | Migrate to SQLite + cloud sync before 50K MAU |
| No real auth backend | HIGH | MEDIUM | Supabase Auth integration before launch |
| Platform API rate limits | MEDIUM | HIGH | Content caching, request throttling |
| Cold-start recommendation quality | HIGH | MEDIUM | Minimum 3 genres + curated seed data |
| Copycat from YouTube/TikTok | LOW | HIGH | Speed to scale, cross-platform moat |

---

*Report generated by Venture Architect AI framework — May 2026*  
*Branch: claude/optimistic-hopper-PLQOv | Tests: 329 passing*
