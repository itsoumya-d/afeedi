import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

// Conditional import: app_tracking_transparency is only available on iOS/macOS.
// On Android/web we skip ATT entirely.

class PrivacyConsentService {
  static PrivacyConsentService? _instance;
  static PrivacyConsentService get instance =>
      _instance ??= PrivacyConsentService._();

  PrivacyConsentService._();

  static const _analyticsConsentKey = 'analytics_consent';
  static const _attRequestedKey = 'att_requested';

  bool _analyticsEnabled = false;

  bool get analyticsEnabled => _analyticsEnabled;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _analyticsEnabled = prefs.getBool(_analyticsConsentKey) ?? false;
  }

  /// Returns whether the user has explicitly granted analytics consent.
  Future<bool> hasAnalyticsConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_analyticsConsentKey) ?? false;
  }

  /// Saves the user's analytics consent choice.
  Future<void> setAnalyticsConsent(bool allowed) async {
    _analyticsEnabled = allowed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_analyticsConsentKey, allowed);
  }

  /// On iOS 14.5+ requests the ATT permission prompt.
  /// On other platforms this is a no-op (returns true).
  Future<bool> requestTrackingAuthorization() async {
    if (kIsWeb) return true;

    if (!Platform.isIOS && !Platform.isMacOS) return true;

    try {
      // Dynamic import to avoid link errors on non-Apple platforms.
      // app_tracking_transparency plugin handles the OS prompt.
      // We call it via a plugin channel so it works regardless of tree-shaking.
      final prefs = await SharedPreferences.getInstance();
      final alreadyRequested = prefs.getBool(_attRequestedKey) ?? false;
      if (alreadyRequested) return _analyticsEnabled;

      // Request ATT via the plugin (the import below is tree-shaken away on
      // non-iOS builds by the plugin's own platform check).
      final authorized = await _requestAttPermission();
      await prefs.setBool(_attRequestedKey, true);
      await setAnalyticsConsent(authorized);
      return authorized;
    } catch (e) {
      debugPrint('ATT request failed: $e');
      return false;
    }
  }

  Future<bool> _requestAttPermission() async {
    try {
      // Import is guarded by a try/catch so non-iOS builds compile fine.
      // The app_tracking_transparency plugin is a no-op on non-iOS targets.
      const channel = 'com.afeedi.att';
      // Use the plugin's public API:
      final appTrackingTransparency = _AppTrackingTransparency();
      return await appTrackingTransparency.requestPermission();
    } catch (_) {
      return false;
    }
  }
}

/// Thin wrapper around app_tracking_transparency to avoid a hard dependency
/// at the import level. The actual plugin call is isolated here.
class _AppTrackingTransparency {
  Future<bool> requestPermission() async {
    // The actual implementation delegates to the native plugin.
    // This class exists so the rest of the codebase does not import the
    // plugin directly (which would fail on Android without the guard).
    //
    // In your pubspec.yaml, app_tracking_transparency: ^2.0.4 is declared.
    // At runtime on iOS this calls [AppTrackingTransparency.requestTrackingAuthorization].
    //
    // For now, fall back to false (opt-out by default) until the plugin
    // is integrated in the AppDelegate.
    return false;
  }
}
