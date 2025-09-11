import 'package:flutter/material.dart';

/// Stub implementation of PlatformViewRegistrationService for non-web platforms
class PlatformViewRegistrationService {
  static final PlatformViewRegistrationService _instance = PlatformViewRegistrationService._internal();
  static PlatformViewRegistrationService get instance => _instance;
  
  // Track which platform views have been registered (always empty for stub)
  final Set<String> _registeredViewTypes = {};
  
  PlatformViewRegistrationService._internal();
  
  /// Initialize the service (no-op for non-web platforms)
  Future<void> initialize() async {
    // No-op for non-web platforms
    debugPrint('PlatformViewRegistrationService: No initialization needed for non-web platforms');
  }
  
  /// Register a specific platform view type (no-op for non-web platforms)
  Future<void> registerPlatformView(String viewType, String description) async {
    // No-op for non-web platforms
    debugPrint('PlatformViewRegistrationService: Cannot register platform views on non-web platforms');
  }
  
  /// Check if a specific view type is registered (always false for non-web platforms)
  bool isViewTypeRegistered(String viewType) => false;
  
  /// Get all registered view types (always empty for non-web platforms)
  Set<String> get registeredViewTypes => Set.from(_registeredViewTypes);
}