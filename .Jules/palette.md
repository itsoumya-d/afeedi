
## 2024-05-18 - Missing Semantic Labels on Icon-Only Buttons
**Learning:** Found that core icon-only interactive elements (`IconButton`) in primary widgets like `FeedPostCard` (e.g., 'More options', 'Bookmark') lacked `tooltip` properties. This degrades accessibility for screen readers and removes helpful hover contexts for desktop/web users.
**Action:** Always ensure any icon-only `IconButton` includes a descriptive `tooltip` attribute to provide proper semantic labeling and hover hints.
