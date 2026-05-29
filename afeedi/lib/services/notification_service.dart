import 'dart:ui' show Color;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();
  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channelId = 'afeedi_main';
  static const _channelName = 'Afeedi Notifications';
  static const _channelDesc = 'Content updates, streak reminders, and personalized recommendations';

  // Notification IDs
  static const int _dailyFeedId = 1;
  static const int _streakReminderId = 2;
  static const int _newContentId = 3;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false, // Request explicitly later
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
      await _plugin.initialize(initSettings);
      _initialized = true;
      debugPrint('NotificationService: initialized');
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  Future<bool> requestPermission() async {
    try {
      // iOS permission request
      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(alert: true, badge: true, sound: true);
        return granted ?? false;
      }
      // Android 13+ permission is handled by the system permission dialog
      // triggered on first notification send
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('NotificationService permission error: $e');
    }
    return false;
  }

  Future<void> showNewContentNotification({required int count, required String category}) async {
    if (!_initialized) return;
    try {
      final details = _buildDetails(
        androidChannelId: _channelId,
        androidChannelName: _channelName,
        androidChannelDesc: _channelDesc,
      );
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
      final details = _buildDetails(
        androidChannelId: _channelId,
        androidChannelName: _channelName,
        androidChannelDesc: _channelDesc,
      );
      final message = streakDays > 1
          ? "Don't break your $streakDays-day streak! Watch a video today."
          : "Start your first streak — watch a video today!";
      await _plugin.show(
        _streakReminderId,
        'Keep your streak going 🔥',
        message,
        details,
      );
    } catch (e) {
      debugPrint('NotificationService streak reminder error: $e');
    }
  }

  Future<void> maybeShowDailyReminder() async {
    if (!_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastReminderDate = prefs.getString('notif_last_reminder_date');
      final today = _dateString(DateTime.now());
      if (lastReminderDate == today) return; // Already shown today

      final streakDays = prefs.getInt('stat_streak_days') ?? 0;
      final lastOpenDate = prefs.getString('stat_streak_last_date');

      // Only remind if user hasn't opened today
      if (lastOpenDate != today) {
        await showStreakReminderNotification(streakDays: streakDays);
        await prefs.setString('notif_last_reminder_date', today);
      }
    } catch (e) {
      debugPrint('NotificationService daily reminder error: $e');
    }
  }

  // Called when app loads fresh content — notify if meaningful new content found
  Future<void> notifyContentLoaded({required int newItemCount, required String category}) async {
    if (newItemCount < 5) return;
    final prefs = await SharedPreferences.getInstance();
    final lastNotifDate = prefs.getString('notif_last_content_date');
    final today = _dateString(DateTime.now());
    if (lastNotifDate == today) return;

    await showNewContentNotification(count: newItemCount, category: category);
    await prefs.setString('notif_last_content_date', today);
  }

  NotificationDetails _buildDetails({
    required String androidChannelId,
    required String androidChannelName,
    required String androidChannelDesc,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        androidChannelId,
        androidChannelName,
        channelDescription: androidChannelDesc,
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

  String _dateString(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

