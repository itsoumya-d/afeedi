import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:afeedi/services/subscription_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('SubscriptionIds', () {
    test('product IDs match store configuration', () {
      expect(SubscriptionIds.monthly, 'afeedi_pro_monthly');
      expect(SubscriptionIds.yearly, 'afeedi_pro_yearly');
      expect(SubscriptionIds.all, contains(SubscriptionIds.monthly));
      expect(SubscriptionIds.all, contains(SubscriptionIds.yearly));
    });

    test('prices are correct', () {
      expect(SubscriptionIds.monthlyPrice, 4.99);
      expect(SubscriptionIds.yearlyPrice, 39.99);
      expect(SubscriptionIds.trialDays, 7);
      // Yearly monthly equivalent should be cheaper than monthly
      expect(SubscriptionIds.yearlyMonthlyEquivalent,
          lessThan(SubscriptionIds.monthlyPrice));
    });
  });

  group('SubscriptionService — initial state', () {
    test('starts as free tier', () {
      expect(SubscriptionService.instance.tier, SubscriptionTier.free);
      expect(SubscriptionService.instance.isPremium, false);
    });

    test('starts with idle purchase state', () {
      expect(SubscriptionService.instance.purchaseState, PurchaseState.idle);
      expect(SubscriptionService.instance.isLoading, false);
      expect(SubscriptionService.instance.errorMessage, isNull);
    });

    test('starts with empty products list', () {
      expect(SubscriptionService.instance.products, isEmpty);
    });
  });

  group('SubscriptionService — debugSetPremium', () {
    test('debugSetPremium(true) grants premium tier', () async {
      await SubscriptionService.instance.debugSetPremium(true);
      expect(SubscriptionService.instance.isPremium, true);
      expect(SubscriptionService.instance.tier, SubscriptionTier.pro);
    });

    test('debugSetPremium(false) reverts to free tier', () async {
      await SubscriptionService.instance.debugSetPremium(true);
      await SubscriptionService.instance.debugSetPremium(false);
      expect(SubscriptionService.instance.isPremium, false);
      expect(SubscriptionService.instance.tier, SubscriptionTier.free);
    });
  });

  group('SubscriptionService — trial', () {
    test('hasUsedTrial returns false by default', () async {
      final used = await SubscriptionService.instance.hasUsedTrial();
      expect(used, false);
    });

    test('markTrialUsed persists the flag', () async {
      await SubscriptionService.instance.markTrialUsed();
      final used = await SubscriptionService.instance.hasUsedTrial();
      expect(used, true);
    });
  });

  group('SubscriptionService — paywall triggers', () {
    test('shouldShowProactivePaywall returns false for premium users', () async {
      await SubscriptionService.instance.debugSetPremium(true);
      final show = await SubscriptionService.instance.shouldShowProactivePaywall();
      expect(show, false);
      await SubscriptionService.instance.debugSetPremium(false);
    });

    test('shouldGateBookmarks returns false for premium users', () async {
      await SubscriptionService.instance.debugSetPremium(true);
      final gate = await SubscriptionService.instance.shouldGateBookmarks();
      expect(gate, false);
      await SubscriptionService.instance.debugSetPremium(false);
    });

    test('shouldShowShortsUpsell returns false for premium users', () async {
      await SubscriptionService.instance.debugSetPremium(true);
      final show = await SubscriptionService.instance.shouldShowShortsUpsell(20);
      expect(show, false);
      await SubscriptionService.instance.debugSetPremium(false);
    });

    test('shouldShowShortsUpsell triggers every 20 scrolls for free users', () async {
      expect(await SubscriptionService.instance.shouldShowShortsUpsell(0), false);
      expect(await SubscriptionService.instance.shouldShowShortsUpsell(19), false);
      expect(await SubscriptionService.instance.shouldShowShortsUpsell(20), true);
      expect(await SubscriptionService.instance.shouldShowShortsUpsell(21), false);
      expect(await SubscriptionService.instance.shouldShowShortsUpsell(40), true);
      expect(await SubscriptionService.instance.shouldShowShortsUpsell(60), true);
    });
  });

  group('SubscriptionService — resetError', () {
    test('resetError clears error state', () {
      SubscriptionService.instance.resetError();
      expect(SubscriptionService.instance.purchaseState, PurchaseState.idle);
      expect(SubscriptionService.instance.errorMessage, isNull);
    });
  });
}
