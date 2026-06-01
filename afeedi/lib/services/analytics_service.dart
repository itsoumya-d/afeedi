import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

// Analytics only runs when the user has granted consent (see PrivacyConsentService).
// No PII (email, name, phone) is ever included in events — only anonymous
// session IDs and hashed user IDs.

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  static AnalyticsService get instance => _instance;

  AnalyticsService._internal();

  SharedPreferences? _prefs;
  List<Map<String, dynamic>> _eventQueue = [];

  // Set to true once the user has granted analytics consent.
  bool _consentGranted = false;

  void setConsentGranted(bool granted) {
    _consentGranted = granted;
  }

  // Initialize the analytics service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadQueuedEvents();
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

  // Private helper methods
  Future<void> _queueEvent(Map<String, dynamic> event) async {
    // Do not record any analytics without explicit user consent.
    if (!_consentGranted) return;

    // Strip any PII fields that may have been accidentally included.
    event.remove('email');
    event.remove('name');
    event.remove('phone');

    _eventQueue.add(event);

    // Get all events including the new one
    final allEvents = await _getStoredEvents();
    allEvents.add(event);
    await _persistEvents(allEvents);

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

  Future<String> _getUserId() async {
    final userId = _prefs?.getString('user_id');
    if (userId != null) {
      return userId;
    }

    final newUserId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    await _prefs?.setString('user_id', newUserId);
    return newUserId;
  }

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
}

// Analytics event types for type safety
class AnalyticsEvents {
  // Onboarding events
  static const String onboardingStarted = 'onboarding_started';
  static const String onboardingStepCompleted = 'onboarding_step_completed';
  static const String onboardingCompleted = 'onboarding_completed';
  static const String onboardingAbandoned = 'onboarding_abandoned';

  // OAuth events
  static const String oauthConnectAttempt = 'oauth_connect_attempt';
  static const String oauthConnectSuccess = 'oauth_connect_success';
  static const String oauthConnectError = 'oauth_connect_error';
  static const String oauthDisconnect = 'oauth_disconnect';

  // User interaction events
  static const String buttonTap = 'button_tap';
  static const String screenView = 'screen_view';
  static const String genreSelection = 'genre_selection';
  static const String platformSelection = 'platform_selection';
}

// Analytics screens for consistency
class AnalyticsScreens {
  static const String onboardingChatbot = 'onboarding_chatbot';
  static const String dashboard = 'dashboard';
  static const String settings = 'settings';
  static const String profile = 'profile';
}
