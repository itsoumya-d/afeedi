## 2024-05-24 - [Optimize Platform View Registration]
**Learning:** Initializing multiple platform views (like 30+ iframes for YouTube, Instagram, TikTok, etc.) sequentially using `await` in a loop creates a significant initialization bottleneck, delaying app startup and responsiveness on the web.
**Action:** Always collect independent `Future`s (like individual view registrations) into a `List` and execute them concurrently using `Future.wait()` when initializing bulk resources or services.
