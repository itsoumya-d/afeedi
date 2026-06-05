## 2024-05-24 - [Concurrent Content Fetching]
**Learning:** Using `.map` to generate Futures for `Future.wait` in Dart produces a lazy iterable, which can unintentionally delay or serialize execution if not explicitly materialized.
**Action:** Always call `.toList()` immediately after `.map()` when building lists of concurrent Futures to ensure eager evaluation and parallel execution.