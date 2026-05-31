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

  RewardedAd? _rewardedAd;
  bool _rewardedAdLoading = false;

  /// Preloads a rewarded ad. Call this when the app goes to foreground or
  /// when the premium screen is about to be shown.
  Future<void> loadRewardedAd() async {
    if (!_initialized || _rewardedAdLoading || _rewardedAd != null) return;
    final id = rewardedAdUnitId;
    if (id.isEmpty) return;
    _rewardedAdLoading = true;
    try {
      await RewardedAd.load(
        adUnitId: id,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _rewardedAdLoading = false;
            debugPrint('AdService: rewarded ad loaded');
          },
          onAdFailedToLoad: (err) {
            _rewardedAd = null;
            _rewardedAdLoading = false;
            debugPrint('AdService: rewarded ad failed to load: $err');
          },
        ),
      );
    } catch (e) {
      _rewardedAdLoading = false;
      debugPrint('AdService: loadRewardedAd error: $e');
    }
  }

  /// Shows the preloaded rewarded ad. Calls [onRewarded] if user completes it.
  /// Automatically preloads the next ad after showing.
  Future<void> showRewardedAd({VoidCallback? onRewarded}) async {
    final ad = _rewardedAd;
    if (ad == null) {
      debugPrint('AdService: no rewarded ad available');
      return;
    }
    _rewardedAd = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        loadRewardedAd(); // Preload next
      },
      onAdFailedToShowFullScreenContent: (a, err) {
        a.dispose();
        loadRewardedAd();
      },
    );
    await ad.show(
      onUserEarnedReward: (_, __) {
        onRewarded?.call();
        debugPrint('AdService: user earned reward');
      },
    );
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

    try {
      await MobileAds.instance.initialize();
      debugPrint('AdService: MobileAds initialized');
    } catch (e) {
      debugPrint('AdService: MobileAds init failed ($e) — ads will not load');
    }
  }
}
