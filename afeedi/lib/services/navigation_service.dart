import 'package:flutter/material.dart';
import 'user_service.dart';
import '../screens/welcome_screen.dart';
import '../screens/create_account_screen.dart';
import '../screens/login_screen.dart';
import '../screens/onboarding/enhanced_onboarding_screen.dart';
import '../screens/onboarding/new_onboarding_screen.dart';
import '../screens/enhanced_onboarding_flow.dart';
import '../screens/feed_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/interest_form_screen.dart';
import '../screens/source_preference_screen.dart';
import '../screens/calendar_customization_screen.dart';
import '../screens/personalized_home_screen.dart';
import '../screens/search_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/placeholder_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/create_content_screen.dart';
import '../screens/player_screen.dart';
import '../screens/privacy_policy_screen.dart';
import '../screens/terms_of_service_screen.dart';
import '../screens/premium_screen.dart';
import '../screens/bookmarks_screen.dart';
import '../screens/history_screen.dart';
import '../screens/referral_screen.dart';
import '../screens/weekly_digest_screen.dart';

class NavigationService {
  static NavigationService? _instance;
  static NavigationService get instance => _instance ??= NavigationService._();
  NavigationService._();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  static NavigatorState? get navigator => navigatorKey.currentState;

  static void navigateToHome() {
    navigatorKey.currentState?.pushReplacementNamed(AppRoutes.dashboard);
  }
  
  static Future<T?> pushNamed<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) {
    return navigator!.pushNamed<T>(routeName, arguments: arguments);
  }
  
  static Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
    String routeName, {
    Object? arguments,
    TO? result,
  }) {
    return navigator!.pushReplacementNamed<T, TO>(
      routeName,
      arguments: arguments,
      result: result,
    );
  }
  
  static void pop<T extends Object?>([T? result]) {
    return navigator!.pop<T>(result);
  }
  
  static Future<T?> push<T extends Object?>(Route<T> route) {
    return navigator!.push<T>(route);
  }
  
  static Future<T?> pushReplacement<T extends Object?, TO extends Object?>(
    Route<T> newRoute, {
    TO? result,
  }) {
    return navigator!.pushReplacement<T, TO>(newRoute, result: result);
  }
}

class AppRoutes {
  // Authentication routes
  static const String welcome = '/';
  static const String createAccount = '/create-account';
  static const String login = '/login';
  static const String onboardingChatbot = '/onboarding-chatbot';
  static const String newOnboarding = '/new-onboarding';
  static const String enhancedOnboarding = '/enhanced-onboarding';
  static const String personalizedHome = '/personalized-home';
  
  // Onboarding flow routes
  static const String interestForm = '/interest-form';
  static const String sourcePreference = '/source-preference';
  static const String calendarCustomization = '/calendar-customization';
  
  // Main app routes
  static const String dashboard = '/dashboard';
  static const String feed = '/feed';
  static const String calendar = '/calendar';
  static const String profile = '/profile';
  static const String search = '/search';
  static const String createContent = '/create';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  static const String player = '/player';

  // Info routes
  static const String privacyPolicy = '/privacy-policy';
  static const String termsOfService = '/terms';
  static const String premium = '/premium';

  // Library routes
  static const String bookmarks = '/bookmarks';
  static const String history = '/history';
  static const String referral = '/referral';
  static const String weeklyDigest = '/weekly-digest';

  // Admin routes
  static const String adminPanel = '/admin';
  static const String adminUsers = '/admin/users';
  static const String adminContent = '/admin/content';
  static const String adminAnalytics = '/admin/analytics';

  static Map<String, WidgetBuilder> get routes => {
        // Authentication routes
        AppRoutes.welcome: (context) => const WelcomeScreen(),
        AppRoutes.createAccount: (context) => const CreateAccountScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.onboardingChatbot: (context) => const EnhancedOnboardingScreen(),
        AppRoutes.newOnboarding: (context) => const NewOnboardingScreen(),
        AppRoutes.enhancedOnboarding: (context) => EnhancedOnboardingFlow(onComplete: () => Navigator.pushReplacementNamed(context, AppRoutes.dashboard)),
        AppRoutes.personalizedHome: (context) => const PersonalizedHomeScreen(),
        
        // Onboarding flow routes
        AppRoutes.interestForm: (context) => const InterestFormScreen(),
        AppRoutes.sourcePreference: (context) => const SourcePreferenceScreen(),
        AppRoutes.calendarCustomization: (context) => const CalendarCustomizationScreen(),
        
        // Main app routes
        AppRoutes.dashboard: (context) => const DashboardScreen(),
        AppRoutes.feed: (context) => const FeedScreen(),
        AppRoutes.profile: (context) => const ProfileScreen(),
        AppRoutes.calendar: (_) => const CalendarScreen(),
        AppRoutes.search: (_) => const SearchScreen(),
        AppRoutes.createContent: (_) => const CreateContentScreen(),
        AppRoutes.notifications: (_) => const NotificationsScreen(),
        AppRoutes.settings: (_) => const SettingsScreen(),
        '/player': (ctx) {
          final content = ModalRoute.of(ctx)?.settings.arguments;
          return content != null
              ? PlayerScreen(content: content as dynamic)
              : const PlaceholderScreen(title: 'Player', icon: Icons.play_circle_filled);
        },
        '/onboarding': (_) => const EnhancedOnboardingScreen(),
        '/onboarding_chatbot': (_) => const EnhancedOnboardingScreen(),
        AppRoutes.privacyPolicy: (_) => const PrivacyPolicyScreen(),
        AppRoutes.termsOfService: (_) => const TermsOfServiceScreen(),
        AppRoutes.premium: (_) => const PremiumScreen(),
        AppRoutes.bookmarks: (_) => const BookmarksScreen(),
        AppRoutes.history: (_) => const HistoryScreen(),
        AppRoutes.referral: (_) => const ReferralScreen(),
        AppRoutes.weeklyDigest: (_) => const WeeklyDigestScreen(),

        // Admin routes — protected by isAdmin guard
        AppRoutes.adminPanel: (context) {
          if (!UserService.instance.isAdmin) {
            return const PlaceholderScreen(title: 'Access Denied', icon: Icons.lock);
          }
          return const PlaceholderScreen(title: 'Admin Panel', icon: Icons.admin_panel_settings);
        },
        AppRoutes.adminUsers: (context) {
          if (!UserService.instance.isAdmin) {
            return const PlaceholderScreen(title: 'Access Denied', icon: Icons.lock);
          }
          return const PlaceholderScreen(title: 'Admin — Users', icon: Icons.people);
        },
        AppRoutes.adminContent: (context) {
          if (!UserService.instance.isAdmin) {
            return const PlaceholderScreen(title: 'Access Denied', icon: Icons.lock);
          }
          return const PlaceholderScreen(title: 'Admin — Content', icon: Icons.video_library);
        },
        AppRoutes.adminAnalytics: (context) {
          if (!UserService.instance.isAdmin) {
            return const PlaceholderScreen(title: 'Access Denied', icon: Icons.lock);
          }
          return const PlaceholderScreen(title: 'Admin — Analytics', icon: Icons.analytics);
        },
      };
}