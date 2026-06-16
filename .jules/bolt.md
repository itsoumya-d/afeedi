## 2024-06-16 - Concurrent Network Requests via Future.wait()
**Learning:** Sequential network requests in a `for` loop unnecessarily block each other, causing cumulative delays. Independent requests should be executed concurrently.
**Action:** Always use `Future.wait()` mapped over independent network calls instead of sequential iteration to improve loading times.
