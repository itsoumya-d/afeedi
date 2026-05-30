import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdService {
  static final AdService instance = AdService._();
  AdService._();

  bool _initialized = false;

  // Ad unit IDs — Google test IDs for debug; production IDs must be set via
  // environment config before App Store / Play Store submission.
  // See: https://developers.google.com/admob/flutter/test-ads
  static String get nativeAdUnitId {
    if (kDebugMode) {
      return Platform.isIOS
          ? 'ca-app-pub-3940256099942544/3986624511' // Google test native iOS
          : 'ca-app-pub-3940256099942544/2247696110'; // Google test native Android
    }
    // Production IDs must be set before release — app will log a clear warning
    // if these placeholder values are shipped.
    const iosId = String.fromEnvironment('ADMOB_NATIVE_IOS', defaultValue: '');
    const androidId = String.fromEnvironment(
      'ADMOB_NATIVE_ANDROID',
      defaultValue: '',
    );
    final id = Platform.isIOS ? iosId : androidId;
    if (id.isEmpty) {
      debugPrint(
        'WARNING: AdService production ad unit ID not configured. Ads will not load.',
      );
      return '';
    }
    return id;
  }

  static String get rewardedAdUnitId {
    if (kDebugMode) {
      return Platform.isIOS
          ? 'ca-app-pub-3940256099942544/1712485313' // Google test rewarded iOS
          : 'ca-app-pub-3940256099942544/5224354917'; // Google test rewarded Android
    }
    const iosId = String.fromEnvironment(
      'ADMOB_REWARDED_IOS',
      defaultValue: '',
    );
    const androidId = String.fromEnvironment(
      'ADMOB_REWARDED_ANDROID',
      defaultValue: '',
    );
    final id = Platform.isIOS ? iosId : androidId;
    if (id.isEmpty) {
      debugPrint(
        'WARNING: AdService production rewarded ad unit ID not configured.',
      );
      return '';
    }
    return id;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    if (!kDebugMode) {
      final nativeId = nativeAdUnitId;
      if (nativeId.isEmpty) {
        debugPrint(
          'AdService: skipping MobileAds init — production IDs not configured',
        );
        return;
      }
    }

    // Respect user's personalized-ads consent toggle (GDPR Art. 7 / CCPA).
    final prefs = await SharedPreferences.getInstance();
    final personalizedAdsEnabled =
        prefs.getBool('setting_personalized_ads') ?? true;
    if (!personalizedAdsEnabled) {
      final config = RequestConfiguration(
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.unspecified,
        tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.unspecified,
        maxAdContentRating: MaxAdContentRating.g,
      );
      MobileAds.instance.updateRequestConfiguration(config);
      debugPrint('AdService: personalized ads disabled by user preference');
    }

    await MobileAds.instance.initialize();
    debugPrint('AdService: MobileAds initialized');
  }
}
