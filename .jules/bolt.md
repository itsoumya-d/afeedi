## 2026-07-07 - [Concurrent Platform Content Fetching]
**Learning:** Sequential `await` in loops over multiple external platforms causes compounding latency. In Dart, using an IIFE within a collection `for` loop inside `Future.wait()` provides an elegant and efficient way to execute them concurrently without sacrificing individual error handling.
**Action:** Use `Future.wait([for (var x in list) () async { ... }() ])` pattern when making multiple independent network calls in Dart.
