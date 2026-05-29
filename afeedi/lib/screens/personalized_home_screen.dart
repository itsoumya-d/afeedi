import 'package:flutter/material.dart';

import '../models/content_item.dart';
import '../services/recommendation_integration_service.dart';
import '../services/analytics_service.dart';
import '../models/analytics_events.dart';
import '../services/onboarding_service.dart';
import '../widgets/personalized_recommendations_widget.dart';
import '../widgets/app_bar_with_profile.dart';
import '../utils/ui_scaling.dart';

/// A home screen that displays personalized content recommendations
/// based on user preferences collected during onboarding.
class PersonalizedHomeScreen extends StatefulWidget {
  const PersonalizedHomeScreen({Key? key}) : super(key: key);

  @override
  _PersonalizedHomeScreenState createState() => _PersonalizedHomeScreenState();
}

class _PersonalizedHomeScreenState extends State<PersonalizedHomeScreen> {
  final RecommendationIntegrationService _recommendationService = RecommendationIntegrationService.instance;
  final OnboardingService _onboardingService = OnboardingService();
  final AnalyticsService _analyticsService = AnalyticsService.instance;
  
  bool _isOnboardingCompleted = false;
  bool _showContextualRecommendations = false;
  Map<String, dynamic>? _personalizationSettings;
  
  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }
  
  Future<void> _initializeScreen() async {
    // Initialize recommendation service
    await _recommendationService.initialize();
    
    // Check if onboarding is completed
    final isCompleted = await _onboardingService.isOnboardingCompleted();
    
    // Get personalization settings
    final preferences = await _onboardingService.getCurrentPreferences();
    final settings = preferences?.personalizationSettings;
    
    // Check if contextual recommendations should be shown
    final enableCalendarContextual = settings?['enableCalendarContextualContent'] ?? false;
    final enableTimeAware = settings?['enableTimeAwareRecommendations'] ?? true;
    
    setState(() {
      _isOnboardingCompleted = isCompleted;
      _showContextualRecommendations = enableCalendarContextual || enableTimeAware;
      _personalizationSettings = settings;
    });
    
    // Track screen view
    _analyticsService.trackEvent(
      eventName: 'screen_view',
      eventType: AnalyticsEvents.screenView,
      screen: 'personalized_home_screen',
      additionalData: {
        'onboarding_completed': _isOnboardingCompleted,
        'show_contextual': _showContextualRecommendations,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
  
  void _handleContentItemTap(ContentItem item) {
    // Track content selection
    _analyticsService.trackEvent(
      eventName: 'content_selected',
      eventType: AnalyticsEvents.buttonTap,
      additionalData: {
        'content_id': item.id,
        'content_title': item.title,
        'content_platform': item.platform,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    
    // Navigate to content player
    Navigator.of(context).pushNamed(
      '/player',
      arguments: item,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          // App bar with profile
          AppBarWithProfile(
            title: 'For You',
            showBackButton: false,
          ),
          
          // Main content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _initializeScreen();
              },
              child: _buildContent(),
            ),
          ),
        ]),
      ),
    );
  }
  
  Widget _buildContent() {
    if (!_isOnboardingCompleted) {
      return _buildOnboardingPrompt();
    }
    
    return ListView(
      children: [
        // Contextual recommendations (time-aware and calendar-based)
        if (_showContextualRecommendations)
          ContextualRecommendationsWidget(
            itemCount: 5,
            showRecommendationReason: _personalizationSettings?['enableRecommendationReasoning'] ?? true,
            onItemTap: _handleContentItemTap,
          ),
        
        SizedBox(height: UIScaling.spacing(context, 2)),
        
        // Main personalized recommendations
        PersonalizedRecommendationsWidget(
          title: 'Recommended for You',
          subtitle: 'Based on your preferences',
          itemCount: 10,
          showRecommendationReason: _personalizationSettings?['enableRecommendationReasoning'] ?? true,
          onItemTap: _handleContentItemTap,
          recommendationType: 'personalized',
        ),
        
        SizedBox(height: UIScaling.spacing(context, 2)),
        
        // Platform-specific recommendations
        PlatformRecommendationsWidget(
          itemsPerPlatform: 5,
          showRecommendationReason: _personalizationSettings?['enableRecommendationReasoning'] ?? true,
          onItemTap: _handleContentItemTap,
        ),
        
        SizedBox(height: UIScaling.spacing(context, 2)),
        
        // Viewing habits based recommendations
        PersonalizedRecommendationsWidget(
          title: 'Matches Your Viewing Style',
          subtitle: 'Content that fits how you like to watch',
          itemCount: 10,
          showRecommendationReason: _personalizationSettings?['enableRecommendationReasoning'] ?? true,
          onItemTap: _handleContentItemTap,
          recommendationType: 'viewing_habits',
        ),
        
        SizedBox(height: UIScaling.spacing(context, 4)),
      ],
    );
  }
  
  Widget _buildOnboardingPrompt() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(UIScaling.padding(context)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: UIScaling.spacing(context)),
            Text(
              'Complete Your Profile',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: UIScaling.spacing(context)),
            Text(
              'Tell us about your preferences to get personalized recommendations tailored just for you.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: UIScaling.spacing(context, 2)),
            ElevatedButton(
              onPressed: () {
                // Track onboarding start from home screen
                _analyticsService.trackEvent(
                  eventName: 'onboarding_start_from_home',
                  eventType: AnalyticsEvents.buttonTap,
                  additionalData: {
                    'timestamp': DateTime.now().toIso8601String(),
                  },
                );
                
                // Navigate to onboarding
                Navigator.of(context).pushNamed('/onboarding');
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: UIScaling.padding(context),
                  vertical: UIScaling.padding(context),
                ),
              ),
              child: Text('Start Personalization'),
            ),
          ],
        ),
      ),
    );
  }
}