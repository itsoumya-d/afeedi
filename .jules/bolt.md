## 2024-06-10 - Concurrent Platform View Registration
**Learning:** Sequential await calls in a loop for platform view registration create a performance bottleneck during app initialization on the web. Using Future.wait() significantly reduces initialization time.
**Action:** Always use Future.wait() for independent initialization tasks to ensure they execute concurrently.
