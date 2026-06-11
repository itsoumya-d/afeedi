## 2024-05-18 - Tooltips on Reusable App Bars
**Learning:** Reusable icon-only buttons like the back button and profile avatar in `AppBarWithProfile` lack tooltips by default, hiding context from screen readers.
**Action:** Always include a `tooltip` property on `IconButton` widgets providing both visual hover text and accessibility label.
