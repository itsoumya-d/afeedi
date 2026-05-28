## 2024-05-28 - Debounce Search Input
**Learning:** The project uses a custom `Debouncer` utility class located at `afeedi/lib/utils/debouncer.dart` to throttle frequent UI events like search inputs and avoid unnecessary re-renders.
**Action:** Always wrap `onChanged` handlers for search text fields in `Debouncer.run(() { ... })` and ensure `dispose()` is called appropriately.
