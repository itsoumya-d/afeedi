## 2024-05-19 - Concurrent Platform API Calls
**Learning:** Using `await` inside a loop when aggregating data from multiple APIs causes sequential network latency bottlenecks.
**Action:** Always map requests to a list of futures (remembering to call `.toList()` for eager evaluation) and use `Future.wait()` to run them concurrently.
