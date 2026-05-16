## 2024-05-18 - Optimize Hive sequential I/O bottleneck
**Learning:** Grouping `Hive.openBox()` and `Hive.box.clear()` calls within `Future.wait()` prevents sequential I/O bottlenecks during app initialization and cleanup, especially when handling multiple separate boxes.
**Action:** When initializing multiple storage boxes or performing bulk clear operations in Hive, always use `Future.wait()` to run them concurrently instead of sequentially `await`ing each one.
