## 2024-07-03 - [Concurrent Content Aggregation]
**Learning:** The content aggregation service fetched platform content sequentially, creating a significant performance bottleneck as each platform's API call had to wait for the previous one to complete.
**Action:** Use `Future.wait` with an Immediately Invoked Function Expression (IIFE) inside a collection `for` loop to execute independent platform fetch calls concurrently, reducing total aggregation time to the slowest individual request rather than the sum of all requests.
