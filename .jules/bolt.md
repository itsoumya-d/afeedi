## 2024-06-26 - Analytics Service Disk I/O Bottleneck
**Learning:** The analytics service was performing O(N) disk reads/parsing on every single event tracked by loading the entire history from disk before appending the new event. The in-memory queue wasn't even being populated on non-web platforms.
**Action:** Use the in-memory `_eventQueue` as the source of truth, persisting it directly and returning it for metrics generation to eliminate redundant disk reads.
