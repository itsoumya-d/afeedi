import 'package:flutter/foundation.dart';
import '../core/storage/local_storage_service.dart';
import 'auth_service.dart';
import 'analytics_service.dart';

class CalendarService {
  static CalendarService? _instance;
  static CalendarService get instance => _instance ??= CalendarService._();

  CalendarService._();

  final _storage = LocalStorageService.instance;

  // Schedule content for later viewing
  Future<Map<String, dynamic>?> scheduleContent({
    required String contentId,
    required DateTime scheduledFor,
    String? notes,
    bool isRecurring = false,
    Map<String, dynamic>? recurrencePattern,
  }) async {
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) {
        return null;
      }

      final scheduledContent = <String, dynamic>{
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'user_id': user.id,
        'content_id': contentId,
        'scheduled_for': scheduledFor.toIso8601String(),
        'notes': notes,
        'is_recurring': isRecurring,
        'recurrence_pattern': recurrencePattern,
        'notification_sent': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _storage.saveScheduledContent(scheduledContent);

      await AnalyticsService.instance.trackUserInteraction(
        action: 'schedule_content',
        screen: 'calendar',
        additionalData: {
          'content_id': contentId,
          'scheduled_for': scheduledFor.toIso8601String(),
          'is_recurring': isRecurring,
        },
      );

      return scheduledContent;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('scheduling content: $error');
      }
      return null;
    }
  }

  // Get scheduled content for a user
  Future<List<Map<String, dynamic>>> getScheduledContent({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) {
        return [];
      }

      final allScheduled = await _storage.getScheduledContentForUser(user.id);

      if (startDate == null && endDate == null) {
        return allScheduled;
      }

      return allScheduled.where((scheduled) {
        final scheduledFor = DateTime.parse(scheduled['scheduled_for'] as String);
        if (startDate != null && scheduledFor.isBefore(startDate)) {
          return false;
        }
        if (endDate != null && scheduledFor.isAfter(endDate)) {
          return false;
        }
        return true;
      }).toList();
    } catch (error) {
      if (kDebugMode) {
        debugPrint('getting scheduled content: $error');
      }
      return [];
    }
  }

  // Get today's scheduled content
  Future<List<Map<String, dynamic>>> getTodaysScheduledContent() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return await getScheduledContent(
      startDate: startOfDay,
      endDate: endOfDay,
    );
  }

  // Get upcoming scheduled content
  Future<List<Map<String, dynamic>>> getUpcomingScheduledContent() async {
    final now = DateTime.now();

    return await getScheduledContent(
      startDate: now,
    );
  }

  // Update scheduled content
  Future<Map<String, dynamic>?> updateScheduledContent(
    String scheduledContentId, {
    DateTime? scheduledFor,
    String? notes,
    bool? isRecurring,
    Map<String, dynamic>? recurrencePattern,
  }) async {
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) {
        return null;
      }

      final existing = await _storage.getScheduledContent(scheduledContentId);
      if (existing == null) {
        return null;
      }

      final updated = Map<String, dynamic>.from(existing);
      if (scheduledFor != null) updated['scheduled_for'] = scheduledFor.toIso8601String();
      if (notes != null) updated['notes'] = notes;
      if (isRecurring != null) updated['is_recurring'] = isRecurring;
      if (recurrencePattern != null) updated['recurrence_pattern'] = recurrencePattern;
      updated['updated_at'] = DateTime.now().toIso8601String();

      await _storage.saveScheduledContent(updated);

      await AnalyticsService.instance.trackUserInteraction(
        action: 'update_scheduled_content',
        screen: 'calendar',
        additionalData: {
          'scheduled_content_id': scheduledContentId,
          'content_id': existing['content_id'],
        },
      );

      return updated;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('updating scheduled content: $error');
      }
      return null;
    }
  }

  // Cancel scheduled content
  Future<bool> cancelScheduledContent(String scheduledContentId) async {
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) {
        return false;
      }

      await _storage.deleteScheduledContent(scheduledContentId);

      await AnalyticsService.instance.trackUserInteraction(
        action: 'cancel_scheduled_content',
        screen: 'calendar',
        additionalData: {
          'scheduled_content_id': scheduledContentId,
        },
      );

      return true;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('canceling scheduled content: $error');
      }
      return false;
    }
  }

  // Get calendar view data
  Future<Map<String, List<Map<String, dynamic>>>> getCalendarViewData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final scheduledContent = await getScheduledContent(
      startDate: startDate,
      endDate: endDate,
    );

    final calendarData = <String, List<Map<String, dynamic>>>{};

    for (final content in scheduledContent) {
      final scheduledFor = DateTime.parse(content['scheduled_for'] as String);
      final dateKey = '${scheduledFor.year}-${scheduledFor.month.toString().padLeft(2, '0')}-${scheduledFor.day.toString().padLeft(2, '0')}';

      if (calendarData[dateKey] == null) {
        calendarData[dateKey] = [];
      }

      calendarData[dateKey]!.add(content);
    }

    return calendarData;
  }

  // Check for conflicts when scheduling
  Future<bool> hasSchedulingConflict({
    required DateTime scheduledFor,
    String? excludeScheduledContentId,
  }) async {
    final existingScheduled = await getScheduledContent(
      startDate: scheduledFor.subtract(const Duration(minutes: 30)),
      endDate: scheduledFor.add(const Duration(minutes: 30)),
    );

    return existingScheduled.any((scheduled) {
      final existingFor = DateTime.parse(scheduled['scheduled_for'] as String);
      return scheduled['id'] != excludeScheduledContentId &&
          existingFor.difference(scheduledFor).abs().inMinutes < 30;
    });
  }

  // Create recurring schedule
  Future<List<Map<String, dynamic>>> createRecurringSchedule({
    required String contentId,
    required DateTime startDate,
    required Map<String, dynamic> recurrencePattern,
    String? notes,
    int maxOccurrences = 52, // Default to 1 year of weekly occurrences
  }) async {
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) {
        return [];
      }

      final scheduledContentList = <Map<String, dynamic>>[];

      // Generate recurring dates based on pattern
      final dates = _generateRecurringDates(
        startDate: startDate,
        pattern: recurrencePattern,
        maxOccurrences: maxOccurrences,
      );

      for (final date in dates) {
        final scheduledContent = <String, dynamic>{
          'id': '${DateTime.now().millisecondsSinceEpoch}_${date.millisecondsSinceEpoch}',
          'user_id': user.id,
          'content_id': contentId,
          'scheduled_for': date.toIso8601String(),
          'notes': notes,
          'is_recurring': true,
          'recurrence_pattern': recurrencePattern,
          'notification_sent': false,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        await _storage.saveScheduledContent(scheduledContent);
        scheduledContentList.add(scheduledContent);
      }

      await AnalyticsService.instance.trackUserInteraction(
        action: 'create_recurring_schedule',
        screen: 'calendar',
        additionalData: {
          'content_id': contentId,
          'occurrences_created': scheduledContentList.length,
        },
      );

      return scheduledContentList;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('creating recurring schedule: $error');
      }
      return [];
    }
  }

  // Generate recurring dates based on pattern
  List<DateTime> _generateRecurringDates({
    required DateTime startDate,
    required Map<String, dynamic> pattern,
    required int maxOccurrences,
  }) {
    final dates = <DateTime>[];
    final frequency = pattern['frequency'] as String? ?? 'weekly';
    final interval = pattern['interval'] as int? ?? 1;

    DateTime currentDate = startDate;

    for (int i = 0; i < maxOccurrences; i++) {
      dates.add(currentDate);

      switch (frequency) {
        case 'daily':
          currentDate = currentDate.add(Duration(days: interval));
          break;
        case 'weekly':
          currentDate = currentDate.add(Duration(days: 7 * interval));
          break;
        case 'monthly':
          currentDate = DateTime(
            currentDate.year,
            currentDate.month + interval,
            currentDate.day,
            currentDate.hour,
            currentDate.minute,
          );
          break;
        case 'yearly':
          currentDate = DateTime(
            currentDate.year + interval,
            currentDate.month,
            currentDate.day,
            currentDate.hour,
            currentDate.minute,
          );
          break;
      }
    }

    return dates;
  }

  // Get calendar statistics
  Future<Map<String, dynamic>> getCalendarStats() async {
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) {
        return {};
      }

      final allScheduled = await _storage.getScheduledContentForUser(user.id);
      final todaysContent = await getTodaysScheduledContent();
      final thisWeekContent = await getScheduledContent(
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
      );

      return {
        'total_scheduled': allScheduled.length,
        'today_scheduled': todaysContent.length,
        'this_week_scheduled': thisWeekContent.length,
        'recurring_schedules': allScheduled.where((s) => s['is_recurring'] == true).length,
      };
    } catch (error) {
      if (kDebugMode) {
        debugPrint('getting calendar stats: $error');
      }
      return {};
    }
  }
}
