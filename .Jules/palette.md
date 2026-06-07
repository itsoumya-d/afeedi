## 2026-06-07 - Missing Tooltips on IconButtons
**Learning:** Found that `IconButton` widgets in Flutter components often lack `tooltip` properties, which is crucial for accessibility (acting as an ARIA label equivalent).
**Action:** Always add descriptive `tooltip` properties to `IconButton` widgets, especially those without text labels.
