## 2024-06-03 - Concurrent Network Requests
**Learning:** Sequential network requests in `aggregateContent` of `ContentAggregationService` created a performance bottleneck by making `_fetchPlatformContent` run consecutively.
**Action:** Use `Future.wait` for fetching data from multiple platforms concurrently to reduce total network latency.
