import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/navigation_service.dart';
import 'services/analytics_service.dart';
import 'services/onboarding_service.dart';
import 'services/recommendation_integration_service.dart';
import 'services/platform_view_registration_service.dart';
import 'services/local_auth_service.dart';
import 'services/privacy_consent_service.dart';
import 'services/locale_service.dart';
import 'core/theme/app_theme.dart';
import 'core/storage/local_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Hive.initFlutter();
    await LocalStorageService.instance.initialize();
    await LocalAuthService.instance.initialize();

    // Privacy consent must be initialized before analytics.
    await PrivacyConsentService.instance.initialize();
    await AnalyticsService.instance.initialize();

    final hasConsent =
        await PrivacyConsentService.instance.hasAnalyticsConsent();
    AnalyticsService.instance.setConsentGranted(hasConsent);

    // iOS 14.5+: request App Tracking Transparency before any tracking.
    if (!kIsWeb) {
      final attGranted =
          await PrivacyConsentService.instance.requestTrackingAuthorization();
      AnalyticsService.instance.setConsentGranted(attGranted);
    }

    await OnboardingService.instance.initialize();
    await RecommendationIntegrationService.instance.initialize();

    if (kIsWeb) {
      await PlatformViewRegistrationService.instance.initialize();
    }

    await AnalyticsService.instance.trackUserInteraction(
      action: 'app_launch',
      screen: 'main',
    );
  } catch (error) {
    debugPrint('Initialization error: $error');
  }

  runApp(const ProviderScope(child: AfeediApp()));
}

class AfeediApp extends StatefulWidget {
  const AfeediApp({super.key});

  @override
  State<AfeediApp> createState() => AfeediAppState();

  static AfeediAppState of(BuildContext context) {
    return context.findAncestorStateOfType<AfeediAppState>()!;
  }
}

class AfeediAppState extends State<AfeediApp> {
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final locale = await LocaleService.instance.getLocale();
    if (mounted) setState(() => _locale = locale);
  }

  Future<void> setLocale(Locale locale) async {
    await LocaleService.instance.setLocale(locale);
    if (mounted) setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Afeedi - Social Media Aggregation',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      locale: _locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: LocaleService.instance.supportedLocales,
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        if (deviceLocale != null) {
          for (final supported in supportedLocales) {
            if (supported.languageCode == deviceLocale.languageCode) {
              return supported;
            }
          }
        }
        return const Locale('en');
      },
      navigatorKey: NavigationService.navigatorKey,
      initialRoute: AppRoutes.worldClassOnboarding,
      routes: AppRoutes.routes,
      debugShowCheckedModeBanner: false,
    );
  }
}
