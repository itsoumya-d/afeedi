import 'dart:io';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';

/// Handles iOS App Tracking Transparency (ATT) permission.
/// Required by Apple before accessing IDFA for personalized ads (iOS 14+).
/// Must be called before MobileAds.instance.initialize().
class AttService {
  AttService._();

  static Future<void> requestTrackingIfNeeded() async {
    if (!Platform.isIOS) return;
    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
      if (kDebugMode) {
        final newStatus = await AppTrackingTransparency.trackingAuthorizationStatus;
        debugPrint('ATT status: $newStatus');
      }
    } catch (e) {
      debugPrint('ATT request failed: $e');
    }
  }
}
