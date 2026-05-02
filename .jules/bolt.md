## 2024-05-02 - Concurrent Content Aggregation Wait Time Optimization
**Learning:** Sequential `await` in `for` loops during multi-platform content fetching creates a significant performance bottleneck (O(sum of network latency)).
**Action:** Replace sequential API fetch loops with `Future.wait` across independent futures. This effectively reduces overall latency from sum of all fetching times to just the max fetching time.
