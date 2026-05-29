# Third-Party Content Compliance Guide

## CRITICAL: youtube_explode_dart is DISABLED

`youtube_explode_dart` scrapes YouTube's internal endpoints without using the official API.
YouTube's Developer Policies (Section "Prohibited Actions") explicitly state:
> "API Clients must not scrape YouTube Applications or obtain scraped YouTube data or content."

**Risk if enabled: immediate Play Store removal + potential legal action. Do not re-enable.**

### Required replacement: YouTube Data API v3
1. Create a project at https://console.cloud.google.com
2. Enable "YouTube Data API v3"
3. Create an API key (restrict to Android/iOS app bundle IDs)
4. Replace `YouTubeLiveContentService` with calls to:
   - `GET https://www.googleapis.com/youtube/v3/videos?part=snippet,statistics&chart=mostPopular&key=YOUR_KEY`
   - `GET https://www.googleapis.com/youtube/v3/search?part=snippet&q=QUERY&type=video&key=YOUR_KEY`
5. Free tier: 10,000 quota units/day (sufficient for up to ~1,000 search queries)

---

## Platform-by-Platform Legal Status

### YouTube ✅ COMPLIANT (IFrame embeds)
- `youtube_player_iframe` wraps Google's official IFrame Player API — **legally approved**
- Attribution: show YouTube logo/branding per item in the feed
- Thumbnails: fetch via YouTube Data API v3 `snippet.thumbnails` — not direct `img.youtube.com` hotlinking
- Autoplay: must be disabled until user initiates (required by YouTube ToS Section III.E.4)
- Player size: minimum 200×200px; must not suppress YouTube's own controls

### Instagram/Facebook ⚠️ REQUIRES META APP REVIEW
**Status: Instagram Basic Display API shut down December 4, 2024. Dead.**

To show Instagram/Facebook content:
1. Register at https://developers.facebook.com
2. Create an app, add "oEmbed Read" use case
3. Submit for Meta App Review (1–3 week timeline)
4. Only after approval: use Meta oEmbed Read API with app access token

**Until approval is granted:** Show Instagram/Facebook posts as link-out only (open in browser/app).
**Current implementation:** Shows TikTok/Instagram as link-out → this is correct and legally safe.

### TikTok ⚠️ LINK-OUT ONLY (no public API for anonymous browsing)
- TikTok Display API requires OAuth user token — only shows content from users who authorized your app
- No anonymous public feed browsing API exists
- **Safe approach (already implemented):** Show TikTok thumbnails/metadata from our seed data + link-out to TikTok app for playback
- For future: register at https://developers.tiktok.com, submit Display API access request

### Instagram Reels ⚠️ SAME AS INSTAGRAM ABOVE
- Reels fall under the same oEmbed Read requirement
- Safe interim: show Reels as link-out to Instagram app

---

## Summary: What to Do Before App Store Submission

| Action | Platform | Timeline | Blocks Launch? |
|--------|----------|----------|----------------|
| Get YouTube Data API v3 key | YouTube | 1 hour | YES — for live content |
| Register Meta Developer App | Instagram + Facebook | 1 day | NO — link-out is safe fallback |
| Submit Meta App Review | Instagram + Facebook | 1-3 weeks | NO — link-out works |
| Register TikTok Developer Portal | TikTok | 1-2 weeks | NO — link-out already works |
| Remove youtube_explode_dart | YouTube | DONE | Already disabled in code |

**Minimum for launch:** Get YouTube Data API v3 key. Everything else can ship as link-out.
