import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../src/stubs/ui.dart' if (dart.library.html) 'dart:ui' as ui;
import '../src/stubs/html.dart' if (dart.library.html) 'dart:html' as html;
import '../src/stubs/ui_web.dart'
    if (dart.library.html) 'dart:ui_web'
    as ui_web;

/// Service responsible for registering platform views for embedded content
/// from various social media platforms (YouTube, Instagram, TikTok, etc.)
class PlatformViewRegistrationService {
  static final PlatformViewRegistrationService _instance =
      PlatformViewRegistrationService._internal();
  static PlatformViewRegistrationService get instance => _instance;

  // Track which platform views have been registered
  final Set<String> _registeredViewTypes = {};

  PlatformViewRegistrationService._internal();

  /// Initialize the service and register all platform views
  Future<void> initialize() async {
    if (kIsWeb) {
      await _registerAllPlatformViews();
    }
  }

  /// Register all platform views used in the application
  Future<void> _registerAllPlatformViews() async {
    try {
      // ⚡ Bolt: Performance optimization
      // Use Future.wait to register platform views concurrently instead of sequentially.
      // Expected Impact: Reduces initialization time by parallelizing iframe registration.
      await Future.wait([
        for (int i = 1; i <= 10; i++)
          registerPlatformView('iframe-yt_$i', 'YouTube Player $i'),
        for (int i = 1; i <= 5; i++)
          registerPlatformView('iframe-ig_$i', 'Instagram Player $i'),
        for (int i = 1; i <= 5; i++)
          registerPlatformView('iframe-tt_$i', 'TikTok Player $i'),
        for (int i = 1; i <= 5; i++)
          registerPlatformView('iframe-fb_$i', 'Facebook Player $i'),
        for (int i = 1; i <= 5; i++)
          registerPlatformView('iframe-tw_$i', 'Twitter Player $i'),
      ]);

      debugPrint(
        'Successfully registered all platform views: ${_registeredViewTypes.join(', ')}',
      );
    } catch (e) {
      debugPrint('Error registering platform views: $e');
    }
  }

  /// Register a specific platform view type
  Future<void> registerPlatformView(String viewType, String description) async {
    if (_registeredViewTypes.contains(viewType)) {
      // Already registered
      return;
    }

    try {
      // Register the platform view factory
      ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
        // Create an iframe element
        final iframe = html.IFrameElement()
          ..style.border = 'none'
          ..style.height = '100%'
          ..style.width = '100%'
          ..allowFullscreen = true;

        // Return the iframe element
        return iframe;
      });

      // Add to registered view types
      _registeredViewTypes.add(viewType);
      debugPrint('Registered platform view: $viewType');
    } catch (e) {
      debugPrint('Error registering platform view $viewType: $e');
      rethrow;
    }
  }

  /// Check if a specific view type is registered
  bool isViewTypeRegistered(String viewType) {
    return _registeredViewTypes.contains(viewType);
  }

  /// Get all registered view types
  Set<String> get registeredViewTypes => Set.from(_registeredViewTypes);
}
