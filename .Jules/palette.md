
## 2024-05-18 - Added semantic tooltips to core AppBarWithProfile
**Learning:** Found that core reusable components like `AppBarWithProfile` were missing `tooltip` attributes on their icon-only `IconButton`s. Without these, screen readers announce generic "button" and desktop users miss hover hints.
**Action:** Always include a descriptive `tooltip` parameter on `IconButton` widgets, especially when the icon is the sole indicator of its function.
