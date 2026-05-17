## 2024-05-17 - Asynchronous I/O Bottlenecks in Flutter Web
**Learning:** Sequential await loops for independent disk/storage I/O or platform registrations in Flutter (especially web) cause significant startup bottlenecks, where Future.wait() provides ~40% performance improvement by running them concurrently.
**Action:** Always group independent, nearly immediate asynchronous operations like Hive.openBox() or Hive.box.clear() within Future.wait() and extract their results by index from the returned list.
