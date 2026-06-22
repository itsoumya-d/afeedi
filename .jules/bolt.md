## 2024-06-22 - [Dart Concurrent Fetching Exception Handling]
**Learning:** When executing concurrent operations with `Future.wait` and inline async closures in Dart, it is critical to use `return await` inside `try` blocks so exceptions are caught locally. Omitting `await` causes exceptions to bubble up unhandled, potentially crashing the entire batch operation.
**Action:** Always use `return await` when returning a Future from within a `try-catch` block inside concurrent collection loops or mappings.
