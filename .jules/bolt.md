## 2026-05-11 - Content Aggregation Bottleneck
**Learning:** The `ContentAggregationService` was fetching content sequentially, creating an O(N) bottleneck where N is the number of connected platforms. This is a common performance issue in aggregate feeds, which can be mitigated with `Future.wait`.
**Action:** When aggregating multiple independent remote data sources in Dart, always use `Future.wait` to retrieve data concurrently rather than iterating sequentially with `await` in a `for` loop.
