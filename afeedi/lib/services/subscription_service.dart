import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'analytics_service.dart';

/// Product IDs — must match exactly what's configured in App Store Connect & Google Play Console
class SubscriptionIds {
  static const String monthly = 'afeedi_pro_monthly';
  static const String yearly = 'afeedi_pro_yearly';
  static const Set<String> all = {monthly, yearly};

  // Prices shown in the paywall (overridden by store-fetched prices when available)
  static const double monthlyPrice = 4.99;
  static const double yearlyPrice = 39.99;
  static const double yearlyMonthlyEquivalent = 3.33; // 39.99/12
  static const int trialDays = 7;
}

enum SubscriptionTier { free, pro }

enum PurchaseState { idle, loading, success, error }

class SubscriptionService extends ChangeNotifier {
  static final SubscriptionService instance = SubscriptionService._();
  SubscriptionService._();

  static const _prefKey = 'is_premium';
  static const _expiryKey = 'subscription_expiry';
  static const _trialKey = 'trial_used';
  static const _openCountKey = 'app_open_count';

  SubscriptionTier _tier = SubscriptionTier.free;
  PurchaseState _purchaseState = PurchaseState.idle;
  String? _errorMessage;
  List<ProductDetails> _products = [];
  bool _isInitialized = false;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  SubscriptionTier get tier => _tier;
  bool get isPremium => _tier == SubscriptionTier.pro;
  PurchaseState get purchaseState => _purchaseState;
  String? get errorMessage => _errorMessage;
  List<ProductDetails> get products => _products;
  bool get isLoading => _purchaseState == PurchaseState.loading;

  ProductDetails? get monthlyProduct =>
      _products.where((p) => p.id == SubscriptionIds.monthly).firstOrNull;
  ProductDetails? get yearlyProduct =>
      _products.where((p) => p.id == SubscriptionIds.yearly).firstOrNull;

  /// Initialize on app startup — load local state first, then verify with store
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // 1. Load cached premium state immediately (fast path)
    await _loadCachedState();

    // 2. Listen to purchase stream
    final purchaseStream = InAppPurchase.instance.purchaseStream;
    _purchaseSubscription = purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (error) => debugPrint('Purchase stream error: $error'),
    );

    // 3. Load available products in background
    await _loadProducts();

    // 4. Restore purchases to catch subscriptions from other devices
    await _restoreSilently();

    // 5. Increment open count (for paywall trigger logic)
    await _incrementOpenCount();
  }

  Future<void> _loadCachedState() async {
    final prefs = await SharedPreferences.getInstance();
    final isPremium = prefs.getBool(_prefKey) ?? false;
    final expiryStr = prefs.getString(_expiryKey);

    if (isPremium && expiryStr != null) {
      final expiry = DateTime.tryParse(expiryStr);
      if (expiry != null && expiry.isAfter(DateTime.now())) {
        _tier = SubscriptionTier.pro;
      } else {
        // Expired — revert to free
        await prefs.setBool(_prefKey, false);
        _tier = SubscriptionTier.free;
      }
    } else if (isPremium) {
      // No expiry stored (legacy or lifetime) — keep premium
      _tier = SubscriptionTier.pro;
    }
    notifyListeners();
  }

  Future<void> _loadProducts() async {
    if (!await InAppPurchase.instance.isAvailable()) {
      debugPrint('SubscriptionService: Store not available');
      return;
    }
    try {
      final response = await InAppPurchase.instance.queryProductDetails(
        SubscriptionIds.all,
      );
      if (response.error != null) {
        debugPrint('Product load error: ${response.error}');
      }
      _products = response.productDetails;
      notifyListeners();
    } catch (e) {
      debugPrint('SubscriptionService._loadProducts error: $e');
    }
  }

  Future<void> _restoreSilently() async {
    try {
      await InAppPurchase.instance.restorePurchases();
    } catch (e) {
      debugPrint('Silent restore error: $e');
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _purchaseState = PurchaseState.loading;
          notifyListeners();
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _verifyAndGrant(purchase);
          if (purchase.pendingCompletePurchase) {
            await InAppPurchase.instance.completePurchase(purchase);
          }
          break;

        case PurchaseStatus.error:
          _purchaseState = PurchaseState.error;
          _errorMessage = purchase.error?.message ?? 'Purchase failed';
          notifyListeners();
          break;

        case PurchaseStatus.canceled:
          _purchaseState = PurchaseState.idle;
          notifyListeners();
          break;
      }
    }
  }

  Future<void> _verifyAndGrant(PurchaseDetails purchase) async {
    // In production: verify receipt server-side before granting
    // For now: trust the store (acceptable for MVP, replace with server verification pre-launch)
    final prefs = await SharedPreferences.getInstance();

    final isYearly = purchase.productID == SubscriptionIds.yearly;
    final expiry = DateTime.now().add(
      isYearly ? const Duration(days: 365) : const Duration(days: 31),
    );

    await prefs.setBool(_prefKey, true);
    await prefs.setString(_expiryKey, expiry.toIso8601String());

    _tier = SubscriptionTier.pro;
    _purchaseState = PurchaseState.success;
    notifyListeners();

    final price = isYearly
        ? SubscriptionIds.yearlyPrice
        : SubscriptionIds.monthlyPrice;
    AnalyticsService.instance
        .trackSubscriptionPurchase(
          planId: purchase.productID,
          amount: price,
          currency: 'USD',
        )
        .catchError((_) {});
  }

  /// Purchase monthly subscription
  Future<void> purchaseMonthly() async {
    await _purchase(SubscriptionIds.monthly);
  }

  /// Purchase yearly subscription
  Future<void> purchaseYearly() async {
    await _purchase(SubscriptionIds.yearly);
  }

  Future<void> _purchase(String productId) async {
    final product = _products.where((p) => p.id == productId).firstOrNull;
    if (product == null) {
      // Store not available — use dev override for testing
      if (kDebugMode) await _devGrantPremium();
      return;
    }
    _purchaseState = PurchaseState.loading;
    _errorMessage = null;
    notifyListeners();

    final param = PurchaseParam(productDetails: product);
    try {
      await InAppPurchase.instance.buyNonConsumable(purchaseParam: param);
    } catch (e) {
      _purchaseState = PurchaseState.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Restore purchases (user-initiated, e.g., from paywall)
  Future<void> restorePurchases() async {
    _purchaseState = PurchaseState.loading;
    notifyListeners();
    try {
      await InAppPurchase.instance.restorePurchases();
      // Result comes via purchaseStream
    } catch (e) {
      _purchaseState = PurchaseState.error;
      _errorMessage = 'Restore failed. Check your account and try again.';
      notifyListeners();
    }
  }

  /// Dev-only: grant premium without store (debug builds / testing)
  Future<void> _devGrantPremium() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);
    final expiry = DateTime.now().add(const Duration(days: 365));
    await prefs.setString(_expiryKey, expiry.toIso8601String());
    _tier = SubscriptionTier.pro;
    _purchaseState = PurchaseState.success;
    notifyListeners();
  }

  /// For testing only — simulate premium
  Future<void> debugSetPremium(bool value) async {
    if (!kDebugMode) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
    _tier = value ? SubscriptionTier.pro : SubscriptionTier.free;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Paywall trigger logic — data-driven, not arbitrary
  // ---------------------------------------------------------------------------

  Future<void> _incrementOpenCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_openCountKey) ?? 0) + 1;
    await prefs.setInt(_openCountKey, count);
  }

  /// Returns true if this app open should proactively show the paywall
  /// Triggers: open 3 (Day 2 rule — highest converting moment per industry data)
  Future<bool> shouldShowProactivePaywall() async {
    if (isPremium) return false;
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_openCountKey) ?? 0;
    final lastShown = prefs.getInt('paywall_last_shown_open') ?? 0;
    // Show on 3rd open, then every 10th open after that
    if (count == 3 || (count > 3 && count - lastShown >= 10)) {
      await prefs.setInt('paywall_last_shown_open', count);
      return true;
    }
    return false;
  }

  /// Returns true if user has hit enough bookmarks to warrant paywall
  Future<bool> shouldGateBookmarks() async {
    if (isPremium) return false;
    final prefs = await SharedPreferences.getInstance();
    final savedCount = prefs
        .getKeys()
        .where((k) => k.startsWith('saved_') && prefs.getBool(k) == true)
        .length;
    return savedCount >= 10;
  }

  /// Returns true if Shorts scroll count warrants soft paywall prompt
  Future<bool> shouldShowShortsUpsell(int scrollCount) async {
    if (isPremium) return false;
    return scrollCount > 0 && scrollCount % 20 == 0;
  }

  Future<bool> hasUsedTrial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_trialKey) ?? false;
  }

  Future<void> markTrialUsed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_trialKey, true);
  }

  void resetError() {
    _purchaseState = PurchaseState.idle;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }
}
