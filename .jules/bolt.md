## 2024-07-01 - [Concurrent Platform Fetching]
**Learning:** The `ContentAggregationService` fetched platform content sequentially in a `for` loop, causing a performance bottleneck where total wait time equaled the sum of all platform API latencies.
**Action:** Use `Future.wait()` with an Immediately Invoked Function Expression (IIFE) inside a collection `for` loop to execute independent asynchronous fetches concurrently, wrapping each in a `try-catch` to prevent a single platform's failure from aborting the entire process.
