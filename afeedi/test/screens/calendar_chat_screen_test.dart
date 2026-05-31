import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:afeedi/screens/calendar_chat_screen.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget _wrap() => const MaterialApp(home: CalendarChatScreen());

  group('CalendarChatScreen', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      expect(find.byType(CalendarChatScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows AI Calendar title in app bar', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      expect(find.text('AI Calendar'), findsOneWidget);
    });

    testWidgets('shows subtitle text', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      expect(find.text('Schedule & discover content'), findsOneWidget);
    });

    testWidgets('renders mini calendar with weekday labels', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      // Weekday header labels rendered in the compact calendar
      expect(find.text('S'), findsWidgets);
      expect(find.text('M'), findsOneWidget);
      expect(find.text('W'), findsOneWidget);
      expect(find.text('F'), findsOneWidget);
    });

    testWidgets('shows greeting bot message', (tester) async {
      await tester.pumpWidget(_wrap());
      // Give time for the greeting message to be added synchronously in initState
      await tester.pump();

      // Greeting is time-aware: "Good morning", "Good afternoon", "Good evening", or "Still up"
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Text &&
              ['Good morning', 'Good afternoon', 'Good evening', 'Still up']
                  .any((phrase) => w.data?.contains(phrase) ?? false),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows quick-reply chips after greeting', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      // Chips are time-aware; verify at least one from any time period is shown
      const allPossibleChips = [
        'Fill my day',
        "Show today's schedule",
        'Schedule for this evening',
        'Find morning content',
        "What's on tonight?",
        'Schedule something for today',
        'Find trending now',
        'Plan my weekend',
        "Show tonight's schedule",
        'Gaming content now',
        'Schedule for tomorrow',
        "What's trending?",
        'Plan tomorrow',
        'Schedule for the weekend',
        'Find something relaxing',
        'Show this week',
      ];
      final anyChipVisible = allPossibleChips.any(
        (chip) => find.text(chip).evaluate().isNotEmpty,
      );
      expect(anyChipVisible, isTrue);
    });

    testWidgets('input bar is present', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('tapping a quick-reply chip adds user bubble', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      // Chips are time-aware; find whichever one is visible and tap it
      const allPossibleChips = [
        'Fill my day',
        "Show today's schedule",
        'Schedule for this evening',
        'Find morning content',
        "What's on tonight?",
        'Schedule something for today',
        'Find trending now',
        'Plan my weekend',
        "Show tonight's schedule",
        'Gaming content now',
        'Schedule for tomorrow',
        "What's trending?",
        'Plan tomorrow',
        'Schedule for the weekend',
        'Find something relaxing',
        'Show this week',
      ];
      final visibleChip = allPossibleChips.firstWhere(
        (chip) => find.text(chip).evaluate().isNotEmpty,
        orElse: () => '',
      );
      expect(visibleChip, isNotEmpty, reason: 'At least one chip should be visible');

      await tester.tap(find.text(visibleChip).first);
      // _handleSend has a 700ms Future.delayed before responding; pump past it
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump();

      // The chip text should now appear as a user bubble
      expect(find.text(visibleChip), findsWidgets);
    });

    testWidgets('refresh button clears chat and shows fresh start', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      // Tap the refresh icon in the app bar
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      expect(find.textContaining('Fresh start'), findsOneWidget);
    });

    testWidgets('calendar month navigation chevrons exist', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('tapping next month chevron changes month header', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      // Get initial month text
      final monthsForward = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      final now = DateTime.now();
      final nextMonth = DateTime(now.year, now.month + 1);
      final expectedNextLabel =
          '${monthsForward[nextMonth.month - 1]} ${nextMonth.year}';

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump();

      expect(find.text(expectedNextLabel), findsOneWidget);
    });

    testWidgets('ScheduledItem serialization round-trips correctly', (_) async {
      final item = ScheduledItem(
        id: 'test_id',
        contentId: 'content_1',
        title: 'Test Video',
        platform: 'youtube',
        thumbnailUrl: null,
        scheduledAt: DateTime(2026, 6, 15, 19, 0),
        category: 'gaming',
      );

      final json = item.toJson();
      final restored = ScheduledItem.fromJson(json);

      expect(restored.id, 'test_id');
      expect(restored.contentId, 'content_1');
      expect(restored.title, 'Test Video');
      expect(restored.platform, 'youtube');
      expect(restored.scheduledAt, DateTime(2026, 6, 15, 19, 0));
      expect(restored.category, 'gaming');
      expect(restored.thumbnailUrl, isNull);
    });
  });
}
