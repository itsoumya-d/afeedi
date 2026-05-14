## 2024-05-14 - Optimize sequential Hive box initialization
**Learning:** Grouping independent, nearly immediate asynchronous operations (like Hive.openBox and Hive.box.clear) with Future.wait provides significant performance improvements (up to 40%) in Flutter web environments over sequential await calls.
**Action:** Identify sequences of independent asynchronous operations during app initialization or cleanup and wrap them in Future.wait to prevent I/O bottlenecks.
