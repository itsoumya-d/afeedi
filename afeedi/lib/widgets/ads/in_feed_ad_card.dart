import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../services/ad_service.dart';

/// Native ad card inserted every 6th position in the home feed for free users.
/// Renders invisible (SizedBox.shrink) if the ad fails to load.
class InFeedAdCard extends StatefulWidget {
  const InFeedAdCard({super.key});

  @override
  State<InFeedAdCard> createState() => _InFeedAdCardState();
}

class _InFeedAdCardState extends State<InFeedAdCard> {
  NativeAd? _ad;
  bool _adLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final ad = NativeAd(
      adUnitId: AdService.nativeAdUnitId,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _adLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('InFeedAdCard failed to load: $error');
          ad.dispose();
          _ad = null;
        },
      ),
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: const Color(0xFF1A1A2E),
        cornerRadius: 12,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black,
          backgroundColor: const Color(0xFF00D4FF),
          style: NativeTemplateFontStyle.bold,
          size: 14,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          style: NativeTemplateFontStyle.bold,
          size: 14,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white70,
          style: NativeTemplateFontStyle.normal,
          size: 12,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white54,
          style: NativeTemplateFontStyle.normal,
          size: 11,
        ),
      ),
    );
    ad.load();
    _ad = ad;
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_adLoaded || _ad == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 120, maxHeight: 400),
        child: AdWidget(ad: _ad!),
      ),
    );
  }
}
