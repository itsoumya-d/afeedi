## 2024-05-25 - [Concurrent Network Requests]
**Learning:** Sequential network requests block the main thread and delay processing. Using Future.wait allows for concurrent execution, but it's important to use .toList() to eagerly start them, and append .catchError to individual futures to prevent one failure from failing the entire aggregation.
**Action:** Always use Future.wait combined with .map().toList() and individual .catchError handlers for batch network requests.
