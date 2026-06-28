## 2024-06-15 - Content Aggregation Concurrency
**Learning:** In Dart, when preparing multiple asynchronous operations for concurrent execution via `Future.wait()`, use idiomatic collection `for` loops inside the `Future.wait()` list literal with Immediately Invoked Function Expressions (IIFEs) for error handling, instead of sequential loops.
**Action:** Apply `Future.wait([for (var x in list) () async { try { return await fetch(x); } catch (e) { return fallback; } }() ])` pattern in `ContentAggregationService` to improve performance.
