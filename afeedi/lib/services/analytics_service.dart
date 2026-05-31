import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class AnalyticsService with WidgetsBindingObserver {
  static final AnalyticsService _instance = AnalyticsService._internal();
  static AnalyticsService get instance => _instance;

  AnalyticsService._internal();

  SharedPreferences? _prefs;
  final List<Map<String, dynamic>> _eventQueue = [];

  // PRODUCTION REQUIREMENT: Call AnalyticsService.setEndpoint(url) in main()
  // before runApp() with your backend ingest URL (e.g. Supabase Edge Function or
  // custom /api/analytics endpoint). Without this, all events are queued locally
  // and never flushed to remote. The queue is persisted across sessions in the
  // app's documents directory.
  static String _endpointUrl = '';
  static const int _flushThreshold = 50;
  bool _flushInProgress = false;

  static void setEndpoint(String url) => _endpointUrl = url;

  // Initialize the analytics service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadQueuedEvents();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      flushToRemote();
    }
  }

  Future<void> flushToRemote() async {
    if (_endpointUrl.isEmpty || _flushInProgress || _eventQueue.isEmpty) return;
    _flushInProgress = true;
    final batch = List<Map<String, dynamic>>.from(_eventQueue);
    try {
      final response = await http
          .post(
            Uri.parse(_endpointUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'events': batch}),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        _eventQueue.removeRange(0, batch.length);
        await _persistEvents(_eventQueue);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Analytics flush failed (will retry): $e');
    } finally {
      _flushInProgress = false;
    }
  }

  // Track onboarding events
  Future<void> trackOnboardingEvent({
    required String eventName,
    required int stepNumber,
    String? stepName,
    Map<String, dynamic>? additionalData,
  }) async {
    final event = {
      'event_type': 'onboarding',
      'event_name': eventName,
      'step_number': stepNumber,
      'step_name': stepName,
      'timestamp': DateTime.now().toIso8601String(),
      'session_id': await _getSessionId(),
      'user_id': await _getUserId(),
      'platform': _getPlatform(),
      'app_version': await _getAppVersion(),
      ...?additionalData,
    };

    await _queueEvent(event);
  }

  // Track OAuth connection events
  Future<void> trackOAuthEvent({
    required String platform,
    required String action, // 'connect', 'disconnect', 'error'
    String? errorMessage,
    Map<String, dynamic>? additionalData,
  }) async {
    final event = {
      'event_type': 'oauth',
      'platform': platform,
      'action': action,
      'error_message': errorMessage,
      'timestamp': DateTime.now().toIso8601String(),
      'session_id': await _getSessionId(),
      'user_id': await _getUserId(),
      'platform_os': _getPlatform(),
      'app_version': await _getAppVersion(),
      ...?additionalData,
    };

    await _queueEvent(event);
  }

  // Track user interaction events
  Future<void> trackUserInteraction({
    required String action,
    required String screen,
    String? element,
    Map<String, dynamic>? additionalData,
  }) async {
    final event = {
      'event_type': 'user_interaction',
      'action': action,
      'screen': screen,
      'element': element,
      'timestamp': DateTime.now().toIso8601String(),
      'session_id': await _getSessionId(),
      'user_id': await _getUserId(),
      'platform': _getPlatform(),
      'app_version': await _getAppVersion(),
      ...?additionalData,
    };

    await _queueEvent(event);
  }

  // Track app performance metrics
  Future<void> trackPerformanceMetric({
    required String metricName,
    required double value,
    String? unit,
    Map<String, dynamic>? additionalData,
  }) async {
    final event = {
      'event_type': 'performance',
      'metric_name': metricName,
      'value': value,
      'unit': unit,
      'timestamp': DateTime.now().toIso8601String(),
      'session_id': await _getSessionId(),
      'user_id': await _getUserId(),
      'platform': _getPlatform(),
      'app_version': await _getAppVersion(),
      ...?additionalData,
    };

    await _queueEvent(event);
  }

  // Track errors and crashes
  Future<void> trackError({
    required String errorType,
    required String errorMessage,
    String? stackTrace,
    String? screen,
    Map<String, dynamic>? additionalData,
  }) async {
    final event = {
      'event_type': 'error',
      'error_type': errorType,
      'error_message': errorMessage,
      'stack_trace': stackTrace,
      'screen': screen,
      'timestamp': DateTime.now().toIso8601String(),
      'session_id': await _getSessionId(),
      'user_id': await _getUserId(),
      'platform': _getPlatform(),
      'app_version': await _getAppVersion(),
      ...?additionalData,
    };

    await _queueEvent(event);
  }

  // Conversion funnel events — required for paywall & subscription optimization

  Future<void> trackFirstContentViewed(
    String contentId,
    String platform,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('_first_content_tracked') == true) return;
    await prefs.setBool('_first_content_tracked', true);
    await trackUserInteraction(
      action: 'first_content_viewed',
      screen: 'feed',
      additionalData: {'content_id': contentId, 'content_platform': platform},
    );
  }

  Future<void> trackFirstSave(String contentId) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('_first_save_tracked') == true) return;
    await prefs.setBool('_first_save_tracked', true);
    await trackUserInteraction(
      action: 'first_save',
      screen: 'feed',
      additionalData: {'content_id': contentId},
    );
  }

  Future<void> trackPaywallShown(String context) async {
    await trackUserInteraction(
      action: 'paywall_shown',
      screen: 'paywall',
      additionalData: {'trigger_context': context},
    );
  }

  Future<void> trackSubscriptionPurchase({
    required String planId,
    required double amount,
    required String currency,
  }) async {
    final event = {
      'event_type': 'subscription',
      'action': 'purchased',
      'plan_id': planId,
      'amount': amount,
      'currency': currency,
      'timestamp': DateTime.now().toIso8601String(),
      'session_id': await _getSessionId(),
      'user_id': await _getUserId(),
      'platform': _getPlatform(),
      'app_version': await _getAppVersion(),
    };
    await _queueEvent(event);
  }

  Future<void> trackSubscriptionCanceled(
    String planId, {
    String? reason,
  }) async {
    final event = {
      'event_type': 'subscription',
      'action': 'canceled',
      'plan_id': planId,
      'reason': reason,
      'timestamp': DateTime.now().toIso8601String(),
      'session_id': await _getSessionId(),
      'user_id': await _getUserId(),
      'platform': _getPlatform(),
      'app_version': await _getAppVersion(),
    };
    await _queueEvent(event);
  }

  // Get onboarding completion metrics
  Future<Map<String, dynamic>> getOnboardingMetrics() async {
    final events = await _getStoredEvents();
    final onboardingEvents = events
        .where((e) => e['event_type'] == 'onboarding')
        .toList();

    if (onboardingEvents.isEmpty) {
      return {
        'total_events': 0,
        'completion_rate': 0.0,
        'average_time': 0.0,
        'drop_off_points': <String, int>{},
      };
    }

    final startEventsBySessionId = <String, Map<String, dynamic>>{};
    final completeEvents = <Map<String, dynamic>>[];

    int startEventsCount = 0;

    for (final event in onboardingEvents) {
      final eventName = event['event_name'];
      if (eventName == 'onboarding_started') {
        startEventsCount++;
        final sessionId = event['session_id'];
        if (sessionId != null) {
          final sessionIdStr = sessionId.toString();
          if (!startEventsBySessionId.containsKey(sessionIdStr)) {
            startEventsBySessionId[sessionIdStr] = event;
          }
        }
      } else if (eventName == 'onboarding_completed') {
        completeEvents.add(event);
      }
    }

    final completionRate = startEventsCount > 0
        ? (completeEvents.length / startEventsCount) * 100
        : 0.0;

    // Calculate average completion time
    double averageTime = 0.0;
    if (startEventsCount > 0 && completeEvents.isNotEmpty) {
      double totalTime = 0.0;
      int validTimesCount = 0;

      for (final complete in completeEvents) {
        final sessionId = complete['session_id']?.toString();
        if (sessionId != null) {
          final start = startEventsBySessionId[sessionId];
          if (start != null) {
            final startTime = DateTime.parse(start['timestamp']);
            final endTime = DateTime.parse(complete['timestamp']);
            totalTime += endTime.difference(startTime).inSeconds.toDouble();
            validTimesCount++;
          }
        }
      }
      if (validTimesCount > 0) {
        averageTime = totalTime / validTimesCount;
      }
    }

    // Calculate drop-off points
    final dropOffPoints = <String, int>{};
    final stepCounts = <int, int>{};
    for (final event in onboardingEvents) {
      final stepNumber = event['step_number'] as int? ?? 0;
      stepCounts[stepNumber] = (stepCounts[stepNumber] ?? 0) + 1;
    }

    return {
      'total_events': onboardingEvents.length,
      'completion_rate': completionRate,
      'average_time_seconds': averageTime,
      'step_counts': stepCounts,
      'drop_off_points': dropOffPoints,
    };
  }

  // Get OAuth connection metrics
  Future<Map<String, dynamic>> getOAuthMetrics() async {
    final events = await _getStoredEvents();
    final oauthEvents = events
        .where((e) => e['event_type'] == 'oauth')
        .toList();

    final platformStats = <String, Map<String, int>>{};
    for (final event in oauthEvents) {
      final platform = event['platform'] as String;
      final action = event['action'] as String;

      platformStats[platform] ??= {'connect': 0, 'disconnect': 0, 'error': 0};
      platformStats[platform]![action] =
          (platformStats[platform]![action] ?? 0) + 1;
    }

    return {
      'total_oauth_events': oauthEvents.length,
      'platform_stats': platformStats,
    };
  }

  // Export analytics data for debugging
  Future<String> exportAnalyticsData() async {
    final events = await _getStoredEvents();
    return jsonEncode({
      'export_timestamp': DateTime.now().toIso8601String(),
      'total_events': events.length,
      'events': events,
    });
  }

  // Clear all analytics data
  Future<void> clearAnalyticsData() async {
    _eventQueue.clear();
    await _prefs?.remove('analytics_events');
    final file = await _getAnalyticsFile();
    if (file != null && await file.exists()) {
      await file.delete();
    }
  }

  /// Deletes analytics events older than [maxAge] (GDPR Art. 5 storage limitation).
  /// Call periodically — e.g., once on app launch — to enforce a 90-day retention policy.
  Future<void> pruneOldEvents({
    Duration maxAge = const Duration(days: 90),
  }) async {
    try {
      final cutoff = DateTime.now().subtract(maxAge);
      final events = await _getStoredEvents();
      final kept = events.where((e) {
        try {
          return DateTime.parse(e['timestamp'] as String).isAfter(cutoff);
        } catch (_) {
          return false;
        }
      }).toList();
      if (kept.length < events.length) {
        await _persistEvents(kept);
        _eventQueue.removeWhere((e) {
          try {
            return DateTime.parse(e['timestamp'] as String).isBefore(cutoff);
          } catch (_) {
            return true;
          }
        });
      }
    } catch (_) {}
  }

  // Private helper methods
  Future<void> _queueEvent(Map<String, dynamic> event) async {
    // Respect user's data-collection consent toggle (GDPR Art. 7).
    final dataCollectionEnabled =
        _prefs?.getBool('setting_data_collection') ?? true;
    if (!dataCollectionEnabled) return;

    _eventQueue.add(event);

    // Get all events including the new one
    final allEvents = await _getStoredEvents();
    allEvents.add(event);
    await _persistEvents(allEvents);

    if (_eventQueue.length >= _flushThreshold) {
      flushToRemote(); // fire-and-forget, does not block event tracking
    }

    // Log event in debug mode
    if (kDebugMode) {
      debugPrint(
        'Analytics Event: ${event['event_type']} - ${event['event_name'] ?? event['action']}',
      );
    }
  }

  Future<void> _persistEvents(List<Map<String, dynamic>> events) async {
    try {
      if (kIsWeb) {
        // Use SharedPreferences for web
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('analytics_events', jsonEncode(events));
      } else {
        final file = await _getAnalyticsFile();
        if (file != null) {
          // Clear existing file
          if (await file.exists()) {
            await file.delete();
          }

          // Write new events
          await file.writeAsString(jsonEncode(events));
        }
      }
    } catch (e) {
      debugPrint('Error persisting analytics events: $e');
    }
  }

  Future<void> _loadQueuedEvents() async {
    try {
      final eventsJson = _prefs?.getString('analytics_events');
      if (eventsJson != null) {
        final events = List<Map<String, dynamic>>.from(jsonDecode(eventsJson));
        _eventQueue.addAll(events);
      }
    } catch (e) {
      debugPrint('Error loading queued events: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _getStoredEvents() async {
    try {
      if (kIsWeb) {
        // Use SharedPreferences for web
        final prefs = await SharedPreferences.getInstance();
        final content = prefs.getString('analytics_events');
        if (content != null) {
          final List<dynamic> jsonList = jsonDecode(content);
          return jsonList.cast<Map<String, dynamic>>();
        }
      } else {
        final file = await _getAnalyticsFile();
        if (file != null && await file.exists()) {
          final content = await file.readAsString();
          final List<dynamic> jsonList = jsonDecode(content);
          return jsonList.cast<Map<String, dynamic>>();
        }
      }
    } catch (e) {
      debugPrint('Error loading stored analytics events: $e');
    }
    return [];
  }

  Future<File?> _getAnalyticsFile() async {
    if (kIsWeb) {
      // For web, we don't use file storage
      return null;
    }
    try {
      final directory = await getApplicationDocumentsDirectory();
      return File('${directory.path}/analytics_events.json');
    } catch (e) {
      // Fallback for web or when path_provider fails
      return null;
    }
  }

  Future<String> _getSessionId() async {
    final sessionId = _prefs?.getString('session_id');
    if (sessionId != null) {
      return sessionId;
    }

    final newSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    await _prefs?.setString('session_id', newSessionId);
    return newSessionId;
  }

  /// Returns a stable, anonymous identifier for this install.
  /// Never contains email or any other PII.
  Future<String> _getAnonymousId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('analytics_anonymous_id');
    if (id == null) {
      id = DateTime.now().millisecondsSinceEpoch.toString();
      await prefs.setString('analytics_anonymous_id', id);
    }
    return id;
  }

  /// Alias used by all event builders — routes to the anonymous ID.
  Future<String> _getUserId() async => _getAnonymousId();

  Future<String> _getAppVersion() async {
    // In a real app, you would get this from package_info_plus
    return '1.0.0';
  }

  String _getPlatform() {
    if (kIsWeb) {
      return 'web';
    }
    try {
      return Platform.operatingSystem;
    } catch (e) {
      return 'unknown';
    }
  }

  // Generic event tracking method for all types of events
  Future<void> trackEvent({
    required String eventName,
    required String eventType,
    String? screen,
    Map<String, dynamic>? additionalData,
  }) async {
    final event = {
      'event_type': eventType,
      'event_name': eventName,
      'screen': screen,
      'timestamp': DateTime.now().toIso8601String(),
      'session_id': await _getSessionId(),
      'user_id': await _getUserId(),
      'platform': _getPlatform(),
      'app_version': await _getAppVersion(),
      ...?additionalData,
    };

    await _queueEvent(event);
  }

  // ---------------------------------------------------------------------------
  // Content tracking
  // ---------------------------------------------------------------------------

  /// Called when a user watches content.
  Future<void> trackContentView({
    required String contentId,
    required String platform,
    required int durationWatched,
    required double percentWatched,
  }) async {
    final event = {
      'event_type': 'content_view',
      'event_name': 'content_viewed',
      'content_id': contentId,
      'platform': platform,
      'duration_watched_seconds': durationWatched,
      'percent_watched': percentWatched,
      'timestamp': DateTime.now().toIso8601String(),
      'session_id': await _getSessionId(),
      'user_id': await _getUserId(),
      'platform_os': _getPlatform(),
      'app_version': await _getAppVersion(),
    };
    await _queueEvent(event);
  }

  // ---------------------------------------------------------------------------
  // Search tracking
  // ---------------------------------------------------------------------------

  /// Called when the user submits a search query.
  Future<void> trackSearchQuery({
    required String query,
    required int resultCount,
  }) async {
    final event = {
      'event_type': 'search',
      'event_name': 'search_query',
      'query_length': query.length,
      'result_count': resultCount,
      'timestamp': DateTime.now().toIso8601String(),
      'session_id': await _getSessionId(),
      'user_id': await _getUserId(),
      'platform': _getPlatform(),
      'app_version': await _getAppVersion(),
    };
    await _queueEvent(event);
  }

  // ---------------------------------------------------------------------------
  // Filter tracking
  // ---------------------------------------------------------------------------

  /// Called when the user applies a filter (e.g. genre, platform, language).
  Future<void> trackFilterApplied({
    required String filterType,
    required String filterValue,
  }) async {
    final event = {
      'event_type': 'filter',
      'event_name': 'filter_applied',
      'filter_type': filterType,
      'filter_value': filterValue,
      'timestamp': DateTime.now().toIso8601String(),
      'session_id': await _getSessionId(),
      'user_id': await _getUserId(),
      'platform': _getPlatform(),
      'app_version': await _getAppVersion(),
    };
    await _queueEvent(event);
  }

  // ---------------------------------------------------------------------------
  // Language tracking
  // ---------------------------------------------------------------------------

  /// Called when the user switches the app language.
  Future<void> trackLanguageChanged({required String languageCode}) async {
    final event = {
      'event_type': 'settings',
      'event_name': 'language_changed',
      'language_code': languageCode,
      'timestamp': DateTime.now().toIso8601String(),
      'session_id': await _getSessionId(),
      'user_id': await _getUserId(),
      'platform': _getPlatform(),
      'app_version': await _getAppVersion(),
    };
    await _queueEvent(event);
  }

  // ---------------------------------------------------------------------------
  // Notification tracking
  // ---------------------------------------------------------------------------

  /// Called when the user taps a notification to open the app.
  Future<void> trackNotificationTapped({
    required String notificationId,
    required String notificationType,
  }) async {
    final event = {
      'event_type': 'notification',
      'event_name': 'notification_tapped',
      'notification_id': notificationId,
      'notification_type': notificationType,
      'timestamp': DateTime.now().toIso8601String(),
      'session_id': await _getSessionId(),
      'user_id': await _getUserId(),
      'platform': _getPlatform(),
      'app_version': await _getAppVersion(),
    };
    await _queueEvent(event);
  }

  // ---------------------------------------------------------------------------
  // Onboarding step tracking
  // ---------------------------------------------------------------------------

  /// Called at each individual onboarding step.
  Future<void> trackOnboardingStep({
    required String stepKey,
    required int stepIndex,
    required int totalSteps,
  }) async {
    final event = {
      'event_type': 'onboarding',
      'event_name': 'onboarding_step_viewed',
      'step_key': stepKey,
      'step_index': stepIndex,
      'total_steps': totalSteps,
      'timestamp': DateTime.now().toIso8601String(),
      'session_id': await _getSessionId(),
      'user_id': await _getUserId(),
      'platform': _getPlatform(),
      'app_version': await _getAppVersion(),
    };
    await _queueEvent(event);
  }

  // ---------------------------------------------------------------------------
  // Retention tracking
  // ---------------------------------------------------------------------------

  /// Record a daily app open for D1/D7/D30 retention tracking.
  Future<void> recordAppOpen() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('install_date')) {
      await prefs.setString('install_date', DateTime.now().toIso8601String());
    }
    final today = DateTime.now().toIso8601String().split('T').first;
    final activeDays = prefs.getStringList('active_days') ?? [];
    if (!activeDays.contains(today)) {
      activeDays.add(today);
      await prefs.setStringList('active_days', activeDays);
    }
  }

  Future<Map<String, dynamic>> getRetentionStats() async {
    final prefs = await SharedPreferences.getInstance();
    final installStr = prefs.getString('install_date');
    if (installStr == null) {
      return {'d1': false, 'd7': false, 'd30': false, 'total_active_days': 0};
    }
    final installDate = DateTime.parse(installStr);
    final activeDays = prefs.getStringList('active_days') ?? [];
    final now = DateTime.now();

    bool returnedOnDay(int n) {
      final target = installDate
          .add(Duration(days: n))
          .toIso8601String()
          .split('T')
          .first;
      return activeDays.contains(target);
    }

    return {
      'd1': returnedOnDay(1),
      'd7': returnedOnDay(7),
      'd30': returnedOnDay(30),
      'total_active_days': activeDays.length,
      'days_since_install': now.difference(installDate).inDays,
    };
  }
}
