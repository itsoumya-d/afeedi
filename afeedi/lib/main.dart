import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/dashboard_screen.dart';
import 'screens/enhanced_onboarding_flow.dart';
import 'screens/gdpr_consent_screen.dart';
import 'services/navigation_service.dart';
import 'services/analytics_service.dart';
import 'services/onboarding_service.dart';
import 'services/recommendation_integration_service.dart';
import 'services/platform_view_registration_service.dart';
import 'services/local_auth_service.dart';
import 'services/streak_service.dart';
import 'core/theme/app_theme.dart';
import 'core/storage/local_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Hive.initFlutter();
    await LocalStorageService.instance.initialize();
    await LocalAuthService.instance.initialize();
    await AnalyticsService.instance.initialize();
    await OnboardingService.instance.initialize();
    await RecommendationIntegrationService.instance.initialize();

    if (kIsWeb) {
      await PlatformViewRegistrationService.instance.initialize();
    }

    await AnalyticsService.instance.trackUserInteraction(
      action: 'app_launch',
      screen: 'main',
    );

    StreakService.instance.recordActivity();

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
      home: const _AppGate(),
      routes: AppRoutes.routes,
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Outer gate: checks GDPR consent first, then routes by auth state.
class _AppGate extends StatefulWidget {
  const _AppGate();

  @override
  State<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<_AppGate> {
  bool? _consentGiven;

  @override
  void initState() {
    super.initState();
    _checkConsent();
  }

  Future<void> _checkConsent() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _consentGiven = prefs.getBool('gdpr_consent_given') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_consentGiven == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0B1E),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00D4FF))),
      );
    }
    if (!_consentGiven!) {
      return GdprConsentScreen(
        onConsented: () => setState(() => _consentGiven = true),
      );
    }
    return const _AuthGate();
  }
}

/// Inner gate: routes authenticated users to dashboard, others to onboarding.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    if (LocalAuthService.instance.isAuthenticated) {
      return const DashboardScreen();
    }
    return EnhancedOnboardingFlow(
      onComplete: () => Navigator.pushReplacementNamed(context, AppRoutes.dashboard),
    );
  }
}
