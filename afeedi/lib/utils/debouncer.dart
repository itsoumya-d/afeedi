import 'dart:async';
import 'package:flutter/foundation.dart';

/// A utility class for debouncing frequent events, such as search input or scroll updates.
/// It delays the execution of a function until a specified duration has passed since the last invocation.
class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    if (_timer?.isActive ?? false) {
      _timer?.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
