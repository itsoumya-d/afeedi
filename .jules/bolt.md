## 2024-07-01 - [Sequential Network Requests Anti-Pattern]
**Learning:** The `ContentAggregationService` in this codebase was fetching content from multiple platforms sequentially in a `for` loop, causing total fetch time to grow linearly with the number of connected platforms.
**Action:** When aggregating data from multiple independent remote sources, always use `Future.wait()` with a collection `for` loop and an async IIFE for error handling to execute the requests concurrently, significantly reducing total wait time.
