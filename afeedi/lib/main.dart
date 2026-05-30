import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'screens/welcome_screen.dart';
import 'services/navigation_service.dart';
import 'services/analytics_service.dart';
import 'services/onboarding_service.dart';
import 'services/recommendation_integration_service.dart';
import 'services/platform_view_registration_service.dart';
import 'services/local_auth_service.dart';
import 'services/privacy_consent_service.dart';
import 'core/theme/app_theme.dart';
import 'core/storage/local_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Hive for local storage
    await Hive.initFlutter();

    // Initialize Local Storage Service
    await LocalStorageService.instance.initialize();

    // Initialize Local Auth Service
    await LocalAuthService.instance.initialize();

    // Initialize Privacy Consent Service BEFORE analytics.
    // Analytics must not start until consent is confirmed.
    await PrivacyConsentService.instance.initialize();

    // Initialize Analytics Service — events are gated by consent flag.
    await AnalyticsService.instance.initialize();

    // Apply the stored consent preference to AnalyticsService.
    final hasConsent = await PrivacyConsentService.instance.hasAnalyticsConsent();
    AnalyticsService.instance.setConsentGranted(hasConsent);

    // On iOS 14.5+, request App Tracking Transparency permission.
    // This must happen before any tracking begins.
    if (!kIsWeb) {
      final attGranted =
          await PrivacyConsentService.instance.requestTrackingAuthorization();
      AnalyticsService.instance.setConsentGranted(attGranted);
    }

    // Initialize Onboarding Service
    await OnboardingService.instance.initialize();

    // Initialize Recommendation Integration Service
    await RecommendationIntegrationService.instance.initialize();

    // Initialize Platform View Registration Service for web
    if (kIsWeb) {
      await PlatformViewRegistrationService.instance.initialize();
    }

    // Track app launch only if consent was given
    await AnalyticsService.instance.trackUserInteraction(
      action: 'app_launch',
      screen: 'main',
    );
  } catch (error) {
    debugPrint('Initialization error: $error');
  }

  runApp(const ProviderScope(child: AfeediApp()));
}

class AfeediApp extends StatelessWidget {
  const AfeediApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Afeedi - Social Media Aggregation',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      navigatorKey: NavigationService.navigatorKey,
      initialRoute: AppRoutes.enhancedOnboarding,
      routes: AppRoutes.routes,
      debugShowCheckedModeBanner: false,
    );
  }
}
