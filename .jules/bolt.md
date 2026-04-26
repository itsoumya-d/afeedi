## 2024-04-26 - Missing Debouncing on Search Inputs
**Learning:** Frequent UI events like search inputs in widgets (e.g. `WebStreamingInterface`, `CalendarTab`, `OnboardingChatbotScreen`) update state synchronously via `setState`, causing unnecessary re-renders. A debouncer can easily reduce UI frame drops and unnecessary computations.
**Action:** Implemented a reusable `Debouncer` class in `lib/utils/debouncer.dart` and integrated it into search/filtering handlers across multiple widgets.
