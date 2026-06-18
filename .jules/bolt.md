## 2026-06-18 - Concurrent Content Fetching in Aggregation Service
**Learning:** In `ContentAggregationService`, fetching content sequentially from multiple platforms created a bottleneck, especially as the number of connected platforms grew. Each platform fetch awaited the previous one's completion.
**Action:** Refactored the content aggregation loop to use `Future.wait(connections.map(...).toList())` with `try-catch` inside the map to allow concurrent fetching across platforms, significantly reducing total load time without failing the entire operation if one platform errors.
