import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'screens/welcome_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/enhanced_onboarding_flow.dart';
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
      debugShowCheckedModeBanner: false,
      home: _buildInitialScreen(),
      routes: AppRoutes.routes,
    );
  }

  Widget _buildInitialScreen() {
    return FutureBuilder<bool>(
      future: OnboardingService.instance.isOnboardingCompleted(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF1A0A3E),
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
              ),
            ),
          );
        }

        final isCompleted = snapshot.data ?? false;

        if (isCompleted) {
          return const DashboardScreen();
        } else {
          return EnhancedOnboardingFlow(
            onComplete: () {
              Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
            },
          );
        }
      },
    );
  }
}
