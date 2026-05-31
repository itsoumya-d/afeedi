import 'dart:async';
import 'package:flutter/foundation.dart';

/// Production error reporting and monitoring service.
///
/// In production, wire [_reportError] to your backend (Sentry, Firebase
/// Crashlytics, Datadog, etc.). In debug/test mode it just logs.
///
/// Usage in main():
///   ErrorReportingService.instance.initialize();
///   runZonedGuarded(
///     () => runApp(...),
///     ErrorReportingService.instance.onZoneError,
///   );
class ErrorReportingService {
  static final ErrorReportingService _instance =
      ErrorReportingService._internal();
  factory ErrorReportingService() => _instance;
  ErrorReportingService._internal();

  static ErrorReportingService get instance => _instance;

  int _errorCount = 0;
  int _warningCount = 0;
  final List<_ErrorEntry> _recentErrors = [];
  static const int _maxRecentErrors = 50;

  /// Initialize: hook into Flutter's error handler.
  void initialize() {
    final originalHandler = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      _recordError(
        details.exceptionAsString(),
        details.stack,
        context: details.context?.toDescription() ?? 'FlutterError',
        isFatal: false,
      );
      // Still call original handler (prints in debug mode)
      if (originalHandler != null) originalHandler(details);
    };
    debugPrint('ErrorReportingService: initialized');
  }

  /// Zone error handler — pass as second arg to runZonedGuarded.
  void onZoneError(Object error, StackTrace stack) {
    _recordError(
      error.toString(),
      stack,
      context: 'uncaughtZoneError',
      isFatal: true,
    );
  }

  /// Record a non-fatal error with optional [context].
  void recordError(Object error, StackTrace? stack, {String? context}) {
    _recordError(
      error.toString(),
      stack,
      context: context ?? 'manual',
      isFatal: false,
    );
  }

  /// Record a warning (lower severity than an error).
  void recordWarning(String message, {String? context}) {
    _warningCount++;
    final entry = _ErrorEntry(
      message: message,
      context: context ?? 'warning',
      severity: 'warning',
      timestamp: DateTime.now(),
    );
    _addEntry(entry);
    debugPrint('[WARNING] ${entry.context}: ${entry.message}');
  }

  // -------------------------------------------------------------------------
  // Diagnostics (useful for monitoring dashboards / admin screens)
  // -------------------------------------------------------------------------
  int get totalErrors => _errorCount;
  int get totalWarnings => _warningCount;
  List<Map<String, dynamic>> get recentErrors =>
      _recentErrors.map((e) => e.toMap()).toList();

  Map<String, dynamic> get diagnostics => {
    'total_errors': _errorCount,
    'total_warnings': _warningCount,
    'recent_count': _recentErrors.length,
    'session_start': _sessionStart.toIso8601String(),
    'uptime_seconds': DateTime.now().difference(_sessionStart).inSeconds,
  };

  final DateTime _sessionStart = DateTime.now();

  // -------------------------------------------------------------------------
  // Private
  // -------------------------------------------------------------------------
  void _recordError(
    String message,
    StackTrace? stack, {
    required String context,
    required bool isFatal,
  }) {
    _errorCount++;
    final entry = _ErrorEntry(
      message: message,
      context: context,
      severity: isFatal ? 'fatal' : 'error',
      timestamp: DateTime.now(),
      stackTrace: stack?.toString().split('\n').take(8).join('\n'),
    );
    _addEntry(entry);

    if (kDebugMode) {
      debugPrint(
        '[ERROR/${entry.severity}] ${entry.context}: ${entry.message}',
      );
    } else {
      // In release mode: send to monitoring backend
      // TODO: Replace with Sentry.captureException(error, stackTrace: stack)
      //       or FirebaseCrashlytics.instance.recordError(error, stack)
      _sendToMonitoringBackend(entry);
    }
  }

  void _addEntry(_ErrorEntry entry) {
    _recentErrors.add(entry);
    if (_recentErrors.length > _maxRecentErrors) {
      _recentErrors.removeAt(0);
    }
  }

  void _sendToMonitoringBackend(_ErrorEntry entry) {
    // Structured log for monitoring ingestion (stdout → log aggregator)
    debugPrint(
      '{"level":"${entry.severity}","context":"${entry.context}",'
      '"message":"${entry.message.replaceAll('"', '\\"')}",'
      '"timestamp":"${entry.timestamp.toIso8601String()}"}',
    );
  }
}

class _ErrorEntry {
  final String message;
  final String context;
  final String severity;
  final DateTime timestamp;
  final String? stackTrace;

  const _ErrorEntry({
    required this.message,
    required this.context,
    required this.severity,
    required this.timestamp,
    this.stackTrace,
  });

  Map<String, dynamic> toMap() => {
    'message': message,
    'context': context,
    'severity': severity,
    'timestamp': timestamp.toIso8601String(),
    if (stackTrace != null) 'stack_trace': stackTrace,
  };
}
