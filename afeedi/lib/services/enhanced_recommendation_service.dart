import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_preferences.dart' as preferences;
import '../models/content_model.dart';
import 'auth_service.dart';
import 'content_aggregation_service.dart';
import 'content_service.dart';
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

  static const Map<String, List<String>> _genreTagMap = {
    'gaming':        ['gaming', 'game', 'games', 'esports', 'fps', 'rpg', 'minecraft', 'fortnite', 'valorant', 'streamer'],
    'music':         ['music', 'song', 'songs', 'artist', 'album', 'concert', 'pop', 'hip-hop', 'rap', 'edm', 'classical', 'guitar', 'piano', 'singing'],
    'technology':    ['technology', 'tech', 'programming', 'coding', 'software', 'hardware', 'ai', 'machine-learning', 'flutter', 'javascript', 'python', 'react', 'startup'],
    'comedy':        ['comedy', 'funny', 'humor', 'memes', 'satire', 'standup', 'sketch', 'parody', 'hilarious'],
    'fitness':       ['fitness', 'workout', 'exercise', 'gym', 'yoga', 'running', 'health', 'nutrition', 'weight', 'muscle'],
    'food':          ['food', 'cooking', 'recipe', 'cuisine', 'chef', 'baking', 'restaurant', 'foodie', 'meal'],
    'travel':        ['travel', 'adventure', 'tourism', 'vacation', 'destination', 'backpacking', 'explore', 'vlog'],
    'education':     ['education', 'learning', 'tutorial', 'how-to', 'science', 'history', 'math', 'language', 'study', 'course'],
    'sports':        ['sports', 'football', 'basketball', 'soccer', 'tennis', 'cricket', 'athletics', 'nfl', 'nba', 'match'],
    'fashion':       ['fashion', 'style', 'outfit', 'clothing', 'designer', 'trends', 'beauty', 'makeup', 'skincare'],
    'art':           ['art', 'design', 'drawing', 'painting', 'illustration', 'photography', 'creative', 'animation'],
    'news':          ['news', 'politics', 'world', 'breaking', 'journalism', 'reporter'],
    'business':      ['business', 'entrepreneur', 'startup', 'marketing', 'finance', 'investing', 'economy', 'stocks'],
    'science':       ['science', 'physics', 'chemistry', 'biology', 'space', 'nasa', 'research', 'discovery'],
    'entertainment': ['entertainment', 'celebrity', 'movie', 'films', 'series', 'hollywood', 'bollywood'],
    'lifestyle':     ['lifestyle', 'vlog', 'daily', 'routine', 'motivation', 'wellness', 'mindfulness', 'productivity'],
    'cars':          ['cars', 'automotive', 'vehicle', 'driving', 'racing', 'tesla', 'bmw'],
    'pets':          ['pets', 'dogs', 'cats', 'animals', 'cute', 'adorable', 'animal', 'wildlife'],
  };

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
      final sp = await SharedPreferences.getInstance();
      final platformWatches = _loadPlatformWatches(sp);
      final selectedGenres = sp.getStringList('onboarding_selected_genres') ?? [];

      for (final content in availableContent) {
        double score = _calculateTimeScore(content, timeContext, currentHour);

        // Add enhanced preference scoring if available
        if (userPreferences != null) {
          final prefScore = await _computeRelevanceScore(
            content,
            userPreferences,
            platformWatches: platformWatches,
            selectedGenres: selectedGenres,
          );
          score += prefScore;
        }

        // Apply watch time weight
        score = _applyWatchTimeWeight(score, content.id, sp);

        scoredContent.add(MapEntry(content, score));
      }
      
      // Sort by score, apply diversity cap, then take top results
      scoredContent.sort((a, b) => b.value.compareTo(a.value));
      final sortedContent = scoredContent.map((e) => e.key).toList();
      final diverseContent = _applyDiversity(sortedContent, maxPerCategory: 4);
      final topContent = diverseContent.take(limit).map((c) {
        final entry = scoredContent.firstWhere((e) => e.key.id == c.id);
        return entry;
      }).toList();

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
  
  /// Applies a per-category diversity cap so no single genre dominates
  /// the recommendation list. [maxPerCategory] items are allowed per
  /// category/genre key; the overall result is capped at 20 items.
  List<Content> _applyDiversity(List<Content> sorted, {int maxPerCategory = 4}) {
    final result = <Content>[];
    final categoryCounts = <String, int>{};
    for (final content in sorted) {
      final category = content.categories.isNotEmpty
          ? content.categories.first
          : (content.tags.isNotEmpty ? content.tags.first : 'other');
      final count = categoryCounts[category] ?? 0;
      if (count < maxPerCategory) {
        result.add(content);
        categoryCounts[category] = count + 1;
      }
      if (result.length >= 20) break;
    }
    return result;
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

  // ---------------------------------------------------------------------------
  // Enhanced scoring signals
  // ---------------------------------------------------------------------------

  /// Computes a multi-signal relevance score for a piece of content.
  ///
  /// Signals applied:
  /// - Watch time weight: content watched > 80% gets a 2x multiplier on its
  ///   base preference score.
  /// - Platform affinity: most-watched platforms (from SharedPreferences
  ///   `stat_platform_watches` map) receive an affinity boost up to +0.5.
  /// - Recency decay: content older than 30 days gets a 0.5x multiplier.
  /// - Genre boost: genres from `onboarding_selected_genres` get 1.5x weight
  ///   applied to their keyword-match contribution.
  Future<double> _computeRelevanceScore(
    Content content,
    preferences.UserPreferences prefs, {
    Map<String, int>? platformWatches,
    List<String>? selectedGenres,
  }) async {
    double score = 0.5; // base

    // --- Recency decay ---
    if (content.publishedAt != null) {
      final age = DateTime.now().difference(content.publishedAt!).inDays;
      if (age > 30) {
        score *= 0.5;
      }
    }

    // --- Genre boost ---
    final genres = selectedGenres ?? [];
    final searchable = [
      content.title ?? '',
      content.description ?? '',
      ...content.tags,
      ...content.categories,
    ].join(' ').toLowerCase();

    for (final genre in genres) {
      final genreKey = genre.toLowerCase();
      // Direct match in tags or categories
      final directMatch =
          content.tags.any((t) => t.toLowerCase().contains(genreKey)) ||
          content.categories.any((c) => c.toLowerCase().contains(genreKey));
      if (directMatch) {
        score += 1.5;
        continue;
      }
      // Expanded synonym match via genre map — also checks title/description
      final synonyms = _genreTagMap[genreKey] ??
          _genreTagMap.entries
              .where((e) => e.key.contains(genreKey) || genreKey.contains(e.key))
              .expand((e) => e.value)
              .toList();
      final synonymMatch = synonyms.any((syn) =>
          content.tags.any((t) => t.toLowerCase().contains(syn)) ||
          (content.title?.toLowerCase().contains(syn) ?? false) ||
          (content.description?.toLowerCase().contains(syn) ?? false));
      if (synonymMatch) score += 1.2;
    }

    // --- Basic interest match ---
    for (final interest in prefs.contentInterests) {
      if (searchable.contains(interest.toLowerCase())) {
        score += 0.3;
      }
    }

    // --- Platform affinity ---
    if (platformWatches != null && platformWatches.isNotEmpty) {
      final totalWatches = platformWatches.values.fold(0, (a, b) => a + b);
      if (totalWatches > 0) {
        final platformCount = platformWatches[content.platform.name] ?? 0;
        final affinity = platformCount / totalWatches; // 0.0–1.0
        score += affinity * 0.5;
      }
    } else {
      // Fall back to stored platform priority
      final platformScore = prefs.platformPriorities[content.platform.name] ?? 0.0;
      score += platformScore * 0.2;
    }

    // --- Implicit taste profile (dynamic learning from watch history) ---
    final implicitWeights = await _loadImplicitWeights();
    if (implicitWeights.isNotEmpty) {
      final totalImplicit = implicitWeights.values.fold(0, (a, b) => a + b);
      if (totalImplicit > 0) {
        double implicitBoost = 0.0;
        for (final signal in [...content.tags, ...content.categories]) {
          final key = signal.toLowerCase();
          final count = implicitWeights[key] ?? 0;
          if (count > 0) {
            // Logarithmic scaling: heavy watchers get diminishing returns
            implicitBoost += (count / totalImplicit) * 1.0;
          }
        }
        score += implicitBoost.clamp(0.0, 2.0);
      }
    }

    return score;
  }

  /// Applies continuous watch-time weight: completion rate is used as a
  /// continuous 0–2x multiplier rather than a binary >80% gate.
  /// Formula: 1.0 + (completionRate ^ 0.5) so that:
  ///   0% watched  → 1.0× (no boost)
  ///   25% watched → 1.5× (light boost)
  ///   50% watched → 1.71×
  ///   80% watched → 1.89×
  ///  100% watched → 2.0× (full boost, matches prior max)
  double _applyWatchTimeWeight(double score, String contentId, SharedPreferences sp) {
    final progress = (sp.getDouble('watch_progress_$contentId') ?? 0.0).clamp(0.0, 1.0);
    final multiplier = 1.0 + progress.toDouble();
    return score * multiplier;
  }
  
  static const String _implicitWeightsKey = 'genre_implicit_weights';

  // Track content interaction and update implicit genre weights in SharedPreferences.
  // Each interaction increments the genre counters, which are read back by
  // _computeRelevanceScore() to bias future recommendations toward watched genres.
  Future<void> trackContentInteraction(Map<String, dynamic> interaction) async {
    try {
      final tags = List<String>.from(interaction['tags'] as List? ?? []);
      final categories = List<String>.from(interaction['categories'] as List? ?? []);
      final allSignals = [...tags, ...categories].map((s) => s.toLowerCase()).toList();
      if (allSignals.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_implicitWeightsKey);
      final weights = <String, int>{};
      if (raw != null) {
        try {
          final decoded = raw.split(',').where((e) => e.contains(':'));
          for (final entry in decoded) {
            final parts = entry.split(':');
            if (parts.length == 2) weights[parts[0]] = int.tryParse(parts[1]) ?? 0;
          }
        } catch (_) {}
      }

      // Map raw tags/categories to canonical genre names via the genre tag map
      for (final signal in allSignals) {
        for (final entry in _genreTagMap.entries) {
          if (entry.key == signal || entry.value.any((v) => signal.contains(v) || v.contains(signal))) {
            weights[entry.key] = (weights[entry.key] ?? 0) + 1;
            break;
          }
        }
        // Also directly track by signal if no genre match
        weights[signal] = (weights[signal] ?? 0) + 1;
      }

      // Persist as a compact "key:value,..." string (SharedPreferences has no Map support)
      await prefs.setString(
        _implicitWeightsKey,
        weights.entries.map((e) => '${e.key}:${e.value}').join(','),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Error tracking implicit genre weight: $e');
    }
  }

  Future<Map<String, int>> _loadImplicitWeights() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_implicitWeightsKey);
      if (raw == null || raw.isEmpty) return {};
      final weights = <String, int>{};
      for (final entry in raw.split(',').where((e) => e.contains(':'))) {
        final parts = entry.split(':');
        if (parts.length == 2) weights[parts[0]] = int.tryParse(parts[1]) ?? 0;
      }
      return weights;
    } catch (_) {
      return {};
    }
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
  
  // Get user behavior insights (simplified)
  Future<UserBehaviorInsight?> _getUserBehaviorInsights(String userId) async {
    try {
      // Return a basic insight for now
      return UserBehaviorInsight(
        userId: userId,
        engagementScore: 0.7,
        interactionCount: 10,
        additionalMetrics: {
          'category_preferences': {'tech': 5, 'entertainment': 3},
          'platform_preferences': {'youtube': 8, 'instagram': 2},
        },
        lastUpdated: DateTime.now(),
      );
    } catch (error) {
      debugPrint('Error getting user behavior insights: $error');
      return null;
    }
  }
  
  // Helper method to save a single recommendation to the database
  Future<void> _saveRecommendation(Recommendation recommendation) async {
    try {
      // Save to local storage instead of Supabase
      debugPrint('Saving recommendation: ${recommendation.id}');
    } catch (error) {
      debugPrint('Error saving recommendation: $error');
    }
  }

  // ---------------------------------------------------------------------------
  // Cold-start recommendations
  // ---------------------------------------------------------------------------

  /// For new users with no watch history: returns a diverse sample of content
  /// (up to 2 items from each of the top 5 genres, ensuring platform variety).
  Future<List<Content>> getColdStartRecommendations() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final storedGenres = sp.getStringList('onboarding_selected_genres') ?? [];
      final genres = storedGenres.take(5).toList();
      if (genres.isEmpty) {
        genres.addAll(['Gaming', 'Music', 'Technology', 'Comedy', 'Education']);
      }

      final results = <Content>[];
      for (final genre in genres) {
        try {
          final genreContent = await ContentService.instance.getVideosByCategory(genre, limit: 2);
          results.addAll(genreContent);
        } catch (e) {
          debugPrint('EnhancedRecommendationService: cold-start genre "$genre" error: $e');
        }
      }
      return results;
    } catch (error) {
      debugPrint('EnhancedRecommendationService getColdStartRecommendations error: $error');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // SharedPreferences helpers
  // ---------------------------------------------------------------------------

  /// Loads `stat_platform_watches` stored as individual keys in the format
  /// `stat_platform_watches_<platform>` → int count.
  Map<String, int> _loadPlatformWatches(SharedPreferences sp) {
    final result = <String, int>{};
    for (final platform in ['youtube', 'instagram', 'tiktok', 'facebook']) {
      final count = sp.getInt('stat_platform_watches_$platform');
      if (count != null) result[platform] = count;
    }
    return result;
  }
}