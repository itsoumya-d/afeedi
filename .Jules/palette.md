## 2024-06-12 - Missing tooltips on icon buttons
**Learning:** Many custom AppBar and navigation components use IconButtons without tooltips, meaning screen readers cannot announce their purpose. In Flutter, `tooltip` provides both visual hover text and the accessibility label.
**Action:** Always add the `tooltip` property to IconButtons, especially for icon-only buttons like back arrows or profile avatars.
