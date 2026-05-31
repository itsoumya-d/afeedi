import 'package:shared_preferences/shared_preferences.dart';

/// Tracks the user's daily app-open streak.
/// A streak increments when the user opens the app on a new calendar day.
/// It resets if they miss a day.
class WatchStreakService {
  static final WatchStreakService _instance = WatchStreakService._();
  static WatchStreakService get instance => _instance;
  WatchStreakService._();

  static const _keyStreak = 'watch_streak_count';
  static const _keyLongest = 'watch_streak_longest';
  static const _keyLastOpen = 'watch_streak_last_open';

  int _currentStreak = 0;
  int _longestStreak = 0;
  bool _initialized = false;

  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;

  /// Call once per app session (e.g. in HomeTab.initState).
  Future<void> recordOpen() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final lastRaw = prefs.getString(_keyLastOpen);
    final lastDate = lastRaw != null ? DateTime.tryParse(lastRaw) : null;
    final lastDay = lastDate != null
        ? DateTime(lastDate.year, lastDate.month, lastDate.day)
        : null;

    int streak = prefs.getInt(_keyStreak) ?? 0;

    if (lastDay == null) {
      // First ever open
      streak = 1;
    } else if (lastDay == today) {
      // Same day — no change
    } else if (today.difference(lastDay).inDays == 1) {
      // Consecutive day
      streak += 1;
    } else {
      // Missed one or more days — reset
      streak = 1;
    }

    final longest = prefs.getInt(_keyLongest) ?? 0;
    final newLongest = streak > longest ? streak : longest;

    await prefs.setInt(_keyStreak, streak);
    await prefs.setInt(_keyLongest, newLongest);
    await prefs.setString(_keyLastOpen, today.toIso8601String());

    _currentStreak = streak;
    _longestStreak = newLongest;
    _initialized = true;
  }

  /// Load persisted values without updating the streak.
  Future<void> load() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    _currentStreak = prefs.getInt(_keyStreak) ?? 0;
    _longestStreak = prefs.getInt(_keyLongest) ?? 0;
    _initialized = true;
  }

  /// Human-friendly label: "🔥 5-day streak" or "" when streak < 2.
  String get streakLabel {
    if (_currentStreak < 2) return '';
    return '🔥 $_currentStreak-day streak';
  }

  /// Whether today's streak milestone deserves a celebration (multiples of 7).
  bool get isMilestone => _currentStreak >= 7 && _currentStreak % 7 == 0;
}
