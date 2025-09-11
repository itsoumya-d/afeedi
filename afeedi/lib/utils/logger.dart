import 'package:flutter/foundation.dart';

/// Simple logging utility for the application
class Logger {
  static const String _tag = 'Afeedi';

  /// Log an info message
  static void info(String message) {
    if (kDebugMode) {
      print('[$_tag] INFO: $message');
    }
  }

  /// Log an error message
  static void error(String message) {
    if (kDebugMode) {
      print('[$_tag] ERROR: $message');
    }
  }

  /// Log a warning message
  static void warning(String message) {
    if (kDebugMode) {
      print('[$_tag] WARNING: $message');
    }
  }

  /// Log a debug message
  static void debug(String message) {
    if (kDebugMode) {
      print('[$_tag] DEBUG: $message');
    }
  }
}