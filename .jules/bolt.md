## 2024-05-13 - Concurrent Hive Box Operations
**Learning:** Sequential opening and clearing of multiple Hive boxes creates significant I/O bottlenecks during app initialization and cleanup.
**Action:** Group independent asynchronous I/O operations (like `Hive.openBox()` and `box.clear()`) within `Future.wait()` to execute them concurrently, significantly reducing overall wait time.
