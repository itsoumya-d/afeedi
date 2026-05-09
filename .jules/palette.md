## 2024-05-09 - Added tooltips to IconButtons
**Learning:** Icon-only buttons in Flutter lack inherent semantic meaning for screen readers and lack visual context on hover without explicitly adding a `tooltip`.
**Action:** Always add a descriptive `tooltip` property to `IconButton` widgets when they do not have accompanying text labels, especially dynamic ones like password visibility toggles.
