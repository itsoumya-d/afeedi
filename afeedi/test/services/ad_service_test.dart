import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:afeedi/services/ad_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // MobileAds uses two channels — return minimal stubs so initialize() succeeds.
    const admobChannel = MethodChannel('plugins.flutter.io/google_mobile_ads');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(admobChannel, (call) async => null);
  });

  group('AdService', () {
    test('singleton returns same instance', () {
      final a = AdService.instance;
      final b = AdService.instance;
      expect(identical(a, b), isTrue);
    });

    test('nativeAdUnitId returns non-empty Google test ID in debug mode', () {
      // kDebugMode is true during flutter test runs — always uses test IDs
      if (kDebugMode) {
        expect(AdService.nativeAdUnitId, isNotEmpty);
        expect(AdService.nativeAdUnitId, startsWith('ca-app-pub-'));
      }
    });

    test('rewardedAdUnitId returns non-empty Google test ID in debug mode', () {
      if (kDebugMode) {
        expect(AdService.rewardedAdUnitId, isNotEmpty);
        expect(AdService.rewardedAdUnitId, startsWith('ca-app-pub-'));
      }
    });

    test('initialize() completes without throwing', () async {
      await expectLater(AdService.instance.initialize(), completes);
    });

    test('initialize() is idempotent — repeated calls do not throw', () async {
      await AdService.instance.initialize();
      await expectLater(AdService.instance.initialize(), completes);
    });
  });
}
