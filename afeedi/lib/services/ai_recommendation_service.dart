import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import '../models/content_model.dart';
import '../models/user_model.dart';
import '../models/analytics_model.dart';
import '../core/storage/local_storage_service.dart';
import 'auth_service.dart';
import 'analytics_service.dart';
import 'content_aggregation_service.dart';
import 'onboarding_service.dart';

class AIRecommendationService {
  static AIRecommendationService? _instance;
  static AIRecommendationService get instance =>
      _instance ??= AIRecommendationService._();

  AIRecommendationService._();

  final _storage = LocalStorageService.instance;
  final _random = math.Random();

  // Algorithm version for tracking
  static const String algorithmVersion = '1.0.0';

  // Generate personalized recommendations
  Future<List<Recommendation>> generateRecommendations({
    int limit = 20,
    List<PlatformType>? platforms,
    bool forceRefresh = false,
  }) async {
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if user has AI recommendations enabled via local preferences
      final localPrefs = await _getUserPreferencesFromStorage(user.id);
      if (localPrefs != null && localPrefs.aiRecommendationsEnabled == false) {
        return [];
      }

      // Check if user has AI recommendations disabled via onboarding preferences
      final onboardingPrefs = await OnboardingService.instance
          .getUserPreferences();
      if (onboardingPrefs != null &&
          onboardingPrefs.enableAIRecommendations == false) {
        return [];
      }

      // Return cached recommendations if not forcing refresh
      if (!forceRefresh) {
        final existingRecommendations = await _getExistingRecommendations(
          user.id,
          limit,
        );
        if (existingRecommendations.isNotEmpty) {
          return existingRecommendations;
        }
      }

      // Analyse user behaviour from local storage
      final userBehavior = await _analyzeUserBehavior(user.id);

      // Get available content from the aggregation service
      final availableContent = await ContentAggregationService.instance
          .aggregateContent(
            limit: limit * 5, // Get more content to choose from
            platforms: platforms,
          );

      if (availableContent.isEmpty) {
        return [];
      }

      // Generate recommendations using local scoring
      final recommendations = await _generateRecommendationsFromContent(
        user: user,
        content: availableContent,
        userBehavior: userBehavior,
        limit: limit,
      );

      // Persist recommendations to local storage
      await _saveRecommendations(recommendations);

      await AnalyticsService.instance.trackUserInteraction(
        action: 'recommendations_generated',
        screen: 'ai_service',
        additionalData: {
          'count': recommendations.length,
          'algorithm_version': algorithmVersion,
        },
      );

      return recommendations;
    } catch (error) {
      await AnalyticsService.instance.trackError(
        errorType: 'ai_recommendation_error',
        errorMessage: error.toString(),
        screen: 'ai_service',
      );
      return [];
    }
  }

  // Analyse user behaviour patterns from local storage
  Future<UserBehaviorInsight> _analyzeUserBehavior(String userId) async {
    try {
      // Load raw interaction and analytics data from Hive
      final rawInteractions = await _storage.getContentInteractions(userId);
      final rawEvents = await _storage.getAnalyticsEvents(userId);

      final screenViews = <String, int>{};
      final actionCounts = <String, int>{};
      final contentTypePreferences = <String, int>{};
      final platformPreferences = <String, int>{};
      final categoryPreferences = <String, int>{};

      // Process analytics events (most recent 500)
      final recentEvents = rawEvents.length > 500
          ? rawEvents.sublist(rawEvents.length - 500)
          : rawEvents;

      for (final eventMap in recentEvents) {
        try {
          final eventData = AnalyticsEvent.fromJson(eventMap);

          if (eventData.screenName != null) {
            screenViews[eventData.screenName!] =
                (screenViews[eventData.screenName!] ?? 0) + 1;
          }

          actionCounts[eventData.eventName] =
              (actionCounts[eventData.eventName] ?? 0) + 1;
        } catch (_) {
          // Skip malformed events
        }
      }

      // Enrich from onboarding preferences (genre affinities)
      final onboardingPrefs = await OnboardingService.instance
          .getUserPreferences();
      if (onboardingPrefs != null) {
        for (final interest in onboardingPrefs.contentInterests) {
          categoryPreferences[interest] =
              (categoryPreferences[interest] ?? 0) + 10;
        }
        for (final entry in onboardingPrefs.platformPriorities.entries) {
          // Higher priority (larger double value) → more preference weight
          final weight = (entry.value * 5).round().clamp(1, 20);
          platformPreferences[entry.key] =
              (platformPreferences[entry.key] ?? 0) + weight;
        }
      }

      // Process content interactions (most recent 1000)
      final recentInteractions = rawInteractions.length > 1000
          ? rawInteractions.sublist(rawInteractions.length - 1000)
          : rawInteractions;

      for (final interactionMap in recentInteractions) {
        try {
          final interaction = ContentInteraction.fromJson(interactionMap);

          // Try to load the associated content from local storage
          final content = await _storage.getContent(interaction.contentId);
          if (content != null) {
            contentTypePreferences[content.contentType.name] =
                (contentTypePreferences[content.contentType.name] ?? 0) + 1;

            platformPreferences[content.platform.name] =
                (platformPreferences[content.platform.name] ?? 0) + 1;

            for (final category in content.categories) {
              categoryPreferences[category] =
                  (categoryPreferences[category] ?? 0) + 1;
            }
          }
        } catch (_) {
          // Skip malformed records
        }
      }

      final totalInteractions = recentInteractions.length;
      final totalEvents = recentEvents.length;
      final engagementScore = _calculateEngagementScore(
        totalInteractions,
        totalEvents,
        actionCounts,
      );

      final preferredContentTypes = contentTypePreferences.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topContentTypes = preferredContentTypes
          .take(5)
          .map((e) => e.key)
          .toList();

      final mostUsedFeaturesEntries = actionCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topFeatures = mostUsedFeaturesEntries
          .take(5)
          .map((e) => e.key)
          .toList();

      return UserBehaviorInsight(
        userId: userId,
        screenViews: screenViews,
        actionCounts: actionCounts,
        preferredContentTypes: topContentTypes,
        mostUsedFeatures: topFeatures,
        engagementScore: engagementScore,
        averageSessionDuration: const Duration(minutes: 15),
        lastActiveAt: DateTime.now(),
        additionalMetrics: {
          'platform_preferences': platformPreferences,
          'category_preferences': categoryPreferences,
          'content_type_preferences': contentTypePreferences,
        },
      );
    } catch (error) {
      debugPrint('Error analyzing user behavior: $error');
      return UserBehaviorInsight(userId: userId, lastActiveAt: DateTime.now());
    }
  }

  // Calculate engagement score based on user activity
  double _calculateEngagementScore(
    int totalInteractions,
    int totalEvents,
    Map<String, int> actionCounts,
  ) {
    if (totalEvents == 0) return 0.0;

    double score = (totalInteractions / totalEvents).clamp(0.0, 1.0);

    final valuableActions = ['like', 'save', 'share', 'schedule'];
    int valuableActionCount = 0;

    for (final action in valuableActions) {
      valuableActionCount += actionCounts[action] ?? 0;
    }

    if (totalInteractions > 0) {
      final valuableRatio = valuableActionCount / totalInteractions;
      score = (score + valuableRatio) / 2;
    }

    return score.clamp(0.0, 1.0);
  }

  // Generate recommendations from available content
  Future<List<Recommendation>> _generateRecommendationsFromContent({
    required User user,
    required List<Content> content,
    required UserBehaviorInsight userBehavior,
    required int limit,
  }) async {
    final recommendations = <Recommendation>[];
    final now = DateTime.now();

    // Retrieve already-interacted content to avoid duplicates
    final existingInteractions = await _getUserInteractions(user.id);
    final interactedContentIds = existingInteractions
        .map((i) => i.contentId)
        .toSet();

    final availableContent = content
        .where((c) => !interactedContentIds.contains(c.id))
        .toList();

    for (final contentItem in availableContent) {
      if (recommendations.length >= limit) break;

      final score = _calculateRecommendationScore(
        content: contentItem,
        userBehavior: userBehavior,
      );

      if (score > 0.3) {
        final reason = _generateRecommendationReason(
          content: contentItem,
          userBehavior: userBehavior,
          score: score,
        );

        recommendations.add(
          Recommendation(
            id: 'rec_${now.millisecondsSinceEpoch}_${recommendations.length}',
            userId: user.id,
            contentId: contentItem.id,
            recommendationScore: score,
            recommendationReason: reason,
            algorithmVersion: algorithmVersion,
            createdAt: now,
            expiresAt: now.add(const Duration(days: 7)),
          ),
        );
      }
    }

    recommendations.sort(
      (a, b) => b.recommendationScore.compareTo(a.recommendationScore),
    );

    return recommendations.take(limit).toList();
  }

  // Calculate recommendation score for content
  double _calculateRecommendationScore({
    required Content content,
    required UserBehaviorInsight userBehavior,
  }) {
    double score = 0.0;

    // Platform preference score (30%)
    final platformPrefs =
        userBehavior.additionalMetrics['platform_preferences']
            as Map<String, int>? ??
        {};
    final platformScore = _calculatePreferenceScore(
      content.platform.name,
      platformPrefs,
    );
    score += platformScore * 0.3;

    // Content type preference score (25%)
    final contentTypePrefs =
        userBehavior.additionalMetrics['content_type_preferences']
            as Map<String, int>? ??
        {};
    final contentTypeScore = _calculatePreferenceScore(
      content.contentType.name,
      contentTypePrefs,
    );
    score += contentTypeScore * 0.25;

    // Category preference score (25%)
    final categoryPrefs =
        userBehavior.additionalMetrics['category_preferences']
            as Map<String, int>? ??
        {};
    double categoryScore = 0.0;
    for (final category in content.categories) {
      categoryScore = math.max(
        categoryScore,
        _calculatePreferenceScore(category, categoryPrefs),
      );
    }
    score += categoryScore * 0.25;

    // Content popularity score (10%)
    final popularityScore = _calculatePopularityScore(content);
    score += popularityScore * 0.1;

    // Recency score (10%)
    final recencyScore = _calculateRecencyScore(content);
    score += recencyScore * 0.1;

    // Add some randomness for diversity
    score += (_random.nextDouble() - 0.5) * 0.1;

    return score.clamp(0.0, 1.0);
  }

  // Calculate preference score for a specific item
  double _calculatePreferenceScore(String item, Map<String, int> preferences) {
    if (preferences.isEmpty) return 0.5;

    final itemCount = preferences[item] ?? 0;
    final maxCount = preferences.values.reduce(math.max);

    if (maxCount == 0) return 0.5;

    return (itemCount / maxCount).clamp(0.0, 1.0);
  }

  // Calculate popularity score based on engagement metrics
  double _calculatePopularityScore(Content content) {
    final totalEngagement = content.viewCount + (content.likeCount * 10);

    if (totalEngagement > 100000) return 1.0;
    if (totalEngagement > 10000) return 0.8;
    if (totalEngagement > 1000) return 0.6;
    if (totalEngagement > 100) return 0.4;
    return 0.2;
  }

  // Calculate recency score (newer content gets higher score)
  double _calculateRecencyScore(Content content) {
    if (content.publishedAt == null) return 0.5;

    final age = DateTime.now().difference(content.publishedAt!);

    if (age.inHours < 24) return 1.0;
    if (age.inDays < 7) return 0.8;
    if (age.inDays < 30) return 0.6;
    if (age.inDays < 90) return 0.4;
    return 0.2;
  }

  // Generate human-readable recommendation reason
  String _generateRecommendationReason({
    required Content content,
    required UserBehaviorInsight userBehavior,
    required double score,
  }) {
    final reasons = <String>[];

    final platformPrefs =
        userBehavior.additionalMetrics['platform_preferences']
            as Map<String, int>? ??
        {};
    if ((platformPrefs[content.platform.name] ?? 0) > 0) {
      reasons.add(
        'You frequently engage with ${content.platform.name} content',
      );
    }

    if (userBehavior.preferredContentTypes.contains(content.contentType.name)) {
      reasons.add('You enjoy ${content.contentType.name} content');
    }

    final categoryPrefs =
        userBehavior.additionalMetrics['category_preferences']
            as Map<String, int>? ??
        {};
    for (final category in content.categories) {
      if ((categoryPrefs[category] ?? 0) > 0) {
        reasons.add('You like $category content');
        break;
      }
    }

    if (content.viewCount > 10000) {
      reasons.add('This content is trending');
    }

    if (content.publishedAt != null &&
        DateTime.now().difference(content.publishedAt!).inHours < 24) {
      reasons.add('This is fresh content');
    }

    if (reasons.isEmpty) {
      return 'Recommended for you';
    }

    return reasons.take(2).join(' and ');
  }

  // Get user preferences from LocalStorageService (user_model.UserPreferences)
  Future<UserPreferences?> _getUserPreferencesFromStorage(String userId) async {
    try {
      return await _storage.getUserPreferences(userId);
    } catch (error) {
      debugPrint('Error getting user preferences: $error');
      return null;
    }
  }

  // Get existing non-expired recommendations from local storage
  Future<List<Recommendation>> _getExistingRecommendations(
    String userId,
    int limit,
  ) async {
    try {
      final rawRecs = await _storage.getRecommendations(userId);
      final now = DateTime.now();

      final valid = rawRecs
          .map((r) {
            try {
              return Recommendation.fromJson(r);
            } catch (_) {
              return null;
            }
          })
          .whereType<Recommendation>()
          .where((r) => r.expiresAt.isAfter(now))
          .toList();

      valid.sort(
        (a, b) => b.recommendationScore.compareTo(a.recommendationScore),
      );
      return valid.take(limit).toList();
    } catch (error) {
      debugPrint('Error getting existing recommendations: $error');
      return [];
    }
  }

  // Get user interactions from local storage
  Future<List<ContentInteraction>> _getUserInteractions(String userId) async {
    try {
      final rawInteractions = await _storage.getContentInteractions(userId);
      return rawInteractions
          .map((i) {
            try {
              return ContentInteraction.fromJson(i);
            } catch (_) {
              return null;
            }
          })
          .whereType<ContentInteraction>()
          .toList();
    } catch (error) {
      debugPrint('Error getting user interactions: $error');
      return [];
    }
  }

  // Persist recommendations to local storage
  Future<void> _saveRecommendations(
    List<Recommendation> recommendations,
  ) async {
    try {
      for (final rec in recommendations) {
        await _storage.saveRecommendation(rec.toJson());
      }
    } catch (error) {
      debugPrint('Error saving recommendations: $error');
    }
  }

  // Mark recommendation as shown
  Future<void> markRecommendationShown(String recommendationId) async {
    try {
      final rawRecs = await _storage.getRecommendations(
        AuthService.instance.currentUser?.id ?? '',
      );
      for (final raw in rawRecs) {
        if (raw['id'] == recommendationId) {
          final updated = Map<String, dynamic>.from(raw);
          updated['is_shown'] = true;
          await _storage.saveRecommendation(updated);
          break;
        }
      }
    } catch (error) {
      debugPrint('Error marking recommendation as shown: $error');
    }
  }

  // Mark recommendation as clicked
  Future<void> markRecommendationClicked(String recommendationId) async {
    try {
      final rawRecs = await _storage.getRecommendations(
        AuthService.instance.currentUser?.id ?? '',
      );
      for (final raw in rawRecs) {
        if (raw['id'] == recommendationId) {
          final updated = Map<String, dynamic>.from(raw);
          updated['is_clicked'] = true;
          await _storage.saveRecommendation(updated);
          break;
        }
      }

      await AnalyticsService.instance.trackUserInteraction(
        action: 'recommendation_clicked',
        screen: 'feed',
        additionalData: {'recommendation_id': recommendationId},
      );
    } catch (error) {
      debugPrint('Error marking recommendation as clicked: $error');
    }
  }

  // Get recommendation performance metrics from local storage
  Future<Map<String, dynamic>> getRecommendationMetrics(String userId) async {
    try {
      final rawRecs = await _storage.getRecommendations(userId);
      final recommendations = rawRecs
          .map((r) {
            try {
              return Recommendation.fromJson(r);
            } catch (_) {
              return null;
            }
          })
          .whereType<Recommendation>()
          .toList();

      final totalRecommendations = recommendations.length;
      final shownRecommendations = recommendations
          .where((r) => r.isShown)
          .length;
      final clickedRecommendations = recommendations
          .where((r) => r.isClicked)
          .length;

      final showRate = totalRecommendations > 0
          ? shownRecommendations / totalRecommendations
          : 0.0;
      final clickThroughRate = shownRecommendations > 0
          ? clickedRecommendations / shownRecommendations
          : 0.0;

      return {
        'total_recommendations': totalRecommendations,
        'shown_recommendations': shownRecommendations,
        'clicked_recommendations': clickedRecommendations,
        'show_rate': showRate,
        'click_through_rate': clickThroughRate,
        'average_score': recommendations.isNotEmpty
            ? recommendations
                      .map((r) => r.recommendationScore)
                      .reduce((a, b) => a + b) /
                  recommendations.length
            : 0.0,
      };
    } catch (error) {
      debugPrint('Error getting recommendation metrics: $error');
      return {};
    }
  }
}
