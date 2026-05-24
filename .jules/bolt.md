## 2026-05-24 - Debouncing Search in Calendar Tab
**Learning:** The calendar tab in this application re-renders the UI to filter a large list of content elements locally every time the search text field changes, with no throttling. This can result in janky text input and unnecessary processing.
**Action:** Always check `onChanged` implementations of text fields that filter lists and ensure they use a debouncer to throttle rebuilds.
