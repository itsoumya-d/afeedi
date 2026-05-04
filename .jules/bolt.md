## 2024-05-04 - [Parallelizing Network Requests]
**Learning:** Sequential network `await` calls inside `for` loops in the `ContentAggregationService` act as a significant performance bottleneck by summing up latencies rather than letting the requests occur simultaneously.
**Action:** Always favor `Future.wait()` over sequential `await` loops for independent asynchronous operations, like aggregating data from multiple platforms.
