import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Google User Messaging Platform (UMP) — GDPR consent for EU/EEA users.
/// Required by Google Play Policy (Jan 2024) before initializing AdMob.
/// Call [requestConsentIfRequired] before [MobileAds.instance.initialize()].
class UmpService {
  UmpService._();

  static Future<void> requestConsentIfRequired() async {
    try {
      final params = ConsentRequestParameters();
      ConsentInformation.instance.requestConsentInfoUpdate(
        params,
        () async {
          // Consent info updated — load form if required
          if (await ConsentInformation.instance.isConsentFormAvailable()) {
            await _loadAndShowConsentForm();
          }
        },
        (FormError error) {
          debugPrint('UMP consent info update failed: ${error.message}');
        },
      );
    } catch (e) {
      debugPrint('UMP: consent request failed: $e');
    }
  }

  static Future<void> _loadAndShowConsentForm() async {
    try {
      await ConsentForm.loadAndShowConsentFormIfRequired(
        (FormError? error) {
          if (error != null) {
            debugPrint('UMP: consent form error: ${error.message}');
          }
        },
      );
    } catch (e) {
      debugPrint('UMP: failed to show consent form: $e');
    }
  }

  /// Returns true if personalized ads are allowed (consent given or not required).
  static Future<bool> canShowPersonalizedAds() async {
    try {
      final status = await ConsentInformation.instance.getConsentStatus();
      return status == ConsentStatus.obtained || status == ConsentStatus.notRequired;
    } catch (_) {
      return false;
    }
  }
}
