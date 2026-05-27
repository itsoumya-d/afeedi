
## 2024-05-18 - [Debounce Search Input to Reduce Re-renders]
**Learning:** Frequent events like `onChanged` in `TextField`s trigger `setState` excessively on every keystroke, leading to unnecessary re-renders of the widget tree, which impacts frontend performance. This was identified in the `CalendarTab`'s search feature.
**Action:** Always wrap `setState` calls within a `Debouncer` class for text inputs to throttle rebuilds and improve overall app responsiveness.
