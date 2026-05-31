import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/analytics_service.dart';
import 'services/content_service.dart';
import 'services/error_reporting_service.dart';
import 'services/local_auth_service.dart';
import 'services/locale_service.dart';
import 'services/navigation_service.dart';
import 'services/onboarding_service.dart';
import 'services/platform_view_registration_service.dart';
import 'services/recommendation_integration_service.dart';
import 'services/user_interaction_service.dart';
import 'services/notification_service.dart';
import 'services/subscription_service.dart';
import 'services/ad_service.dart';
import 'services/att_service.dart';
import 'services/ump_service.dart';
import 'core/theme/app_theme.dart';
import 'core/storage/local_storage_service.dart';
import 'l10n/app_localizations.dart';

/// Global theme mode notifier — updated by SettingsScreen, observed by AfeediApp.
final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

void main() {
  // Wrap in runZonedGuarded so uncaught async errors are captured by
  // ErrorReportingService rather than silently crashing.
  runZonedGuarded(_appMain, ErrorReportingService.instance.onZoneError);
}

/// Exposed for integration tests. Initializes services and runs the app.
// ignore: library_private_types_in_public_api
Future<void> appMain() => _appMain();

Future<void> _appMain() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cap image cache to 100 images / 50MB to prevent OOM on image-heavy feeds.
  // Default Flutter cache is 1000 images / 100MB — too high for long scroll sessions.
  PaintingBinding.instance.imageCache.maximumSize = 100;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20; // 50MB

  // Initialize error reporting first so all subsequent errors are captured
  ErrorReportingService.instance.initialize();

  try {
    // Initialize Hive for local storage
    await Hive.initFlutter();

    // Initialize Local Storage Service
    await LocalStorageService.instance.initialize();

    // Initialize Local Auth Service
    await LocalAuthService.instance.initialize();

    // Initialize Analytics Service
    await AnalyticsService.instance.initialize();
    await AnalyticsService.instance.recordAppOpen();
    // Prune events older than 90 days (GDPR Art. 5 storage limitation)
    AnalyticsService.instance.pruneOldEvents().catchError((_) {});

    // Parallelize all independent service initializations (cuts startup time
    // from sum-of-all to max-of-any on the critical path)
    await Future.wait([
      OnboardingService.instance.initialize(),
      RecommendationIntegrationService.instance.initialize(),
      UserInteractionService.instance.initialize(),
      NotificationService.instance.initialize(),
      LocaleService.instance.initialize(),
      SubscriptionService.instance.initialize(),
    ]);

    // ContentService — non-blocking background fetch (falls back to seed data)
    ContentService.instance.initialize().catchError(
      (e) => debugPrint('ContentService background init error: $e'),
    );

    // Initialize Platform View Registration Service for web
    if (kIsWeb) {
      await PlatformViewRegistrationService.instance.initialize();
    }

    // Track app launch (non-blocking)
    AnalyticsService.instance
        .trackUserInteraction(action: 'app_launch', screen: 'main')
        .catchError((e) => debugPrint('Analytics launch error: $e'));

    // Update daily streak (non-blocking)
    _updateDailyStreak().catchError(
      (e) => debugPrint('Streak update error: $e'),
    );

    // Request iOS App Tracking Transparency before initializing AdMob (required by Apple)
    await AttService.requestTrackingIfNeeded();

    // Request GDPR/EU consent via Google UMP before AdMob initializes (required by Play Policy)
    await UmpService.requestConsentIfRequired();

    // Initialize AdMob (non-blocking; ads load lazily when widgets mount)
    AdService.instance
        .initialize()
        .then((_) {
          // Preload rewarded ad immediately after init so it's ready when needed
          AdService.instance.loadRewardedAd().catchError(
            (e) => debugPrint('AdService rewarded preload error: $e'),
          );
        })
        .catchError((e) => debugPrint('AdService init error: $e'));
  } catch (error) {
    // Handle initialization errors
    debugPrint('Initialization error: $error');
  }

  runApp(const ProviderScope(child: AfeediApp()));
}

Future<void> _updateDailyStreak() async {
  final prefs = await SharedPreferences.getInstance();
  final today = DateTime.now();
  final todayStr =
      '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  final lastDateStr = prefs.getString('stat_streak_last_date');
  final currentStreak = prefs.getInt('stat_streak_days') ?? 0;

  if (lastDateStr == null) {
    await prefs.setInt('stat_streak_days', 1);
    await prefs.setString('stat_streak_last_date', todayStr);
    return;
  }

  if (lastDateStr == todayStr) return; // Already counted today

  final lastDate = DateTime.parse(lastDateStr);
  final diff = today.difference(lastDate).inDays;
  if (diff == 1) {
    await prefs.setInt('stat_streak_days', currentStreak + 1);
  } else {
    await prefs.setInt('stat_streak_days', 1);
  }
  await prefs.setString('stat_streak_last_date', todayStr);
}

class AfeediApp extends StatefulWidget {
  const AfeediApp({super.key});

  @override
  State<AfeediApp> createState() => _AfeediAppState();
}

class _AfeediAppState extends State<AfeediApp> with WidgetsBindingObserver {
  String _initialRoute = AppRoutes.welcome;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _determineInitialRoute();
    _loadThemeSetting();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didHaveMemoryPressure() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    super.didHaveMemoryPressure();
  }

  Future<void> _determineInitialRoute() async {
    try {
      final isLoggedIn = LocalAuthService.instance.currentUser != null;
      if (isLoggedIn) {
        final onboarded = await OnboardingService.instance
            .isOnboardingCompleted();
        _initialRoute = onboarded
            ? AppRoutes.dashboard
            : AppRoutes.onboardingChatbot;
      } else {
        _initialRoute = AppRoutes.welcome;
      }
    } catch (_) {
      _initialRoute = AppRoutes.welcome;
    }
    if (mounted) setState(() => _ready = true);
  }

  Future<void> _loadThemeSetting() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool('setting_dark_mode');
      if (isDark != null && mounted) {
        themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Color(0xFF1A1A2E),
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFF00D4FF)),
          ),
        ),
      );
    }
    return ListenableBuilder(
      listenable: LocaleService.instance,
      builder: (_, __) => ValueListenableBuilder<ThemeMode>(
        valueListenable: themeModeNotifier,
        builder: (_, themeMode, __) => MaterialApp(
          title: 'Afeedi - Social Media Aggregation',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          locale: LocaleService.instance.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          navigatorKey: NavigationService.navigatorKey,
          initialRoute: _initialRoute,
          routes: AppRoutes.routes,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
