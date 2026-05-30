import 'dart:ui' show Color;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

// Notification categories
enum NotificationCategory { newContent, recommendation, achievement, system }

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();
  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _tzInitialized = false;

  static const _channelName = 'Afeedi Notifications';
  static const _channelDesc =
      'Content updates, streak reminders, and personalized recommendations';

  // Per-category channel IDs
  static const _channelNewContent = 'afeedi_new_content';
  static const _channelRecommendation = 'afeedi_recommendation';
  static const _channelAchievement = 'afeedi_achievement';
  static const _channelSystem = 'afeedi_system';

  // Notification IDs
  static const int _streakReminderId = 2;
  static const int _newContentId = 3;
  // Scheduled IDs
  static const int _dailyTrendingId = 100;
  static const int _weeklyNewContentId = 101;
  static const int _continueWatchingId = 102;
  // Achievement IDs start at 200

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      _initTimezone();
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      await _plugin.initialize(initSettings);
      _initialized = true;
      debugPrint('NotificationService: initialized');
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  void _initTimezone() {
    if (_tzInitialized) return;
    try {
      tz_data.initializeTimeZones();
      _tzInitialized = true;
    } catch (e) {
      debugPrint('NotificationService timezone init error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Permission
  // ---------------------------------------------------------------------------

  Future<bool> requestPermission() async {
    try {
      final iosPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('NotificationService permission error: $e');
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // Immediate notifications
  // ---------------------------------------------------------------------------

  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    NotificationCategory category = NotificationCategory.system,
  }) async {
    if (!_initialized) return;
    try {
      final details = _buildDetails(category: category);
      await _plugin.show(id, title, body, details);
    } catch (e) {
      debugPrint('NotificationService showImmediateNotification error: $e');
    }
  }

  Future<void> showNewContentNotification({
    required int count,
    required String category,
  }) async {
    if (!_initialized) return;
    try {
      final details = _buildDetails(category: NotificationCategory.newContent);
      await _plugin.show(
        _newContentId,
        '$count new videos in your feed',
        'Fresh $category content is ready for you',
        details,
      );
    } catch (e) {
      debugPrint('NotificationService show error: $e');
    }
  }

  Future<void> showStreakReminderNotification({required int streakDays}) async {
    if (!_initialized) return;
    try {
      final details = _buildDetails(category: NotificationCategory.system);
      final message = streakDays > 1
          ? "Don't break your $streakDays-day streak! Watch a video today."
          : "Start your first streak — watch a video today!";
      await _plugin.show(
        _streakReminderId,
        'Keep your streak going',
        message,
        details,
      );
    } catch (e) {
      debugPrint('NotificationService streak reminder error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Scheduled notifications
  // ---------------------------------------------------------------------------

  /// Schedule a daily notification at [hour]:[minute] local time.
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    NotificationCategory category = NotificationCategory.recommendation,
  }) async {
    if (!_initialized || kIsWeb) return;
    try {
      _initTimezone();
      final location = tz.local;
      final now = tz.TZDateTime.now(location);
      var scheduledDate = tz.TZDateTime(
        location,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      final details = _buildDetails(category: category);
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.wallClockTime,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint(
        'NotificationService: scheduled daily notification id=$id at $hour:$minute',
      );
    } catch (e) {
      debugPrint('NotificationService scheduleDailyNotification error: $e');
    }
  }

  /// Schedule a weekly notification (same day of week each week).
  Future<void> scheduleWeeklyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    NotificationCategory category = NotificationCategory.newContent,
  }) async {
    if (!_initialized || kIsWeb) return;
    try {
      _initTimezone();
      final location = tz.local;
      final now = tz.TZDateTime.now(location);
      var scheduledDate = tz.TZDateTime(
        location,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 7));
      }
      final details = _buildDetails(category: category);
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.wallClockTime,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
      debugPrint('NotificationService: scheduled weekly notification id=$id');
    } catch (e) {
      debugPrint('NotificationService scheduleWeeklyNotification error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Personalized scheduling
  // ---------------------------------------------------------------------------

  /// Reads user preferences and schedules relevant local notifications.
  Future<void> schedulePersonalizedNotifications() async {
    if (!_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final genres = prefs.getStringList('onboarding_selected_genres') ?? [];
      final watched = prefs.getInt('stat_videos_watched') ?? 0;

      // 1. Daily trending notification at 10am
      await scheduleDailyNotification(
        id: _dailyTrendingId,
        title: 'Trending now',
        body: genres.isNotEmpty
            ? 'New ${genres.first} content is trending today'
            : "Check out what's trending today",
        hour: 10,
        minute: 0,
        category: NotificationCategory.recommendation,
      );

      // 2. Weekly AI Digest — always fires on Sunday at 10AM
      await _scheduleWeeklyDigest(genres);

      // 3. Continue watching — if any progress entry exists with progress < 0.8
      await _scheduleIfContinueWatchingPending(prefs);

      // 4. Achievement unlock check
      if (watched >= 5 && watched % 5 == 0) {
        await showImmediateNotification(
          id: 200 + watched ~/ 5,
          title: 'Achievement unlocked!',
          body: "You've watched $watched videos. Keep it up!",
          category: NotificationCategory.achievement,
        );
      }
    } catch (e) {
      debugPrint(
        'NotificationService schedulePersonalizedNotifications error: $e',
      );
    }
  }

  Future<void> _scheduleWeeklyDigest(List<String> genres) async {
    if (!_initialized || kIsWeb) return;
    try {
      _initTimezone();
      final location = tz.local;
      final now = tz.TZDateTime.now(location);
      // Calculate next Sunday at 10:00 AM
      final daysUntilSunday = (DateTime.sunday - now.weekday + 7) % 7;
      var nextSunday = tz.TZDateTime(
        location,
        now.year,
        now.month,
        now.day + daysUntilSunday,
        10, // 10 AM
        0,
      );
      // If today is Sunday but already past 10AM, schedule for next week
      if (daysUntilSunday == 0 && now.hour >= 10) {
        nextSunday = nextSunday.add(const Duration(days: 7));
      }

      final genreHint = genres.isNotEmpty
          ? genres.take(2).join(' & ')
          : 'your interests';
      final details = _buildDetails(
        category: NotificationCategory.recommendation,
      );
      await _plugin.zonedSchedule(
        _weeklyNewContentId,
        'Your Weekly Digest is ready ✨',
        '5 top picks in $genreHint — curated just for you.',
        nextSunday,
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.wallClockTime,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
      debugPrint(
        'NotificationService: weekly digest scheduled for Sunday 10AM',
      );
    } catch (e) {
      debugPrint('NotificationService _scheduleWeeklyDigest error: $e');
    }
  }

  Future<void> _scheduleIfContinueWatchingPending(
    SharedPreferences prefs,
  ) async {
    try {
      final keys = prefs.getKeys();
      final progressKeys = keys
          .where((k) => k.startsWith('watch_progress_'))
          .toList();
      for (final key in progressKeys) {
        final progress = prefs.getDouble(key) ?? 0.0;
        if (progress > 0.0 && progress < 0.8) {
          await scheduleDailyNotification(
            id: _continueWatchingId,
            title: 'Continue watching...',
            body: "You left off mid-way — pick up where you left off",
            hour: 18,
            minute: 0,
            category: NotificationCategory.recommendation,
          );
          break; // Only schedule one reminder
        }
      }
    } catch (e) {
      debugPrint(
        'NotificationService _scheduleIfContinueWatchingPending error: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Daily reminder (existing behavior preserved)
  // ---------------------------------------------------------------------------

  Future<void> maybeShowDailyReminder() async {
    if (!_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastReminderDate = prefs.getString('notif_last_reminder_date');
      final today = _dateString(DateTime.now());
      if (lastReminderDate == today) return;

      final streakDays = prefs.getInt('stat_streak_days') ?? 0;
      final lastOpenDate = prefs.getString('stat_streak_last_date');

      if (lastOpenDate != today) {
        await showStreakReminderNotification(streakDays: streakDays);
        await prefs.setString('notif_last_reminder_date', today);
      }
    } catch (e) {
      debugPrint('NotificationService daily reminder error: $e');
    }
  }

  Future<void> notifyContentLoaded({
    required int newItemCount,
    required String category,
  }) async {
    if (newItemCount < 5) return;
    final prefs = await SharedPreferences.getInstance();
    final lastNotifDate = prefs.getString('notif_last_content_date');
    final today = _dateString(DateTime.now());
    if (lastNotifDate == today) return;

    await showNewContentNotification(count: newItemCount, category: category);
    await prefs.setString('notif_last_content_date', today);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  NotificationDetails _buildDetails({
    NotificationCategory category = NotificationCategory.system,
  }) {
    final channelId = _channelIdForCategory(category);
    final channelName = _channelNameForCategory(category);
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: _channelDesc,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF00D4FF),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  String _channelIdForCategory(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.newContent:
        return _channelNewContent;
      case NotificationCategory.recommendation:
        return _channelRecommendation;
      case NotificationCategory.achievement:
        return _channelAchievement;
      case NotificationCategory.system:
        return _channelSystem;
    }
  }

  String _channelNameForCategory(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.newContent:
        return 'New Content';
      case NotificationCategory.recommendation:
        return 'Recommendations';
      case NotificationCategory.achievement:
        return 'Achievements';
      case NotificationCategory.system:
        return _channelName;
    }
  }

  String _dateString(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
