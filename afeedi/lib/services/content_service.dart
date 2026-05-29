import 'dart:async';
import 'dart:math';
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

  // Sample real YouTube video data for testing
  static final List<Content> _sampleVideos = [
    Content(
      id: 'yt_1',
      platform: PlatformType.youtube,
      platformContentId: '1ukSR1GRtMU',
      title: 'Flutter Tutorial - Build Beautiful Apps',
      description: 'Learn how to build beautiful mobile apps with Flutter',
      videoUrl: 'https://www.youtube.com/embed/1ukSR1GRtMU',
      thumbnailUrl: 'https://img.youtube.com/vi/1ukSR1GRtMU/mqdefault.jpg',
      creatorName: 'Flutter',
      durationSeconds: 930,
      viewCount: 1250000,
      likeCount: 45000,
      publishedAt: DateTime.now().subtract(Duration(days: 7)),
      tags: ['flutter', 'mobile', 'development'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 7)),
      updatedAt: DateTime.now().subtract(Duration(days: 7)),
    ),
    Content(
      id: 'yt_2',
      platform: PlatformType.youtube,
      platformContentId: 'X8ipUgXH6jw',
      title: 'React Native vs Flutter Comparison',
      description: 'Detailed comparison between React Native and Flutter frameworks',
      videoUrl: 'https://www.youtube.com/embed/X8ipUgXH6jw',
      thumbnailUrl: 'https://img.youtube.com/vi/X8ipUgXH6jw/mqdefault.jpg',
      creatorName: 'Tech Explained',
      durationSeconds: 1335,
      viewCount: 890000,
      likeCount: 32000,
      publishedAt: DateTime.now().subtract(Duration(days: 3)),
      tags: ['react-native', 'flutter', 'comparison'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 3)),
      updatedAt: DateTime.now().subtract(Duration(days: 3)),
    ),
    Content(
      id: 'yt_3',
      platform: PlatformType.youtube,
      platformContentId: 'NCwa_xi0Uuc',
      title: 'JavaScript ES6 Features Explained',
      description: 'Modern JavaScript features every developer should know',
      videoUrl: 'https://www.youtube.com/embed/NCwa_xi0Uuc',
      thumbnailUrl: 'https://img.youtube.com/vi/NCwa_xi0Uuc/mqdefault.jpg',
      creatorName: 'JavaScript Mastery',
      durationSeconds: 1125,
      viewCount: 567000,
      likeCount: 28000,
      publishedAt: DateTime.now().subtract(Duration(days: 5)),
      tags: ['javascript', 'es6', 'programming'],
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
      videoUrl: 'https://www.youtube.com/embed/vmEHCJofslg',
      thumbnailUrl: 'https://img.youtube.com/vi/vmEHCJofslg/mqdefault.jpg',
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
      videoUrl: 'https://www.youtube.com/embed/ysEN5RaKOlA',
      thumbnailUrl: 'https://img.youtube.com/vi/ysEN5RaKOlA/mqdefault.jpg',
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
      thumbnailUrl: null,
      creatorName: 'photography_pro',
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
      thumbnailUrl: null,
      creatorName: 'chef_maria',
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
      thumbnailUrl: null,
      creatorName: 'dance_moves',
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
      thumbnailUrl: null,
      creatorName: 'life_hacker',
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
      thumbnailUrl: null,
      creatorName: 'Travel Adventures',
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
      thumbnailUrl: null,
      creatorName: 'Tech Today',
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
      videoUrl: 'https://www.youtube.com/embed/ukzFI9rgwfU',
      thumbnailUrl: 'https://img.youtube.com/vi/ukzFI9rgwfU/mqdefault.jpg',
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
    // YouTube Shorts
    Content(
      id: 'yt_short_1',
      platform: PlatformType.youtube,
      platformContentId: 'dQw4w9WgXcQ',
      title: 'Rick Astley - Never Gonna Give You Up',
      description: 'The classic Rick Roll — one of the most iconic videos on YouTube.',
      videoUrl: 'https://www.youtube.com/embed/dQw4w9WgXcQ',
      thumbnailUrl: 'https://img.youtube.com/vi/dQw4w9WgXcQ/mqdefault.jpg',
      creatorName: 'Rick Astley',
      durationSeconds: 53,
      viewCount: 1400000000,
      likeCount: 15000000,
      publishedAt: DateTime.now().subtract(Duration(days: 365 * 10)),
      tags: ['music', 'pop', 'classic', 'trending'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(days: 365 * 10)),
      updatedAt: DateTime.now().subtract(Duration(days: 1)),
    ),
    Content(
      id: 'yt_short_2',
      platform: PlatformType.youtube,
      platformContentId: 'jNQXAC9IVRw',
      title: 'Me at the zoo',
      description: 'The very first video ever uploaded to YouTube. Featuring co-founder Jawed Karim at the San Diego Zoo.',
      videoUrl: 'https://www.youtube.com/embed/jNQXAC9IVRw',
      thumbnailUrl: 'https://img.youtube.com/vi/jNQXAC9IVRw/mqdefault.jpg',
      creatorName: 'jawed',
      durationSeconds: 19,
      viewCount: 280000000,
      likeCount: 3500000,
      publishedAt: DateTime.now().subtract(Duration(days: 365 * 19)),
      tags: ['classic', 'youtube', 'history', 'zoo'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(days: 365 * 19)),
      updatedAt: DateTime.now().subtract(Duration(days: 2)),
    ),
    Content(
      id: 'yt_short_3',
      platform: PlatformType.youtube,
      platformContentId: '9bZkp7q19f0',
      title: 'PSY - GANGNAM STYLE',
      description: 'The video that broke the YouTube view counter. A global music phenomenon.',
      videoUrl: 'https://www.youtube.com/embed/9bZkp7q19f0',
      thumbnailUrl: 'https://img.youtube.com/vi/9bZkp7q19f0/mqdefault.jpg',
      creatorName: 'officialpsy',
      durationSeconds: 58,
      viewCount: 5000000000,
      likeCount: 25000000,
      publishedAt: DateTime.now().subtract(Duration(days: 365 * 12)),
      tags: ['music', 'kpop', 'dance', 'trending', 'viral'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(days: 365 * 12)),
      updatedAt: DateTime.now().subtract(Duration(days: 1)),
    ),
    Content(
      id: 'yt_short_4',
      platform: PlatformType.youtube,
      platformContentId: 'JGwWNGJdvx8',
      title: 'Ed Sheeran - Shape of You',
      description: 'Official music video for Ed Sheeran\'s hit single Shape of You.',
      videoUrl: 'https://www.youtube.com/embed/JGwWNGJdvx8',
      thumbnailUrl: 'https://img.youtube.com/vi/JGwWNGJdvx8/mqdefault.jpg',
      creatorName: 'Ed Sheeran',
      durationSeconds: 54,
      viewCount: 6000000000,
      likeCount: 28000000,
      publishedAt: DateTime.now().subtract(Duration(days: 365 * 7)),
      tags: ['music', 'pop', 'edsheeran', 'official'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(days: 365 * 7)),
      updatedAt: DateTime.now().subtract(Duration(days: 1)),
    ),
    Content(
      id: 'yt_short_5',
      platform: PlatformType.youtube,
      platformContentId: 'kJQP7kiw5Fk',
      title: 'Luis Fonsi - Despacito',
      description: 'Official music video for Despacito, the most-streamed song of all time.',
      videoUrl: 'https://www.youtube.com/embed/kJQP7kiw5Fk',
      thumbnailUrl: 'https://img.youtube.com/vi/kJQP7kiw5Fk/mqdefault.jpg',
      creatorName: 'Luis Fonsi',
      durationSeconds: 55,
      viewCount: 8400000000,
      likeCount: 50000000,
      publishedAt: DateTime.now().subtract(Duration(days: 365 * 7)),
      tags: ['music', 'latin', 'pop', 'despacito', 'viral'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(days: 365 * 7)),
      updatedAt: DateTime.now().subtract(Duration(days: 1)),
    ),
    // More TikTok-style shorts
    Content(
      id: 'tt_3',
      platform: PlatformType.tiktok,
      platformContentId: '7456789012345678901',
      title: 'Cooking Hack: Perfect Pasta Every Time',
      description: 'This simple trick makes perfect pasta every time! 🍝 #cooking #foodhack #pasta #viral',
      videoUrl: 'https://www.tiktok.com/@cookingpro/video/7456789012345678901',
      thumbnailUrl: null,
      creatorName: 'cooking_pro',
      durationSeconds: 30,
      viewCount: 3200000,
      likeCount: 245000,
      publishedAt: DateTime.now().subtract(Duration(hours: 5)),
      tags: ['cooking', 'food', 'hack', 'pasta'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(hours: 5)),
      updatedAt: DateTime.now().subtract(Duration(hours: 5)),
    ),
    Content(
      id: 'ig_3',
      platform: PlatformType.instagram,
      platformContentId: 'C9xYz1aB2cD',
      title: 'Morning Workout Routine',
      description: '5-minute morning workout to start your day! 💪 No equipment needed. #fitness #workout #morning',
      videoUrl: 'https://www.instagram.com/p/C9xYz1aB2cD/',
      thumbnailUrl: null,
      creatorName: 'fit_daily',
      durationSeconds: 47,
      viewCount: 156000,
      likeCount: 12000,
      publishedAt: DateTime.now().subtract(Duration(hours: 8)),
      tags: ['fitness', 'workout', 'morning', 'health'],
      contentType: ContentType.reel,
      createdAt: DateTime.now().subtract(Duration(hours: 8)),
      updatedAt: DateTime.now().subtract(Duration(hours: 8)),
    ),
  ];

  Future<List<Content>> getVideos({
    PlatformType? platform,
    String? category,
    int limit = 10,
  }) async {
    
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

  Future<List<Content>> getTrendingVideos({int limit = 5}) async {
    
    // Sort by views and likes for trending
    List<Content> trending = List.from(_sampleVideos);
    trending.sort((a, b) => (b.viewCount + b.likeCount).compareTo(a.viewCount + a.likeCount));
    
    return trending.take(limit).toList();
  }

  // Get videos by category
  Future<List<Content>> getVideosByCategory(String category, {int limit = 10}) async {
    return getVideos(category: category, limit: limit);
  }

  Future<List<Content>> searchVideos(String query, {int limit = 10}) async {
    
    if (query.isEmpty) return [];
    
    List<Content> searchResults = _sampleVideos.where((video) => 
      video.title?.toLowerCase().contains(query.toLowerCase()) == true ||
      video.description?.toLowerCase().contains(query.toLowerCase()) == true ||
      video.creatorName?.toLowerCase().contains(query.toLowerCase()) == true ||
      video.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()))
    ).toList();
    
    return searchResults.take(limit).toList();
  }

  Future<Content?> getVideoById(String id) async {
    
    try {
      return _sampleVideos.firstWhere((video) => video.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<List<Content>> getRecommendedVideos(String videoId, {int limit = 5}) async {
    
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

  Future<List<Content>> getFeedContent({int limit = 10}) async {
    
    List<Content> feedContent = List.from(_sampleVideos);
    feedContent.shuffle(Random());
    
    return feedContent.take(limit).toList();
  }

  Future<List<Content>> loadMoreContent(int offset, {int limit = 10}) async {
    
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