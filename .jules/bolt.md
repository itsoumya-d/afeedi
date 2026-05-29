## 2025-05-29 - Throttling Search Inputs with Debouncer
**Learning:** Found that un-debounced `TextField` `onChanged` handlers (e.g. in `CalendarTab` and `ChatController`) cause frequent, unnecessary state rebuilds on every keystroke, which blocks the main thread.
**Action:** Ensure `Debouncer` utility class is used to wrap `setState` and data-fetching calls in search handlers to throttle rebuilds and save performance. Always dispose of `Debouncer` instances in the widget's `dispose()` lifecycle.
