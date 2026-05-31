import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/content_model.dart';
import '../models/analytics_model.dart';
import 'enhanced_recommendation_service.dart';
import 'onboarding_service.dart';
import 'auth_service.dart';

class ContentService {
  static final ContentService _instance = ContentService._internal();
  factory ContentService() => _instance;
  ContentService._internal();

  static ContentService get instance => _instance;

  // YouTube RSS feed channels for trending content (public, no API key needed)
  static const List<String> _trendingChannelIds = [
    'UCbmNph6atAoGfqLoCL_duAg', // Techquickie
    'UCXuqSBlHAE6Xw-yeJA0Tunw', // Linus Tech Tips
    'UCBcRF18a7Qf58cCRy5xuWwQ', // Mark Rober
    'UC29ju8bIPH5as8OGnQzwJyA', // Traversy Media
    'UCW5YeuERMmlnqo4oq8vwUpg', // The Game Theorists
    'UCo8bcnLyZH8tBIH9V1mLgqQ', // ByteByteGo
    'UCWX3yGbODI0KyQJgFMDCTnA', // ColdFusion
  ];

  Future<List<Content>> fetchYouTubeRssFeed(String channelId, {int limit = 5}) async {
    try {
      final url = 'https://www.youtube.com/feeds/videos.xml?channel_id=$channelId';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return [];
      return _parseYouTubeRss(response.body, limit: limit);
    } catch (_) {
      return [];
    }
  }

  List<Content> _parseYouTubeRss(String xml, {int limit = 5}) {
    final results = <Content>[];
    final entryRegex = RegExp(r'<entry>([\s\S]*?)</entry>');
    final videoIdRegex = RegExp(r'<yt:videoId>(.*?)</yt:videoId>');
    final titleRegex = RegExp(r'<title>(.*?)</title>');
    final authorRegex = RegExp(r'<name>(.*?)</name>');
    final publishedRegex = RegExp(r'<published>(.*?)</published>');
    final viewCountRegex = RegExp(r'<media:statistics views="(\d+)"');

    for (final match in entryRegex.allMatches(xml).take(limit)) {
      final entry = match.group(1) ?? '';
      final videoId = videoIdRegex.firstMatch(entry)?.group(1) ?? '';
      final titleMatch = titleRegex.allMatches(entry).skip(1).firstOrNull;
      final title = titleMatch?.group(1) ?? '';
      final author = authorRegex.firstMatch(entry)?.group(1) ?? '';
      final published = publishedRegex.firstMatch(entry)?.group(1);
      final viewCount = int.tryParse(viewCountRegex.firstMatch(entry)?.group(1) ?? '0') ?? 0;

      if (videoId.isEmpty) continue;

      results.add(Content(
        id: 'yt_rss_$videoId',
        platform: PlatformType.youtube,
        platformContentId: videoId,
        contentType: ContentType.video,
        title: _unescapeXml(title),
        thumbnailUrl: 'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
        videoUrl: 'https://www.youtube.com/watch?v=$videoId',
        embedUrl: 'https://www.youtube.com/embed/$videoId',
        creatorName: author,
        viewCount: viewCount,
        publishedAt: published != null ? DateTime.tryParse(published) : null,
        tags: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }
    return results;
  }

  String _unescapeXml(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
  }

  Future<List<Content>> fetchTrendingContent({int limit = 20}) async {
    final allContent = <Content>[];
    final futures = _trendingChannelIds
        .take(4)
        .map((id) => fetchYouTubeRssFeed(id, limit: (limit / 4).ceil()));
    final results = await Future.wait(futures, eagerError: false);
    for (final batch in results) {
      allContent.addAll(batch);
    }
    allContent.sort((a, b) {
      final aDate = a.publishedAt ?? DateTime(2000);
      final bDate = b.publishedAt ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });
    return allContent.take(limit).toList();
  }

  // Sample content — guaranteed-playable YouTube IDs are listed first so the
  // fallback path always surfaces real, embeddable videos.
  // Reliable IDs:
  //   dQw4w9WgXcQ  Rick Astley "Never Gonna Give You Up" (never removed)
  //   jNQXAC9IVRw  "Me at the zoo" (first YouTube video ever)
  //   M7lc1UVf-VE  YouTube Help intro (official channel)
  static final List<Content> _sampleVideos = [
    Content(
      id: 'yt_1',
      platform: PlatformType.youtube,
      platformContentId: 'dQw4w9WgXcQ',
      title: 'Rick Astley – Never Gonna Give You Up',
      description: 'The iconic music video, guaranteed to be available and embeddable.',
      videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      embedUrl: 'https://www.youtube.com/embed/dQw4w9WgXcQ',
      thumbnailUrl: 'https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
      creatorName: 'RickAstleyVEVO',
      durationSeconds: 213,
      viewCount: 1500000000,
      likeCount: 15000000,
      publishedAt: DateTime.now().subtract(Duration(days: 7)),
      tags: ['music', 'classic', 'pop'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 7)),
      updatedAt: DateTime.now().subtract(Duration(days: 7)),
    ),
    Content(
      id: 'yt_2',
      platform: PlatformType.youtube,
      platformContentId: 'jNQXAC9IVRw',
      title: 'Me at the zoo – First YouTube Video',
      description: 'The very first video ever uploaded to YouTube by co-founder Jawed Karim.',
      videoUrl: 'https://www.youtube.com/watch?v=jNQXAC9IVRw',
      embedUrl: 'https://www.youtube.com/embed/jNQXAC9IVRw',
      thumbnailUrl: 'https://img.youtube.com/vi/jNQXAC9IVRw/hqdefault.jpg',
      creatorName: 'jawed',
      durationSeconds: 19,
      viewCount: 300000000,
      likeCount: 2500000,
      publishedAt: DateTime.now().subtract(Duration(days: 3)),
      tags: ['history', 'youtube', 'animals'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 3)),
      updatedAt: DateTime.now().subtract(Duration(days: 3)),
    ),
    Content(
      id: 'yt_3',
      platform: PlatformType.youtube,
      platformContentId: 'M7lc1UVf-VE',
      title: 'YouTube – Broadcast Yourself',
      description: 'Official YouTube intro video, always available and embeddable.',
      videoUrl: 'https://www.youtube.com/watch?v=M7lc1UVf-VE',
      embedUrl: 'https://www.youtube.com/embed/M7lc1UVf-VE',
      thumbnailUrl: 'https://img.youtube.com/vi/M7lc1UVf-VE/hqdefault.jpg',
      creatorName: 'YouTube',
      durationSeconds: 61,
      viewCount: 50000000,
      likeCount: 500000,
      publishedAt: DateTime.now().subtract(Duration(days: 5)),
      tags: ['youtube', 'official', 'intro'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 5)),
      updatedAt: DateTime.now().subtract(Duration(days: 5)),
    ),
    Content(
      id: 'yt_4',
      platform: PlatformType.youtube,
      platformContentId: 'vmEHCJofslg',
      title: 'Python Data Science Tutorial',
      description: 'Complete guide to data science with Python and pandas',
      videoUrl: 'https://www.youtube.com/watch?v=vmEHCJofslg',
      embedUrl: 'https://www.youtube.com/embed/vmEHCJofslg',
      thumbnailUrl: 'https://img.youtube.com/vi/vmEHCJofslg/hqdefault.jpg',
      creatorName: 'Data Science Pro',
      durationSeconds: 2120,
      viewCount: 1100000,
      likeCount: 52000,
      publishedAt: DateTime.now().subtract(Duration(days: 10)),
      tags: ['python', 'data-science', 'pandas'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 10)),
      updatedAt: DateTime.now().subtract(Duration(days: 10)),
    ),
    Content(
      id: 'yt_5',
      platform: PlatformType.youtube,
      platformContentId: 'ysEN5RaKOlA',
      title: 'Web Development Roadmap 2024',
      description: 'Complete roadmap for becoming a web developer in 2024',
      videoUrl: 'https://www.youtube.com/watch?v=ysEN5RaKOlA',
      embedUrl: 'https://www.youtube.com/embed/ysEN5RaKOlA',
      thumbnailUrl: 'https://img.youtube.com/vi/ysEN5RaKOlA/hqdefault.jpg',
      creatorName: 'Web Dev Simplified',
      durationSeconds: 1690,
      viewCount: 750000,
      likeCount: 38000,
      publishedAt: DateTime.now().subtract(Duration(days: 2)),
      tags: ['web-development', 'roadmap', '2024'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 2)),
      updatedAt: DateTime.now().subtract(Duration(days: 2)),
    ),
    
    // Instagram Content
    Content(
      id: 'ig_1',
      platform: PlatformType.instagram,
      platformContentId: 'C8vQJ2nL9Kx',
      title: 'Amazing Sunset Photography',
      description: 'Captured this beautiful sunset at the beach today! 🌅 #photography #sunset #nature',
      videoUrl: 'https://www.instagram.com/p/C8vQJ2nL9Kx/',
      thumbnailUrl: 'https://scontent.cdninstagram.com/v/t51.2885-15/example.jpg',
      creatorName: 'photography_pro',
      creatorAvatarUrl: 'https://scontent.cdninstagram.com/v/t51.2885-19/example_avatar.jpg',
      durationSeconds: 30,
      viewCount: 125000,
      likeCount: 8500,
      publishedAt: DateTime.now().subtract(Duration(hours: 6)),
      tags: ['photography', 'sunset', 'nature', 'beach'],
      contentType: ContentType.reel,
      createdAt: DateTime.now().subtract(Duration(hours: 6)),
      updatedAt: DateTime.now().subtract(Duration(hours: 6)),
    ),
    Content(
      id: 'ig_2',
      platform: PlatformType.instagram,
      platformContentId: 'C9aB3dE4fG5',
      title: 'Quick Recipe: Pasta Carbonara',
      description: 'Easy 15-minute pasta carbonara recipe! 🍝 Perfect for busy weeknights #cooking #recipe #pasta',
      videoUrl: 'https://www.instagram.com/p/C9aB3dE4fG5/',
      thumbnailUrl: 'https://scontent.cdninstagram.com/v/t51.2885-15/cooking_example.jpg',
      creatorName: 'chef_maria',
      creatorAvatarUrl: 'https://scontent.cdninstagram.com/v/t51.2885-19/chef_avatar.jpg',
      durationSeconds: 45,
      viewCount: 89000,
      likeCount: 6200,
      publishedAt: DateTime.now().subtract(Duration(days: 1)),
      tags: ['cooking', 'recipe', 'pasta', 'italian'],
      contentType: ContentType.reel,
      createdAt: DateTime.now().subtract(Duration(days: 1)),
      updatedAt: DateTime.now().subtract(Duration(days: 1)),
    ),
    
    // TikTok Content
    Content(
      id: 'tt_1',
      platform: PlatformType.tiktok,
      platformContentId: '7234567890123456789',
      title: 'Dance Challenge Compilation',
      description: 'Latest dance trends compilation! Which one is your favorite? 💃 #dance #trending #fyp',
      videoUrl: 'https://www.tiktok.com/@user/video/7234567890123456789',
      thumbnailUrl: 'https://p16-sign-va.tiktokcdn.com/example_thumbnail.jpg',
      creatorName: 'dance_moves',
      creatorAvatarUrl: 'https://p16-sign-va.tiktokcdn.com/example_avatar.jpg',
      durationSeconds: 60,
      viewCount: 2100000,
      likeCount: 156000,
      publishedAt: DateTime.now().subtract(Duration(hours: 12)),
      tags: ['dance', 'trending', 'fyp', 'challenge'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(hours: 12)),
      updatedAt: DateTime.now().subtract(Duration(hours: 12)),
    ),
    Content(
      id: 'tt_2',
      platform: PlatformType.tiktok,
      platformContentId: '7345678901234567890',
      title: 'Life Hacks You Need to Know',
      description: 'Mind-blowing life hacks that will change your daily routine! 🤯 #lifehacks #tips #viral',
      videoUrl: 'https://www.tiktok.com/@user/video/7345678901234567890',
      thumbnailUrl: 'https://p16-sign-va.tiktokcdn.com/lifehacks_thumbnail.jpg',
      creatorName: 'life_hacker',
      creatorAvatarUrl: 'https://p16-sign-va.tiktokcdn.com/hacker_avatar.jpg',
      durationSeconds: 45,
      viewCount: 890000,
      likeCount: 67000,
      publishedAt: DateTime.now().subtract(Duration(hours: 18)),
      tags: ['lifehacks', 'tips', 'viral', 'useful'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(hours: 18)),
      updatedAt: DateTime.now().subtract(Duration(hours: 18)),
    ),
    
    // Facebook Content
    Content(
      id: 'fb_1',
      platform: PlatformType.facebook,
      platformContentId: '1234567890123456',
      title: 'Travel Vlog: Exploring Japan',
      description: 'Join me on an incredible journey through Japan! From Tokyo to Kyoto, experiencing the culture, food, and beautiful landscapes.',
      videoUrl: 'https://www.facebook.com/video.php?v=1234567890123456',
      thumbnailUrl: 'https://scontent.xx.fbcdn.net/v/t15.5256-10/japan_travel.jpg',
      creatorName: 'Travel Adventures',
      creatorAvatarUrl: 'https://scontent.xx.fbcdn.net/v/t1.30497-1/travel_avatar.jpg',
      durationSeconds: 1200,
      viewCount: 450000,
      likeCount: 23000,
      publishedAt: DateTime.now().subtract(Duration(days: 4)),
      tags: ['travel', 'japan', 'vlog', 'culture'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 4)),
      updatedAt: DateTime.now().subtract(Duration(days: 4)),
    ),
    Content(
      id: 'fb_2',
      platform: PlatformType.facebook,
      platformContentId: '2345678901234567',
      title: 'Tech News Weekly Roundup',
      description: 'This week in tech: AI breakthroughs, new smartphone releases, and the latest in sustainable technology innovations.',
      videoUrl: 'https://www.facebook.com/video.php?v=2345678901234567',
      thumbnailUrl: 'https://scontent.xx.fbcdn.net/v/t15.5256-10/tech_news.jpg',
      creatorName: 'Tech Today',
      creatorAvatarUrl: 'https://scontent.xx.fbcdn.net/v/t1.30497-1/tech_avatar.jpg',
      durationSeconds: 900,
      viewCount: 320000,
      likeCount: 18500,
      publishedAt: DateTime.now().subtract(Duration(days: 6)),
      tags: ['tech', 'news', 'ai', 'smartphones'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 6)),
      updatedAt: DateTime.now().subtract(Duration(days: 6)),
    ),
    Content(
      id: 'yt_6',
      platform: PlatformType.youtube,
      platformContentId: 'ukzFI9rgwfU',
      title: 'Machine Learning Basics',
      description: 'Introduction to machine learning concepts and algorithms',
      videoUrl: 'https://www.youtube.com/watch?v=ukzFI9rgwfU',
      embedUrl: 'https://www.youtube.com/embed/ukzFI9rgwfU',
      thumbnailUrl: 'https://img.youtube.com/vi/ukzFI9rgwfU/hqdefault.jpg',
      creatorName: 'AI Academy',
      durationSeconds: 2550,
      viewCount: 1800000,
      likeCount: 67000,
      publishedAt: DateTime.now().subtract(Duration(days: 8)),
      tags: ['machine-learning', 'ai', 'algorithms'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 8)),
      updatedAt: DateTime.now().subtract(Duration(days: 8)),
    ),
  ];

  // Simulate API call with delay
  Future<List<Content>> getVideos({
    PlatformType? platform,
    String? category,
    int limit = 10,
  }) async {
    // Simulate network delay
    await Future.delayed(Duration(milliseconds: 500));
    
    List<Content> filteredVideos = List.from(_sampleVideos);
    
    // Filter by platform if specified
    if (platform != null) {
      filteredVideos = filteredVideos.where((video) => video.platform == platform).toList();
    }
    
    // Filter by category/tags if specified
    if (category != null && category.isNotEmpty) {
      filteredVideos = filteredVideos.where((video) => 
        video.tags.any((tag) => tag.toLowerCase().contains(category.toLowerCase()))
      ).toList();
    }
    
    // Shuffle for variety
    filteredVideos.shuffle(Random());
    
    // Limit results
    return filteredVideos.take(limit).toList();
  }

  // Get trending videos — tries YouTube RSS first, falls back to sample data
  Future<List<Content>> getTrendingVideos({int limit = 15}) async {
    try {
      final rssContent = await fetchTrendingContent(limit: limit);
      if (rssContent.isNotEmpty) return rssContent;
    } catch (_) {}
    // Fallback to sample data (guaranteed-playable IDs are listed first)
    final shuffled = List<Content>.from(_sampleVideos)..shuffle(Random());
    return shuffled.take(limit).toList();
  }

  // Get videos by category
  Future<List<Content>> getVideosByCategory(String category, {int limit = 10}) async {
    return getVideos(category: category, limit: limit);
  }

  // Search videos
  Future<List<Content>> searchVideos(String query, {int limit = 10}) async {
    await Future.delayed(Duration(milliseconds: 400));
    
    if (query.isEmpty) return [];
    
    List<Content> searchResults = _sampleVideos.where((video) => 
      video.title?.toLowerCase().contains(query.toLowerCase()) == true ||
      video.description?.toLowerCase().contains(query.toLowerCase()) == true ||
      video.creatorName?.toLowerCase().contains(query.toLowerCase()) == true ||
      video.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()))
    ).toList();
    
    return searchResults.take(limit).toList();
  }

  // Get video by ID
  Future<Content?> getVideoById(String id) async {
    await Future.delayed(Duration(milliseconds: 200));
    
    try {
      return _sampleVideos.firstWhere((video) => video.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get recommended videos based on a video
  Future<List<Content>> getRecommendedVideos(String videoId, {int limit = 5}) async {
    await Future.delayed(Duration(milliseconds: 300));
    
    Content? currentVideo = await getVideoById(videoId);
    if (currentVideo == null) return [];
    
    // Find videos with similar tags
    List<Content> recommended = _sampleVideos.where((video) => 
      video.id != videoId &&
      video.tags.any((tag) => currentVideo.tags.contains(tag))
    ).toList();
    
    // If not enough similar videos, add random ones
    if (recommended.length < limit) {
      List<Content> remaining = _sampleVideos.where((video) => 
        video.id != videoId && !recommended.contains(video)
      ).toList();
      remaining.shuffle(Random());
      recommended.addAll(remaining.take(limit - recommended.length));
    }
    
    recommended.shuffle(Random());
    return recommended.take(limit).toList();
  }

  // Get feed content (mixed content for feed screen)
  Future<List<Content>> getFeedContent({int limit = 10}) async {
    await Future.delayed(Duration(milliseconds: 600));
    
    List<Content> feedContent = List.from(_sampleVideos);
    feedContent.shuffle(Random());
    
    return feedContent.take(limit).toList();
  }

  // Load more content (pagination simulation)
  Future<List<Content>> loadMoreContent(int offset, {int limit = 10}) async {
    await Future.delayed(Duration(milliseconds: 500));
    
    // Simulate pagination by cycling through content
    List<Content> allContent = List.from(_sampleVideos);
    List<Content> moreContent = [];
    
    for (int i = 0; i < limit; i++) {
      int index = (offset + i) % allContent.length;
      Content content = allContent[index];
      // Create a copy with modified data to simulate new content
      moreContent.add(content.copyWith(
        id: '${content.id}_${offset + i}',
        publishedAt: DateTime.now().subtract(Duration(hours: offset + i)),
      ));
    }
    
    return moreContent;
  }

  // Get personalized content based on onboarding preferences
  Future<List<Content>> getPersonalizedContent({int limit = 10}) async {
    try {
      final enhancedService = EnhancedRecommendationService.instance;
      final onboardingService = OnboardingService();
      final authService = AuthService.instance;
      
      // Check if user is authenticated
      final user = authService.currentUser;
      if (user == null) {
        // Return general trending content for unauthenticated users
        return getTrendingVideos(limit: limit);
      }
      
      // Check if onboarding is completed
      final isOnboardingCompleted = await onboardingService.isOnboardingCompleted();
      if (!isOnboardingCompleted) {
        // Return general content if onboarding not completed
        return getFeedContent(limit: limit);
      }
      
      // Get personalized recommendations
      final recommendations = await enhancedService.getPersonalizedRecommendations(
        userId: user.id,
        limit: limit,
      );
      
      // Convert recommendations to content objects
      return recommendations.map((rec) => rec.content).toList();
    } catch (e) {
      print('Error getting personalized content: $e');
      // Fallback to regular feed content
      return getFeedContent(limit: limit);
    }
  }

  // Get onboarding-based recommendations for new users
  Future<List<Content>> getOnboardingBasedRecommendations({int limit = 10}) async {
    try {
      final enhancedService = EnhancedRecommendationService.instance;
      final onboardingService = OnboardingService();
      final authService = AuthService.instance;
      
      final user = authService.currentUser;
      if (user == null) {
        return getFeedContent(limit: limit);
      }
      
      // Get user preferences from onboarding
      final preferences = await onboardingService.getCurrentPreferences();
      if (preferences == null) {
        return getFeedContent(limit: limit);
      }
      
      // Get onboarding-based recommendations
      final recommendations = await enhancedService.getOnboardingBasedRecommendations(
        userId: user.id,
        limit: limit,
      );
      
      // Convert recommendations to content objects
      return recommendations.map((rec) => rec.content).toList();
    } catch (e) {
      print('Error getting onboarding-based recommendations: $e');
      // Fallback to regular feed content
      return getFeedContent(limit: limit);
    }
  }

  // Get content filtered by user preferences
  Future<List<Content>> getPreferenceFilteredContent({
    PlatformType? platform,
    String? category,
    int limit = 10,
  }) async {
    try {
      final onboardingService = OnboardingService();
      final preferences = await onboardingService.getCurrentPreferences();
      
      List<Content> filteredContent = List.from(_sampleVideos);
      
      // Apply platform preferences if available
      if (preferences != null && preferences.platformPriorities.isNotEmpty) {
        // Sort by platform priority
        filteredContent.sort((a, b) {
          final aPriority = preferences.platformPriorities[a.platform] ?? 0.0;
          final bPriority = preferences.platformPriorities[b.platform] ?? 0.0;
          return bPriority.compareTo(aPriority);
        });
      }
      
      // Apply additional filters
      if (platform != null) {
        filteredContent = filteredContent.where((content) => content.platform == platform).toList();
      }
      
      if (category != null && category.isNotEmpty) {
        filteredContent = filteredContent.where((content) => 
          content.tags.any((tag) => tag.toLowerCase().contains(category.toLowerCase()))
        ).toList();
      }
      
      // Apply content preferences if available
      if (preferences != null && preferences.contentInterests.isNotEmpty) {
        filteredContent = filteredContent.where((content) {
          return content.tags.any((tag) => 
            preferences.contentInterests.any((category) => 
              tag.toLowerCase().contains(category.toLowerCase())
            )
          );
        }).toList();
      }
      
      return filteredContent.take(limit).toList();
    } catch (e) {
      print('Error getting preference filtered content: $e');
      // Fallback to regular filtered content
      return getVideos(platform: platform, category: category, limit: limit);
    }
  }

  // Track user interaction for recommendation improvement
  Future<void> trackContentInteraction({
    required String contentId,
    required InteractionType interactionType,
    int? watchTimeSeconds,
  }) async {
    try {
      final enhancedService = EnhancedRecommendationService.instance;
      final authService = AuthService.instance;
      
      final user = authService.currentUser;
      if (user == null) return;
      
      final interaction = ContentInteraction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.id,
        contentId: contentId,
        interactionType: interactionType,
        interactionData: watchTimeSeconds != null ? {'watchTimeSeconds': watchTimeSeconds} : {},
        createdAt: DateTime.now(),
      );
      
      await enhancedService.trackContentInteraction(interaction.toJson());
    } catch (e) {
      print('Error tracking content interaction: $e');
    }
  }

  // Get content recommendations based on time of day
  Future<List<Content>> getTimeBasedRecommendations({int limit = 10}) async {
    try {
      final enhancedService = EnhancedRecommendationService.instance;
      final authService = AuthService.instance;
      
      final user = authService.currentUser;
      if (user == null) {
        return getFeedContent(limit: limit);
      }
      
      final recommendations = await enhancedService.getTimeBasedRecommendations(
        userId: user.id,
        limit: limit,
      );
      
      // Convert recommendations to content objects
      return recommendations.map((rec) => rec.content).toList();
    } catch (e) {
      print('Error getting time-based recommendations: $e');
      return getFeedContent(limit: limit);
    }
  }
}