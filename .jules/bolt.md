## 2026-06-21 - [Concurrent Platform Content Fetching]
**Learning:** Platform content fetch calls were executed sequentially in `ContentAggregationService.aggregateContent`, causing N API wait times instead of 1.
**Action:** Use `Future.wait()` with an idiomatic collection `for` loop and inner `try-catch` with `return await` to fetch all platforms concurrently without failing the whole batch if one fails.
