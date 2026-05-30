import 'package:flutter/foundation.dart';
import '../models/content_model.dart';
import '../models/platform_connection_model.dart';
import '../models/user_model.dart';
import 'auth_service.dart';
import 'analytics_service.dart';
import 'content_service.dart';
import 'enhanced_recommendation_service.dart';

class ContentAggregationService {
  static ContentAggregationService? _instance;
  static ContentAggregationService get instance =>
      _instance ??= ContentAggregationService._();

  ContentAggregationService._();

  // Aggregate content from all connected platforms
  Future<List<Content>> aggregateContent({
    int limit = 50,
    List<PlatformType>? platforms,
    List<String>? categories,
    String? searchQuery,
  }) async {
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get user's platform connections
      final connections = await AuthService.instance.getPlatformConnections();
      if (connections.isEmpty) {
        return [];
      }

      // Filter connections by requested platforms
      final filteredConnections = platforms != null
          ? connections.where((c) => platforms.contains(c.platform)).toList()
          : connections;

      final allContent = <Content>[];

      // Aggregate content from each platform
      for (final connection in filteredConnections) {
        try {
          final platformContent = await _fetchPlatformContent(
            connection: connection,
            limit: limit ~/ filteredConnections.length,
            categories: categories,
            searchQuery: searchQuery,
          );
          allContent.addAll(platformContent);
        } catch (error) {
          debugPrint(
            'Error fetching content from ${connection.platform}: $error',
          );
          await AnalyticsService.instance.trackError(
            errorType: 'content_aggregation_error',
            errorMessage: 'Failed to fetch from ${connection.platform}: $error',
            screen: 'content_aggregation',
          );
        }
      }

      // Sort by published date (newest first)
      allContent.sort((a, b) {
        if (a.publishedAt == null && b.publishedAt == null) return 0;
        if (a.publishedAt == null) return 1;
        if (b.publishedAt == null) return -1;
        return b.publishedAt!.compareTo(a.publishedAt!);
      });

      // Apply user preferences and filters
      final filteredContent = await _applyUserFilters(allContent, user);

      // Cache content for performance
      await _cacheContent(filteredContent);

      await AnalyticsService.instance.trackUserInteraction(
        action: 'content_aggregated',
        screen: 'feed',
        additionalData: {
          'total_content': filteredContent.length,
          'platforms': filteredConnections.map((c) => c.platform.name).toList(),
        },
      );

      return filteredContent.take(limit).toList();
    } catch (error) {
      await AnalyticsService.instance.trackError(
        errorType: 'content_aggregation_error',
        errorMessage: error.toString(),
        screen: 'content_aggregation',
      );
      return [];
    }
  }

  // Fetch content from a specific platform
  Future<List<Content>> _fetchPlatformContent({
    required PlatformConnection connection,
    int limit = 20,
    List<String>? categories,
    String? searchQuery,
  }) async {
    switch (connection.platform) {
      case PlatformType.youtube:
        return await _fetchYouTubeContent(
          connection,
          limit,
          categories,
          searchQuery,
        );
      case PlatformType.instagram:
        return await _fetchInstagramContent(
          connection,
          limit,
          categories,
          searchQuery,
        );
      case PlatformType.tiktok:
        return await _fetchTikTokContent(
          connection,
          limit,
          categories,
          searchQuery,
        );
      case PlatformType.facebook:
        return await _fetchFacebookContent(
          connection,
          limit,
          categories,
          searchQuery,
        );
    }
  }

  // YouTube content fetching
  Future<List<Content>> _fetchYouTubeContent(
    PlatformConnection connection,
    int limit,
    List<String>? categories,
    String? searchQuery,
  ) async {
    try {
      // Mock implementation - replace with actual YouTube API calls
      await Future.delayed(const Duration(milliseconds: 500));

      final mockContent = <Content>[];

      for (int i = 0; i < limit; i++) {
        mockContent.add(
          Content(
            id: 'youtube_${DateTime.now().millisecondsSinceEpoch}_$i',
            platform: PlatformType.youtube,
            platformContentId: 'yt_video_$i',
            contentType: ContentType.video,
            title:
                'YouTube Video ${i + 1}${searchQuery != null ? ' - $searchQuery' : ''}',
            description:
                'This is a sample YouTube video description for video ${i + 1}',
            thumbnailUrl:
                'https://img.youtube.com/vi/sample_$i/maxresdefault.jpg',
            videoUrl: 'https://www.youtube.com/watch?v=sample_$i',
            embedUrl: 'https://www.youtube.com/embed/sample_$i',
            durationSeconds: 300 + (i * 60),
            viewCount: 1000 + (i * 100),
            likeCount: 50 + (i * 5),
            creatorName: 'YouTube Creator ${i % 5 + 1}',
            creatorId: 'creator_${i % 5 + 1}',
            creatorAvatarUrl: 'https://via.placeholder.com/150',
            tags: ['youtube', 'video', 'content'],
            categories: categories ?? ['entertainment'],
            language: 'en',
            publishedAt: DateTime.now().subtract(Duration(hours: i)),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }

      return mockContent;
    } catch (error) {
      debugPrint('Error fetching YouTube content: $error');
      return [];
    }
  }

  // Instagram content fetching
  Future<List<Content>> _fetchInstagramContent(
    PlatformConnection connection,
    int limit,
    List<String>? categories,
    String? searchQuery,
  ) async {
    try {
      // Mock implementation - replace with actual Instagram API calls
      await Future.delayed(const Duration(milliseconds: 300));

      final mockContent = <Content>[];

      for (int i = 0; i < limit; i++) {
        mockContent.add(
          Content(
            id: 'instagram_${DateTime.now().millisecondsSinceEpoch}_$i',
            platform: PlatformType.instagram,
            platformContentId: 'ig_post_$i',
            contentType: i % 3 == 0 ? ContentType.reel : ContentType.post,
            title:
                'Instagram Post ${i + 1}${searchQuery != null ? ' - $searchQuery' : ''}',
            description:
                'This is a sample Instagram post description #instagram #content',
            thumbnailUrl: 'https://via.placeholder.com/400x400',
            videoUrl: i % 3 == 0
                ? 'https://instagram.com/reel/sample_$i'
                : null,
            embedUrl: 'https://instagram.com/p/sample_$i/embed',
            durationSeconds: i % 3 == 0 ? 30 : null,
            viewCount: 500 + (i * 50),
            likeCount: 25 + (i * 3),
            creatorName: 'Instagram Creator ${i % 3 + 1}',
            creatorId: 'ig_creator_${i % 3 + 1}',
            creatorAvatarUrl: 'https://via.placeholder.com/150',
            tags: ['instagram', 'post', 'social'],
            categories: categories ?? ['lifestyle'],
            language: 'en',
            publishedAt: DateTime.now().subtract(Duration(hours: i * 2)),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }

      return mockContent;
    } catch (error) {
      debugPrint('Error fetching Instagram content: $error');
      return [];
    }
  }

  // Enhanced TikTok content fetching with trending and discovery features
  Future<List<Content>> _fetchTikTokContent(
    PlatformConnection connection,
    int limit,
    List<String>? categories,
    String? searchQuery,
  ) async {
    try {
      // Enhanced implementation with better mock data and real-world patterns
      await Future.delayed(const Duration(milliseconds: 400));

      final tiktokContent = <Content>[];

      // Trending hashtags and topics for more realistic content
      final trendingHashtags = [
        ['fyp', 'viral', 'trending'],
        ['dance', 'music', 'choreography'],
        ['comedy', 'funny', 'meme'],
        ['food', 'recipe', 'cooking'],
        ['fashion', 'style', 'outfit'],
        ['pets', 'animals', 'cute'],
        ['travel', 'adventure', 'explore'],
        ['art', 'creative', 'diy'],
        ['fitness', 'workout', 'health'],
        ['tech', 'gadgets', 'review'],
      ];

      final creators = [
        {'name': '@charlidamelio', 'followers': '151M', 'verified': true},
        {'name': '@khaby.lame', 'followers': '162M', 'verified': true},
        {'name': '@bellapoarch', 'followers': '93M', 'verified': true},
        {'name': '@addisonre', 'followers': '88M', 'verified': true},
        {'name': '@zachking', 'followers': '70M', 'verified': true},
        {'name': '@spencerx', 'followers': '55M', 'verified': true},
        {'name': '@dixiedamelio', 'followers': '57M', 'verified': true},
        {'name': '@lorengray', 'followers': '54M', 'verified': true},
      ];

      for (int i = 0; i < limit; i++) {
        final creator = creators[i % creators.length];
        final hashtags = trendingHashtags[i % trendingHashtags.length];
        final videoId = '${7000000000000000000 + i}';

        // Generate realistic view counts based on creator popularity
        final baseViews = creator['verified'] == true ? 500000 : 50000;
        final viewCount =
            baseViews +
            (i * 10000) +
            (DateTime.now().millisecondsSinceEpoch % 100000);

        final content = Content(
          id: 'tiktok_${DateTime.now().millisecondsSinceEpoch}_$i',
          platform: PlatformType.tiktok,
          platformContentId: videoId,
          contentType: ContentType.short,
          title: _generateTikTokTitle(hashtags, searchQuery, i),
          description: _generateTikTokDescription(
            hashtags,
            creator['name'] as String,
          ),
          thumbnailUrl:
              'https://p16-sign-va.tiktokcdn.com/tos-maliva-p-0068/example_thumbnail_$i.jpg',
          videoUrl: 'https://www.tiktok.com/${creator['name']}/video/$videoId',
          embedUrl: 'https://www.tiktok.com/embed/v2/$videoId',
          durationSeconds: _generateRealisticDuration(),
          viewCount: viewCount,
          likeCount: (viewCount * 0.08).round(), // ~8% like rate
          creatorName: creator['name'] as String,
          creatorId:
              'creator_${(creator['name'] as String).replaceAll('@', '')}_$i',
          creatorAvatarUrl:
              'https://p16-sign-va.tiktokcdn.com/tos-maliva-avt-0068/creator_${i % 8}.jpg',
          tags: hashtags,
          categories: _categorizeTikTokContent(hashtags, categories),
          language: 'en',
          publishedAt: DateTime.now().subtract(
            Duration(hours: i % 24, minutes: (i * 17) % 60),
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          // Enhanced metadata for TikTok
          metadata: {
            'sound_id': 'sound_${7000000000000000000 + (i * 3)}',
            'sound_title': _generateSoundTitle(hashtags),
            'effects': _generateEffects(i),
            'is_trending': i < 5, // First 5 are trending
            'engagement_rate': ((viewCount * 0.11) / 1000000).toStringAsFixed(
              2,
            ),
            'creator_followers': creator['followers'],
            'is_verified': creator['verified'] as bool? ?? false,
            'share_count': (viewCount * 0.02).round(), // ~2% share rate
            'comment_count': (viewCount * 0.01).round(), // ~1% comment rate
          },
        );

        tiktokContent.add(content);
      }

      // Sort by engagement for better discovery
      tiktokContent.sort((a, b) => b.viewCount.compareTo(a.viewCount));

      return tiktokContent;
    } catch (error) {
      debugPrint('Error fetching TikTok content: $error');

      // Return fallback content even on error
      return _generateFallbackTikTokContent(limit);
    }
  }

  String _generateTikTokTitle(
    List<String> hashtags,
    String? searchQuery,
    int index,
  ) {
    final titles = [
      'This trend is everywhere! 🔥',
      'POV: You discover this hack',
      'Wait for the plot twist...',
      'This changed my life 💯',
      'Rate my outfit 1-10',
      'Teaching you something new',
      'This sound is addictive',
      'Trying this viral recipe',
      'Day in my life as...',
      'This transition though 🤯',
    ];

    String baseTitle = titles[index % titles.length];
    if (searchQuery != null && searchQuery.isNotEmpty) {
      baseTitle += ' - $searchQuery';
    }
    return baseTitle;
  }

  String _generateTikTokDescription(List<String> hashtags, String creatorName) {
    final descriptions = [
      'Can\'t believe this worked! What do you think?',
      'This took me way too long to figure out 😅',
      'Obsessed with this new trend! Who else?',
      'Teaching you my secret technique ✨',
      'This sound hits different every time',
      'Rate this from 1-10 in the comments!',
      'POV: You\'re scrolling at 3am again',
      'This is your sign to try something new',
      'Manifesting good vibes only 🌟',
      'Who can relate to this? 🙋\u200d♀️',
    ];

    final randomDesc =
        descriptions[DateTime.now().millisecond % descriptions.length];
    final hashtagString = hashtags.map((tag) => '#$tag').join(' ');

    return '$randomDesc\n\n$hashtagString';
  }

  int _generateRealisticDuration() {
    // TikTok videos are typically 15-60 seconds, with most being 15-30s
    final durations = [15, 15, 15, 30, 30, 45, 60]; // Weighted towards shorter
    return durations[DateTime.now().millisecond % durations.length];
  }

  List<String> _categorizeTikTokContent(
    List<String> hashtags,
    List<String>? userCategories,
  ) {
    final categoryMap = {
      'dance': ['entertainment', 'music'],
      'music': ['entertainment', 'music'],
      'comedy': ['entertainment', 'comedy'],
      'food': ['lifestyle', 'food'],
      'fashion': ['lifestyle', 'fashion'],
      'pets': ['lifestyle', 'animals'],
      'travel': ['lifestyle', 'travel'],
      'art': ['creative', 'art'],
      'fitness': ['health', 'fitness'],
      'tech': ['technology', 'reviews'],
    };

    final categories = <String>{};

    for (final hashtag in hashtags) {
      if (categoryMap.containsKey(hashtag)) {
        categories.addAll(categoryMap[hashtag]!);
      }
    }

    if (categories.isEmpty) {
      categories.add('entertainment');
    }

    if (userCategories != null) {
      categories.addAll(userCategories);
    }

    return categories.toList();
  }

  String _generateSoundTitle(List<String> hashtags) {
    final soundTitles = [
      'Original Sound',
      'Trending Audio',
      'Viral Beat',
      'Popular Song',
      'Remix Version',
      'Audio Trend',
      'Hit Song',
      'Dance Beat',
    ];

    return soundTitles[DateTime.now().millisecond % soundTitles.length];
  }

  List<String> _generateEffects(int index) {
    final allEffects = [
      ['Beauty', 'Smooth'],
      ['Vintage', 'Film'],
      ['Neon', 'Glow'],
      ['Sparkle', 'Glitter'],
      ['Blur', 'Focus'],
      ['Color Pop', 'Vibrant'],
      ['Black & White', 'Classic'],
      ['Slow Motion', 'Speed'],
    ];

    return allEffects[index % allEffects.length];
  }

  List<Content> _generateFallbackTikTokContent(int limit) {
    // Minimal fallback content when API fails
    return List.generate(
      limit,
      (i) => Content(
        id: 'tiktok_fallback_$i',
        platform: PlatformType.tiktok,
        platformContentId: 'fallback_$i',
        contentType: ContentType.short,
        title: 'TikTok Video ${i + 1}',
        description: 'Trending TikTok content #fyp #viral',
        thumbnailUrl:
            'https://via.placeholder.com/300x400/000000/FFFFFF?text=TikTok',
        videoUrl: 'https://www.tiktok.com/@user/video/fallback_$i',
        durationSeconds: 30,
        viewCount: 10000 + (i * 1000),
        likeCount: 800 + (i * 80),
        creatorName: 'TikTok Creator',
        creatorId: 'fallback_creator',
        tags: ['fyp', 'viral'],
        categories: ['entertainment'],
        language: 'en',
        publishedAt: DateTime.now().subtract(Duration(hours: i)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  // Facebook content fetching
  Future<List<Content>> _fetchFacebookContent(
    PlatformConnection connection,
    int limit,
    List<String>? categories,
    String? searchQuery,
  ) async {
    try {
      // Mock implementation - replace with actual Facebook API calls
      await Future.delayed(const Duration(milliseconds: 600));

      final mockContent = <Content>[];

      for (int i = 0; i < limit; i++) {
        mockContent.add(
          Content(
            id: 'facebook_${DateTime.now().millisecondsSinceEpoch}_$i',
            platform: PlatformType.facebook,
            platformContentId: 'fb_post_$i',
            contentType: i % 2 == 0 ? ContentType.video : ContentType.post,
            title:
                'Facebook Post ${i + 1}${searchQuery != null ? ' - $searchQuery' : ''}',
            description:
                'This is a sample Facebook post with some content and links',
            thumbnailUrl: 'https://via.placeholder.com/500x300',
            videoUrl: i % 2 == 0
                ? 'https://facebook.com/video/sample_$i'
                : null,
            embedUrl: 'https://facebook.com/plugins/post.php?href=sample_$i',
            durationSeconds: i % 2 == 0 ? 120 + (i * 30) : null,
            viewCount: 800 + (i * 80),
            likeCount: 40 + (i * 4),
            creatorName: 'Facebook Page ${i % 3 + 1}',
            creatorId: 'fb_page_${i % 3 + 1}',
            creatorAvatarUrl: 'https://via.placeholder.com/150',
            tags: ['facebook', 'post', 'social'],
            categories: categories ?? ['news'],
            language: 'en',
            publishedAt: DateTime.now().subtract(Duration(hours: i * 3)),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }

      return mockContent;
    } catch (error) {
      debugPrint('Error fetching Facebook content: $error');
      return [];
    }
  }

  // Apply user preferences and filters
  Future<List<Content>> _applyUserFilters(
    List<Content> content,
    User user,
  ) async {
    try {
      // TODO: Implement user preferences filtering when database is available
      debugPrint('Applying user filters for user: ${user.id}');

      // For now, just return the content as-is
      return content;
    } catch (error) {
      debugPrint('Error applying user filters: $error');
      return content;
    }
  }

  // Cache content for performance
  Future<void> _cacheContent(List<Content> content) async {
    try {
      // TODO: Implement content caching when database is available
      debugPrint(
        'Caching ${content.length} content items for user: ${AuthService.instance.currentUser?.id}',
      );
    } catch (error) {
      debugPrint('Error caching content: $error');
    }
  }

  // Get cached content
  Future<List<Content>?> getCachedContent() async {
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) return null;

      // TODO: Implement cache retrieval when database is available
      debugPrint('Getting cached content for user: ${user.id}');
      return null;
    } catch (error) {
      debugPrint('Error getting cached content: $error');
      return null;
    }
  }

  // Search content across platforms
  Future<List<Content>> searchContent({
    required String query,
    List<PlatformType>? platforms,
    int limit = 30,
  }) async {
    return await aggregateContent(
      searchQuery: query,
      platforms: platforms,
      limit: limit,
    );
  }

  // Get trending content
  Future<List<Content>> getTrendingContent({
    List<PlatformType>? platforms,
    int limit = 20,
  }) async {
    final content = await aggregateContent(
      platforms: platforms,
      limit: limit * 2, // Get more to filter for trending
    );

    // Sort by engagement (views + likes)
    content.sort((a, b) {
      final aEngagement = a.viewCount + (a.likeCount * 10);
      final bEngagement = b.viewCount + (b.likeCount * 10);
      return bEngagement.compareTo(aEngagement);
    });

    return content.take(limit).toList();
  }

  // Refresh content for a specific platform
  Future<List<Content>> refreshPlatformContent(PlatformType platform) async {
    final connections = await AuthService.instance.getPlatformConnections();
    final connection = connections.firstWhere(
      (c) => c.platform == platform,
      orElse: () => throw Exception('Platform not connected'),
    );

    return await _fetchPlatformContent(connection: connection, limit: 50);
  }

  // ---------------------------------------------------------------------------
  // Cold-start content
  // ---------------------------------------------------------------------------

  /// Returns content for a new user who has no watch history.
  /// Fallback chain: cold-start recommendations → trending → seed feed data.
  Future<List<Content>> getColdStartContent({int limit = 20}) async {
    try {
      // 1. Try enhanced cold-start recommendations (genre-diverse)
      final coldStart = await EnhancedRecommendationService.instance
          .getColdStartRecommendations();
      if (coldStart.isNotEmpty) {
        debugPrint(
          'ContentAggregationService: cold-start from recommendation service (${coldStart.length} items)',
        );
        return coldStart.take(limit).toList();
      }
    } catch (e) {
      debugPrint(
        'ContentAggregationService: cold-start recommendations failed: $e',
      );
    }

    try {
      // 2. Fallback to trending content
      final trending = await getTrendingContent(limit: limit);
      if (trending.isNotEmpty) {
        debugPrint(
          'ContentAggregationService: cold-start fallback to trending (${trending.length} items)',
        );
        return trending;
      }
    } catch (e) {
      debugPrint('ContentAggregationService: trending fallback failed: $e');
    }

    // 3. Final fallback: seed feed data from ContentService
    try {
      final seed = await ContentService.instance.getFeedContent(limit: limit);
      debugPrint(
        'ContentAggregationService: cold-start fallback to seed data (${seed.length} items)',
      );
      return seed;
    } catch (e) {
      debugPrint('ContentAggregationService: seed data fallback failed: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Discover page content
  // ---------------------------------------------------------------------------

  /// Returns a mixed content set for the Discover screen:
  /// - top 5 trending items
  /// - 3 items per category for a set of common categories
  /// - the full mixed list deduplicated
  Future<List<Content>> getContentForDiscover({int categoryLimit = 3}) async {
    final results = <String, Content>{}; // deduplicate by id

    // 1. Top 5 trending
    try {
      final trending = await getTrendingContent(limit: 5);
      for (final item in trending) {
        results[item.id] = item;
      }
    } catch (e) {
      debugPrint(
        'ContentAggregationService getContentForDiscover trending error: $e',
      );
    }

    // 2. 3 items per category
    const discoverCategories = [
      'Gaming',
      'Music',
      'Technology',
      'Comedy',
      'Education',
      'Sports',
      'Lifestyle',
      'News',
    ];

    for (final category in discoverCategories) {
      try {
        final catContent = await ContentService.instance.getVideosByCategory(
          category,
          limit: categoryLimit,
        );
        for (final item in catContent) {
          results[item.id] = item;
        }
      } catch (e) {
        debugPrint(
          'ContentAggregationService getContentForDiscover category "$category" error: $e',
        );
      }
    }

    // 3. Return deduplicated mixed list
    final mixed = results.values.toList();
    debugPrint(
      'ContentAggregationService getContentForDiscover: ${mixed.length} items total',
    );
    return mixed;
  }
}
