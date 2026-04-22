## $(date +%Y-%m-%d) - Adding Tooltips to Icon-Only Buttons
**Learning:** Found several icon-only `IconButton`s in the Flutter app missing `tooltip` properties (e.g. Back, Show/Hide Password, Search, Notifications, Profile). These tooltips are crucial for accessibility, acting as the semantic label for screen readers. Dynamic tooltips based on state (like password visibility) enhance the experience.
**Action:** Always verify `IconButton` elements have corresponding `tooltip` text for better accessibility and hover interaction, adhering to UX standards for the project.
