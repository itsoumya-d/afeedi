## 2024-05-05 - Concurrent Platform Content Aggregation
**Learning:** Sequential `await` statements inside `for` loops during network calls (e.g. fetching content from multiple platforms sequentially in `ContentAggregationService`) introduces a significant performance bottleneck by accumulating latency linearly.
**Action:** Always use `Future.wait` combined with `.map` to execute independent asynchronous operations concurrently, thereby parallelizing network requests and minimizing total wait time to that of the slowest single request.
