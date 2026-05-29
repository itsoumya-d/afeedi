import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'services/navigation_service.dart';
import 'services/analytics_service.dart';
import 'services/onboarding_service.dart';
import 'services/recommendation_integration_service.dart';
import 'services/platform_view_registration_service.dart';
import 'services/local_auth_service.dart';
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
    
    // Initialize Analytics Service
    await AnalyticsService.instance.initialize();
    
    // Initialize Onboarding Service
    await OnboardingService.instance.initialize();
    
    // Initialize Recommendation Integration Service
    await RecommendationIntegrationService.instance.initialize();
    
    // Initialize Platform View Registration Service for web
    if (kIsWeb) {
      await PlatformViewRegistrationService.instance.initialize();
    }
    
    // Track app launch
    await AnalyticsService.instance.trackUserInteraction(
      action: 'app_launch',
      screen: 'main',
    );
    
  } catch (error) {
    // Handle initialization errors
    debugPrint('Initialization error: $error');
  }
  
  runApp(const ProviderScope(child: AfeediApp()));
}

class AfeediApp extends StatefulWidget {
  const AfeediApp({super.key});

  @override
  State<AfeediApp> createState() => _AfeediAppState();
}

class _AfeediAppState extends State<AfeediApp> {
  String _initialRoute = AppRoutes.welcome;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _determineInitialRoute();
  }

  Future<void> _determineInitialRoute() async {
    try {
      final isLoggedIn = LocalAuthService.instance.currentUser != null;
      if (isLoggedIn) {
        final onboarded = await OnboardingService.instance.isOnboardingCompleted();
        _initialRoute = onboarded ? AppRoutes.dashboard : AppRoutes.onboardingChatbot;
      } else {
        _initialRoute = AppRoutes.welcome;
      }
    } catch (_) {
      _initialRoute = AppRoutes.welcome;
    }
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Color(0xFF1A1A2E),
          body: Center(child: CircularProgressIndicator(color: Color(0xFF00D4FF))),
        ),
      );
    }
    return MaterialApp(
      title: 'Afeedi - Social Media Aggregation',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      navigatorKey: NavigationService.navigatorKey,
      initialRoute: _initialRoute,
      routes: AppRoutes.routes,
      debugShowCheckedModeBanner: false,
    );
  }
}
