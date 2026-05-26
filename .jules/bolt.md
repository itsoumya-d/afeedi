## 2024-05-26 - Fetching external platform content concurrently
**Learning:** Sequential network calls during aggregation bottlenecks the overall service, especially since we are fetching from multiple diverse platforms (YouTube, TikTok, Facebook, Instagram) that each have varied latency characteristics (300-600ms).
**Action:** Use `Future.wait` combined with `.map().toList()` and `.catchError` to execute the fetching methods concurrently, reducing overall latency to the slowest single platform call instead of the sum of all latencies, while isolating failures gracefully.
