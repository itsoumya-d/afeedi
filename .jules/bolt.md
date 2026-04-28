## 2024-04-28 - Added debouncer to calendar tab
**Learning:** Frequent updates to `TextField`'s `onChanged` were firing `setState` repeatedly, causing unnecessary layout passes and potential UI blocking, which is especially problematic in lists or complex views like `calendar_tab.dart`.
**Action:** Implemented a simple reusable `Debouncer` class to limit the rate at which state changes occur. This should be applied to any fast-firing inputs to avoid main thread jitter.
