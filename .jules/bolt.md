## 2024-06-08 - Content Aggregation Bottleneck
**Learning:** In `ContentAggregationService`, fetching content from multiple social platforms sequentially using a `for` loop creates a massive performance bottleneck. The time to load the feed scales linearly with the number of connected platforms.
**Action:** Replace the sequential `for` loop with a concurrent `Future.wait` combined with `.map(...).toList()` whenever aggregating independent remote resources to fetch them in parallel and reduce overall load time to the slowest individual request.
