## 2024-06-07 - Sequential Platform Content Fetching
**Learning:** `ContentAggregationService.aggregateContent` was fetching content from connected platforms sequentially in a loop, which caused total fetch time to scale linearly with the number of connected platforms. By leveraging `Future.wait()`, we can parallelize these network calls to dramatically reduce load times.
**Action:** Always use `Future.wait()` mapped to an `.toList()` evaluated list of futures when aggregating independent network data across multiple sources.
