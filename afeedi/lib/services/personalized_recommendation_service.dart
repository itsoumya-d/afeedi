import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import '../core/config/supabase_config.dart';
import '../models/content_model.dart';
import '../models/user_model.dart';
import '../models/user_preferences.dart';
import '../models/analytics_model.dart';
// import '../models/calendar_event.dart'; // Temporarily commented out due to compilation errors
import '../models/content_item.dart';
import '../models/recommendation.dart';
import 'auth_service.dart';
import 'analytics_service.dart';
import 'content_aggregation_service.dart';
import 'ai_recommendation_service.dart';
import 'onboarding_service.dart';
// import 'calendar_service.dart'; // Temporarily commented out due to compilation errors

class PersonalizedRecommendationService {
  static PersonalizedRecommendationService? _instance;
  static PersonalizedRecommendationService get instance =>
      _instance ??= PersonalizedRecommendationService._();

  PersonalizedRecommendationService._();

  final _supabase = SupabaseConfig.client;
  math.Random _random = math.Random();

  // For testing purposes only
  void setRandom(math.Random random) {
    _random = random;
  }

  // Algorithm version for tracking
  static const String algorithmVersion = '3.0.0';

  // Generate a sample content item for testing
  ContentItem _generateSampleContentItem({
    required int index,
    String? contentType,
    String? genre,
    String? platform,
    bool contextual = false,
    String? timeOfDay,
    String? dayOfWeek,
    Map<String, dynamic>? userPreferences,
  }) {
    final genres = [
      'Action',
      'Comedy',
      'Drama',
      'Sci-Fi',
      'Horror',
      'Documentary',
      'Animation',
      'Thriller',
      'Romance',
      'Fantasy',
    ];

    final platforms = [
      'Netflix',
      'Hulu',
      'Disney+',
      'Prime Video',
      'HBO Max',
      'Apple TV+',
      'Peacock',
      'Paramount+',
      'YouTube',
      'Tubi',
    ];

    final contentTypes = ['Movie', 'TV Show', 'Documentary', 'Short Film'];

    final selectedGenre = genre ?? genres[_random.nextInt(genres.length)];
    final selectedPlatform =
        platform ?? platforms[_random.nextInt(platforms.length)];
    final selectedType =
        contentType ?? contentTypes[_random.nextInt(contentTypes.length)];

    String title;
    String description;
    String imageUrl;
    String recommendationReason;

    if (contextual) {
      final currentTimeOfDay = timeOfDay ?? _getCurrentTimeOfDay();
      final currentDayOfWeek = dayOfWeek ?? _getCurrentDayOfWeek();

      title = '${selectedType} for ${currentTimeOfDay} ${currentDayOfWeek}';
      description =
          'Perfect for watching during ${currentTimeOfDay} on ${currentDayOfWeek}';
      recommendationReason = 'Recommended for ${currentTimeOfDay} viewing';
    } else {
      title = '${selectedGenre} ${selectedType} ${index + 1}';
      description =
          'A great ${selectedGenre.toLowerCase()} ${selectedType.toLowerCase()} available on ${selectedPlatform}';
      recommendationReason = 'Based on your interest in ${selectedGenre}';
    }

    // Generate a random image URL from a placeholder service
    final imageId = 100 + index;
    imageUrl = 'https://picsum.photos/id/${imageId}/300/450';

    return ContentItem(
      id: 'content_${DateTime.now().millisecondsSinceEpoch}_$index',
      title: title,
      description: description,
      imageUrl: imageUrl,
      contentType: selectedType,
      genre: selectedGenre,
      platform: selectedPlatform,
      durationMinutes: _random.nextInt(150) + 30,
      releaseYear: 2020 + _random.nextInt(4),
      rating: (3 + _random.nextDouble() * 2).toStringAsFixed(1),
      recommendationReason: recommendationReason,
    );
  }

  // Get the current time of day (Morning, Afternoon, Evening, Night)
  String _getCurrentTimeOfDay() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return 'Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Afternoon';
    } else if (hour >= 17 && hour < 21) {
      return 'Evening';
    } else {
      return 'Night';
    }
  }

  // Get the current day of week
  String _getCurrentDayOfWeek() {
    final day = DateTime.now().weekday;

    switch (day) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Weekday';
    }
  }

  // Generate highly personalized recommendations based on comprehensive user data
  Future<List<Recommendation>> generateComprehensiveRecommendations({
    int limit = 20,
    List<PlatformType>? platforms,
    bool forceRefresh = false,
    bool includeCalendarContext = true,
  }) async {
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get user preferences from onboarding
      final onboardingPreferences = await OnboardingService.instance
          .getUserPreferences();
      if (onboardingPreferences == null) {
        // Fall back to basic recommendations if no onboarding data
        return await _generateBasicRecommendations(
          limit: limit,
          platforms: platforms,
        );
      }

      // Get behavioral insights from AI service
      final behaviorInsights = await _getBehaviorInsights(user.id);

      // Get calendar context if enabled
      // List<CalendarEvent>? upcomingEvents;
      // if (includeCalendarContext && onboardingPreferences.calendarIntegration) {
      //   upcomingEvents = await CalendarService.instance.getUpcomingEvents(
      //     limit: 5,
      //     withinHours: 24,
      //   );
      // }
      List<dynamic>? upcomingEvents; // Temporary placeholder

      // Get available content with expanded limit for better filtering
      final availableContent = await ContentAggregationService.instance
          .aggregateContent(
            limit: limit * 5, // Get more content to choose from
            platforms: _getPrioritizedPlatforms(
              onboardingPreferences,
              platforms,
            ),
          );

      if (availableContent.isEmpty) {
        return [];
      }

      // Generate recommendations using comprehensive algorithm
      final recommendations = await _generateComprehensiveRecommendations(
        user: user,
        content: availableContent,
        preferences: onboardingPreferences,
        behaviorInsights: behaviorInsights,
        upcomingEvents: upcomingEvents,
        limit: limit,
      );

      // Save recommendations to database for analytics
      await _saveRecommendations(recommendations);

      await AnalyticsService.instance.trackUserInteraction(
        action: 'comprehensive_recommendations_generated',
        screen: 'personalized_recommendation_service',
        additionalData: {
          'count': recommendations.length,
          'algorithm_version': algorithmVersion,
          'calendar_integrated': upcomingEvents != null,
          'platforms': platforms?.map((p) => p.toString()).toList() ?? 'all',
        },
      );

      return recommendations;
    } catch (e) {
      debugPrint('Error generating comprehensive recommendations: $e');
      return [];
    }
  }

  // Get personalized recommendations based on user preferences
  Future<List<Recommendation>> getPersonalizedRecommendations({
    required UserPreferences userPreferences,
  }) async {
    // Generate sample recommendations based on user interests
    final recommendations = List.generate(
      10, // Default count
      (index) => Recommendation(
        id: 'rec_${DateTime.now().millisecondsSinceEpoch}_$index',
        title: 'Personalized Content ${index + 1}',
        description: 'Content tailored to your interests',
        imageUrl: 'https://picsum.photos/id/${300 + index}/300/450',
        platform: _random.nextBool() ? 'Netflix' : 'YouTube',
        category: _random.nextBool() ? 'video' : 'article',
        durationSeconds: _random.nextInt(3600) + 300,
        relevanceScore: 0.8 + _random.nextDouble() * 0.2,
        recommendationReason:
            'Based on your interest in ${userPreferences.interests[index % userPreferences.interests.length]}',
        createdAt: DateTime.now(),
      ),
    );

    return recommendations;
  }

  // Get contextual recommendations based on calendar events, location, etc.
  Future<List<Recommendation>> getContextualRecommendations({
    required Map<String, dynamic> context,
    required UserPreferences userPreferences,
  }) async {
    final eventName = context['eventName'] as String? ?? 'general';
    final eventType = context['eventType'] as String? ?? 'meeting';

    // Generate contextual recommendations
    final List<Recommendation> recommendations = List.generate(
      10,
      (index) => Recommendation(
        id: 'context_${DateTime.now().millisecondsSinceEpoch}_$index',
        title: 'Content for $eventName',
        description: 'Content related to your $eventType: $eventName',
        imageUrl: 'https://picsum.photos/id/${200 + index}/300/450',
        platform: _random.nextBool() ? 'Netflix' : 'YouTube',
        category: _random.nextBool() ? 'video' : 'article',
        durationSeconds: _random.nextInt(1800) + 300,
        relevanceScore: 0.7 + _random.nextDouble() * 0.3,
        recommendationReason: 'Based on your upcoming $eventType: $eventName',
        createdAt: DateTime.now(),
      ),
    );

    return recommendations;
  }

  // Get platform-specific recommendations
  Future<List<Recommendation>> getPlatformRecommendations({
    required UserPreferences userPreferences,
    required String platform,
    required int count,
  }) async {
    // Generate recommendations for the specified platform
    final recommendations = List.generate(
      count,
      (index) => Recommendation(
        id: 'platform_${DateTime.now().millisecondsSinceEpoch}_$index',
        title: '$platform Content ${index + 1}',
        description: 'A great content item from $platform',
        imageUrl: 'https://picsum.photos/id/${100 + index}/300/450',
        platform: platform,
        category: _random.nextBool() ? 'video' : 'article',
        durationSeconds: _random.nextInt(3600) + 300,
        relevanceScore: 0.5 + _random.nextDouble() * 0.5,
        recommendationReason: 'Based on your platform preferences',
        createdAt: DateTime.now(),
      ),
    );

    return recommendations;
  }

  // Apply diversity to recommendations to avoid showing too many similar items
  List<Recommendation> applyDiversityToRecommendations(
    List<Recommendation> recommendations, {
    double diversityFactor = 0.3,
  }) {
    // In a real implementation, this would use a sophisticated algorithm
    // to ensure diversity across genres, content types, etc.
    // For this demo, we'll just shuffle the list
    final diversifiedList = List<Recommendation>.from(recommendations);
    diversifiedList.shuffle(_random);

    // Sort by category to group similar content types together
    diversifiedList.sort((a, b) => a.category.compareTo(b.category));

    return diversifiedList;
  }

  // Apply diversity to content items to avoid showing too similar content
  List<ContentItem> applyDiversityToContentItems(
    List<ContentItem> contentItems,
  ) {
    // In a real implementation, this would use a sophisticated algorithm
    // to ensure diversity across genres, content types, etc.
    // For this demo, we'll just shuffle the list
    final diversifiedList = List<ContentItem>.from(contentItems);
    diversifiedList.shuffle(_random);
    return diversifiedList;
  }

  // Generate recommendations specifically aligned with calendar events
  Future<List<Recommendation>> generateCalendarContextualRecommendations({
    required CalendarEvent event,
    int limit = 5,
    List<PlatformType>? platforms,
  }) async {
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get user preferences
      final preferences = await OnboardingService.instance.getUserPreferences();

      // Get content that aligns with the calendar event
      final availableContent = await ContentAggregationService.instance
          .aggregateContent(
            limit: limit * 3,
            platforms: platforms,
            keywords: _extractKeywordsFromEvent(event),
          );

      if (availableContent.isEmpty) {
        return [];
      }

      // Score content based on relevance to the event
      final recommendations = _scoreContentForCalendarContext(
        user: user,
        content: availableContent,
        event: event,
        preferences: preferences,
        limit: limit,
      );

      await AnalyticsService.instance.trackUserInteraction(
        action: 'calendar_recommendations_generated',
        screen: 'personalized_recommendation_service',
        additionalData: {
          'count': recommendations.length,
          'event_type': event.eventType,
          'algorithm_version': algorithmVersion,
        },
      );

      return recommendations;
    } catch (error) {
      await AnalyticsService.instance.trackError(
        errorType: 'calendar_recommendation_error',
        errorMessage: error.toString(),
        screen: 'personalized_recommendation_service',
      );
      return [];
    }
  }

  // Generate time-aware recommendations based on user's preferred viewing times
  Future<List<Recommendation>> generateTimeAwareRecommendations({
    int limit = 10,
    List<PlatformType>? platforms,
  }) async {
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get user preferences
      final preferences = await OnboardingService.instance.getUserPreferences();
      if (preferences == null) {
        return await _generateBasicRecommendations(
          limit: limit,
          platforms: platforms,
        );
      }

      // Determine current time context
      final timeContext = _getCurrentTimeContext();

      // Get preferred content types for this time of day
      final preferredContentTypes = _getTimeBasedContentPreferences(
        preferences: preferences,
        timeContext: timeContext,
      );

      // Get content aligned with time preferences
      final availableContent = await ContentAggregationService.instance
          .aggregateContent(
            limit: limit * 3,
            platforms: platforms,
            contentTypes: preferredContentTypes,
          );

      if (availableContent.isEmpty) {
        return [];
      }

      // Score content based on time context
      final recommendations = _scoreContentForTimeContext(
        user: user,
        content: availableContent,
        preferences: preferences,
        timeContext: timeContext,
        limit: limit,
      );

      await AnalyticsService.instance.trackUserInteraction(
        action: 'time_aware_recommendations_generated',
        screen: 'personalized_recommendation_service',
        additionalData: {
          'count': recommendations.length,
          'time_context': timeContext,
          'algorithm_version': algorithmVersion,
        },
      );

      return recommendations;
    } catch (error) {
      await AnalyticsService.instance.trackError(
        errorType: 'time_aware_recommendation_error',
        errorMessage: error.toString(),
        screen: 'personalized_recommendation_service',
      );
      return [];
    }
  }

  // Private methods

  // Generate basic recommendations when no onboarding data is available
  Future<List<Recommendation>> _generateBasicRecommendations({
    required int limit,
    List<PlatformType>? platforms,
  }) async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      return [];
    }

    final availableContent = await ContentAggregationService.instance
        .aggregateContent(limit: limit, platforms: platforms);

    if (availableContent.isEmpty) {
      return [];
    }

    final recommendations = <Recommendation>[];
    final now = DateTime.now();

    for (final content in availableContent.take(limit)) {
      recommendations.add(
        Recommendation(
          id: 'basic_rec_${now.millisecondsSinceEpoch}_${recommendations.length}',
          userId: user.id,
          contentId: content.id,
          recommendationScore: 0.5, // Neutral score
          recommendationReason: 'Trending content you might enjoy',
          algorithmVersion: algorithmVersion,
          createdAt: now,
          expiresAt: now.add(const Duration(days: 1)),
        ),
      );
    }

    return recommendations;
  }

  // Generate comprehensive recommendations using all available data
  Future<List<Recommendation>> _generateComprehensiveRecommendations({
    required User user,
    required List<Content> content,
    required UserPreferences preferences,
    UserBehaviorInsight? behaviorInsights,
    List<CalendarEvent>? upcomingEvents,
    required int limit,
  }) async {
    final recommendations = <Recommendation>[];
    final now = DateTime.now();

    // Get user's existing interactions to avoid duplicates
    final existingInteractions = await _getUserInteractions(user.id);
    final interactedContentIds = existingInteractions
        .map((i) => i.contentId)
        .toSet();

    // Filter out already interacted content
    final availableContent = content
        .where((c) => !interactedContentIds.contains(c.id))
        .toList();

    // Score each content item
    final scoredContent = <ScoredContent>[];

    for (final contentItem in availableContent) {
      final baseScore = _calculateBaseScore(
        content: contentItem,
        preferences: preferences,
        behaviorInsights: behaviorInsights,
      );

      // Apply calendar context boost if applicable
      double calendarBoost = 0.0;
      String? calendarContext;

      if (upcomingEvents != null && upcomingEvents.isNotEmpty) {
        for (final event in upcomingEvents) {
          final eventRelevance = _calculateEventRelevance(
            content: contentItem,
            event: event,
          );

          if (eventRelevance > calendarBoost) {
            calendarBoost = eventRelevance;
            calendarContext = 'Relevant to your upcoming ${event.title} event';
          }
        }
      }

      // Apply time context boost
      final timeContext = _getCurrentTimeContext();
      final timeBoost = _calculateTimeContextBoost(
        content: contentItem,
        preferences: preferences,
        timeContext: timeContext,
      );

      // Calculate final score with all factors
      final finalScore = baseScore + (calendarBoost * 0.3) + (timeBoost * 0.2);

      if (finalScore > 0.3) {
        // Threshold for inclusion
        scoredContent.add(
          ScoredContent(
            content: contentItem,
            score: finalScore,
            calendarContext: calendarBoost > 0.3 ? calendarContext : null,
            timeContext: timeBoost > 0.3
                ? 'Perfect for ${timeContext.toLowerCase()}'
                : null,
          ),
        );
      }
    }

    // Sort by score and apply diversity
    scoredContent.sort((a, b) => b.score.compareTo(a.score));

    // Apply diversity factor based on user preference
    final diversifiedContent = _applyDiversityFactor(
      scoredContent: scoredContent,
      diversityLevel: preferences.diversityLevel,
    );

    // Create recommendation objects
    for (final item in diversifiedContent.take(limit)) {
      String reason = _generateRecommendationReason(
        content: item.content,
        preferences: preferences,
        score: item.score,
        calendarContext: item.calendarContext,
        timeContext: item.timeContext,
      );

      recommendations.add(
        Recommendation(
          id: 'comprehensive_rec_${now.millisecondsSinceEpoch}_${recommendations.length}',
          userId: user.id,
          contentId: item.content.id,
          recommendationScore: item.score,
          recommendationReason: reason,
          algorithmVersion: algorithmVersion,
          createdAt: now,
          expiresAt: now.add(const Duration(days: 3)),
          metadata: {
            'calendar_context': item.calendarContext,
            'time_context': item.timeContext,
          },
        ),
      );
    }

    return recommendations;
  }

  // Calculate base recommendation score using preferences and behavior
  double _calculateBaseScore({
    required Content content,
    required UserPreferences preferences,
    UserBehaviorInsight? behaviorInsights,
  }) {
    double score = 0.0;

    // Interest match (0-0.3)
    if (content.tags != null && content.tags!.isNotEmpty) {
      final matchingInterests = content.tags!
          .where((tag) => preferences.interests.contains(tag))
          .length;

      if (matchingInterests > 0) {
        score += 0.3 * (matchingInterests / content.tags!.length);
      }
    }

    // Content type match (0-0.2)
    if (content.contentType != null &&
        preferences.contentTypes.contains(content.contentType)) {
      score += 0.2;
    }

    // Platform priority (0-0.15)
    if (content.platform != null &&
        preferences.platformPriorities.containsKey(content.platform!.name)) {
      score += 0.15 * preferences.platformPriorities[content.platform!.name]!;
    }

    // Creator preference (0-0.15)
    if (content.creator != null &&
        preferences.preferredCreators.contains(content.creator)) {
      score += 0.15;
    }

    // Content length preference (0-0.1)
    if (content.duration != null) {
      String lengthCategory;
      if (content.duration! < 60) {
        // Less than 1 minute
        lengthCategory = 'short';
      } else if (content.duration! < 600) {
        // 1-10 minutes
        lengthCategory = 'medium';
      } else {
        // > 10 minutes
        lengthCategory = 'long';
      }

      if (preferences.contentLengthPreferences.containsKey(lengthCategory)) {
        score +=
            0.1 * (preferences.contentLengthPreferences[lengthCategory]! / 100);
      }
    }

    // Behavioral insights boost (0-0.1)
    if (behaviorInsights != null) {
      // Apply behavioral insights logic here
      // This would use past viewing patterns, engagement metrics, etc.
      score += 0.1 * _calculateBehavioralBoost(content, behaviorInsights);
    }

    return score;
  }

  // Calculate relevance of content to a calendar event
  double _calculateEventRelevance({
    required Content content,
    required CalendarEvent event,
  }) {
    double relevance = 0.0;

    // Check for keyword matches between content and event
    final contentKeywords = _extractContentKeywords(content);
    final eventKeywords = _extractKeywordsFromEvent(event);

    final matchingKeywords = contentKeywords
        .where((keyword) => eventKeywords.contains(keyword))
        .length;

    if (matchingKeywords > 0) {
      relevance += 0.6 * (matchingKeywords / eventKeywords.length);
    }

    // Check if content type aligns with event type
    if (content.contentType != null &&
        _isContentTypeRelevantForEvent(content.contentType!, event.eventType)) {
      relevance += 0.4;
    }

    return relevance;
  }

  // Calculate time context boost based on user preferences
  double _calculateTimeContextBoost({
    required Content content,
    required UserPreferences preferences,
    required String timeContext,
  }) {
    double boost = 0.0;

    // Check if user has time-based preferences
    if (preferences.timeBasedPreferences.containsKey(
      timeContext.toLowerCase(),
    )) {
      final preferredType =
          preferences.timeBasedPreferences[timeContext.toLowerCase()];

      if (content.contentType == preferredType) {
        boost += 0.7;
      }
    }

    // Check if current time is in user's preferred viewing times
    if (preferences.preferredViewingTimes.contains(timeContext.toLowerCase())) {
      boost += 0.3;
    }

    return boost;
  }

  // Apply diversity factor to recommendations
  List<ScoredContent> _applyDiversityFactor({
    required List<ScoredContent> scoredContent,
    required double diversityLevel,
  }) {
    if (scoredContent.length <= 1 || diversityLevel <= 0.1) {
      return scoredContent;
    }

    final result = <ScoredContent>[];
    final platforms = <PlatformType>{};
    final contentTypes = <String>{};
    final creators = <String>{};

    // First add the highest scored item
    if (scoredContent.isNotEmpty) {
      final first = scoredContent.first;
      result.add(first);

      if (first.content.platform != null) {
        platforms.add(first.content.platform!);
      }

      if (first.content.contentType != null) {
        contentTypes.add(first.content.contentType!);
      }

      if (first.content.creator != null) {
        creators.add(first.content.creator!);
      }
    }

    // Process remaining items with diversity factor
    for (int i = 1; i < scoredContent.length; i++) {
      final item = scoredContent[i];
      double diversityBoost = 0.0;

      // Boost for platform diversity
      if (item.content.platform != null &&
          !platforms.contains(item.content.platform)) {
        diversityBoost += 0.3 * diversityLevel;
      }

      // Boost for content type diversity
      if (item.content.contentType != null &&
          !contentTypes.contains(item.content.contentType)) {
        diversityBoost += 0.3 * diversityLevel;
      }

      // Boost for creator diversity
      if (item.content.creator != null &&
          !creators.contains(item.content.creator)) {
        diversityBoost += 0.4 * diversityLevel;
      }

      // Apply diversity boost to score
      final adjustedScore = item.score * (1 + diversityBoost);

      // Add to result with adjusted score
      result.add(
        ScoredContent(
          content: item.content,
          score: adjustedScore,
          calendarContext: item.calendarContext,
          timeContext: item.timeContext,
        ),
      );

      // Update diversity tracking sets
      if (item.content.platform != null) {
        platforms.add(item.content.platform!);
      }

      if (item.content.contentType != null) {
        contentTypes.add(item.content.contentType!);
      }

      if (item.content.creator != null) {
        creators.add(item.content.creator!);
      }
    }

    // Re-sort after applying diversity
    result.sort((a, b) => b.score.compareTo(a.score));
    return result;
  }

  // Generate personalized recommendation reason
  String _generateRecommendationReason({
    required Content content,
    required UserPreferences preferences,
    required double score,
    String? calendarContext,
    String? timeContext,
  }) {
    // Priority order for reason generation
    if (calendarContext != null) {
      return calendarContext;
    }

    if (timeContext != null) {
      return timeContext;
    }

    // Check for interest match
    if (content.tags != null && content.tags!.isNotEmpty) {
      for (final interest in preferences.interests) {
        if (content.tags!.contains(interest)) {
          return 'Matches your interest in $interest';
        }
      }
    }

    // Check for content type match
    if (content.contentType != null &&
        preferences.contentTypes.contains(content.contentType)) {
      return 'Based on your preference for ${content.contentType} content';
    }

    // Check for creator preference
    if (content.creator != null &&
        preferences.preferredCreators.contains(content.creator)) {
      return 'From ${content.creator}, one of your favorite creators';
    }

    // Default reasons based on score
    if (score > 0.8) {
      return 'Highly recommended based on your preferences';
    } else if (score > 0.6) {
      return 'Recommended based on your viewing habits';
    } else if (score > 0.4) {
      return 'You might enjoy this content';
    } else {
      return 'Trending content you might like';
    }
  }

  // Helper methods

  Future<UserBehaviorInsight?> _getBehaviorInsights(String userId) async {
    try {
      return await AIRecommendationService.instance.getUserBehaviorInsights(
        userId,
      );
    } catch (e) {
      return null;
    }
  }

  Future<List<UserInteraction>> _getUserInteractions(String userId) async {
    try {
      final response = await _supabase
          .from('user_interactions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(100);

      return (response as List)
          .map((data) => UserInteraction.fromJson(data))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _saveRecommendations(
    List<Recommendation> recommendations,
  ) async {
    try {
      if (recommendations.isEmpty) return;

      final data = recommendations.map((r) => r.toJson()).toList();
      await _supabase.from('recommendations').upsert(data);
    } catch (e) {
      // Log error but don't fail the recommendation process
      debugPrint('Error saving recommendations: $e');
    }
  }

  List<PlatformType>? _getPrioritizedPlatforms(
    UserPreferences preferences,
    List<PlatformType>? requestedPlatforms,
  ) {
    if (requestedPlatforms != null && requestedPlatforms.isNotEmpty) {
      return requestedPlatforms;
    }

    if (preferences.platformPriorities.isEmpty) {
      return null; // No preferences, return all platforms
    }

    // Convert platform priorities to sorted list
    final entries = preferences.platformPriorities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Return platforms with priority > 0.3
    return entries
        .where((e) => e.value > 0.3)
        .map((e) => _platformNameToType(e.key))
        .whereType<PlatformType>()
        .toList();
  }

  PlatformType? _platformNameToType(String name) {
    switch (name.toLowerCase()) {
      case 'youtube':
        return PlatformType.youtube;
      case 'tiktok':
        return PlatformType.tiktok;
      case 'instagram':
        return PlatformType.instagram;
      case 'facebook':
        return PlatformType.facebook;
      case 'twitter':
        return PlatformType.twitter;
      case 'twitch':
        return PlatformType.twitch;
      default:
        return null;
    }
  }

  String _getCurrentTimeContext() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return 'Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Afternoon';
    } else if (hour >= 17 && hour < 22) {
      return 'Evening';
    } else {
      return 'Night';
    }
  }

  List<String> _getTimeBasedContentPreferences({
    required UserPreferences preferences,
    required String timeContext,
  }) {
    final timeKey = timeContext.toLowerCase();

    if (preferences.timeBasedPreferences.containsKey(timeKey)) {
      final contentType = preferences.timeBasedPreferences[timeKey];
      if (contentType != null) {
        return [contentType];
      }
    }

    // Default preferences by time of day if not specified
    switch (timeKey) {
      case 'morning':
        return ['Educational Content', 'News', 'Podcasts'];
      case 'afternoon':
        return ['Reviews', 'Tutorials', 'Vlogs'];
      case 'evening':
        return ['Entertainment', 'Music Videos', 'Comedy Sketches'];
      case 'night':
        return ['Documentaries', 'Gaming Content', 'Live Streams'];
      default:
        return preferences.contentTypes;
    }
  }

  List<String> _extractKeywordsFromEvent(CalendarEvent event) {
    final keywords = <String>[];

    // Add event title words
    keywords.addAll(
      event.title
          .split(' ')
          .where((word) => word.length > 3)
          .map((word) => word.toLowerCase()),
    );

    // Add event description words if available
    if (event.description != null && event.description!.isNotEmpty) {
      keywords.addAll(
        event.description!
            .split(' ')
            .where((word) => word.length > 3)
            .map((word) => word.toLowerCase()),
      );
    }

    // Add event type
    keywords.add(event.eventType.toLowerCase());

    // Add event location if available
    if (event.location != null && event.location!.isNotEmpty) {
      keywords.addAll(
        event.location!
            .split(' ')
            .where((word) => word.length > 3)
            .map((word) => word.toLowerCase()),
      );
    }

    return keywords;
  }

  List<String> _extractContentKeywords(Content content) {
    final keywords = <String>[];

    // Add title words
    keywords.addAll(
      content.title
          .split(' ')
          .where((word) => word.length > 3)
          .map((word) => word.toLowerCase()),
    );

    // Add description words if available
    if (content.description != null && content.description!.isNotEmpty) {
      keywords.addAll(
        content.description!
            .split(' ')
            .where((word) => word.length > 3)
            .map((word) => word.toLowerCase()),
      );
    }

    // Add tags if available
    if (content.tags != null && content.tags!.isNotEmpty) {
      keywords.addAll(content.tags!.map((tag) => tag.toLowerCase()));
    }

    // Add content type if available
    if (content.contentType != null) {
      keywords.add(content.contentType!.toLowerCase());
    }

    return keywords;
  }

  bool _isContentTypeRelevantForEvent(String contentType, String eventType) {
    // Map event types to relevant content types
    final relevanceMap = {
      'meeting': ['Tutorials', 'Educational Content', 'Interviews'],
      'appointment': ['Reviews', 'Vlogs', 'Documentaries'],
      'class': ['Educational Content', 'Tutorials', 'Documentaries'],
      'workout': ['Tutorials', 'Music Videos', 'Vlogs'],
      'social': ['Entertainment', 'Music Videos', 'Comedy Sketches'],
      'travel': ['Vlogs', 'Travel', 'Documentaries'],
      'entertainment': [
        'Entertainment',
        'Music Videos',
        'Comedy Sketches',
        'Gaming Content',
      ],
      'meal': ['Food', 'Vlogs', 'Reviews'],
      'other': [],
    };

    final lowerEventType = eventType.toLowerCase();
    final lowerContentType = contentType.toLowerCase();

    if (relevanceMap.containsKey(lowerEventType)) {
      return relevanceMap[lowerEventType]!
          .map((type) => type.toLowerCase())
          .contains(lowerContentType);
    }

    return false;
  }

  double _calculateBehavioralBoost(
    Content content,
    UserBehaviorInsight insights,
  ) {
    // This would implement logic based on user's past behavior
    // For now, return a random value as placeholder
    return _random.nextDouble();
  }

  List<Recommendation> _scoreContentForCalendarContext({
    required User user,
    required List<Content> content,
    required CalendarEvent event,
    UserPreferences? preferences,
    required int limit,
  }) {
    final scoredContent = <ScoredContent>[];
    final now = DateTime.now();

    for (final item in content) {
      final relevance = _calculateEventRelevance(content: item, event: event);

      if (relevance > 0.3) {
        scoredContent.add(
          ScoredContent(
            content: item,
            score: relevance,
            calendarContext:
                'Relevant to your ${event.title} ${event.eventType}',
          ),
        );
      }
    }

    scoredContent.sort((a, b) => b.score.compareTo(a.score));

    // Create recommendation objects
    final recommendations = <Recommendation>[];
    for (final item in scoredContent.take(limit)) {
      recommendations.add(
        Recommendation(
          id: 'calendar_rec_${now.millisecondsSinceEpoch}_${recommendations.length}',
          userId: user.id,
          contentId: item.content.id,
          recommendationScore: item.score,
          recommendationReason:
              item.calendarContext ?? 'Relevant to your calendar event',
          algorithmVersion: algorithmVersion,
          createdAt: now,
          expiresAt: event.endTime ?? now.add(const Duration(days: 1)),
          metadata: {'event_id': event.id, 'event_type': event.eventType},
        ),
      );
    }

    return recommendations;
  }

  List<Recommendation> _scoreContentForTimeContext({
    required User user,
    required List<Content> content,
    required UserPreferences preferences,
    required String timeContext,
    required int limit,
  }) {
    final scoredContent = <ScoredContent>[];
    final now = DateTime.now();

    for (final item in content) {
      double score = 0.5; // Base score

      // Boost for content type match with time preferences
      if (item.contentType != null) {
        final preferredTypes = _getTimeBasedContentPreferences(
          preferences: preferences,
          timeContext: timeContext,
        );

        if (preferredTypes.contains(item.contentType)) {
          score += 0.3;
        }
      }

      // Boost for content length appropriate for time of day
      if (item.duration != null) {
        final appropriateLength = _isContentLengthAppropriateForTime(
          duration: item.duration!,
          timeContext: timeContext,
          preferences: preferences,
        );

        if (appropriateLength) {
          score += 0.2;
        }
      }

      scoredContent.add(
        ScoredContent(
          content: item,
          score: score,
          timeContext: 'Perfect for ${timeContext.toLowerCase()} viewing',
        ),
      );
    }

    scoredContent.sort((a, b) => b.score.compareTo(a.score));

    // Create recommendation objects
    final recommendations = <Recommendation>[];
    for (final item in scoredContent.take(limit)) {
      recommendations.add(
        Recommendation(
          id: 'time_rec_${now.millisecondsSinceEpoch}_${recommendations.length}',
          userId: user.id,
          contentId: item.content.id,
          recommendationScore: item.score,
          recommendationReason:
              item.timeContext ??
              'Recommended for ${timeContext.toLowerCase()}',
          algorithmVersion: algorithmVersion,
          createdAt: now,
          expiresAt: now.add(const Duration(hours: 6)),
          metadata: {'time_context': timeContext},
        ),
      );
    }

    return recommendations;
  }

  bool _isContentLengthAppropriateForTime({
    required int duration,
    required String timeContext,
    required UserPreferences preferences,
  }) {
    // Default time-based length preferences if not specified by user
    final defaultLengthMap = {
      'morning': {'max': 300}, // 5 minutes max in morning
      'afternoon': {'min': 300, 'max': 900}, // 5-15 minutes in afternoon
      'evening': {'min': 600}, // 10+ minutes in evening
      'night': {'min': 300}, // 5+ minutes at night
    };

    final timeKey = timeContext.toLowerCase();

    if (defaultLengthMap.containsKey(timeKey)) {
      final prefs = defaultLengthMap[timeKey]!;

      if (prefs.containsKey('min') && duration < prefs['min']!) {
        return false;
      }

      if (prefs.containsKey('max') && duration > prefs['max']!) {
        return false;
      }

      return true;
    }

    return true; // Default to appropriate if no specific rules
  }
}

// Helper classes

class ScoredContent {
  final Content content;
  final double score;
  final String? calendarContext;
  final String? timeContext;

  ScoredContent({
    required this.content,
    required this.score,
    this.calendarContext,
    this.timeContext,
  });
}
