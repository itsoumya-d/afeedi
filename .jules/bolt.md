## 2024-06-29 - [Concurrent API Fetching]
**Learning:** Sequential await loops for multiple independent API calls create significant and unnecessary bottlenecks in Flutter applications.
**Action:** Always use `Future.wait` with an asynchronous Immediately Invoked Function Expression (IIFE) within a collection `for` loop for concurrent fetching when tasks are independent, while maintaining individual `try-catch` blocks so a single failure doesn't abort the entire batch.
