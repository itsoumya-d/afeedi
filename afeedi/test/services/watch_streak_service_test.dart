import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:afeedi/services/watch_streak_service.dart';

/// Helper: yesterday's date as an ISO-8601 string that the service will parse.
String _yesterday() {
  final now = DateTime.now();
  final yesterday = DateTime(now.year, now.month, now.day - 1);
  return yesterday.toIso8601String();
}

/// Helper: a date two days ago (i.e. a missed day).
String _twoDaysAgo() {
  final now = DateTime.now();
  final twoDaysAgo = DateTime(now.year, now.month, now.day - 2);
  return twoDaysAgo.toIso8601String();
}

void main() {
  // The service is a singleton, so each test must reset SharedPreferences AND
  // call recordOpen() (which always overwrites in-memory state) to get a
  // predictable starting point.

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('WatchStreakService — first open', () {
    test('streak becomes 1 on first ever open', () async {
      await WatchStreakService.instance.recordOpen();
      expect(WatchStreakService.instance.currentStreak, 1);
    });

    test('longestStreak is also 1 after first open', () async {
      await WatchStreakService.instance.recordOpen();
      expect(WatchStreakService.instance.longestStreak, 1);
    });
  });

  group('WatchStreakService — same-day idempotency', () {
    test(
      'calling recordOpen twice on the same day keeps streak at 1',
      () async {
        await WatchStreakService.instance.recordOpen();
        await WatchStreakService.instance.recordOpen();
        expect(WatchStreakService.instance.currentStreak, 1);
      },
    );
  });

  group('WatchStreakService — consecutive day', () {
    test('streak becomes 2 when opened on the day after yesterday', () async {
      // Seed last-open to yesterday, streak = 1
      SharedPreferences.setMockInitialValues({
        'watch_streak_count': 1,
        'watch_streak_longest': 1,
        'watch_streak_last_open': _yesterday(),
      });
      await WatchStreakService.instance.recordOpen();
      expect(WatchStreakService.instance.currentStreak, 2);
    });

    test('longestStreak is updated when streak grows', () async {
      SharedPreferences.setMockInitialValues({
        'watch_streak_count': 1,
        'watch_streak_longest': 1,
        'watch_streak_last_open': _yesterday(),
      });
      await WatchStreakService.instance.recordOpen();
      expect(WatchStreakService.instance.longestStreak, 2);
    });
  });

  group('WatchStreakService — missed day resets streak', () {
    test('streak resets to 1 after missing a day', () async {
      // Last open was two days ago → missed a day
      SharedPreferences.setMockInitialValues({
        'watch_streak_count': 5,
        'watch_streak_longest': 5,
        'watch_streak_last_open': _twoDaysAgo(),
      });
      await WatchStreakService.instance.recordOpen();
      expect(WatchStreakService.instance.currentStreak, 1);
    });

    test('longestStreak is preserved (not reset) when streak resets', () async {
      SharedPreferences.setMockInitialValues({
        'watch_streak_count': 5,
        'watch_streak_longest': 5,
        'watch_streak_last_open': _twoDaysAgo(),
      });
      await WatchStreakService.instance.recordOpen();
      expect(WatchStreakService.instance.longestStreak, 5);
    });
  });

  group('WatchStreakService — isMilestone', () {
    Future<void> setStreak(int n) async {
      // Build up to the desired streak by seeding prefs and calling recordOpen.
      // We seed streak = n-1 with last_open = yesterday so recordOpen makes it n.
      if (n == 1) {
        SharedPreferences.setMockInitialValues({});
        await WatchStreakService.instance.recordOpen();
        return;
      }
      SharedPreferences.setMockInitialValues({
        'watch_streak_count': n - 1,
        'watch_streak_longest': n - 1,
        'watch_streak_last_open': _yesterday(),
      });
      await WatchStreakService.instance.recordOpen();
    }

    test('isMilestone is false at streak 6', () async {
      await setStreak(6);
      expect(WatchStreakService.instance.isMilestone, isFalse);
    });

    test('isMilestone is true at streak 7', () async {
      await setStreak(7);
      expect(WatchStreakService.instance.isMilestone, isTrue);
    });

    test('isMilestone is false at streak 8', () async {
      await setStreak(8);
      expect(WatchStreakService.instance.isMilestone, isFalse);
    });

    test('isMilestone is false at streak 13', () async {
      await setStreak(13);
      expect(WatchStreakService.instance.isMilestone, isFalse);
    });

    test('isMilestone is true at streak 14', () async {
      await setStreak(14);
      expect(WatchStreakService.instance.isMilestone, isTrue);
    });

    test('isMilestone is true at streak 21', () async {
      await setStreak(21);
      expect(WatchStreakService.instance.isMilestone, isTrue);
    });
  });

  group('WatchStreakService — streakLabel', () {
    test('returns empty string when streak is 1', () async {
      SharedPreferences.setMockInitialValues({});
      await WatchStreakService.instance.recordOpen();
      expect(WatchStreakService.instance.currentStreak, 1);
      expect(WatchStreakService.instance.streakLabel, '');
    });

    test("returns '🔥 2-day streak' when streak is 2", () async {
      SharedPreferences.setMockInitialValues({
        'watch_streak_count': 1,
        'watch_streak_longest': 1,
        'watch_streak_last_open': _yesterday(),
      });
      await WatchStreakService.instance.recordOpen();
      expect(WatchStreakService.instance.currentStreak, 2);
      expect(WatchStreakService.instance.streakLabel, '🔥 2-day streak');
    });

    test("returns '🔥 7-day streak' when streak is 7", () async {
      SharedPreferences.setMockInitialValues({
        'watch_streak_count': 6,
        'watch_streak_longest': 6,
        'watch_streak_last_open': _yesterday(),
      });
      await WatchStreakService.instance.recordOpen();
      expect(WatchStreakService.instance.currentStreak, 7);
      expect(WatchStreakService.instance.streakLabel, '🔥 7-day streak');
    });
  });

  group('WatchStreakService — longestStreak across resets', () {
    test('longestStreak persists correctly across a streak reset', () async {
      // Build up a streak of 3
      SharedPreferences.setMockInitialValues({
        'watch_streak_count': 2,
        'watch_streak_longest': 2,
        'watch_streak_last_open': _yesterday(),
      });
      await WatchStreakService.instance.recordOpen();
      expect(WatchStreakService.instance.currentStreak, 3);
      expect(WatchStreakService.instance.longestStreak, 3);

      // Now miss a day — streak resets but longest stays 3
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('watch_streak_last_open', _twoDaysAgo());
      await WatchStreakService.instance.recordOpen();
      expect(WatchStreakService.instance.currentStreak, 1);
      expect(WatchStreakService.instance.longestStreak, 3);
    });
  });

  group('WatchStreakService — load() respects persisted values', () {
    test('load() reads persisted streak without incrementing it', () async {
      // Verify that recordOpen() on the same day (last_open == today)
      // does NOT increment: the same-day branch leaves streak unchanged.
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day).toIso8601String();
      SharedPreferences.setMockInitialValues({
        'watch_streak_count': 4,
        'watch_streak_longest': 4,
        'watch_streak_last_open': today,
      });
      await WatchStreakService.instance.recordOpen();
      expect(WatchStreakService.instance.currentStreak, 4);
      expect(WatchStreakService.instance.longestStreak, 4);
    });
  });
}
