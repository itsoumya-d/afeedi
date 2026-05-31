import 'dart:io' show InternetAddress;
import 'package:flutter/foundation.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._();
  ConnectivityService._();
  static ConnectivityService get instance => _instance;

  // Since we don't have connectivity_plus package, use a simple HTTP check
  Future<bool> isConnected() async {
    if (kIsWeb) return true; // Web always connected for our purposes
    try {
      // Try to resolve a known host
      final result = await InternetAddress.lookup('8.8.8.8');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
