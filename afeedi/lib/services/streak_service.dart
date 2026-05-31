import 'package:shared_preferences/shared_preferences.dart';

class StreakService {
  static StreakService? _instance;
  static StreakService get instance => _instance ??= StreakService._();
  StreakService._();

  static const String _lastActiveKey = 'streak_last_active';
  static const String _currentStreakKey = 'streak_current';
  static const String _longestStreakKey = 'streak_longest';

  Future<void> recordActivity() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayStr = _dateKey(today);
    final lastActiveStr = prefs.getString(_lastActiveKey);

    if (lastActiveStr == todayStr) return; // Already recorded today

    int current = prefs.getInt(_currentStreakKey) ?? 0;
    int longest = prefs.getInt(_longestStreakKey) ?? 0;

    if (lastActiveStr != null) {
      final lastActive = DateTime.parse(lastActiveStr);
      final diff = today.difference(lastActive).inDays;
      if (diff == 1) {
        current += 1;
      } else if (diff > 1) {
        current = 1; // Streak broken
      }
    } else {
      current = 1; // First day
    }

    if (current > longest) longest = current;

    await prefs.setString(_lastActiveKey, todayStr);
    await prefs.setInt(_currentStreakKey, current);
    await prefs.setInt(_longestStreakKey, longest);
  }

  Future<int> getCurrentStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _dateKey(DateTime.now());
    final yesterday = _dateKey(DateTime.now().subtract(const Duration(days: 1)));
    final lastActive = prefs.getString(_lastActiveKey);
    // Streak is alive only if active today or yesterday
    if (lastActive == today || lastActive == yesterday) {
      return prefs.getInt(_currentStreakKey) ?? 0;
    }
    return 0;
  }

  Future<int> getLongestStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_longestStreakKey) ?? 0;
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
