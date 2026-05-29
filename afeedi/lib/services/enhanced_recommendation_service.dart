import 'package:flutter/foundation.dart';
import '../models/user_preferences.dart' as preferences;
import '../models/content_model.dart';
import 'auth_service.dart';
import 'content_aggregation_service.dart';
import 'onboarding_service.dart';

// Simplified recommendation model
class Recommendation {
  final String id;
  final String userId;
  final String contentId;
  final Content content;
  final double score;
  final String reason;
  final String algorithmVersion;
  final DateTime createdAt;
  final DateTime expiresAt;
  
  Recommendation({
    required this.id,
    required this.userId,
    required this.contentId,
    required this.content,
    required this.score,
    required this.reason,
    required this.algorithmVersion,
    required this.createdAt,
    required this.expiresAt,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'content_id': contentId,
      'recommendation_score': score,
      'recommendation_reason': reason,
      'algorithm_version': algorithmVersion,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    };
  }
}

// Simplified user behavior insights
class UserBehaviorInsight {
  final String userId;
  final double engagementScore;
  final int interactionCount;
  final Map<String, dynamic> additionalMetrics;
  final DateTime lastUpdated;
  
  UserBehaviorInsight({
    required this.userId,
    required this.engagementScore,
    required this.interactionCount,
    required this.additionalMetrics,
    required this.lastUpdated,
  });
}

class EnhancedRecommendationService {
  static EnhancedRecommendationService? _instance;
  static EnhancedRecommendationService get instance => _instance ??= EnhancedRecommendationService._();
  
  EnhancedRecommendationService._();
  
  // Get time-based recommendations
  Future<List<Recommendation>> getTimeBasedRecommendations({
    required String userId,
    int limit = 10,
  }) async {
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) return [];

      // Get user preferences
      final userPreferences = await OnboardingService().getCurrentPreferences();
      
      // Get content based on current time context
      final currentHour = DateTime.now().hour;
      final timeContext = _getTimeContext(currentHour);
      
      // Get available content
      final contentService = ContentAggregationService.instance;
      final availableContent = await contentService.aggregateContent(
        platforms: userPreferences?.platformPriorities.keys.map((p) => PlatformType.values.firstWhere((pt) => pt.name == p, orElse: () => PlatformType.youtube)).toList() ?? [PlatformType.youtube],
        categories: userPreferences?.contentInterests ?? [],
        limit: limit * 3, // Get more to filter from
      );
      
      // Score content based on time context
      final scoredContent = <MapEntry<Content, double>>[];
      
      for (final content in availableContent) {
        double score = _calculateTimeScore(content, timeContext, currentHour);
        
        // Add user preference scoring if available
        if (userPreferences != null) {
          score += _calculateBasicPreferenceScore(content, userPreferences);
        }
        
        scoredContent.add(MapEntry(content, score));
      }
      
      // Sort by score and take top results
      scoredContent.sort((a, b) => b.value.compareTo(a.value));
      final topContent = scoredContent.take(limit).toList();
      
      // Convert to recommendations
      final recommendations = <Recommendation>[];
      for (int i = 0; i < topContent.length; i++) {
        final content = topContent[i].key;
        final score = topContent[i].value;
        
        final recommendation = Recommendation(
          id: 'time_${DateTime.now().millisecondsSinceEpoch}_$i',
          userId: user.id,
          contentId: content.id,
          content: content,
          score: score,
          reason: 'Time-based recommendation for $timeContext',
          algorithmVersion: '1.0.0',
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 2)),
        );
        
        recommendations.add(recommendation);
      }
      
      return recommendations;
    } catch (error) {
      debugPrint('Error getting time-based recommendations: $error');
      return [];
    }
  }
  
  String _getTimeContext(int hour) {
    if (hour >= 6 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 22) return 'evening';
    return 'night';
  }
  
  double _calculateTimeScore(Content content, String timeContext, int hour) {
    // Base score
    double score = 0.5;
    
    // Adjust based on content type and time
    switch (timeContext) {
      case 'morning':
        if (content.categories.any((cat) => cat.toLowerCase().contains('news')) ||
            content.categories.any((cat) => cat.toLowerCase().contains('education'))) {
          score += 0.3;
        }
        break;
      case 'afternoon':
        if (content.categories.any((cat) => cat.toLowerCase().contains('productivity')) ||
            content.tags.any((tag) => tag.toLowerCase().contains('tutorial'))) {
          score += 0.2;
        }
        break;
      case 'evening':
        if (content.categories.any((cat) => cat.toLowerCase().contains('entertainment')) ||
            content.tags.any((tag) => tag.toLowerCase().contains('music'))) {
          score += 0.3;
        }
        break;
      case 'night':
        if (content.categories.any((cat) => cat.toLowerCase().contains('relaxation')) ||
            content.tags.any((tag) => tag.toLowerCase().contains('podcast'))) {
          score += 0.2;
        }
        break;
    }
    
    return score;
  }
  
  double _calculateBasicPreferenceScore(Content content, preferences.UserPreferences userPreferences) {
    double score = 0.0;
    
    // Check content interests
    for (final interest in userPreferences.contentInterests) {
      if (content.tags.any((tag) => tag.toLowerCase().contains(interest.toLowerCase()))) {
        score += 0.3;
      }
    }
    
    // Check platform preferences
    final platformScore = userPreferences.platformPriorities[content.platform.name] ?? 0.0;
    score += platformScore * 0.2;
    
    return score;
  }
  
  // Track content interaction for future recommendations
  Future<void> trackContentInteraction(Map<String, dynamic> interaction) async {
    // TODO: Implement interaction tracking
    // For now, just log the interaction
    print('Content interaction tracked: $interaction');
  }
  
  // Get personalized recommendations
  Future<List<Recommendation>> getPersonalizedRecommendations({
    required String userId,
    int limit = 10,
  }) async {
    // For now, return time-based recommendations
    return getTimeBasedRecommendations(userId: userId, limit: limit);
  }
  
  // Get onboarding-based recommendations
  Future<List<Recommendation>> getOnboardingBasedRecommendations({
    required String userId,
    int limit = 10,
  }) async {
    // For now, return time-based recommendations
    return getTimeBasedRecommendations(userId: userId, limit: limit);
  }
  
  // Generate viewing habits recommendations
  Future<List<Recommendation>> generateViewingHabitsRecommendations({
    required String userId,
    int limit = 10,
  }) async {
    // For now, return time-based recommendations
    return getTimeBasedRecommendations(userId: userId, limit: limit);
  }
  
  // Generate platform-specific recommendations
  Future<List<Recommendation>> generatePlatformSpecificRecommendations({
    required String userId,
    required String platform,
    int limit = 10,
  }) async {
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) return [];
      
      final contentService = ContentAggregationService.instance;
      final availableContent = await contentService.aggregateContent(
        platforms: [_getPlatformTypeFromString(platform)],
        limit: limit * 2, // Get more to filter
      );
      
      if (availableContent.isEmpty) return [];
      
      // Score content based on platform-specific factors
      final scoredContent = <MapEntry<Content, double>>[];
      
      for (final content in availableContent) {
        double score = 0.5; // Base score
        
        // Platform-specific scoring logic
        if (platform.toLowerCase() == 'youtube') {
          // Prefer longer content for YouTube
          if (content.durationSeconds != null && content.durationSeconds! > 600) score += 0.2;
          if (content.categories.any((cat) => cat.toLowerCase().contains('education'))) {
            score += 0.3;
          }
        } else if (platform.toLowerCase() == 'tiktok') {
          // Prefer shorter content for TikTok
          if (content.durationSeconds != null && content.durationSeconds! < 180) score += 0.3;
          if (content.categories.any((cat) => cat.toLowerCase().contains('entertainment'))) {
            score += 0.2;
          }
        } else if (platform.toLowerCase() == 'instagram') {
          // Prefer visual content for Instagram
          if (content.categories.any((cat) => cat.toLowerCase().contains('lifestyle'))) {
            score += 0.2;
          }
        }
        
        scoredContent.add(MapEntry(content, score));
      }
      
      // Sort by score and take top results
      scoredContent.sort((a, b) => b.value.compareTo(a.value));
      final topContent = scoredContent.take(limit).toList();
      
      // Convert to recommendations
      final recommendations = <Recommendation>[];
      for (int i = 0; i < topContent.length; i++) {
        final content = topContent[i].key;
        final score = topContent[i].value;
        
        final recommendation = Recommendation(
          id: 'platform_${platform}_${DateTime.now().millisecondsSinceEpoch}_$i',
          userId: user.id,
          contentId: content.id,
          content: content,
          score: score,
          reason: 'Platform-specific recommendation for $platform',
          algorithmVersion: '1.0.0',
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 4)),
        );
        
        recommendations.add(recommendation);
      }
      
      return recommendations;
    } catch (error) {
      debugPrint('Error getting platform-specific recommendations: $error');
      return [];
    }
  }
  
  // Helper method to convert string to PlatformType
  PlatformType _getPlatformTypeFromString(String platform) {
    switch (platform.toLowerCase()) {
      case 'youtube':
        return PlatformType.youtube;
      case 'instagram':
        return PlatformType.instagram;
      case 'tiktok':
        return PlatformType.tiktok;
      case 'facebook':
        return PlatformType.facebook;
      default:
        return PlatformType.youtube;
    }
  }
  
}