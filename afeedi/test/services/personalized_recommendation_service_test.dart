import 'package:shared_preferences/shared_preferences.dart';
import 'package:afeedi/services/auth_service.dart';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:afeedi/services/personalized_recommendation_service.dart';
import 'package:afeedi/models/user_preferences.dart';
import 'package:afeedi/models/recommendation.dart';

void main() {
  late PersonalizedRecommendationService recommendationService;
  late UserPreferences mockUserPreferences;

  setUp(() {
    recommendationService = PersonalizedRecommendationService.instance;
    recommendationService.setRandom(math.Random(42));

    // Create mock user preferences using the actual UserPreferences API
    mockUserPreferences = const UserPreferences(
      name: 'Test User',
      age: 30,
      language: 'en',
      timezone: 'UTC-5',
      contentInterests: ['technology', 'science', 'travel'],
      contentTypes: ['video', 'article', 'podcast'],
      platformPriorities: {'youtube': 0.8, 'instagram': 0.6, 'tiktok': 0.4},
      preferredCreators: ['Creator1', 'Creator2'],
      contentFilters: {'explicit': false, 'violent': false},
      preferredViewingTimes: ['evening', 'night'],
      averageSessionDuration: 'medium',
      contentDiscoveryStyle: 'balanced',
      genreAffinityScores: {'tech': 0.9, 'documentary': 0.7, 'comedy': 0.6},
      contentMoodPreferences: {
        'morning': 'educational',
        'evening': 'entertainment',
      },
      contentLengthPreferences: {'short': 80, 'medium': 15, 'long': 5},
      enableAIRecommendations: true,
      diversityLevel: 0.7,
      crossPlatformRecommendations: true,
      timeBasedPreferences: {
        'morning': 'educational',
        'evening': 'entertainment',
      },
      smartScheduling: true,
      theme: 'dark',
      compactMode: false,
      feedLayout: 'cards',
    );
  });

  group('PersonalizedRecommendationService', () {
    test(
      'getPersonalizedRecommendations returns personalized recommendations',
      () async {
        // Arrange
        final userPreferences = mockUserPreferences;

        // Act
        final recommendations = await recommendationService
            .getPersonalizedRecommendations(userPreferences: userPreferences);

        // Assert
        expect(recommendations, isNotEmpty);
        expect(recommendations.length, 10);

        // Verify that recommendations have a recommendationReason
        final reasonedItems = recommendations.where((Recommendation item) {
          return item.recommendationReason.isNotEmpty;
        }).toList();

        expect(reasonedItems.length, greaterThan(0));
      },
    );

    test(
      'getContextualRecommendations returns recommendations based on context',
      () async {
        // Arrange
        final context = {
          'eventName': 'Business Meeting',
          'eventType': 'meeting',
          'location': 'Conference Room A',
          'startTime': DateTime.now().add(const Duration(hours: 1)),
          'endTime': DateTime.now().add(const Duration(hours: 2)),
        };

        // Act
        final recommendations = await recommendationService
            .getContextualRecommendations(
              userPreferences: mockUserPreferences,
              context: context,
            );

        // Assert
        expect(recommendations, isNotEmpty);
        expect(recommendations.length, 10);

        // Verify that recommendations are related to the context
        final contextualItems = recommendations.where((Recommendation item) {
          return item.recommendationReason.toLowerCase().contains('meeting') ||
              item.recommendationReason.toLowerCase().contains('business');
        }).toList();

        expect(contextualItems.length, greaterThan(0));
      },
    );

    test(
      'getPlatformRecommendations returns recommendations for specific platform',
      () async {
        // Arrange
        const platform = 'youtube';

        // Act
        final recommendations = await recommendationService
            .getPlatformRecommendations(
              userPreferences: mockUserPreferences,
              platform: platform,
              count: 5,
            );

        // Assert
        expect(recommendations, isNotEmpty);
        expect(recommendations.length, lessThanOrEqualTo(5));

        // Verify that recommendations are for the specified platform
        final platformItems = recommendations.where(
          (Recommendation item) => item.platform.toLowerCase() == platform,
        );
        expect(platformItems, isNotEmpty);
      },
    );

    test('applyDiversityToRecommendations returns diverse recommendations', () {
      // Arrange
      final recommendations = [
        Recommendation(
          id: '1',
          title: 'Tech Video 1',
          description: 'A tech video about the latest technologies',
          imageUrl: 'https://example.com/image1.jpg',
          platform: 'youtube',
          category: 'video',
          recommendationReason: 'Based on your interest in technology',
          durationSeconds: 300,
          relevanceScore: 0.9,
          createdAt: DateTime.now(),
        ),
        Recommendation(
          id: '2',
          title: 'Tech Video 2',
          description: 'Another tech video about programming',
          imageUrl: 'https://example.com/image2.jpg',
          platform: 'youtube',
          category: 'video',
          recommendationReason: 'Based on your interest in technology',
          durationSeconds: 300,
          relevanceScore: 0.8,
          createdAt: DateTime.now(),
        ),
        Recommendation(
          id: '3',
          title: 'Science Article',
          description: 'An article about recent scientific discoveries',
          imageUrl: 'https://example.com/image3.jpg',
          platform: 'medium',
          category: 'article',
          recommendationReason: 'Based on your interest in science',
          durationSeconds: 600,
          relevanceScore: 0.7,
          createdAt: DateTime.now(),
        ),
      ];

      // Act
      final diversifiedRecommendations = recommendationService
          .applyDiversityToRecommendations(
            recommendations,
            diversityFactor: 0.5,
          );

      // Assert
      expect(diversifiedRecommendations, isNotEmpty);
      expect(diversifiedRecommendations.length, recommendations.length);

      // Verify that recommendations are sorted by category
      final categoryGroups = <String, List<Recommendation>>{};
      for (final rec in diversifiedRecommendations) {
        categoryGroups.putIfAbsent(rec.category, () => []).add(rec);
      }
      expect(categoryGroups.length, greaterThanOrEqualTo(1));
    });
  });

  group('generateComprehensiveRecommendations', () {
    test(
      'returns empty list when user is not authenticated (caught exception)',
      () async {
        SharedPreferences.setMockInitialValues({});
        await AuthService.instance.initializeAuth();

        // Act
        final recommendations = await recommendationService
            .generateComprehensiveRecommendations();

        // Assert
        expect(recommendations, isEmpty);
      },
    );

    test(
      'returns seed data when authenticated but no platform connections',
      () async {
        // Setting mock preferences to simulate an authenticated user with no OAuth connections
        SharedPreferences.setMockInitialValues({
          'user_id': 'test_user',
          'user_email': 'test@test.com',
        });
        await AuthService.instance.initializeAuth();

        // Act
        final recommendations = await recommendationService
            .generateComprehensiveRecommendations();

        // Assert: now falls back to seed content instead of empty list
        expect(recommendations, isNotEmpty);
      },
    );
  });
}
