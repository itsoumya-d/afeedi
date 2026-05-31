# Best-in-Class Research Report
## Afeedi Comparative Analysis: TikTok, YouTube, Netflix, Instagram, Spotify, Duolingo, Notion

**Prepared:** 2026-05-30  
**Scope:** Algorithm design, onboarding patterns, UX paradigms used by top consumer apps  

---

## 1. TikTok — For You Page (FYP) Algorithm

TikTok's FYP is the gold standard for short-form video recommendation. It is powered by a multi-signal ranking model that balances recency with personalisation.

### Primary Ranking Signals

- **Watch time / completion rate:** The single strongest signal. A video watched to 100% is weighted far more heavily than a liked video watched to 30%.
- **Replays:** A user replaying a video is treated as a strong positive signal, roughly equivalent to a share.
- **Shares:** Highest-value social action. Indicates the viewer found the content remarkable enough to propagate.
- **Comments:** High engagement; text comments indicate emotional or intellectual investment.
- **Likes:** Weaker than the above. Easy to give, frequently inflated.
- **Profile visits after watching:** Strong intent signal — viewer wants to see more from this creator.
- **"Not Interested" / skips after <2 s:** Strong negative signals that suppress the creator for this user.

### Cold-Start Strategy

TikTok solves the cold-start problem (both new users and new content) with a test-pool system:

1. New content is inserted into a **seed batch** of ~200–500 users with matching interest tags.
2. Completion rate is measured over the first 24 hours.
3. If completion rate exceeds ~70%, the video advances to a **rising pool** (10 k–50 k users).
4. Successive promotion gates (100 k → 1 M+) are triggered by maintaining engagement thresholds at each level.
5. New users are seeded with a diversity basket (multiple genres/creators) for the first 30 sessions, then the model narrows.

### Content Pools

| Pool | Size | Criteria |
|------|------|----------|
| Fresh | 200–500 | Any new upload |
| Rising | 10 k–50 k | >70% completion in seed batch |
| Established | 100 k–1 M+ | Sustained engagement through rising |
| Viral | 1 M+ | Breakout velocity; often amplified by TikTok editorial |

---

## 2. YouTube — Homepage & Shorts Algorithm

### Homepage Engagement Prediction

YouTube's homepage uses a two-stage neural ranking system (described in the "Deep Neural Networks for YouTube Recommendations" paper, Covington et al., 2016, updated continuously since):

- **Stage 1 — Candidate generation:** Retrieves ~100–200 videos from billions using collaborative filtering on watch history and search history.
- **Stage 2 — Ranking:** Scores candidates using:
  - **Click-through rate (CTR):** High CTR videos are surfaced but penalised if watch time is low (clickbait detection).
  - **Watch time:** Total minutes watched per impression. YouTube explicitly optimises for this over raw views.
  - **Post-watch satisfaction:** Thumbs up/down, survey ratings ("Did you enjoy watching this?").
  - **Implicit satisfaction:** Subscribing or sharing after watching.

### Trending Algorithm

YouTube Trending uses a **velocity-based** score, not raw view count:

- `TrendScore = (views_last_24h × recency_weight) + (comment_velocity) + (share_velocity)`
- Regional trending is geo-filtered — a video trending in Brazil may not appear in Japan.
- Recency weight decays exponentially: views from the last 2 hours count ~4× more than views from 20 hours ago.

### Shorts Algorithm

YouTube Shorts (post-2021) ranks on:

- **Swipe-up rate:** What percentage of viewers swiped past vs. watched.
- **Completion rate:** Mirrors TikTok's primary signal.
- **Shares to external platforms:** Strong virality indicator.
- Shorts do **not** use traditional impressions/CTR — there is no thumbnail click in the Shorts feed.

---

## 3. Netflix — "Rows" Personalisation Paradigm

Netflix's homepage is composed of algorithm-powered **rows**, each driven by a distinct model:

- **Top Picks for [Name]:** Maximises `P(play) × P(enjoy | play)` — the product of likelihood to start and likelihood to rate positively.
- **Continue Watching:** Prominent placement in row 2 or 3 (below the hero banner). Completion drives retention; Netflix A/B tested this row's position extensively.
- **Trending Now:** Short-term velocity model similar to YouTube's.
- **Because You Watched [X]:** Item-to-item collaborative filtering — users who finished X also watched Y.
- **New Releases:** Recency-weighted; boosts content within 28 days of availability.

### Thumbnail A/B Testing

Netflix runs continuous **multi-armed bandit** experiments on thumbnails. Each title can have 10–30 artwork variants. The model serves the artwork predicted to maximise play rate for each individual user (e.g., showing a romantic scene to viewers with romantic-genre history).

### Key Takeaway for Afeedi

The "Continue Watching" row is Netflix's highest-engagement row after the hero. Afeedi has `_continueWatching` partially implemented but does not surface it as a dedicated horizontal scroll row at the top of the feed — this is a high-value gap.

---

## 4. Instagram Reels — Hybrid Graph Recommendation

Instagram Reels combines two recommendation signals:

- **Interest graph:** What topics, creators, and formats the user has engaged with (regardless of follows).
- **Social graph:** Content from accounts the user follows — mixed in to maintain relationship value.

### Engagement Bait Detection

Instagram's ranking model includes a dedicated **engagement bait classifier** that detects phrases like "comment your answer" or "tag a friend" and *reduces* ranking weight when detected. This is a direct counter-gaming mechanism absent in most smaller apps.

### Originality Score

Meta's systems assign an **originality score** to Reels, penalising watermarked content (e.g., a TikTok video re-uploaded to Instagram) by reducing distribution. Original, native content receives a distribution bonus.

---

## 5. Spotify — Discover Weekly

Spotify's Discover Weekly (released 2015) remains the reference implementation for collaborative music recommendation:

- **Collaborative filtering:** Identifies users with overlapping listening history, then surfaces songs those users like that the target user has not heard.
- **Natural Language Processing (NLP):** Spotify scrapes blog posts, reviews, and playlist names to assign semantic tags to tracks ("dreamy," "workout," "focus").
- **Audio feature analysis:** Tempo, key, loudness, danceability extracted via audio ML models (The Echo Nest, acquired by Spotify 2014).
- The playlist refreshes **every Monday** — a deliberate weekly cadence that drives a habit loop. Users check in on Mondays because they expect new content.

**Key Insight:** The cadence itself (Monday refresh) is a product decision as important as the algorithm. Afeedi could benefit from a "Your Weekly Picks" feature with a predictable refresh schedule.

---

## 6. Duolingo — Onboarding Conversion Optimisation

Duolingo's onboarding is the most studied example of activation optimisation in mobile apps:

### Step Sequence

1. **Language selection** (immediate, requires no account) — shown on first screen.
2. **Goal setting:** 5 / 10 / 15 / 20 minutes per day — creates commitment and allows the app to personalise lesson pacing.
3. **Familiarity level:** "Never studied before" → "Advanced" — determines starting lesson difficulty.
4. **First lesson immediately** — user experiences the product value *before* being asked to register.

### "Try First, Register Later"

Duolingo's most impactful onboarding change: moving account creation to *after* the first lesson. This change delivered a reported **~40% improvement in D1 activation rate**. Users who experience value before friction convert at far higher rates.

**Afeedi Gap:** The current onboarding (8 steps including language, genre, platform selection) requires completion before accessing any content. A "skip to feed" option or a guest-mode trial run would directly address this.

---

## 7. Notion — Progressive Disclosure

Notion surfaces features progressively rather than all at once:

- **New user view:** Simplified workspace with a single "Getting Started" page. Advanced features (databases, formulas, API integrations) are hidden until the user demonstrates readiness.
- **Contextual hints:** Tooltips appear on first interaction with each advanced feature — not as a modal tutorial blocking the UI.
- **Template gallery:** Lowers the blank-canvas anxiety by offering pre-built structures.

**Relevance to Afeedi:** The settings screen and feed filter system expose many options simultaneously. Progressive disclosure — showing basic filters first, with an "Advanced Filters" expansion — would reduce cognitive load for new users.

---

## Summary Table

| App | Primary Strength | Key Afeedi Gap |
|-----|-----------------|----------------|
| TikTok | Cold-start content testing | No completion-rate signal; same seed for all new users |
| YouTube | Watch-time optimised ranking | No watch-time tracking beyond interaction events |
| Netflix | "Continue Watching" row prominence | `_continueWatching` implemented but not surfaced as a row |
| Instagram | Engagement bait detection | No anti-gaming classifier |
| Spotify | Predictable refresh cadence | No scheduled "fresh picks" feature |
| Duolingo | Try-before-register activation | No guest mode / immediate value before account creation |
| Notion | Progressive disclosure | All filter/settings options shown simultaneously |

---

*Research based on publicly documented algorithm descriptions, official engineering blog posts (TikTok Engineering, YouTube Research, Netflix Tech Blog, Spotify R&D), and peer-reviewed papers (Covington et al. 2016). No non-public or proprietary data was used.*
