## 2026-05-29 - Debounce search input to reduce unnecessary computations

**Learning:** Search inputs in features like `web_streaming_interface`, `calendar_tab` and `interest_selection_grid` trigger `setState`, expensive filtering and analytics operations synchronously on every keystroke in their `onChanged` handlers. This blocks the main thread, drops frames during rapid typing, and spams the analytics server with intermediate/incomplete queries.

**Action:** Created a reusable `Debouncer` class and integrated it into these `TextField` widgets. Now, we wait for a brief pause (e.g., 300ms) before executing the search logic, significantly reducing UI rebuilds, CPU workload and avoiding redundant network calls. Always remember to dispose of the debouncer instance to avoid active timer leaks when components unmount.
