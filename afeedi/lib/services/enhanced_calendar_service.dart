import 'package:flutter/foundation.dart';
import '../models/content_model.dart';
import '../models/user_model.dart';
import 'content_service.dart';
import 'analytics_service.dart';
import 'auth_service.dart';

class EnhancedCalendarService {
  static EnhancedCalendarService? _instance;
  static EnhancedCalendarService get instance =>
      _instance ??= EnhancedCalendarService._();

  EnhancedCalendarService._();

  // Calendar content filtering and scheduling
  Future<List<Content>> getContentForDate(
    DateTime date, {
    String? categoryFilter,
    PlatformType? platformFilter,
    double? educationPercentage,
    double? entertainmentPercentage,
  }) async {
    try {
      // Get all available content
      final allContent = await ContentService.instance.getFeedContent();

      // Filter by date (if content has scheduling info)
      var filteredContent = allContent.where((content) {
        // Check if content is scheduled for this date
        final scheduledDate = content.metadata['scheduled_date'];
        if (scheduledDate != null) {
          final contentDate = DateTime.parse(scheduledDate);
          return _isSameDay(contentDate, date);
        }
        return true; // Include all content if no specific date scheduling
      }).toList();

      // Apply category filter
      if (categoryFilter != null && categoryFilter != 'all') {
        filteredContent = filteredContent.where((content) {
          return content.categories.contains(categoryFilter) ||
              _getContentCategory(content) == categoryFilter;
        }).toList();
      }

      // Apply platform filter
      if (platformFilter != null) {
        filteredContent = filteredContent.where((content) {
          return content.platform == platformFilter;
        }).toList();
      }

      // Apply percentage-based filtering
      if (educationPercentage != null && entertainmentPercentage != null) {
        filteredContent = _applyPercentageFilter(
          filteredContent,
          educationPercentage,
          entertainmentPercentage,
        );
      }

      // Track calendar content request
      await AnalyticsService.instance.trackUserInteraction(
        action: 'calendar_content_filtered',
        screen: 'calendar',
        additionalData: {
          'date': date.toIso8601String(),
          'category_filter': categoryFilter,
          'platform_filter': platformFilter?.name,
          'education_percentage': educationPercentage,
          'entertainment_percentage': entertainmentPercentage,
          'result_count': filteredContent.length,
        },
      );

      return filteredContent;
    } catch (error) {
      await AnalyticsService.instance.trackError(
        errorType: 'calendar_content_filter_error',
        errorMessage: error.toString(),
        screen: 'calendar',
      );
      return [];
    }
  }

  // Schedule content for specific time
  Future<bool> scheduleContent(Content content, DateTime scheduledTime) async {
    try {
      // Update content metadata with scheduling info
      final updatedMetadata = Map<String, dynamic>.from(content.metadata);
      updatedMetadata['scheduled_date'] = scheduledTime.toIso8601String();
      updatedMetadata['scheduled_time'] =
          '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}';

      // In a real app, this would save to the backend
      // For now, we'll track the scheduling action
      await AnalyticsService.instance.trackUserInteraction(
        action: 'content_scheduled',
        screen: 'calendar',
        additionalData: {
          'content_id': content.id,
          'platform': content.platform.name,
          'scheduled_time': scheduledTime.toIso8601String(),
        },
      );

      return true;
    } catch (error) {
      await AnalyticsService.instance.trackError(
        errorType: 'content_scheduling_error',
        errorMessage: error.toString(),
        screen: 'calendar',
      );
      return false;
    }
  }

  // Get scheduled content for a specific time range
  Future<List<ScheduledContentItem>> getScheduledContent(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final allContent = await ContentService.instance.getFeedContent();
      final scheduledItems = <ScheduledContentItem>[];

      for (final content in allContent) {
        final scheduledDateStr = content.metadata['scheduled_date'];
        if (scheduledDateStr != null) {
          final scheduledDate = DateTime.parse(scheduledDateStr);
          if (scheduledDate.isAfter(
                startDate.subtract(const Duration(days: 1)),
              ) &&
              scheduledDate.isBefore(endDate.add(const Duration(days: 1)))) {
            scheduledItems.add(
              ScheduledContentItem(
                content: content,
                scheduledTime: scheduledDate,
                category: _getContentCategory(content),
              ),
            );
          }
        }
      }

      // Sort by scheduled time
      scheduledItems.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

      return scheduledItems;
    } catch (error) {
      await AnalyticsService.instance.trackError(
        errorType: 'scheduled_content_fetch_error',
        errorMessage: error.toString(),
        screen: 'calendar',
      );
      return [];
    }
  }

  // Get content recommendations for a specific time slot
  Future<List<Content>> getTimeSlotRecommendations(
    DateTime timeSlot, {
    String? preferredCategory,
    int limit = 10,
  }) async {
    try {
      final allContent = await ContentService.instance.getFeedContent();

      // Filter content based on time of day preferences
      var recommendations = allContent.where((content) {
        final hour = timeSlot.hour;

        // Morning (6-12): Educational content
        if (hour >= 6 && hour < 12) {
          return _getContentCategory(content) == 'education' ||
              content.categories.contains('educational') ||
              content.categories.contains('news');
        }
        // Afternoon (12-18): Mixed content
        else if (hour >= 12 && hour < 18) {
          return true; // All content types
        }
        // Evening (18-24): Entertainment
        else {
          return _getContentCategory(content) == 'entertainment' ||
              content.categories.contains('entertainment') ||
              content.categories.contains('music');
        }
      }).toList();

      // Apply preferred category filter
      if (preferredCategory != null && preferredCategory != 'all') {
        recommendations = recommendations.where((content) {
          return content.categories.contains(preferredCategory) ||
              _getContentCategory(content) == preferredCategory;
        }).toList();
      }

      // Sort by relevance (view count, like count, etc.)
      recommendations.sort((a, b) {
        final scoreA = a.viewCount + (a.likeCount * 2);
        final scoreB = b.viewCount + (b.likeCount * 2);
        return scoreB.compareTo(scoreA);
      });

      return recommendations.take(limit).toList();
    } catch (error) {
      await AnalyticsService.instance.trackError(
        errorType: 'time_slot_recommendations_error',
        errorMessage: error.toString(),
        screen: 'calendar',
      );
      return [];
    }
  }

  // Helper methods
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _getContentCategory(Content content) {
    // Determine category based on content metadata, tags, or platform
    if (content.categories.isNotEmpty) {
      final category = content.categories.first.toLowerCase();
      if (category.contains('education') ||
          category.contains('tutorial') ||
          category.contains('learn')) {
        return 'education';
      } else if (category.contains('entertainment') ||
          category.contains('music') ||
          category.contains('comedy')) {
        return 'entertainment';
      } else if (category.contains('study') || category.contains('academic')) {
        return 'study';
      }
    }

    // Fallback based on platform
    switch (content.platform) {
      case PlatformType.youtube:
        return content.durationSeconds != null && content.durationSeconds! > 600
            ? 'education'
            : 'entertainment';
      case PlatformType.tiktok:
        return 'entertainment';
      case PlatformType.instagram:
        return 'entertainment';
      case PlatformType.facebook:
        return 'entertainment';
      default:
        return 'entertainment';
    }
  }

  List<Content> _applyPercentageFilter(
    List<Content> content,
    double educationPercentage,
    double entertainmentPercentage,
  ) {
    final educationContent = content
        .where((c) => _getContentCategory(c) == 'education')
        .toList();
    final entertainmentContent = content
        .where((c) => _getContentCategory(c) == 'entertainment')
        .toList();
    final studyContent = content
        .where((c) => _getContentCategory(c) == 'study')
        .toList();

    final totalDesired = 20; // Target number of items
    final educationCount = ((educationPercentage / 100) * totalDesired).round();
    final entertainmentCount = ((entertainmentPercentage / 100) * totalDesired)
        .round();

    final result = <Content>[];

    // Add education content
    if (educationContent.isNotEmpty) {
      result.addAll(educationContent.take(educationCount));
    }

    // Add entertainment content
    if (entertainmentContent.isNotEmpty) {
      result.addAll(entertainmentContent.take(entertainmentCount));
    }

    // Fill remaining slots with study content or mixed content
    final remaining = totalDesired - result.length;
    if (remaining > 0) {
      final remainingContent = content
          .where((c) => !result.contains(c))
          .toList();
      result.addAll(remainingContent.take(remaining));
    }

    return result;
  }
}

// Data models for calendar functionality
class ScheduledContentItem {
  final Content content;
  final DateTime scheduledTime;
  final String category;

  const ScheduledContentItem({
    required this.content,
    required this.scheduledTime,
    required this.category,
  });

  String get formattedTime {
    return '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}';
  }
}

class CalendarFilter {
  final String? category;
  final PlatformType? platform;
  final double? educationPercentage;
  final double? entertainmentPercentage;
  final String? searchQuery;

  const CalendarFilter({
    this.category,
    this.platform,
    this.educationPercentage,
    this.entertainmentPercentage,
    this.searchQuery,
  });
}
