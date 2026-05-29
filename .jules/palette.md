## 2024-05-30 - Add tooltips to icon-only buttons in reusable components
**Learning:** Discovered an accessibility issue pattern where core reusable components (like `AppBarWithProfile`) use icon-only `IconButton` widgets without semantic labels. In Flutter, this causes screen readers to announce "button" without context.
**Action:** Always add a descriptive `tooltip` property to `IconButton` widgets, especially in shared widgets, to ensure visible hints on hover and semantic labels for screen readers.
