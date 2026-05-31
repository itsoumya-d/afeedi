/// Defines the types of analytics events that can be tracked in the application.
/// This helps standardize event tracking across the app.
class AnalyticsEvents {
  /// Events related to user interactions like button clicks, selections, etc.
  static const String userInteraction = 'user_interaction';

  /// Events related to screen views and navigation.
  static const String screenView = 'screen_view';

  /// Events related to content engagement like plays, pauses, etc.
  static const String contentEngagement = 'content_engagement';

  /// Events related to personalization and recommendations.
  static const String personalization = 'personalization';

  /// Events related to onboarding process.
  static const String onboarding = 'onboarding';

  /// Events related to user account actions like login, signup, etc.
  static const String account = 'account';

  /// Events related to errors and exceptions.
  static const String error = 'error';

  /// Events related to performance metrics.
  static const String performance = 'performance';

  /// Events related to feature usage.
  static const String featureUsage = 'feature_usage';

  /// Events related to search actions.
  static const String search = 'search';

  // Specific onboarding event names
  static const String onboardingStarted = 'onboarding_started';
  static const String onboardingStepCompleted = 'onboarding_step_completed';
  static const String onboardingCompleted = 'onboarding_completed';
  static const String onboardingAbandoned = 'onboarding_abandoned';

  // OAuth event names
  static const String oauthConnectAttempt = 'oauth_connect_attempt';
  static const String oauthConnectSuccess = 'oauth_connect_success';
  static const String oauthConnectError = 'oauth_connect_error';
  static const String oauthDisconnect = 'oauth_disconnect';

  // UI interaction event names
  static const String buttonTap = 'button_tap';
  static const String genreSelection = 'genre_selection';
  static const String platformSelection = 'platform_selection';
}
