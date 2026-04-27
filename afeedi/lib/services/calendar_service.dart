import 'package:flutter/foundation.dart';
import '../models/content_model.dart';
import '../models/user_model.dart';
import '../core/storage/local_storage_service.dart';
import 'auth_service.dart';
import 'analytics_service.dart';

class CalendarService {
  static CalendarService? _instance;
  static CalendarService get instance => _instance ??= CalendarService._();

  CalendarService._();

  final _storage = LocalStorageService.instance;

  // Schedule content for later viewing
  Future<ScheduledContent?> scheduleContent({
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

      final scheduledContent = ScheduledContent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.id,
        contentId: contentId,
        scheduledFor: scheduledFor,
        notes: notes,
        isRecurring: isRecurring,
        recurrencePattern: recurrencePattern,
        notificationSent: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _storage.saveScheduledContent(scheduledContent);

      await AnalyticsService.instance.trackUserInteraction(
        userId: user.id,
        action: 'schedule_content',
        contentId: contentId,
        metadata: {
          'scheduled_for': scheduledFor.toIso8601String(),
          'is_recurring': isRecurring,
        },
      );

      return scheduledContent;
    } catch (error) {
      if (kDebugMode) {
        print('Error scheduling content: $error');
      }
      return null;
    }
  }

  // Get scheduled content for a user
  Future<List<ScheduledContent>> getScheduledContent({
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
        if (startDate != null && scheduled.scheduledFor.isBefore(startDate)) {
          return false;
        }
        if (endDate != null && scheduled.scheduledFor.isAfter(endDate)) {
          return false;
        }
        return true;
      }).toList();
    } catch (error) {
      if (kDebugMode) {
        print('Error getting scheduled content: $error');
      }
      return [];
    }
  }

  // Get today's scheduled content
  Future<List<ScheduledContent>> getTodaysScheduledContent() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return await getScheduledContent(startDate: startOfDay, endDate: endOfDay);
  }

  // Get upcoming scheduled content
  Future<List<ScheduledContent>> getUpcomingScheduledContent() async {
    final now = DateTime.now();

    return await getScheduledContent(startDate: now);
  }

  // Update scheduled content
  Future<ScheduledContent?> updateScheduledContent(
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

      final updated = existing.copyWith(
        scheduledFor: scheduledFor,
        notes: notes,
        isRecurring: isRecurring,
        recurrencePattern: recurrencePattern,
        updatedAt: DateTime.now(),
      );

      await _storage.saveScheduledContent(updated);

      await AnalyticsService.instance.trackUserInteraction(
        userId: user.id,
        action: 'update_scheduled_content',
        contentId: existing.contentId,
        metadata: {'scheduled_content_id': scheduledContentId},
      );

      return updated;
    } catch (error) {
      if (kDebugMode) {
        print('Error updating scheduled content: $error');
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
        userId: user.id,
        action: 'cancel_scheduled_content',
        metadata: {'scheduled_content_id': scheduledContentId},
      );

      return true;
    } catch (error) {
      if (kDebugMode) {
        print('Error canceling scheduled content: $error');
      }
      return false;
    }
  }

  // Get calendar view data
  Future<Map<String, List<ScheduledContent>>> getCalendarViewData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final scheduledContent = await getScheduledContent(
      startDate: startDate,
      endDate: endDate,
    );

    final calendarData = <String, List<ScheduledContent>>{};

    for (final content in scheduledContent) {
      final dateKey =
          '${content.scheduledFor.year}-${content.scheduledFor.month.toString().padLeft(2, '0')}-${content.scheduledFor.day.toString().padLeft(2, '0')}';

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

    return existingScheduled.any(
      (scheduled) =>
          scheduled.id != excludeScheduledContentId &&
          scheduled.scheduledFor.difference(scheduledFor).abs().inMinutes < 30,
    );
  }

  // Create recurring schedule
  Future<List<ScheduledContent>> createRecurringSchedule({
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

      final scheduledContentList = <ScheduledContent>[];

      // Generate recurring dates based on pattern
      final dates = _generateRecurringDates(
        startDate: startDate,
        pattern: recurrencePattern,
        maxOccurrences: maxOccurrences,
      );

      for (final date in dates) {
        final scheduledContent = ScheduledContent(
          id: '${DateTime.now().millisecondsSinceEpoch}_${date.millisecondsSinceEpoch}',
          userId: user.id,
          contentId: contentId,
          scheduledFor: date,
          notes: notes,
          isRecurring: true,
          recurrencePattern: recurrencePattern,
          notificationSent: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _storage.saveScheduledContent(scheduledContent);
        scheduledContentList.add(scheduledContent);
      }

      await AnalyticsService.instance.trackUserInteraction(
        userId: user.id,
        action: 'create_recurring_schedule',
        contentId: contentId,
        metadata: {'occurrences_created': scheduledContentList.length},
      );

      return scheduledContentList;
    } catch (error) {
      if (kDebugMode) {
        print('Error creating recurring schedule: $error');
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
        'recurring_schedules': allScheduled.where((s) => s.isRecurring).length,
      };
    } catch (error) {
      if (kDebugMode) {
        print('Error getting calendar stats: $error');
      }
      return {};
    }
  }
}
