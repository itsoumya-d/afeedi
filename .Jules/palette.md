## 2024-05-18 - Added Tooltips to IconButtons
**Learning:** Found multiple instances of icon-only `IconButton`s missing `tooltip` properties (`AppBarWithProfile`, `FeedPostCard`). This is an accessibility issue for screen reader users and those seeking clarification on actions.
**Action:** Always verify `IconButton` usages to ensure semantic `tooltip` text is provided for elements lacking visible text labels.
