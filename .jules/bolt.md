
## 2024-05-18 - Prevent Unnecessary Render Cycles on Search
**Learning:** Frequent events like search input in stateful widgets (e.g. OnboardingChatbotScreen) trigger `setState` on every keystroke, which causes unnecessary performance overhead by re-rendering the whole widget tree for rapid sequential inputs.
**Action:** Implement and use a standard `Debouncer` class to limit the rate of state updates, only firing after the user pauses typing. This simple change reduces visual jank and limits computation.
