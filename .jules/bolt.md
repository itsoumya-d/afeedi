## 2024-05-20 - [Concurrent Hive I/O]
**Learning:** Sequential calls to `Hive.openBox()` and `Hive.box.clear()` create a significant I/O bottleneck during application initialization and cleanup.
**Action:** Always group these asynchronous Hive operations using `Future.wait()` to perform them concurrently, minimizing overall startup/teardown time. Ensure the results are correctly unpacked when assigning to multiple variables.
