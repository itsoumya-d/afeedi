## 2024-07-04 - [Concurrent Fetching in Content Aggregation]
**Learning:** Sequential network requests in loops create severe N+1 bottlenecks. Dart requires an async Immediately Invoked Function Expression (IIFE) within collection for loops inside `Future.wait` to properly handle individual platform errors without aborting the entire aggregation.
**Action:** Use `Future.wait([for (var x in list) () async { try { ... } catch { ... } }() ])` instead of sequential `for` loops when fetching data from multiple independent sources.
