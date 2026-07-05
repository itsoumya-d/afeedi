## 2024-07-05 - [Concurrent API Fetching in Aggregation Service]
**Learning:** Sequential network calls for each connected platform inside `ContentAggregationService` create a massive performance bottleneck. In Dart, complex asynchronous operations with error handling can be executed concurrently by using `Future.wait()` alongside an Immediately Invoked Function Expression (IIFE) within a collection `for` loop.
**Action:** Always prefer `Future.wait([for (var x in list) () async { ... }() ])` over sequential `for` loops when dealing with independent API requests to minimize total load time.
