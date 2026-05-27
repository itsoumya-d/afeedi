## Plan
1.  **Add `debouncer.dart` utility:**
    - Create a new file `afeedi/lib/utils/debouncer.dart`.
    - Implement a simple `Debouncer` class to handle action throttling.
2.  **Integrate `Debouncer` in `CalendarTab`:**
    - Open `afeedi/lib/widgets/dashboard/calendar_tab.dart`.
    - Import the new `debouncer.dart` utility.
    - Instantiate the `Debouncer` in `_CalendarTabState` with a 300ms delay.
    - Update the `TextField`'s `onChanged` method in `_buildSearchBar()` to use the debouncer when updating the `_searchQuery` and triggering `setState()`.
    - Ensure the `Debouncer` is properly disposed of in the `dispose()` method.
3.  **Journal the Performance Optimization:**
    - Add an entry to `.jules/bolt.md` documenting this performance win, explaining why un-debounced search inputs can lead to excessive re-renders.
4.  **Complete pre-commit steps to ensure proper testing, verification, review, and reflection are done:**
    - Run code formatting and linting.
    - Run the widget/unit test suite.
5.  **Submit the PR:**
    - Ensure all criteria are met and create the Pull Request.
