import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/content_model.dart';
import 'enhanced_recommendation_service.dart';
import 'onboarding_service.dart';
import 'auth_service.dart';
import 'youtube_live_content_service.dart';
import 'api_content_service.dart';

class ContentService {
  static final ContentService _instance = ContentService._internal();
  static const String _feedCacheKey = 'cached_feed_ids';
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
      categories: ['Technology'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 7)),
      updatedAt: DateTime.now().subtract(Duration(days: 7)),
    ),
    Content(
      id: 'yt_2',
      platform: PlatformType.youtube,
      platformContentId: 'X8ipUgXH6jw',
      title: 'React Native vs Flutter Comparison',
      description:
          'Detailed comparison between React Native and Flutter frameworks',
      videoUrl: 'https://www.youtube.com/embed/X8ipUgXH6jw',
      thumbnailUrl: 'https://img.youtube.com/vi/X8ipUgXH6jw/mqdefault.jpg',
      creatorName: 'Tech Explained',
      durationSeconds: 1335,
      viewCount: 890000,
      likeCount: 32000,
      publishedAt: DateTime.now().subtract(Duration(days: 3)),
      tags: ['react-native', 'flutter', 'comparison'],
      categories: ['Technology'],
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
      categories: ['Technology'],
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
      categories: ['Technology', 'Education'],
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
      categories: ['Technology', 'Education'],
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
      description:
          'Captured this beautiful sunset at the beach today! 🌅 #photography #sunset #nature',
      videoUrl: 'https://www.instagram.com/explore/',
      thumbnailUrl: null,
      creatorName: 'photography_pro',
      durationSeconds: 30,
      viewCount: 125000,
      likeCount: 8500,
      publishedAt: DateTime.now().subtract(Duration(hours: 6)),
      tags: ['photography', 'sunset', 'nature', 'beach'],
      categories: ['Photography', 'Nature'],
      contentType: ContentType.reel,
      createdAt: DateTime.now().subtract(Duration(hours: 6)),
      updatedAt: DateTime.now().subtract(Duration(hours: 6)),
    ),
    Content(
      id: 'ig_2',
      platform: PlatformType.instagram,
      platformContentId: 'C9aB3dE4fG5',
      title: 'Quick Recipe: Pasta Carbonara',
      description:
          'Easy 15-minute pasta carbonara recipe! 🍝 Perfect for busy weeknights #cooking #recipe #pasta',
      videoUrl: 'https://www.instagram.com/explore/',
      thumbnailUrl: null,
      creatorName: 'chef_maria',
      durationSeconds: 45,
      viewCount: 89000,
      likeCount: 6200,
      publishedAt: DateTime.now().subtract(Duration(days: 1)),
      tags: ['cooking', 'recipe', 'pasta', 'italian'],
      categories: ['Food'],
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
      description:
          'Latest dance trends compilation! Which one is your favorite? 💃 #dance #trending #fyp',
      videoUrl: 'https://www.tiktok.com/explore',
      thumbnailUrl: null,
      creatorName: 'dance_moves',
      durationSeconds: 60,
      viewCount: 2100000,
      likeCount: 156000,
      publishedAt: DateTime.now().subtract(Duration(hours: 12)),
      tags: ['dance', 'trending', 'fyp', 'challenge'],
      categories: ['Dance'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(hours: 12)),
      updatedAt: DateTime.now().subtract(Duration(hours: 12)),
    ),
    Content(
      id: 'tt_2',
      platform: PlatformType.tiktok,
      platformContentId: '7345678901234567890',
      title: 'Life Hacks You Need to Know',
      description:
          'Mind-blowing life hacks that will change your daily routine! 🤯 #lifehacks #tips #viral',
      videoUrl: 'https://www.tiktok.com/explore',
      thumbnailUrl: null,
      creatorName: 'life_hacker',
      durationSeconds: 45,
      viewCount: 890000,
      likeCount: 67000,
      publishedAt: DateTime.now().subtract(Duration(hours: 18)),
      tags: ['lifehacks', 'tips', 'viral', 'useful'],
      categories: ['Education'],
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
      description:
          'Join me on an incredible journey through Japan! From Tokyo to Kyoto, experiencing the culture, food, and beautiful landscapes.',
      videoUrl: 'https://www.facebook.com/watch',
      thumbnailUrl: null,
      creatorName: 'Travel Adventures',
      durationSeconds: 1200,
      viewCount: 450000,
      likeCount: 23000,
      publishedAt: DateTime.now().subtract(Duration(days: 4)),
      tags: ['travel', 'japan', 'vlog', 'culture'],
      categories: ['Travel'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 4)),
      updatedAt: DateTime.now().subtract(Duration(days: 4)),
    ),
    Content(
      id: 'fb_2',
      platform: PlatformType.facebook,
      platformContentId: '2345678901234567',
      title: 'Tech News Weekly Roundup',
      description:
          'This week in tech: AI breakthroughs, new smartphone releases, and the latest in sustainable technology innovations.',
      videoUrl: 'https://www.facebook.com/watch',
      thumbnailUrl: null,
      creatorName: 'Tech Today',
      durationSeconds: 900,
      viewCount: 320000,
      likeCount: 18500,
      publishedAt: DateTime.now().subtract(Duration(days: 6)),
      tags: ['tech', 'news', 'ai', 'smartphones'],
      categories: ['Technology'],
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
      categories: ['Technology', 'Education'],
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
      description:
          'The classic Rick Roll — one of the most iconic videos on YouTube.',
      videoUrl: 'https://www.youtube.com/embed/dQw4w9WgXcQ',
      thumbnailUrl: 'https://img.youtube.com/vi/dQw4w9WgXcQ/mqdefault.jpg',
      creatorName: 'Rick Astley',
      durationSeconds: 53,
      viewCount: 1400000000,
      likeCount: 15000000,
      publishedAt: DateTime.now().subtract(Duration(days: 365 * 10)),
      tags: ['music', 'pop', 'classic', 'trending'],
      categories: ['Music'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(days: 365 * 10)),
      updatedAt: DateTime.now().subtract(Duration(days: 1)),
    ),
    Content(
      id: 'yt_short_2',
      platform: PlatformType.youtube,
      platformContentId: 'jNQXAC9IVRw',
      title: 'Me at the zoo',
      description:
          'The very first video ever uploaded to YouTube. Featuring co-founder Jawed Karim at the San Diego Zoo.',
      videoUrl: 'https://www.youtube.com/embed/jNQXAC9IVRw',
      thumbnailUrl: 'https://img.youtube.com/vi/jNQXAC9IVRw/mqdefault.jpg',
      creatorName: 'jawed',
      durationSeconds: 19,
      viewCount: 280000000,
      likeCount: 3500000,
      publishedAt: DateTime.now().subtract(Duration(days: 365 * 19)),
      tags: ['classic', 'youtube', 'history', 'zoo'],
      categories: ['Education'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(days: 365 * 19)),
      updatedAt: DateTime.now().subtract(Duration(days: 2)),
    ),
    Content(
      id: 'yt_short_3',
      platform: PlatformType.youtube,
      platformContentId: '9bZkp7q19f0',
      title: 'PSY - GANGNAM STYLE',
      description:
          'The video that broke the YouTube view counter. A global music phenomenon.',
      videoUrl: 'https://www.youtube.com/embed/9bZkp7q19f0',
      thumbnailUrl: 'https://img.youtube.com/vi/9bZkp7q19f0/mqdefault.jpg',
      creatorName: 'officialpsy',
      durationSeconds: 58,
      viewCount: 5000000000,
      likeCount: 25000000,
      publishedAt: DateTime.now().subtract(Duration(days: 365 * 12)),
      tags: ['music', 'kpop', 'dance', 'trending', 'viral'],
      categories: ['Music', 'Dance'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(days: 365 * 12)),
      updatedAt: DateTime.now().subtract(Duration(days: 1)),
    ),
    Content(
      id: 'yt_short_4',
      platform: PlatformType.youtube,
      platformContentId: 'JGwWNGJdvx8',
      title: 'Ed Sheeran - Shape of You',
      description:
          'Official music video for Ed Sheeran\'s hit single Shape of You.',
      videoUrl: 'https://www.youtube.com/embed/JGwWNGJdvx8',
      thumbnailUrl: 'https://img.youtube.com/vi/JGwWNGJdvx8/mqdefault.jpg',
      creatorName: 'Ed Sheeran',
      durationSeconds: 54,
      viewCount: 6000000000,
      likeCount: 28000000,
      publishedAt: DateTime.now().subtract(Duration(days: 365 * 7)),
      tags: ['music', 'pop', 'edsheeran', 'official'],
      categories: ['Music'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(days: 365 * 7)),
      updatedAt: DateTime.now().subtract(Duration(days: 1)),
    ),
    Content(
      id: 'yt_short_5',
      platform: PlatformType.youtube,
      platformContentId: 'kJQP7kiw5Fk',
      title: 'Luis Fonsi - Despacito',
      description:
          'Official music video for Despacito, the most-streamed song of all time.',
      videoUrl: 'https://www.youtube.com/embed/kJQP7kiw5Fk',
      thumbnailUrl: 'https://img.youtube.com/vi/kJQP7kiw5Fk/mqdefault.jpg',
      creatorName: 'Luis Fonsi',
      durationSeconds: 55,
      viewCount: 8400000000,
      likeCount: 50000000,
      publishedAt: DateTime.now().subtract(Duration(days: 365 * 7)),
      tags: ['music', 'latin', 'pop', 'despacito', 'viral'],
      categories: ['Music'],
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
      description:
          'This simple trick makes perfect pasta every time! 🍝 #cooking #foodhack #pasta #viral',
      videoUrl: 'https://www.tiktok.com/explore',
      thumbnailUrl: null,
      creatorName: 'cooking_pro',
      durationSeconds: 30,
      viewCount: 3200000,
      likeCount: 245000,
      publishedAt: DateTime.now().subtract(Duration(hours: 5)),
      tags: ['cooking', 'food', 'hack', 'pasta'],
      categories: ['Food'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(hours: 5)),
      updatedAt: DateTime.now().subtract(Duration(hours: 5)),
    ),
    Content(
      id: 'ig_3',
      platform: PlatformType.instagram,
      platformContentId: 'C9xYz1aB2cD',
      title: 'Morning Workout Routine',
      description:
          '5-minute morning workout to start your day! 💪 No equipment needed. #fitness #workout #morning',
      videoUrl: 'https://www.instagram.com/explore/',
      thumbnailUrl: null,
      creatorName: 'fit_daily',
      durationSeconds: 47,
      viewCount: 156000,
      likeCount: 12000,
      publishedAt: DateTime.now().subtract(Duration(hours: 8)),
      tags: ['fitness', 'workout', 'morning', 'health'],
      categories: ['Fitness'],
      contentType: ContentType.reel,
      createdAt: DateTime.now().subtract(Duration(hours: 8)),
      updatedAt: DateTime.now().subtract(Duration(hours: 8)),
    ),

    // Additional YouTube educational & entertainment content
    Content(
      id: 'yt_7',
      platform: PlatformType.youtube,
      platformContentId: 'aircAruvnKk',
      title: 'But what is a neural network?',
      description:
          'The math of deep learning visualized — neurons, layers, and activation functions.',
      videoUrl: 'https://www.youtube.com/embed/aircAruvnKk',
      thumbnailUrl: 'https://img.youtube.com/vi/aircAruvnKk/mqdefault.jpg',
      creatorName: '3Blue1Brown',
      durationSeconds: 1918,
      viewCount: 15000000,
      likeCount: 410000,
      publishedAt: DateTime.now().subtract(Duration(days: 365 * 6)),
      tags: ['ai', 'neural-networks', 'deep-learning', 'math'],
      categories: ['Technology', 'Education'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 365 * 6)),
      updatedAt: DateTime.now().subtract(Duration(days: 30)),
    ),
    Content(
      id: 'yt_8',
      platform: PlatformType.youtube,
      platformContentId: 'DHjqpvDnNGE',
      title: 'JavaScript in 100 Seconds',
      description: 'Quick visual tour of JavaScript — the language of the web.',
      videoUrl: 'https://www.youtube.com/embed/DHjqpvDnNGE',
      thumbnailUrl: 'https://img.youtube.com/vi/DHjqpvDnNGE/mqdefault.jpg',
      creatorName: 'Fireship',
      durationSeconds: 120,
      viewCount: 4800000,
      likeCount: 195000,
      publishedAt: DateTime.now().subtract(Duration(days: 365 * 3)),
      tags: ['javascript', 'programming', 'web', '100seconds'],
      categories: ['Technology'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(days: 365 * 3)),
      updatedAt: DateTime.now().subtract(Duration(days: 14)),
    ),
    Content(
      id: 'yt_9',
      platform: PlatformType.youtube,
      platformContentId: 'x7X9w_GIm1s',
      title: 'Python in 100 Seconds',
      description:
          'Everything you need to know about Python in under 2 minutes.',
      videoUrl: 'https://www.youtube.com/embed/x7X9w_GIm1s',
      thumbnailUrl: 'https://img.youtube.com/vi/x7X9w_GIm1s/mqdefault.jpg',
      creatorName: 'Fireship',
      durationSeconds: 115,
      viewCount: 3900000,
      likeCount: 162000,
      publishedAt: DateTime.now().subtract(Duration(days: 365 * 3)),
      tags: ['python', 'programming', '100seconds', 'beginner'],
      categories: ['Technology'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(days: 365 * 3)),
      updatedAt: DateTime.now().subtract(Duration(days: 10)),
    ),
    Content(
      id: 'yt_10',
      platform: PlatformType.youtube,
      platformContentId: 'Tn6-PIqc4UM',
      title: 'React in 100 Seconds',
      description: 'Everything important about React packed into 100 seconds.',
      videoUrl: 'https://www.youtube.com/embed/Tn6-PIqc4UM',
      thumbnailUrl: 'https://img.youtube.com/vi/Tn6-PIqc4UM/mqdefault.jpg',
      creatorName: 'Fireship',
      durationSeconds: 105,
      viewCount: 2700000,
      likeCount: 98000,
      publishedAt: DateTime.now().subtract(Duration(days: 365 * 2)),
      tags: ['react', 'javascript', 'frontend', '100seconds'],
      categories: ['Technology'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(days: 365 * 2)),
      updatedAt: DateTime.now().subtract(Duration(days: 7)),
    ),
    Content(
      id: 'yt_11',
      platform: PlatformType.youtube,
      platformContentId: 'vIRkjTMhFvs',
      title: 'Why Planes Don\'t Fly Over the Pacific',
      description:
          'The surprising reason why transpacific flights avoid a straight path over the ocean.',
      videoUrl: 'https://www.youtube.com/embed/vIRkjTMhFvs',
      thumbnailUrl: 'https://img.youtube.com/vi/vIRkjTMhFvs/mqdefault.jpg',
      creatorName: 'Wendover Productions',
      durationSeconds: 912,
      viewCount: 10500000,
      likeCount: 287000,
      publishedAt: DateTime.now().subtract(Duration(days: 365 * 5)),
      tags: ['science', 'aviation', 'geography', 'education'],
      categories: ['Education'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 365 * 5)),
      updatedAt: DateTime.now().subtract(Duration(days: 60)),
    ),
    Content(
      id: 'yt_12',
      platform: PlatformType.youtube,
      platformContentId: 'e-P5IFTqB98',
      title: 'Genetic Engineering Will Change Everything Forever',
      description:
          'How CRISPR gene editing could eliminate disease and change what it means to be human.',
      videoUrl: 'https://www.youtube.com/embed/e-P5IFTqB98',
      thumbnailUrl: 'https://img.youtube.com/vi/e-P5IFTqB98/mqdefault.jpg',
      creatorName: 'Kurzgesagt',
      durationSeconds: 1623,
      viewCount: 24000000,
      likeCount: 680000,
      publishedAt: DateTime.now().subtract(Duration(days: 365 * 7)),
      tags: ['science', 'genetics', 'crispr', 'biology', 'education'],
      categories: ['Education'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 365 * 7)),
      updatedAt: DateTime.now().subtract(Duration(days: 45)),
    ),
    Content(
      id: 'yt_13',
      platform: PlatformType.youtube,
      platformContentId: 'wjZofJX0v4M',
      title: 'The Entire History of the Universe',
      description:
          'From the Big Bang to today — 13.8 billion years in one video.',
      videoUrl: 'https://www.youtube.com/embed/wjZofJX0v4M',
      thumbnailUrl: 'https://img.youtube.com/vi/wjZofJX0v4M/mqdefault.jpg',
      creatorName: 'Kurzgesagt',
      durationSeconds: 1920,
      viewCount: 18000000,
      likeCount: 520000,
      publishedAt: DateTime.now().subtract(Duration(days: 365 * 4)),
      tags: ['science', 'space', 'universe', 'education', 'history'],
      categories: ['Education'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 365 * 4)),
      updatedAt: DateTime.now().subtract(Duration(days: 20)),
    ),
    Content(
      id: 'yt_14',
      platform: PlatformType.youtube,
      platformContentId: 'ZHwVBirqD2s',
      title: 'Advanced Flutter State Management',
      description:
          'A deep dive into Riverpod, Bloc, and Provider patterns for large-scale Flutter apps.',
      videoUrl: 'https://www.youtube.com/embed/ZHwVBirqD2s',
      thumbnailUrl: 'https://img.youtube.com/vi/ZHwVBirqD2s/mqdefault.jpg',
      creatorName: 'Flutter Dev',
      durationSeconds: 2790,
      viewCount: 340000,
      likeCount: 18000,
      publishedAt: DateTime.now().subtract(Duration(days: 90)),
      tags: ['flutter', 'state-management', 'riverpod', 'bloc'],
      categories: ['Technology'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 90)),
      updatedAt: DateTime.now().subtract(Duration(days: 5)),
    ),
    Content(
      id: 'yt_15',
      platform: PlatformType.youtube,
      platformContentId: 'rdSJBd4YhA4',
      title: 'Glitter Bomb 5.0 vs Package Thieves',
      description:
          'The fifth generation glitter bomb package designed to catch porch pirates.',
      videoUrl: 'https://www.youtube.com/embed/rdSJBd4YhA4',
      thumbnailUrl: 'https://img.youtube.com/vi/rdSJBd4YhA4/mqdefault.jpg',
      creatorName: 'Mark Rober',
      durationSeconds: 1020,
      viewCount: 38000000,
      likeCount: 900000,
      publishedAt: DateTime.now().subtract(Duration(days: 365 * 2)),
      tags: ['engineering', 'comedy', 'viral', 'invention'],
      categories: ['Comedy'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 365 * 2)),
      updatedAt: DateTime.now().subtract(Duration(days: 10)),
    ),
    // Additional Instagram reels
    Content(
      id: 'ig_4',
      platform: PlatformType.instagram,
      platformContentId: 'CAbC4dEf5gH',
      title: 'Travel Guide: Hidden Gems in Bali',
      description:
          'Secret spots in Bali that tourists never find 🌴✨ #bali #travel #hidden',
      videoUrl: 'https://www.instagram.com/explore/',
      thumbnailUrl: null,
      creatorName: 'wanderlust_vibes',
      durationSeconds: 60,
      viewCount: 420000,
      likeCount: 31000,
      publishedAt: DateTime.now().subtract(Duration(hours: 14)),
      tags: ['travel', 'bali', 'indonesia', 'hidden-gems'],
      categories: ['Travel'],
      contentType: ContentType.reel,
      createdAt: DateTime.now().subtract(Duration(hours: 14)),
      updatedAt: DateTime.now().subtract(Duration(hours: 14)),
    ),
    Content(
      id: 'ig_5',
      platform: PlatformType.instagram,
      platformContentId: 'CBdE5fGh6iJ',
      title: 'Beginner Photography Tips',
      description:
          '5 camera settings that instantly improve your photos 📸 #photography #tips #beginner',
      videoUrl: 'https://www.instagram.com/explore/',
      thumbnailUrl: null,
      creatorName: 'photo_academy',
      durationSeconds: 55,
      viewCount: 280000,
      likeCount: 22000,
      publishedAt: DateTime.now().subtract(Duration(days: 2)),
      tags: ['photography', 'camera', 'tips', 'beginner'],
      categories: ['Photography'],
      contentType: ContentType.reel,
      createdAt: DateTime.now().subtract(Duration(days: 2)),
      updatedAt: DateTime.now().subtract(Duration(days: 2)),
    ),
    // Additional TikTok shorts
    Content(
      id: 'tt_4',
      platform: PlatformType.tiktok,
      platformContentId: '7567890123456789012',
      title: 'Study Hack: 20-Minute Focus Sessions',
      description:
          'The Pomodoro technique changed my grades! 📚⏱️ #studyhack #pomodoro #student #fyp',
      videoUrl: 'https://www.tiktok.com/explore',
      thumbnailUrl: null,
      creatorName: 'study_pro',
      durationSeconds: 35,
      viewCount: 1800000,
      likeCount: 142000,
      publishedAt: DateTime.now().subtract(Duration(hours: 20)),
      tags: ['study', 'productivity', 'pomodoro', 'student'],
      categories: ['Education'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(hours: 20)),
      updatedAt: DateTime.now().subtract(Duration(hours: 20)),
    ),
    Content(
      id: 'tt_5',
      platform: PlatformType.tiktok,
      platformContentId: '7678901234567890123',
      title: 'DIY Home Decor on a Budget',
      description:
          'Thrift store flip that cost me £8 and looks amazing! 🏠✨ #diy #homeDecor #thrift',
      videoUrl: 'https://www.tiktok.com/explore',
      thumbnailUrl: null,
      creatorName: 'diy_crafts',
      durationSeconds: 42,
      viewCount: 950000,
      likeCount: 78000,
      publishedAt: DateTime.now().subtract(Duration(days: 1, hours: 4)),
      tags: ['diy', 'home-decor', 'budget', 'thrift'],
      categories: ['DIY'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(days: 1, hours: 4)),
      updatedAt: DateTime.now().subtract(Duration(days: 1, hours: 4)),
    ),
    // Facebook videos
    Content(
      id: 'fb_3',
      platform: PlatformType.facebook,
      platformContentId: '3456789012345678',
      title: 'Electric Vehicle Myths Debunked',
      description:
          'Are EVs actually good for the environment? We look at the real data on battery lifecycle, charging infrastructure, and emissions comparison.',
      videoUrl: 'https://www.facebook.com/watch',
      thumbnailUrl: null,
      creatorName: 'Science Explained',
      durationSeconds: 780,
      viewCount: 215000,
      likeCount: 11500,
      publishedAt: DateTime.now().subtract(Duration(days: 9)),
      tags: ['ev', 'electric-vehicles', 'environment', 'science'],
      categories: ['Education'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 9)),
      updatedAt: DateTime.now().subtract(Duration(days: 9)),
    ),
    // Gaming content
    Content(
      id: 'yt_gaming_1',
      platform: PlatformType.youtube,
      platformContentId: '2Gg7EPzq5Vs',
      title: 'Top 10 Gaming Moments of the Year',
      description:
          'The most incredible esports plays and gaming highlights from 2024. Featuring Valorant, League of Legends, CS2, and more.',
      videoUrl: 'https://www.youtube.com/embed/2Gg7EPzq5Vs',
      thumbnailUrl: 'https://img.youtube.com/vi/2Gg7EPzq5Vs/mqdefault.jpg',
      creatorName: 'GamersHub',
      durationSeconds: 1245,
      viewCount: 2800000,
      likeCount: 124000,
      publishedAt: DateTime.now().subtract(Duration(days: 5)),
      tags: ['gaming', 'esports', 'gameplay', 'highlights', 'valorant'],
      categories: ['Gaming'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 5)),
      updatedAt: DateTime.now().subtract(Duration(days: 5)),
    ),
    Content(
      id: 'tt_gaming_1',
      platform: PlatformType.tiktok,
      platformContentId: '7600000000000000001',
      title: 'Insane 360 no-scope in Fortnite',
      description:
          'That gameplay moment that made me scream 🎮 #gaming #fortnite #esports #fyp',
      videoUrl: 'https://www.tiktok.com/explore',
      thumbnailUrl: null,
      creatorName: 'gamer_pro',
      durationSeconds: 28,
      viewCount: 4500000,
      likeCount: 380000,
      publishedAt: DateTime.now().subtract(Duration(hours: 8)),
      tags: ['gaming', 'fortnite', 'gameplay', 'streaming', 'esports'],
      categories: ['Gaming'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(hours: 8)),
      updatedAt: DateTime.now().subtract(Duration(hours: 8)),
    ),
    // Beauty content
    Content(
      id: 'ig_beauty_1',
      platform: PlatformType.instagram,
      platformContentId: 'Cbeauty0001',
      title: 'Everyday Glam Makeup Tutorial',
      description:
          '5-minute everyday makeup look using drugstore products 💄 Full tutorial with product links in bio! #beauty #makeup #tutorial',
      videoUrl: 'https://www.instagram.com/reel/Cbeauty0001/',
      thumbnailUrl: null,
      creatorName: 'glam_with_sarah',
      durationSeconds: 58,
      viewCount: 1200000,
      likeCount: 89000,
      publishedAt: DateTime.now().subtract(Duration(days: 2)),
      tags: ['beauty', 'makeup', 'tutorial', 'cosmetics', 'skincare'],
      categories: ['Beauty'],
      contentType: ContentType.reel,
      createdAt: DateTime.now().subtract(Duration(days: 2)),
      updatedAt: DateTime.now().subtract(Duration(days: 2)),
    ),
    Content(
      id: 'yt_beauty_1',
      platform: PlatformType.youtube,
      platformContentId: '7JZbBgBJPCM',
      title: 'Skincare Routine for Beginners 2024',
      description:
          'Build your perfect skincare routine from scratch. We cover cleansers, moisturizers, SPF and serums for every skin type.',
      videoUrl: 'https://www.youtube.com/embed/7JZbBgBJPCM',
      thumbnailUrl: 'https://img.youtube.com/vi/7JZbBgBJPCM/mqdefault.jpg',
      creatorName: 'Skincare Science',
      durationSeconds: 1560,
      viewCount: 3400000,
      likeCount: 145000,
      publishedAt: DateTime.now().subtract(Duration(days: 14)),
      tags: ['skincare', 'beauty', 'cosmetics', 'makeup', 'routine'],
      categories: ['Beauty'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 14)),
      updatedAt: DateTime.now().subtract(Duration(days: 14)),
    ),
    // Fashion content
    Content(
      id: 'ig_fashion_1',
      platform: PlatformType.instagram,
      platformContentId: 'Cfashion001',
      title: 'Thrift Store Outfit Transformation',
      description:
          'Turned a £15 thrift haul into 7 complete outfits 👗 Style tips and tricks to shop sustainably. #fashion #style #outfits #thrift',
      videoUrl: 'https://www.instagram.com/reel/Cfashion001/',
      thumbnailUrl: null,
      creatorName: 'style_by_maya',
      durationSeconds: 45,
      viewCount: 2100000,
      likeCount: 178000,
      publishedAt: DateTime.now().subtract(Duration(days: 3)),
      tags: ['fashion', 'style', 'outfits', 'trends', 'thrift'],
      categories: ['Fashion'],
      contentType: ContentType.reel,
      createdAt: DateTime.now().subtract(Duration(days: 3)),
      updatedAt: DateTime.now().subtract(Duration(days: 3)),
    ),
    // Sports content
    Content(
      id: 'yt_sports_1',
      platform: PlatformType.youtube,
      platformContentId: 'UrfTFk6YIUA',
      title: 'Top 50 Football Goals of 2024',
      description:
          'The most stunning goals from the Premier League, Champions League, La Liga and more. Best football moments of the year!',
      videoUrl: 'https://www.youtube.com/embed/UrfTFk6YIUA',
      thumbnailUrl: 'https://img.youtube.com/vi/UrfTFk6YIUA/mqdefault.jpg',
      creatorName: 'Football Daily',
      durationSeconds: 1800,
      viewCount: 12000000,
      likeCount: 520000,
      publishedAt: DateTime.now().subtract(Duration(days: 6)),
      tags: ['sports', 'football', 'soccer', 'goals', 'highlights'],
      categories: ['Sports'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 6)),
      updatedAt: DateTime.now().subtract(Duration(days: 6)),
    ),
    Content(
      id: 'tt_sports_1',
      platform: PlatformType.tiktok,
      platformContentId: '7600000000000000002',
      title: 'NBA Ankle Breaker 🏀',
      description:
          'This crossover should be illegal 😤 #basketball #nba #sports #fyp',
      videoUrl: 'https://www.tiktok.com/explore',
      thumbnailUrl: null,
      creatorName: 'hoops_daily',
      durationSeconds: 22,
      viewCount: 6800000,
      likeCount: 490000,
      publishedAt: DateTime.now().subtract(Duration(hours: 12)),
      tags: ['sports', 'basketball', 'nba', 'football', 'soccer'],
      categories: ['Sports'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(hours: 12)),
      updatedAt: DateTime.now().subtract(Duration(hours: 12)),
    ),
    // Movies content
    Content(
      id: 'yt_movies_1',
      platform: PlatformType.youtube,
      platformContentId: '4HXBT2XJXzo',
      title: 'Every Marvel Movie Ranked Worst to Best',
      description:
          'A comprehensive ranking of all 33 MCU films based on storytelling, visuals, and cultural impact. From Thor: The Dark World to Infinity War.',
      videoUrl: 'https://www.youtube.com/embed/4HXBT2XJXzo',
      thumbnailUrl: 'https://img.youtube.com/vi/4HXBT2XJXzo/mqdefault.jpg',
      creatorName: 'Cinema Critics',
      durationSeconds: 2400,
      viewCount: 5600000,
      likeCount: 210000,
      publishedAt: DateTime.now().subtract(Duration(days: 11)),
      tags: ['movies', 'films', 'cinema', 'reviews', 'marvel'],
      categories: ['Movies'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 11)),
      updatedAt: DateTime.now().subtract(Duration(days: 11)),
    ),
    // Pets content
    Content(
      id: 'ig_pets_1',
      platform: PlatformType.instagram,
      platformContentId: 'Cpets000001',
      title: 'My Dog Learned a New Trick in 5 Minutes',
      description:
          'Positive reinforcement training works so well for dogs 🐕 This is how I taught "spin" in one session. #pets #dogs #animals',
      videoUrl: 'https://www.instagram.com/reel/Cpets000001/',
      thumbnailUrl: null,
      creatorName: 'dogs_of_instagram',
      durationSeconds: 38,
      viewCount: 3200000,
      likeCount: 256000,
      publishedAt: DateTime.now().subtract(Duration(days: 1)),
      tags: ['pets', 'dogs', 'animals', 'cats', 'training'],
      categories: ['Pets'],
      contentType: ContentType.reel,
      createdAt: DateTime.now().subtract(Duration(days: 1)),
      updatedAt: DateTime.now().subtract(Duration(days: 1)),
    ),
    // Cars content
    Content(
      id: 'yt_cars_1',
      platform: PlatformType.youtube,
      platformContentId: '1BSkSf8F7e4',
      title: 'We Bought the Cheapest Lamborghini on the Internet',
      description:
          'Found a Lamborghini Gallardo for £28,000 and had it shipped to the UK. Here\'s what happened after 6 months of ownership.',
      videoUrl: 'https://www.youtube.com/embed/1BSkSf8F7e4',
      thumbnailUrl: 'https://img.youtube.com/vi/1BSkSf8F7e4/mqdefault.jpg',
      creatorName: 'Car Throttle',
      durationSeconds: 2160,
      viewCount: 8900000,
      likeCount: 340000,
      publishedAt: DateTime.now().subtract(Duration(days: 8)),
      tags: ['cars', 'automotive', 'vehicles', 'racing', 'lamborghini'],
      categories: ['Cars'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 8)),
      updatedAt: DateTime.now().subtract(Duration(days: 8)),
    ),
    // DIY content (more)
    Content(
      id: 'yt_diy_1',
      platform: PlatformType.youtube,
      platformContentId: 'Ahg6qcgoay4',
      title: 'Build a Gaming PC for £500 in 2024',
      description:
          'Complete step-by-step guide to building your first gaming PC from scratch. Parts list, cable management, and BIOS setup included.',
      videoUrl: 'https://www.youtube.com/embed/Ahg6qcgoay4',
      thumbnailUrl: 'https://img.youtube.com/vi/Ahg6qcgoay4/mqdefault.jpg',
      creatorName: 'DIY Tech Builds',
      durationSeconds: 3600,
      viewCount: 4200000,
      likeCount: 185000,
      publishedAt: DateTime.now().subtract(Duration(days: 4)),
      tags: ['diy', 'crafts', 'projects', 'handmade', 'tech'],
      categories: ['DIY', 'Technology'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 4)),
      updatedAt: DateTime.now().subtract(Duration(days: 4)),
    ),

    // ── Comedy ───────────────────────────────────────────────────────────────
    Content(
      id: 'yt_comedy_1',
      platform: PlatformType.youtube,
      platformContentId: 'hHJm4w2x7hQ',
      title: 'Stand-Up Special: Airport Security Is Wild',
      description:
          'A hilarious set about the absurdity of airport security checks, travel delays, and fellow passengers. Crowd favourite from 2024.',
      videoUrl: 'https://www.youtube.com/embed/hHJm4w2x7hQ',
      thumbnailUrl: 'https://img.youtube.com/vi/hHJm4w2x7hQ/mqdefault.jpg',
      creatorName: 'Comedy Central',
      durationSeconds: 780,
      viewCount: 9200000,
      likeCount: 410000,
      publishedAt: DateTime.now().subtract(Duration(days: 12)),
      tags: ['funny', 'humor', 'comedy', 'stand-up', 'jokes'],
      categories: ['Comedy'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 12)),
      updatedAt: DateTime.now().subtract(Duration(days: 12)),
    ),
    Content(
      id: 'tt_comedy_1',
      platform: PlatformType.tiktok,
      platformContentId: '7610000000000000001',
      title: 'When You Say "5 More Minutes" and Fall Back Asleep',
      description:
          'The most relatable struggle known to humanity 😂 #funny #humor #memes #fyp #relatable',
      videoUrl: 'https://www.tiktok.com/explore',
      thumbnailUrl: null,
      creatorName: 'daily_laughs',
      durationSeconds: 18,
      viewCount: 11500000,
      likeCount: 920000,
      publishedAt: DateTime.now().subtract(Duration(hours: 9)),
      tags: ['funny', 'humor', 'memes', 'relatable', 'jokes'],
      categories: ['Comedy'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(hours: 9)),
      updatedAt: DateTime.now().subtract(Duration(hours: 9)),
    ),
    Content(
      id: 'ig_comedy_1',
      platform: PlatformType.instagram,
      platformContentId: 'Ccomedy0002',
      title: 'Expectations vs Reality: Cooking Edition',
      description:
          'Why does my food never look like the recipe video? 😭😂 #funny #cooking #humor #memes',
      videoUrl: 'https://www.instagram.com/reel/Ccomedy0002/',
      thumbnailUrl: null,
      creatorName: 'reel_laughs',
      durationSeconds: 32,
      viewCount: 6800000,
      likeCount: 560000,
      publishedAt: DateTime.now().subtract(Duration(hours: 22)),
      tags: ['funny', 'humor', 'jokes', 'memes', 'cooking'],
      categories: ['Comedy'],
      contentType: ContentType.reel,
      createdAt: DateTime.now().subtract(Duration(hours: 22)),
      updatedAt: DateTime.now().subtract(Duration(hours: 22)),
    ),
    Content(
      id: 'fb_comedy_1',
      platform: PlatformType.facebook,
      platformContentId: '4100000000000001',
      title: 'Classic British Comedy Sketches Compilation',
      description:
          'The best sketches from Monty Python, Fawlty Towers, and Blackadder in one epic 10-minute compilation. Pure gold.',
      videoUrl: 'https://www.facebook.com/watch',
      thumbnailUrl: null,
      creatorName: 'Classic Comedy UK',
      durationSeconds: 620,
      viewCount: 3400000,
      likeCount: 198000,
      publishedAt: DateTime.now().subtract(Duration(days: 7)),
      tags: ['funny', 'humor', 'comedy', 'jokes', 'british'],
      categories: ['Comedy'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 7)),
      updatedAt: DateTime.now().subtract(Duration(days: 7)),
    ),

    // ── Art ───────────────────────────────────────────────────────────────────
    Content(
      id: 'yt_art_1',
      platform: PlatformType.youtube,
      platformContentId: 'Pk48cJYRjrg',
      title: 'Drawing a Hyperrealistic Eye in 60 Minutes',
      description:
          'Watch a full time-lapse and step-by-step breakdown of how to draw a photorealistic eye using graphite pencils. Suitable for intermediate artists.',
      videoUrl: 'https://www.youtube.com/embed/Pk48cJYRjrg',
      thumbnailUrl: 'https://img.youtube.com/vi/Pk48cJYRjrg/mqdefault.jpg',
      creatorName: 'Realistic Art Studio',
      durationSeconds: 1860,
      viewCount: 7100000,
      likeCount: 310000,
      publishedAt: DateTime.now().subtract(Duration(days: 9)),
      tags: ['art', 'drawing', 'painting', 'creative', 'pencil'],
      categories: ['Art'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 9)),
      updatedAt: DateTime.now().subtract(Duration(days: 9)),
    ),
    Content(
      id: 'ig_art_1',
      platform: PlatformType.instagram,
      platformContentId: 'Cart000000002',
      title: 'Watercolour Sunset in 60 Seconds',
      description:
          'Full watercolour painting sped up to 60 seconds ✨ Supplies linked in bio. #art #painting #creative #watercolour #drawing',
      videoUrl: 'https://www.instagram.com/reel/Cart000000002/',
      thumbnailUrl: null,
      creatorName: 'palette_and_brush',
      durationSeconds: 60,
      viewCount: 4500000,
      likeCount: 385000,
      publishedAt: DateTime.now().subtract(Duration(hours: 16)),
      tags: ['art', 'painting', 'creative', 'drawing', 'watercolour'],
      categories: ['Art'],
      contentType: ContentType.reel,
      createdAt: DateTime.now().subtract(Duration(hours: 16)),
      updatedAt: DateTime.now().subtract(Duration(hours: 16)),
    ),
    Content(
      id: 'tt_art_1',
      platform: PlatformType.tiktok,
      platformContentId: '7610000000000000002',
      title: 'Turning a Blank Canvas into a Galaxy',
      description:
          'Acrylic pour painting step by step 🎨✨ #art #creative #painting #drawing #fyp',
      videoUrl: 'https://www.tiktok.com/explore',
      thumbnailUrl: null,
      creatorName: 'art_with_alex',
      durationSeconds: 55,
      viewCount: 8900000,
      likeCount: 720000,
      publishedAt: DateTime.now().subtract(Duration(hours: 14)),
      tags: ['art', 'painting', 'creative', 'drawing', 'acrylic'],
      categories: ['Art'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(hours: 14)),
      updatedAt: DateTime.now().subtract(Duration(hours: 14)),
    ),
    Content(
      id: 'fb_art_1',
      platform: PlatformType.facebook,
      platformContentId: '4100000000000002',
      title: 'Street Art: Murals Transforming Urban Spaces',
      description:
          'A documentary-style look at how street artists around the world are turning grey city walls into breathtaking murals full of meaning and colour.',
      videoUrl: 'https://www.facebook.com/watch',
      thumbnailUrl: null,
      creatorName: 'Urban Art Collective',
      durationSeconds: 1140,
      viewCount: 1800000,
      likeCount: 92000,
      publishedAt: DateTime.now().subtract(Duration(days: 15)),
      tags: ['art', 'creative', 'drawing', 'painting', 'street-art'],
      categories: ['Art'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 15)),
      updatedAt: DateTime.now().subtract(Duration(days: 15)),
    ),

    // ── Books ─────────────────────────────────────────────────────────────────
    Content(
      id: 'yt_books_1',
      platform: PlatformType.youtube,
      platformContentId: 'J3kGMJ6KFhw',
      title: '10 Books That Changed How I Think',
      description:
          'An honest deep-dive into the ten books that had the biggest impact on my worldview: from Sapiens to Atomic Habits and The Power of Now.',
      videoUrl: 'https://www.youtube.com/embed/J3kGMJ6KFhw',
      thumbnailUrl: 'https://img.youtube.com/vi/J3kGMJ6KFhw/mqdefault.jpg',
      creatorName: 'Better Reading',
      durationSeconds: 2040,
      viewCount: 5300000,
      likeCount: 245000,
      publishedAt: DateTime.now().subtract(Duration(days: 18)),
      tags: ['books', 'reading', 'literature', 'authors', 'self-improvement'],
      categories: ['Books'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 18)),
      updatedAt: DateTime.now().subtract(Duration(days: 18)),
    ),
    Content(
      id: 'ig_books_1',
      platform: PlatformType.instagram,
      platformContentId: 'Cbooks0000002',
      title: 'Autumn Reading List 🍂',
      description:
          '5 cosy books to read this autumn. Which one are you adding to your TBR? 📚 #books #reading #literature #booktok #authors',
      videoUrl: 'https://www.instagram.com/reel/Cbooks0000002/',
      thumbnailUrl: null,
      creatorName: 'the_book_nook',
      durationSeconds: 48,
      viewCount: 2100000,
      likeCount: 168000,
      publishedAt: DateTime.now().subtract(Duration(days: 3)),
      tags: [
        'books',
        'reading',
        'literature',
        'authors',
        'bookrecommendations',
      ],
      categories: ['Books'],
      contentType: ContentType.reel,
      createdAt: DateTime.now().subtract(Duration(days: 3)),
      updatedAt: DateTime.now().subtract(Duration(days: 3)),
    ),
    Content(
      id: 'tt_books_1',
      platform: PlatformType.tiktok,
      platformContentId: '7610000000000000003',
      title: 'The Book That Broke Me in the Best Way',
      description:
          'I was not prepared for this ending 😭 #books #reading #literature #booktok #authors #fyp',
      videoUrl: 'https://www.tiktok.com/explore',
      thumbnailUrl: null,
      creatorName: 'bookish_takes',
      durationSeconds: 42,
      viewCount: 6200000,
      likeCount: 510000,
      publishedAt: DateTime.now().subtract(Duration(hours: 30)),
      tags: ['books', 'reading', 'literature', 'authors', 'booktok'],
      categories: ['Books'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(hours: 30)),
      updatedAt: DateTime.now().subtract(Duration(hours: 30)),
    ),
    Content(
      id: 'fb_books_1',
      platform: PlatformType.facebook,
      platformContentId: '4100000000000003',
      title: 'Classic Literature Book Club: Pride and Prejudice',
      description:
          'Join our monthly book club discussion of Jane Austen\'s Pride and Prejudice. We break down themes, characters, and why it still resonates 200 years later.',
      videoUrl: 'https://www.facebook.com/watch',
      thumbnailUrl: null,
      creatorName: 'The Reading Room',
      durationSeconds: 3600,
      viewCount: 890000,
      likeCount: 45000,
      publishedAt: DateTime.now().subtract(Duration(days: 22)),
      tags: ['books', 'reading', 'literature', 'authors', 'classics'],
      categories: ['Books'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 22)),
      updatedAt: DateTime.now().subtract(Duration(days: 22)),
    ),

    // ── Photography ───────────────────────────────────────────────────────────
    Content(
      id: 'yt_photo_1',
      platform: PlatformType.youtube,
      platformContentId: 'OqjF4XeeTRs',
      title: 'Master Manual Mode in 15 Minutes',
      description:
          'The simplest explanation of ISO, shutter speed, and aperture on the internet. After this video you will never shoot on Auto again.',
      videoUrl: 'https://www.youtube.com/embed/OqjF4XeeTRs',
      thumbnailUrl: 'https://img.youtube.com/vi/OqjF4XeeTRs/mqdefault.jpg',
      creatorName: 'Camera Craft',
      durationSeconds: 900,
      viewCount: 11200000,
      likeCount: 498000,
      publishedAt: DateTime.now().subtract(Duration(days: 25)),
      tags: ['photography', 'camera', 'photos', 'visual', 'tutorial'],
      categories: ['Photography'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 25)),
      updatedAt: DateTime.now().subtract(Duration(days: 25)),
    ),
    Content(
      id: 'ig_photo_1',
      platform: PlatformType.instagram,
      platformContentId: 'Cphoto000002',
      title: 'Golden Hour Portrait Editing Tutorial',
      description:
          'My full Lightroom edit on this golden-hour portrait 🌅 All presets linked in bio. #photography #photos #camera #visual #lightroom',
      videoUrl: 'https://www.instagram.com/reel/Cphoto000002/',
      thumbnailUrl: null,
      creatorName: 'lens_and_light',
      durationSeconds: 53,
      viewCount: 3700000,
      likeCount: 295000,
      publishedAt: DateTime.now().subtract(Duration(days: 4)),
      tags: ['photography', 'photos', 'camera', 'visual', 'editing'],
      categories: ['Photography'],
      contentType: ContentType.reel,
      createdAt: DateTime.now().subtract(Duration(days: 4)),
      updatedAt: DateTime.now().subtract(Duration(days: 4)),
    ),
    Content(
      id: 'tt_photo_1',
      platform: PlatformType.tiktok,
      platformContentId: '7610000000000000004',
      title: '3 iPhone Camera Tricks You Didn\'t Know',
      description:
          'These settings completely transformed my phone photography 📸 #photography #camera #photos #visual #iphone #fyp',
      videoUrl: 'https://www.tiktok.com/explore',
      thumbnailUrl: null,
      creatorName: 'shotoniphone_tips',
      durationSeconds: 38,
      viewCount: 14300000,
      likeCount: 1180000,
      publishedAt: DateTime.now().subtract(Duration(hours: 11)),
      tags: ['photography', 'camera', 'photos', 'visual', 'iphone'],
      categories: ['Photography'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(hours: 11)),
      updatedAt: DateTime.now().subtract(Duration(hours: 11)),
    ),
    Content(
      id: 'fb_photo_1',
      platform: PlatformType.facebook,
      platformContentId: '4100000000000004',
      title: 'Wildlife Photography in the Amazon',
      description:
          'A behind-the-scenes look at a 2-week wildlife photography expedition in the Amazon rainforest. Gear, techniques, and rare species captured on camera.',
      videoUrl: 'https://www.facebook.com/watch',
      thumbnailUrl: null,
      creatorName: 'Wild Lens',
      durationSeconds: 1560,
      viewCount: 2600000,
      likeCount: 134000,
      publishedAt: DateTime.now().subtract(Duration(days: 13)),
      tags: ['photography', 'photos', 'camera', 'visual', 'wildlife'],
      categories: ['Photography', 'Nature'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 13)),
      updatedAt: DateTime.now().subtract(Duration(days: 13)),
    ),

    // ── Dance ─────────────────────────────────────────────────────────────────
    Content(
      id: 'yt_dance_1',
      platform: PlatformType.youtube,
      platformContentId: 'pCDS0s3SLKQ',
      title: 'Learn the Viral TikTok Dance in 10 Minutes',
      description:
          'Step-by-step beginner-friendly tutorial for the biggest TikTok dance trend of 2024. We break it down 8 counts at a time.',
      videoUrl: 'https://www.youtube.com/embed/pCDS0s3SLKQ',
      thumbnailUrl: 'https://img.youtube.com/vi/pCDS0s3SLKQ/mqdefault.jpg',
      creatorName: 'Dance With Me',
      durationSeconds: 605,
      viewCount: 8400000,
      likeCount: 620000,
      publishedAt: DateTime.now().subtract(Duration(days: 5)),
      tags: ['dance', 'choreography', 'movement', 'rhythm', 'tutorial'],
      categories: ['Dance'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 5)),
      updatedAt: DateTime.now().subtract(Duration(days: 5)),
    ),
    Content(
      id: 'ig_dance_1',
      platform: PlatformType.instagram,
      platformContentId: 'Cdance000002',
      title: 'Ballet Meets Hip-Hop Fusion',
      description:
          'Classical ballet technique mixed with hip-hop energy 🩰🔥 The contrast is everything. #dance #choreography #movement #rhythm #ballet',
      videoUrl: 'https://www.instagram.com/reel/Cdance000002/',
      thumbnailUrl: null,
      creatorName: 'fusion_moves',
      durationSeconds: 45,
      viewCount: 12700000,
      likeCount: 1050000,
      publishedAt: DateTime.now().subtract(Duration(hours: 7)),
      tags: ['dance', 'choreography', 'movement', 'rhythm', 'ballet'],
      categories: ['Dance'],
      contentType: ContentType.reel,
      createdAt: DateTime.now().subtract(Duration(hours: 7)),
      updatedAt: DateTime.now().subtract(Duration(hours: 7)),
    ),
    Content(
      id: 'tt_dance_1',
      platform: PlatformType.tiktok,
      platformContentId: '7610000000000000005',
      title: 'This Salsa Spin Sequence Goes Hard',
      description:
          'Partner salsa choreography that we nailed on the first take 💃🕺 #dance #choreography #movement #rhythm #salsa #fyp',
      videoUrl: 'https://www.tiktok.com/explore',
      thumbnailUrl: null,
      creatorName: 'salsa_kings',
      durationSeconds: 30,
      viewCount: 18200000,
      likeCount: 1540000,
      publishedAt: DateTime.now().subtract(Duration(hours: 5)),
      tags: ['dance', 'choreography', 'movement', 'rhythm', 'salsa'],
      categories: ['Dance'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(hours: 5)),
      updatedAt: DateTime.now().subtract(Duration(hours: 5)),
    ),
    Content(
      id: 'fb_dance_1',
      platform: PlatformType.facebook,
      platformContentId: '4100000000000005',
      title: 'World Dance Day: Styles From 20 Countries',
      description:
          'Celebrating World Dance Day with a tour through 20 traditional and contemporary dance styles from around the globe — from Flamenco to Kecak.',
      videoUrl: 'https://www.facebook.com/watch',
      thumbnailUrl: null,
      creatorName: 'World Dance Collective',
      durationSeconds: 2100,
      viewCount: 4100000,
      likeCount: 210000,
      publishedAt: DateTime.now().subtract(Duration(days: 20)),
      tags: ['dance', 'choreography', 'movement', 'rhythm', 'world-dance'],
      categories: ['Dance'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 20)),
      updatedAt: DateTime.now().subtract(Duration(days: 20)),
    ),

    // ── Nature ────────────────────────────────────────────────────────────────
    Content(
      id: 'yt_nature_1',
      platform: PlatformType.youtube,
      platformContentId: 'Gc2en3nHxA4',
      title: 'Planet Earth III: Deep Ocean Episode',
      description:
          'Breathtaking footage from the deepest points of the ocean, revealing creatures never before captured on film. A BBC Natural World masterpiece.',
      videoUrl: 'https://www.youtube.com/embed/Gc2en3nHxA4',
      thumbnailUrl: 'https://img.youtube.com/vi/Gc2en3nHxA4/mqdefault.jpg',
      creatorName: 'BBC Earth',
      durationSeconds: 3180,
      viewCount: 22000000,
      likeCount: 890000,
      publishedAt: DateTime.now().subtract(Duration(days: 30)),
      tags: ['nature', 'outdoors', 'wildlife', 'environment', 'ocean'],
      categories: ['Nature'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 30)),
      updatedAt: DateTime.now().subtract(Duration(days: 30)),
    ),
    Content(
      id: 'ig_nature_1',
      platform: PlatformType.instagram,
      platformContentId: 'Cnature000002',
      title: 'Northern Lights Over Norway',
      description:
          'Shot entirely on the Sony A7IV during a solo trip to Tromsø in January 🌌 The aurora was dancing for 3 hours straight. #nature #outdoors #wildlife #environment',
      videoUrl: 'https://www.instagram.com/reel/Cnature000002/',
      thumbnailUrl: null,
      creatorName: 'arctic_explorer',
      durationSeconds: 58,
      viewCount: 9800000,
      likeCount: 780000,
      publishedAt: DateTime.now().subtract(Duration(days: 6)),
      tags: ['nature', 'outdoors', 'wildlife', 'environment', 'aurora'],
      categories: ['Nature'],
      contentType: ContentType.reel,
      createdAt: DateTime.now().subtract(Duration(days: 6)),
      updatedAt: DateTime.now().subtract(Duration(days: 6)),
    ),
    Content(
      id: 'tt_nature_1',
      platform: PlatformType.tiktok,
      platformContentId: '7610000000000000006',
      title: 'Baby Otters Learning to Swim',
      description:
          'I could watch this on loop forever 🦦💙 #nature #outdoors #wildlife #animals #cute #fyp',
      videoUrl: 'https://www.tiktok.com/explore',
      thumbnailUrl: null,
      creatorName: 'wildlife_moments',
      durationSeconds: 24,
      viewCount: 31000000,
      likeCount: 2800000,
      publishedAt: DateTime.now().subtract(Duration(hours: 4)),
      tags: ['nature', 'outdoors', 'wildlife', 'environment', 'animals'],
      categories: ['Nature'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(hours: 4)),
      updatedAt: DateTime.now().subtract(Duration(hours: 4)),
    ),
    Content(
      id: 'fb_nature_1',
      platform: PlatformType.facebook,
      platformContentId: '4100000000000006',
      title: 'Protecting the Amazon: Conservation Stories',
      description:
          'Meet the local communities on the front lines of Amazon conservation. A powerful 20-minute documentary on biodiversity, Indigenous rights, and hope.',
      videoUrl: 'https://www.facebook.com/watch',
      thumbnailUrl: null,
      creatorName: 'Earth Guardians',
      durationSeconds: 1200,
      viewCount: 3900000,
      likeCount: 205000,
      publishedAt: DateTime.now().subtract(Duration(days: 11)),
      tags: ['nature', 'outdoors', 'wildlife', 'environment', 'conservation'],
      categories: ['Nature'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 11)),
      updatedAt: DateTime.now().subtract(Duration(days: 11)),
    ),

    // ── Gaming (additional) ───────────────────────────────────────────────────
    Content(
      id: 'yt_gaming_2',
      platform: PlatformType.youtube,
      platformContentId: 'FoU37T1RFEM',
      title: 'I Spent 100 Days in Minecraft — Here\'s What Happened',
      description:
          'The ultimate 100-day Minecraft survival series. From a dirt house to a mega-castle, every milestone documented.',
      videoUrl: 'https://www.youtube.com/embed/FoU37T1RFEM',
      thumbnailUrl: 'https://img.youtube.com/vi/FoU37T1RFEM/mqdefault.jpg',
      creatorName: 'BlockCraft Master',
      durationSeconds: 4200,
      viewCount: 35000000,
      likeCount: 1800000,
      publishedAt: DateTime.now().subtract(Duration(days: 21)),
      tags: ['gaming', 'gameplay', 'streaming', 'minecraft', 'esports'],
      categories: ['Gaming'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 21)),
      updatedAt: DateTime.now().subtract(Duration(days: 21)),
    ),
    Content(
      id: 'ig_gaming_1',
      platform: PlatformType.instagram,
      platformContentId: 'Cgaming000003',
      title: 'The Clutch That Ended the Tournament',
      description:
          '1v4 clutch in CS2 that nobody saw coming 🎮😱 #gaming #esports #gameplay #streaming #clutch',
      videoUrl: 'https://www.instagram.com/reel/Cgaming000003/',
      thumbnailUrl: null,
      creatorName: 'pro_esports_clips',
      durationSeconds: 35,
      viewCount: 5600000,
      likeCount: 450000,
      publishedAt: DateTime.now().subtract(Duration(hours: 20)),
      tags: ['gaming', 'esports', 'gameplay', 'streaming', 'cs2'],
      categories: ['Gaming'],
      contentType: ContentType.reel,
      createdAt: DateTime.now().subtract(Duration(hours: 20)),
      updatedAt: DateTime.now().subtract(Duration(hours: 20)),
    ),
    Content(
      id: 'fb_gaming_1',
      platform: PlatformType.facebook,
      platformContentId: '4100000000000007',
      title: 'The History of Video Game Consoles',
      description:
          'From Atari to PlayStation 5 — a complete history of home video game consoles spanning 50 years of gaming evolution.',
      videoUrl: 'https://www.facebook.com/watch',
      thumbnailUrl: null,
      creatorName: 'Game History Channel',
      durationSeconds: 3300,
      viewCount: 4700000,
      likeCount: 230000,
      publishedAt: DateTime.now().subtract(Duration(days: 17)),
      tags: ['gaming', 'gameplay', 'esports', 'streaming', 'history'],
      categories: ['Gaming', 'Education'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 17)),
      updatedAt: DateTime.now().subtract(Duration(days: 17)),
    ),

    // ── Travel (additional) ───────────────────────────────────────────────────
    Content(
      id: 'yt_travel_1',
      platform: PlatformType.youtube,
      platformContentId: 'WxfZkMm3wcg',
      title: 'Solo Travel in Morocco: A Complete Guide',
      description:
          'Everything you need to know for a solo trip to Morocco — Marrakech, the Sahara, the Atlas Mountains, and the blue city of Chefchaouen.',
      videoUrl: 'https://www.youtube.com/embed/WxfZkMm3wcg',
      thumbnailUrl: 'https://img.youtube.com/vi/WxfZkMm3wcg/mqdefault.jpg',
      creatorName: 'Off the Beaten Path',
      durationSeconds: 2760,
      viewCount: 6800000,
      likeCount: 310000,
      publishedAt: DateTime.now().subtract(Duration(days: 14)),
      tags: ['travel', 'destinations', 'adventure', 'culture', 'morocco'],
      categories: ['Travel'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 14)),
      updatedAt: DateTime.now().subtract(Duration(days: 14)),
    ),
    Content(
      id: 'tt_travel_1',
      platform: PlatformType.tiktok,
      platformContentId: '7610000000000000007',
      title: r'24 Hours in Tokyo for Under $50',
      description:
          'Proof that Tokyo can be done on a budget 🇯🇵 Full itinerary in my bio! #travel #destinations #adventure #culture #tokyo #fyp',
      videoUrl: 'https://www.tiktok.com/explore',
      thumbnailUrl: null,
      creatorName: 'budget_wanderer',
      durationSeconds: 58,
      viewCount: 9200000,
      likeCount: 730000,
      publishedAt: DateTime.now().subtract(Duration(hours: 26)),
      tags: ['travel', 'destinations', 'adventure', 'culture', 'tokyo'],
      categories: ['Travel'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(hours: 26)),
      updatedAt: DateTime.now().subtract(Duration(hours: 26)),
    ),
    Content(
      id: 'fb_travel_1',
      platform: PlatformType.facebook,
      platformContentId: '4100000000000008',
      title: 'The World\'s Most Breathtaking Train Journeys',
      description:
          'From the Glacier Express in Switzerland to the Ghan through the Australian outback — the 10 most scenic train routes on Earth.',
      videoUrl: 'https://www.facebook.com/watch',
      thumbnailUrl: null,
      creatorName: 'Rail & Wander',
      durationSeconds: 1980,
      viewCount: 5100000,
      likeCount: 248000,
      publishedAt: DateTime.now().subtract(Duration(days: 19)),
      tags: ['travel', 'destinations', 'adventure', 'culture', 'trains'],
      categories: ['Travel'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 19)),
      updatedAt: DateTime.now().subtract(Duration(days: 19)),
    ),

    // ── Fitness (additional) ──────────────────────────────────────────────────
    Content(
      id: 'yt_fitness_1',
      platform: PlatformType.youtube,
      platformContentId: 'UItWltVZgxI',
      title: '30-Day Ab Challenge — Full Month Workout Plan',
      description:
          'A complete 30-day ab challenge with progressive difficulty. No equipment needed. Full calendar included in the description.',
      videoUrl: 'https://www.youtube.com/embed/UItWltVZgxI',
      thumbnailUrl: 'https://img.youtube.com/vi/UItWltVZgxI/mqdefault.jpg',
      creatorName: 'Fit For Life',
      durationSeconds: 1320,
      viewCount: 14500000,
      likeCount: 680000,
      publishedAt: DateTime.now().subtract(Duration(days: 28)),
      tags: ['workout', 'fitness', 'health', 'exercise', 'abs'],
      categories: ['Fitness'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 28)),
      updatedAt: DateTime.now().subtract(Duration(days: 28)),
    ),
    Content(
      id: 'tt_fitness_1',
      platform: PlatformType.tiktok,
      platformContentId: '7610000000000000008',
      title: 'Form Check: Are You Squatting Wrong?',
      description:
          'The 3 most common squat mistakes and exactly how to fix them 🏋️ #workout #fitness #health #exercise #gym #fyp',
      videoUrl: 'https://www.tiktok.com/explore',
      thumbnailUrl: null,
      creatorName: 'form_coach',
      durationSeconds: 45,
      viewCount: 7800000,
      likeCount: 620000,
      publishedAt: DateTime.now().subtract(Duration(hours: 18)),
      tags: ['workout', 'fitness', 'health', 'exercise', 'squat'],
      categories: ['Fitness'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(hours: 18)),
      updatedAt: DateTime.now().subtract(Duration(hours: 18)),
    ),
    Content(
      id: 'fb_fitness_1',
      platform: PlatformType.facebook,
      platformContentId: '4100000000000009',
      title: 'The Science of Building Muscle After 40',
      description:
          'Sports science researcher explains how muscle growth changes after 40 and what training adjustments will keep your gains coming.',
      videoUrl: 'https://www.facebook.com/watch',
      thumbnailUrl: null,
      creatorName: 'Sports Science Lab',
      durationSeconds: 2160,
      viewCount: 3200000,
      likeCount: 158000,
      publishedAt: DateTime.now().subtract(Duration(days: 16)),
      tags: ['workout', 'fitness', 'health', 'exercise', 'science'],
      categories: ['Fitness'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 16)),
      updatedAt: DateTime.now().subtract(Duration(days: 16)),
    ),

    // ── Fashion (additional) ──────────────────────────────────────────────────
    Content(
      id: 'yt_fashion_1',
      platform: PlatformType.youtube,
      platformContentId: 'kfFhsYNfCwk',
      title: 'Men\'s Style Guide 2024: Build a Capsule Wardrobe',
      description:
          'How to build a versatile men\'s capsule wardrobe with just 20 pieces that work for every occasion — office, casual, and date night.',
      videoUrl: 'https://www.youtube.com/embed/kfFhsYNfCwk',
      thumbnailUrl: 'https://img.youtube.com/vi/kfFhsYNfCwk/mqdefault.jpg',
      creatorName: 'The Style OG',
      durationSeconds: 1740,
      viewCount: 4600000,
      likeCount: 198000,
      publishedAt: DateTime.now().subtract(Duration(days: 10)),
      tags: ['fashion', 'style', 'outfits', 'trends', 'menswear'],
      categories: ['Fashion'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 10)),
      updatedAt: DateTime.now().subtract(Duration(days: 10)),
    ),
    Content(
      id: 'tt_fashion_1',
      platform: PlatformType.tiktok,
      platformContentId: '7610000000000000009',
      title: 'Colour Theory That Will Change How You Dress',
      description:
          'The 60-30-10 rule for outfit colour balance 🎨 game-changer fr #fashion #style #outfits #trends #colour #fyp',
      videoUrl: 'https://www.tiktok.com/explore',
      thumbnailUrl: null,
      creatorName: 'style_theory',
      durationSeconds: 40,
      viewCount: 16000000,
      likeCount: 1320000,
      publishedAt: DateTime.now().subtract(Duration(hours: 15)),
      tags: ['fashion', 'style', 'outfits', 'trends', 'colour'],
      categories: ['Fashion'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(hours: 15)),
      updatedAt: DateTime.now().subtract(Duration(hours: 15)),
    ),

    // ── Beauty (additional) ───────────────────────────────────────────────────
    Content(
      id: 'tt_beauty_1',
      platform: PlatformType.tiktok,
      platformContentId: '7610000000000000010',
      title: 'The Skincare Order That Actually Works',
      description:
          'Stop layering your skincare in the wrong order! Here\'s the correct sequence explained simply 🧴 #beauty #skincare #cosmetics #makeup #fyp',
      videoUrl: 'https://www.tiktok.com/explore',
      thumbnailUrl: null,
      creatorName: 'skin_scientist',
      durationSeconds: 48,
      viewCount: 21000000,
      likeCount: 1750000,
      publishedAt: DateTime.now().subtract(Duration(hours: 10)),
      tags: ['beauty', 'skincare', 'cosmetics', 'makeup', 'routine'],
      categories: ['Beauty'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(hours: 10)),
      updatedAt: DateTime.now().subtract(Duration(hours: 10)),
    ),
    Content(
      id: 'fb_beauty_1',
      platform: PlatformType.facebook,
      platformContentId: '4100000000000010',
      title: 'Is Expensive Skincare Worth It? Dermatologist Answers',
      description:
          'A board-certified dermatologist compares drugstore versus luxury skincare brands across cleansers, retinols, and SPF. The results may surprise you.',
      videoUrl: 'https://www.facebook.com/watch',
      thumbnailUrl: null,
      creatorName: 'Derm Decoded',
      durationSeconds: 1800,
      viewCount: 6700000,
      likeCount: 312000,
      publishedAt: DateTime.now().subtract(Duration(days: 8)),
      tags: ['beauty', 'skincare', 'cosmetics', 'makeup', 'dermatology'],
      categories: ['Beauty'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 8)),
      updatedAt: DateTime.now().subtract(Duration(days: 8)),
    ),

    // ── Movies (additional) ───────────────────────────────────────────────────
    Content(
      id: 'ig_movies_1',
      platform: PlatformType.instagram,
      platformContentId: 'Cmovies00002',
      title: 'Hot Take: Interstellar Is Overrated',
      description:
          'Said what I said 😤 Drop your thoughts below 👇 #movies #films #cinema #reviews #nolan',
      videoUrl: 'https://www.instagram.com/reel/Cmovies00002/',
      thumbnailUrl: null,
      creatorName: 'cinema_unpopular',
      durationSeconds: 55,
      viewCount: 4200000,
      likeCount: 340000,
      publishedAt: DateTime.now().subtract(Duration(days: 2)),
      tags: ['movies', 'films', 'cinema', 'reviews', 'nolan'],
      categories: ['Movies'],
      contentType: ContentType.reel,
      createdAt: DateTime.now().subtract(Duration(days: 2)),
      updatedAt: DateTime.now().subtract(Duration(days: 2)),
    ),
    Content(
      id: 'tt_movies_1',
      platform: PlatformType.tiktok,
      platformContentId: '7610000000000000011',
      title: 'Movie Plot Holes That Can\'t Be Unseen',
      description:
          'Once you see these you can\'t un-see them 😭 #movies #films #cinema #reviews #plothole #fyp',
      videoUrl: 'https://www.tiktok.com/explore',
      thumbnailUrl: null,
      creatorName: 'cinemafails',
      durationSeconds: 52,
      viewCount: 12400000,
      likeCount: 980000,
      publishedAt: DateTime.now().subtract(Duration(hours: 28)),
      tags: ['movies', 'films', 'cinema', 'reviews', 'funny'],
      categories: ['Movies', 'Comedy'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(hours: 28)),
      updatedAt: DateTime.now().subtract(Duration(hours: 28)),
    ),
    Content(
      id: 'fb_movies_1',
      platform: PlatformType.facebook,
      platformContentId: '4100000000000011',
      title: 'How Christopher Nolan Shoots Without CGI',
      description:
          'A deep dive into the practical effects, in-camera tricks, and real stunts that Christopher Nolan insists on for every film. From The Dark Knight to Oppenheimer.',
      videoUrl: 'https://www.facebook.com/watch',
      thumbnailUrl: null,
      creatorName: 'Behind the Frame',
      durationSeconds: 2580,
      viewCount: 8900000,
      likeCount: 410000,
      publishedAt: DateTime.now().subtract(Duration(days: 24)),
      tags: ['movies', 'films', 'cinema', 'reviews', 'nolan'],
      categories: ['Movies'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 24)),
      updatedAt: DateTime.now().subtract(Duration(days: 24)),
    ),

    // ── Sports (additional) ───────────────────────────────────────────────────
    Content(
      id: 'ig_sports_1',
      platform: PlatformType.instagram,
      platformContentId: 'Csports00002',
      title: 'Ronaldo Free-Kick Tutorial',
      description:
          'Breaking down Ronaldo\'s knuckleball technique step by step ⚽ Practice these drills every day and your free kicks will improve dramatically. #sports #football #soccer',
      videoUrl: 'https://www.instagram.com/reel/Csports00002/',
      thumbnailUrl: null,
      creatorName: 'football_skills_lab',
      durationSeconds: 50,
      viewCount: 7800000,
      likeCount: 620000,
      publishedAt: DateTime.now().subtract(Duration(days: 3)),
      tags: ['sports', 'football', 'soccer', 'skills', 'training'],
      categories: ['Sports'],
      contentType: ContentType.reel,
      createdAt: DateTime.now().subtract(Duration(days: 3)),
      updatedAt: DateTime.now().subtract(Duration(days: 3)),
    ),
    Content(
      id: 'fb_sports_1',
      platform: PlatformType.facebook,
      platformContentId: '4100000000000012',
      title: 'The Greatest Sporting Comebacks of All Time',
      description:
          'From Leicester City winning the Premier League to Tiger Woods at the 2019 Masters — the most extraordinary sporting comebacks ever witnessed.',
      videoUrl: 'https://www.facebook.com/watch',
      thumbnailUrl: null,
      creatorName: 'Sports Legacy',
      durationSeconds: 2400,
      viewCount: 11500000,
      likeCount: 540000,
      publishedAt: DateTime.now().subtract(Duration(days: 26)),
      tags: ['sports', 'football', 'basketball', 'soccer', 'history'],
      categories: ['Sports'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 26)),
      updatedAt: DateTime.now().subtract(Duration(days: 26)),
    ),

    // ── Cars (additional) ─────────────────────────────────────────────────────
    Content(
      id: 'ig_cars_1',
      platform: PlatformType.instagram,
      platformContentId: 'Ccars0000002',
      title: 'Ferrari vs Lamborghini Drag Race',
      description:
          'Ferrari SF90 vs Lamborghini Huracán STO — who wins? 🏁🔥 Full result in comments. #cars #automotive #vehicles #racing',
      videoUrl: 'https://www.instagram.com/reel/Ccars0000002/',
      thumbnailUrl: null,
      creatorName: 'drag_race_daily',
      durationSeconds: 42,
      viewCount: 8300000,
      likeCount: 670000,
      publishedAt: DateTime.now().subtract(Duration(hours: 24)),
      tags: ['cars', 'automotive', 'vehicles', 'racing', 'ferrari'],
      categories: ['Cars'],
      contentType: ContentType.reel,
      createdAt: DateTime.now().subtract(Duration(hours: 24)),
      updatedAt: DateTime.now().subtract(Duration(hours: 24)),
    ),
    Content(
      id: 'tt_cars_1',
      platform: PlatformType.tiktok,
      platformContentId: '7610000000000000012',
      title: 'Why Modern Cars All Look the Same',
      description:
          'The aerodynamics & regulation rabbit hole that explains the current car design problem 🚗 #cars #automotive #vehicles #design #fyp',
      videoUrl: 'https://www.tiktok.com/explore',
      thumbnailUrl: null,
      creatorName: 'motormouth',
      durationSeconds: 55,
      viewCount: 5400000,
      likeCount: 435000,
      publishedAt: DateTime.now().subtract(Duration(hours: 36)),
      tags: ['cars', 'automotive', 'vehicles', 'racing', 'design'],
      categories: ['Cars'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(hours: 36)),
      updatedAt: DateTime.now().subtract(Duration(hours: 36)),
    ),
    Content(
      id: 'fb_cars_1',
      platform: PlatformType.facebook,
      platformContentId: '4100000000000013',
      title: 'Restoring a 1969 Ford Mustang from Scratch',
      description:
          'A 6-month complete frame-off restoration of a 1969 Ford Mustang Fastback, condensed into 25 minutes. From rust bucket to showroom condition.',
      videoUrl: 'https://www.facebook.com/watch',
      thumbnailUrl: null,
      creatorName: 'Classic Restore Co',
      durationSeconds: 1500,
      viewCount: 7200000,
      likeCount: 345000,
      publishedAt: DateTime.now().subtract(Duration(days: 23)),
      tags: ['cars', 'automotive', 'vehicles', 'racing', 'restoration'],
      categories: ['Cars'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 23)),
      updatedAt: DateTime.now().subtract(Duration(days: 23)),
    ),

    // ── Pets (additional) ─────────────────────────────────────────────────────
    Content(
      id: 'yt_pets_1',
      platform: PlatformType.youtube,
      platformContentId: 'LmCB9dLQlhs',
      title: 'How to Train Any Dog in 7 Days',
      description:
          'Positive reinforcement training system that works on any breed. Cover sit, stay, recall, and loose-lead walking in just one week.',
      videoUrl: 'https://www.youtube.com/embed/LmCB9dLQlhs',
      thumbnailUrl: 'https://img.youtube.com/vi/LmCB9dLQlhs/mqdefault.jpg',
      creatorName: 'Zak George',
      durationSeconds: 2640,
      viewCount: 18000000,
      likeCount: 820000,
      publishedAt: DateTime.now().subtract(Duration(days: 35)),
      tags: ['pets', 'dogs', 'animals', 'cats', 'training'],
      categories: ['Pets'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 35)),
      updatedAt: DateTime.now().subtract(Duration(days: 35)),
    ),
    Content(
      id: 'tt_pets_1',
      platform: PlatformType.tiktok,
      platformContentId: '7610000000000000013',
      title: 'Cat Discovers Snow for the First Time',
      description:
          'His little face when the paw hit the snow 🐱❄️ I\'m obsessed #pets #cats #animals #dogs #cute #fyp',
      videoUrl: 'https://www.tiktok.com/explore',
      thumbnailUrl: null,
      creatorName: 'fluffy_chronicles',
      durationSeconds: 20,
      viewCount: 28000000,
      likeCount: 2400000,
      publishedAt: DateTime.now().subtract(Duration(hours: 6)),
      tags: ['pets', 'cats', 'animals', 'dogs', 'cute'],
      categories: ['Pets'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(hours: 6)),
      updatedAt: DateTime.now().subtract(Duration(hours: 6)),
    ),
    Content(
      id: 'fb_pets_1',
      platform: PlatformType.facebook,
      platformContentId: '4100000000000014',
      title: 'Shelter Dogs Before and After Adoption',
      description:
          'Heartwarming transformations of rescue dogs one week, one month, and one year after adoption. Have tissues ready.',
      videoUrl: 'https://www.facebook.com/watch',
      thumbnailUrl: null,
      creatorName: 'Rescue Tails',
      durationSeconds: 840,
      viewCount: 14000000,
      likeCount: 980000,
      publishedAt: DateTime.now().subtract(Duration(days: 9)),
      tags: ['pets', 'dogs', 'animals', 'cats', 'rescue'],
      categories: ['Pets'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 9)),
      updatedAt: DateTime.now().subtract(Duration(days: 9)),
    ),

    // ── DIY (additional) ──────────────────────────────────────────────────────
    Content(
      id: 'yt_diy_2',
      platform: PlatformType.youtube,
      platformContentId: 'aBZjxFuqLTs',
      title: 'Build a Floating Bookshelf for £20',
      description:
          'A complete woodworking project — hidden bracket floating bookshelf from raw pine. Full materials list, cut list, and finishing guide included.',
      videoUrl: 'https://www.youtube.com/embed/aBZjxFuqLTs',
      thumbnailUrl: 'https://img.youtube.com/vi/aBZjxFuqLTs/mqdefault.jpg',
      creatorName: 'Weekend Woodworker',
      durationSeconds: 2280,
      viewCount: 5100000,
      likeCount: 240000,
      publishedAt: DateTime.now().subtract(Duration(days: 27)),
      tags: ['diy', 'crafts', 'projects', 'handmade', 'woodworking'],
      categories: ['DIY'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 27)),
      updatedAt: DateTime.now().subtract(Duration(days: 27)),
    ),
    Content(
      id: 'ig_diy_1',
      platform: PlatformType.instagram,
      platformContentId: 'Cdiy00000003',
      title: 'Macramé Wall Hanging in 30 Minutes',
      description:
          'First time doing macramé and it turned out SO good 🪢✨ Full tutorial on my channel! #diy #crafts #handmade #projects #macrame',
      videoUrl: 'https://www.instagram.com/reel/Cdiy00000003/',
      thumbnailUrl: null,
      creatorName: 'craft_corner',
      durationSeconds: 58,
      viewCount: 3600000,
      likeCount: 290000,
      publishedAt: DateTime.now().subtract(Duration(days: 5)),
      tags: ['diy', 'crafts', 'handmade', 'projects', 'macrame'],
      categories: ['DIY'],
      contentType: ContentType.reel,
      createdAt: DateTime.now().subtract(Duration(days: 5)),
      updatedAt: DateTime.now().subtract(Duration(days: 5)),
    ),
    Content(
      id: 'fb_diy_1',
      platform: PlatformType.facebook,
      platformContentId: '4100000000000015',
      title: 'Upcycled Pallet Furniture: 5 Projects',
      description:
          'Turn free wooden pallets into a sofa, coffee table, garden planter, shoe rack, and wine rack. All five projects covered step by step.',
      videoUrl: 'https://www.facebook.com/watch',
      thumbnailUrl: null,
      creatorName: 'Pallet Projects',
      durationSeconds: 2880,
      viewCount: 4300000,
      likeCount: 205000,
      publishedAt: DateTime.now().subtract(Duration(days: 18)),
      tags: ['diy', 'crafts', 'projects', 'handmade', 'upcycling'],
      categories: ['DIY'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 18)),
      updatedAt: DateTime.now().subtract(Duration(days: 18)),
    ),

    // ── Music (additional) ────────────────────────────────────────────────────
    Content(
      id: 'yt_music_1',
      platform: PlatformType.youtube,
      platformContentId: 'gdZLi9oWNZg',
      title: 'Best Live Concerts of 2024 — Highlights',
      description:
          'The most electrifying moments from Beyoncé, Taylor Swift, Coldplay, and The Weeknd\'s 2024 tours. Epic concerts, epic performances.',
      videoUrl: 'https://www.youtube.com/embed/gdZLi9oWNZg',
      thumbnailUrl: 'https://img.youtube.com/vi/gdZLi9oWNZg/mqdefault.jpg',
      creatorName: 'Concert Weekly',
      durationSeconds: 1560,
      viewCount: 19000000,
      likeCount: 870000,
      publishedAt: DateTime.now().subtract(Duration(days: 7)),
      tags: ['music', 'concerts', 'songs', 'artists', 'live'],
      categories: ['Music'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 7)),
      updatedAt: DateTime.now().subtract(Duration(days: 7)),
    ),
    Content(
      id: 'ig_music_1',
      platform: PlatformType.instagram,
      platformContentId: 'Cmusic000002',
      title: 'Busker Stops Traffic in NYC 🎸',
      description:
          'This guitarist set up on a corner in Manhattan and the crowd just kept growing 😭🎶 #music #songs #artists #concerts #guitar',
      videoUrl: 'https://www.instagram.com/reel/Cmusic000002/',
      thumbnailUrl: null,
      creatorName: 'street_sounds_nyc',
      durationSeconds: 58,
      viewCount: 15400000,
      likeCount: 1260000,
      publishedAt: DateTime.now().subtract(Duration(hours: 13)),
      tags: ['music', 'songs', 'artists', 'concerts', 'guitar'],
      categories: ['Music'],
      contentType: ContentType.reel,
      createdAt: DateTime.now().subtract(Duration(hours: 13)),
      updatedAt: DateTime.now().subtract(Duration(hours: 13)),
    ),

    // ── Food (additional) ─────────────────────────────────────────────────────
    Content(
      id: 'yt_food_1',
      platform: PlatformType.youtube,
      platformContentId: 'CZKc5-SMxm8',
      title: 'Gordon Ramsay\'s Ultimate Burger Guide',
      description:
          'Everything Gordon Ramsay knows about burgers in one video — from beef blend to bun toasting. A masterclass in burger construction.',
      videoUrl: 'https://www.youtube.com/embed/CZKc5-SMxm8',
      thumbnailUrl: 'https://img.youtube.com/vi/CZKc5-SMxm8/mqdefault.jpg',
      creatorName: 'Gordon Ramsay',
      durationSeconds: 1380,
      viewCount: 26000000,
      likeCount: 1100000,
      publishedAt: DateTime.now().subtract(Duration(days: 40)),
      tags: ['cooking', 'recipes', 'food', 'restaurants', 'burger'],
      categories: ['Food'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 40)),
      updatedAt: DateTime.now().subtract(Duration(days: 40)),
    ),
    Content(
      id: 'tt_food_1',
      platform: PlatformType.tiktok,
      platformContentId: '7610000000000000014',
      title: 'Viral Feta Pasta in 20 Minutes',
      description:
          'The TikTok pasta that broke the internet — and for good reason 🍅🧀 #cooking #recipes #food #pasta #viral #fyp',
      videoUrl: 'https://www.tiktok.com/explore',
      thumbnailUrl: null,
      creatorName: 'eatwithme_official',
      durationSeconds: 42,
      viewCount: 43000000,
      likeCount: 3600000,
      publishedAt: DateTime.now().subtract(Duration(hours: 32)),
      tags: ['cooking', 'recipes', 'food', 'restaurants', 'pasta'],
      categories: ['Food'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(hours: 32)),
      updatedAt: DateTime.now().subtract(Duration(hours: 32)),
    ),
    Content(
      id: 'fb_food_1',
      platform: PlatformType.facebook,
      platformContentId: '4100000000000016',
      title: 'Street Food Tour: Bangkok Night Market',
      description:
          'A 30-minute tour through Bangkok\'s best night market street food: pad thai, mango sticky rice, grilled skewers, and freshly squeezed juices.',
      videoUrl: 'https://www.facebook.com/watch',
      thumbnailUrl: null,
      creatorName: 'Street Food World',
      durationSeconds: 1860,
      viewCount: 8600000,
      likeCount: 395000,
      publishedAt: DateTime.now().subtract(Duration(days: 13)),
      tags: ['cooking', 'recipes', 'food', 'restaurants', 'street-food'],
      categories: ['Food', 'Travel'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 13)),
      updatedAt: DateTime.now().subtract(Duration(days: 13)),
    ),

    // ── Education ─────────────────────────────────────────────────────────────
    Content(
      id: 'yt_edu_1',
      platform: PlatformType.youtube,
      platformContentId: 'HluANRwPyNo',
      title: 'How to Learn Anything 10x Faster',
      description:
          'The science of accelerated learning: spaced repetition, active recall, the Feynman technique, and interleaving explained with actionable steps.',
      videoUrl: 'https://www.youtube.com/embed/HluANRwPyNo',
      thumbnailUrl: 'https://img.youtube.com/vi/HluANRwPyNo/mqdefault.jpg',
      creatorName: 'Thomas Frank',
      durationSeconds: 1500,
      viewCount: 17000000,
      likeCount: 780000,
      publishedAt: DateTime.now().subtract(Duration(days: 45)),
      tags: ['learning', 'education', 'tutorials', 'knowledge', 'productivity'],
      categories: ['Education'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 45)),
      updatedAt: DateTime.now().subtract(Duration(days: 45)),
    ),
    Content(
      id: 'ig_edu_1',
      platform: PlatformType.instagram,
      platformContentId: 'Cedu0000002',
      title: 'One Economics Concept Every Week 📈',
      description:
          'This week: Supply and Demand explained in 60 seconds 🎓 #learning #education #tutorials #knowledge #economics',
      videoUrl: 'https://www.instagram.com/reel/Cedu0000002/',
      thumbnailUrl: null,
      creatorName: 'micro_lessons',
      durationSeconds: 60,
      viewCount: 4800000,
      likeCount: 385000,
      publishedAt: DateTime.now().subtract(Duration(days: 1)),
      tags: ['learning', 'education', 'tutorials', 'knowledge', 'economics'],
      categories: ['Education'],
      contentType: ContentType.reel,
      createdAt: DateTime.now().subtract(Duration(days: 1)),
      updatedAt: DateTime.now().subtract(Duration(days: 1)),
    ),
    Content(
      id: 'tt_edu_1',
      platform: PlatformType.tiktok,
      platformContentId: '7610000000000000015',
      title: 'A History Fact That Will Blow Your Mind',
      description:
          'Cleopatra lived closer to the Moon landing than to the building of the Great Pyramid 🤯 #learning #education #tutorials #knowledge #history #fyp',
      videoUrl: 'https://www.tiktok.com/explore',
      thumbnailUrl: null,
      creatorName: 'mindblown_facts',
      durationSeconds: 25,
      viewCount: 22000000,
      likeCount: 1900000,
      publishedAt: DateTime.now().subtract(Duration(hours: 7)),
      tags: ['learning', 'education', 'tutorials', 'knowledge', 'history'],
      categories: ['Education'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(hours: 7)),
      updatedAt: DateTime.now().subtract(Duration(hours: 7)),
    ),
    Content(
      id: 'fb_edu_1',
      platform: PlatformType.facebook,
      platformContentId: '4100000000000017',
      title: 'MIT OpenCourseWare: Introduction to Algorithms',
      description:
          'The full first lecture from MIT\'s legendary 6.006 Introduction to Algorithms course, taught by Erik Demaine. Now freely available to everyone.',
      videoUrl: 'https://www.facebook.com/watch',
      thumbnailUrl: null,
      creatorName: 'MIT OpenCourseWare',
      durationSeconds: 4800,
      viewCount: 3100000,
      likeCount: 145000,
      publishedAt: DateTime.now().subtract(Duration(days: 60)),
      tags: ['learning', 'education', 'tutorials', 'knowledge', 'algorithms'],
      categories: ['Education', 'Technology'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 60)),
      updatedAt: DateTime.now().subtract(Duration(days: 60)),
    ),

    // ── Extra YouTube — Tech ──────────────────────────────────────────────────
    Content(
      id: 'yt_extra_001',
      platform: PlatformType.youtube,
      platformContentId: 'gAjR4_CbPpQ',
      title: 'Google I/O 2024: Everything Announced',
      description:
          'Every major announcement from Google I/O 2024 — Gemini AI, Android 15, Pixel hardware, and more. Full keynote highlights in under 15 minutes.',
      videoUrl: 'https://www.youtube.com/embed/gAjR4_CbPpQ',
      thumbnailUrl: 'https://img.youtube.com/vi/gAjR4_CbPpQ/maxresdefault.jpg',
      creatorName: 'Google',
      durationSeconds: 890,
      viewCount: 4200000,
      likeCount: 182000,
      publishedAt: DateTime.now().subtract(Duration(days: 12)),
      tags: ['tech', 'google', 'ai', 'android', 'gemini'],
      categories: ['Technology'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 12)),
      updatedAt: DateTime.now().subtract(Duration(days: 12)),
    ),
    Content(
      id: 'yt_extra_002',
      platform: PlatformType.youtube,
      platformContentId: 'kqtD5dpn9C8',
      title: 'React Tutorial for Beginners — Full Course 2024',
      description:
          'Build a complete React app from scratch. Covers hooks, state, props, context, and React Router. Beginner-friendly and up-to-date for 2024.',
      videoUrl: 'https://www.youtube.com/embed/kqtD5dpn9C8',
      thumbnailUrl: 'https://img.youtube.com/vi/kqtD5dpn9C8/maxresdefault.jpg',
      creatorName: 'Mosh Hamedani',
      durationSeconds: 5400,
      viewCount: 3800000,
      likeCount: 165000,
      publishedAt: DateTime.now().subtract(Duration(days: 20)),
      tags: ['react', 'javascript', 'tutorial', 'frontend', 'programming'],
      categories: ['Technology', 'Education'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 20)),
      updatedAt: DateTime.now().subtract(Duration(days: 20)),
    ),
    Content(
      id: 'yt_extra_003',
      platform: PlatformType.youtube,
      platformContentId: '8idr1WZ1A7Q',
      title: 'Flutter 3.22 — What\'s New & Exciting',
      description:
          'The Flutter team walks through every change in Flutter 3.22: improved web rendering, new widgets, performance gains, and the Impeller engine update.',
      videoUrl: 'https://www.youtube.com/embed/8idr1WZ1A7Q',
      thumbnailUrl: 'https://img.youtube.com/vi/8idr1WZ1A7Q/maxresdefault.jpg',
      creatorName: 'Flutter',
      durationSeconds: 1245,
      viewCount: 980000,
      likeCount: 42000,
      publishedAt: DateTime.now().subtract(Duration(days: 8)),
      tags: ['flutter', 'mobile', 'development', 'dart', 'tech'],
      categories: ['Technology'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 8)),
      updatedAt: DateTime.now().subtract(Duration(days: 8)),
    ),

    // ── Extra YouTube — Gaming ────────────────────────────────────────────────
    Content(
      id: 'yt_extra_004',
      platform: PlatformType.youtube,
      platformContentId: 'MmB9b5njVbA',
      title: 'Minecraft: 1000 Days in Hardcore Mode',
      description:
          'What happens when you survive 1000 days in Minecraft Hardcore? Every challenge, near-death experience, and megabuild documented.',
      videoUrl: 'https://www.youtube.com/embed/MmB9b5njVbA',
      thumbnailUrl: 'https://img.youtube.com/vi/MmB9b5njVbA/maxresdefault.jpg',
      creatorName: 'Luke TheNotable',
      durationSeconds: 4620,
      viewCount: 55000000,
      likeCount: 2400000,
      publishedAt: DateTime.now().subtract(Duration(days: 30)),
      tags: ['gaming', 'minecraft', 'hardcore', 'survival', 'gameplay'],
      categories: ['Gaming'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 30)),
      updatedAt: DateTime.now().subtract(Duration(days: 30)),
    ),
    Content(
      id: 'yt_extra_005',
      platform: PlatformType.youtube,
      platformContentId: 'NR3d4KDh8BM',
      title: 'World Record Speedrun Explained — Sub 7 Minutes',
      description:
          'Breaking down the world record any% speedrun of a classic platformer frame-by-frame. Every trick, glitch, and precise input explained.',
      videoUrl: 'https://www.youtube.com/embed/NR3d4KDh8BM',
      thumbnailUrl: 'https://img.youtube.com/vi/NR3d4KDh8BM/maxresdefault.jpg',
      creatorName: 'Summoning Salt',
      durationSeconds: 1800,
      viewCount: 6700000,
      likeCount: 295000,
      publishedAt: DateTime.now().subtract(Duration(days: 15)),
      tags: ['gaming', 'speedrun', 'esports', 'gameplay', 'highlights'],
      categories: ['Gaming'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 15)),
      updatedAt: DateTime.now().subtract(Duration(days: 15)),
    ),
    Content(
      id: 'yt_extra_006',
      platform: PlatformType.youtube,
      platformContentId: 'jABzLoPCGHE',
      title: '10 Gaming Tips Every Player Should Know',
      description:
          'Pro tips that apply across almost every game genre — from aim training and sensitivity settings to mental game and tilt prevention.',
      videoUrl: 'https://www.youtube.com/embed/jABzLoPCGHE',
      thumbnailUrl: 'https://img.youtube.com/vi/jABzLoPCGHE/maxresdefault.jpg',
      creatorName: 'ProGuides',
      durationSeconds: 960,
      viewCount: 2100000,
      likeCount: 95000,
      publishedAt: DateTime.now().subtract(Duration(days: 6)),
      tags: ['gaming', 'tips', 'tutorial', 'esports', 'gameplay'],
      categories: ['Gaming', 'Education'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 6)),
      updatedAt: DateTime.now().subtract(Duration(days: 6)),
    ),

    // ── Extra YouTube — Education ─────────────────────────────────────────────
    Content(
      id: 'yt_extra_007',
      platform: PlatformType.youtube,
      platformContentId: '7y_xFMCkZtU',
      title: '5 Mental Math Tricks That Will Blow Your Mind',
      description:
          'These quick mental arithmetic tricks let you multiply, square, and calculate percentages faster than a calculator — all in your head.',
      videoUrl: 'https://www.youtube.com/embed/7y_xFMCkZtU',
      thumbnailUrl: 'https://img.youtube.com/vi/7y_xFMCkZtU/maxresdefault.jpg',
      creatorName: 'Math Antics',
      durationSeconds: 720,
      viewCount: 8500000,
      likeCount: 370000,
      publishedAt: DateTime.now().subtract(Duration(days: 22)),
      tags: ['math', 'education', 'learning', 'tricks', 'knowledge'],
      categories: ['Education'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 22)),
      updatedAt: DateTime.now().subtract(Duration(days: 22)),
    ),

    // ── Extra YouTube — Comedy ────────────────────────────────────────────────
    Content(
      id: 'yt_extra_008',
      platform: PlatformType.youtube,
      platformContentId: '_OBlgSz8sSM',
      title: 'Stand-Up Set: The Problem with Smart Home Devices',
      description:
          "A comedian's take on why smart home technology makes life both easier and infinitely more frustrating. Sold-out show, full set.",
      videoUrl: 'https://www.youtube.com/embed/_OBlgSz8sSM',
      thumbnailUrl: 'https://img.youtube.com/vi/_OBlgSz8sSM/maxresdefault.jpg',
      creatorName: 'Comedy Central Stand-Up',
      durationSeconds: 840,
      viewCount: 3400000,
      likeCount: 148000,
      publishedAt: DateTime.now().subtract(Duration(days: 18)),
      tags: ['comedy', 'stand-up', 'funny', 'humor', 'jokes'],
      categories: ['Comedy'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 18)),
      updatedAt: DateTime.now().subtract(Duration(days: 18)),
    ),
    Content(
      id: 'yt_extra_009',
      platform: PlatformType.youtube,
      platformContentId: 'pnTHROHlpCU',
      title: 'Funniest Moments Compilation — Vol. 12',
      description:
          'The best funny moments, fails, and unexpected clips from the past month. Hand-curated for maximum laughs.',
      videoUrl: 'https://www.youtube.com/embed/pnTHROHlpCU',
      thumbnailUrl: 'https://img.youtube.com/vi/pnTHROHlpCU/maxresdefault.jpg',
      creatorName: 'FailArmy',
      durationSeconds: 720,
      viewCount: 12000000,
      likeCount: 520000,
      publishedAt: DateTime.now().subtract(Duration(days: 4)),
      tags: ['funny', 'comedy', 'humor', 'fails', 'viral'],
      categories: ['Comedy'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 4)),
      updatedAt: DateTime.now().subtract(Duration(days: 4)),
    ),
    Content(
      id: 'yt_extra_010',
      platform: PlatformType.youtube,
      platformContentId: 'jNQXAC9IVRw',
      title: 'Me at the Zoo — The First YouTube Video (2005)',
      description:
          'The very first video ever uploaded to YouTube, posted by co-founder Jawed Karim on April 23, 2005 at the San Diego Zoo.',
      videoUrl: 'https://www.youtube.com/embed/jNQXAC9IVRw',
      thumbnailUrl: 'https://img.youtube.com/vi/jNQXAC9IVRw/maxresdefault.jpg',
      creatorName: 'jawed',
      durationSeconds: 19,
      viewCount: 310000000,
      likeCount: 3800000,
      publishedAt: DateTime.now().subtract(Duration(days: 365 * 19)),
      tags: ['youtube', 'history', 'classic', 'viral', 'trending'],
      categories: ['Education'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(days: 365 * 19)),
      updatedAt: DateTime.now().subtract(Duration(days: 1)),
    ),

    // ── Extra TikTok ──────────────────────────────────────────────────────────
    Content(
      id: 'tt_extra_001',
      platform: PlatformType.tiktok,
      platformContentId: 'tiktok_viral_001',
      title: 'Dance Challenge: Everybody\'s Doing It',
      description:
          'The dance trend taking over TikTok right now 💃 #dance #viral #trending #fyp #challenge',
      videoUrl: null,
      thumbnailUrl: null,
      creatorName: 'charli_d_amelio',
      durationSeconds: 30,
      viewCount: 85000000,
      likeCount: 7200000,
      publishedAt: DateTime.now().subtract(Duration(hours: 3)),
      tags: ['dance', 'viral', 'trending', 'challenge', 'fyp'],
      categories: ['Dance'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(hours: 3)),
      updatedAt: DateTime.now().subtract(Duration(hours: 3)),
    ),
    Content(
      id: 'tt_extra_002',
      platform: PlatformType.tiktok,
      platformContentId: 'tiktok_viral_002',
      title: '3-Ingredient Chocolate Mousse That Takes 5 Minutes',
      description:
          'No eggs, no cream — this chocolate mousse uses a genius trick 🍫✨ #cooking #recipe #food #foodtok #viral',
      videoUrl: null,
      thumbnailUrl: null,
      creatorName: 'nini_cooks',
      durationSeconds: 45,
      viewCount: 22000000,
      likeCount: 1800000,
      publishedAt: DateTime.now().subtract(Duration(hours: 9)),
      tags: ['cooking', 'recipe', 'food', 'dessert', 'viral'],
      categories: ['Food'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(hours: 9)),
      updatedAt: DateTime.now().subtract(Duration(hours: 9)),
    ),
    Content(
      id: 'tt_extra_003',
      platform: PlatformType.tiktok,
      platformContentId: 'tiktok_viral_003',
      title: 'Hack: Fold a Fitted Sheet Perfectly Every Time',
      description:
          'I cannot believe this works 😭 Never struggling with fitted sheets again #lifehacks #tips #home #viral #fyp',
      videoUrl: null,
      thumbnailUrl: null,
      creatorName: 'home_hacks_daily',
      durationSeconds: 38,
      viewCount: 47000000,
      likeCount: 3900000,
      publishedAt: DateTime.now().subtract(Duration(hours: 15)),
      tags: ['lifehacks', 'tips', 'home', 'viral', 'useful'],
      categories: ['Education'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(hours: 15)),
      updatedAt: DateTime.now().subtract(Duration(hours: 15)),
    ),
    Content(
      id: 'tt_extra_004',
      platform: PlatformType.tiktok,
      platformContentId: 'tiktok_viral_004',
      title: 'POV: You\'re a Barista and a Customer Orders This',
      description:
          'The most chaotic coffee order I\'ve ever received 😂 #comedy #barista #funny #relatable #fyp',
      videoUrl: null,
      thumbnailUrl: null,
      creatorName: 'coffeeshop_confessions',
      durationSeconds: 28,
      viewCount: 31000000,
      likeCount: 2600000,
      publishedAt: DateTime.now().subtract(Duration(hours: 6)),
      tags: ['comedy', 'funny', 'humor', 'relatable', 'barista'],
      categories: ['Comedy'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(hours: 6)),
      updatedAt: DateTime.now().subtract(Duration(hours: 6)),
    ),
    Content(
      id: 'tt_extra_005',
      platform: PlatformType.tiktok,
      platformContentId: 'tiktok_viral_005',
      title: 'The Most Satisfying Cake Decorating You\'ll See Today',
      description:
          'Butter cream roses that look too good to eat 🌹🎂 #cooking #cake #food #satisfying #fyp',
      videoUrl: null,
      thumbnailUrl: null,
      creatorName: 'cake_art_studio',
      durationSeconds: 55,
      viewCount: 18000000,
      likeCount: 1500000,
      publishedAt: DateTime.now().subtract(Duration(hours: 22)),
      tags: ['cooking', 'food', 'cake', 'satisfying', 'art'],
      categories: ['Food'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(hours: 22)),
      updatedAt: DateTime.now().subtract(Duration(hours: 22)),
    ),
    Content(
      id: 'tt_extra_006',
      platform: PlatformType.tiktok,
      platformContentId: 'tiktok_viral_006',
      title: 'How to Actually Fall Asleep in 2 Minutes',
      description:
          'The military sleep technique that works every time 😴 #lifehacks #tips #health #sleep #fyp',
      videoUrl: null,
      thumbnailUrl: null,
      creatorName: 'wellness_with_kay',
      durationSeconds: 40,
      viewCount: 62000000,
      likeCount: 5100000,
      publishedAt: DateTime.now().subtract(Duration(hours: 30)),
      tags: ['lifehacks', 'tips', 'health', 'wellness', 'sleep'],
      categories: ['Education'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(hours: 30)),
      updatedAt: DateTime.now().subtract(Duration(hours: 30)),
    ),
    Content(
      id: 'tt_extra_007',
      platform: PlatformType.tiktok,
      platformContentId: 'tiktok_viral_007',
      title: 'Thrift Flip: £3 Charity Shop Find to Designer Look',
      description:
          'Turning a £3 charity shop blazer into something designer-looking 🔥 #fashion #thrift #diy #style #fyp',
      videoUrl: null,
      thumbnailUrl: null,
      creatorName: 'thrift_queen_uk',
      durationSeconds: 52,
      viewCount: 9800000,
      likeCount: 820000,
      publishedAt: DateTime.now().subtract(Duration(days: 2)),
      tags: ['fashion', 'thrift', 'style', 'diy', 'trending'],
      categories: ['Fashion'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(days: 2)),
      updatedAt: DateTime.now().subtract(Duration(days: 2)),
    ),
    Content(
      id: 'tt_extra_008',
      platform: PlatformType.tiktok,
      platformContentId: 'tiktok_viral_008',
      title: 'NFL Player Reacts to Fan\'s Amazing Throw',
      description:
          'This fan has a better arm than half the league 😳🏈 #sports #nfl #football #viral #fyp',
      videoUrl: null,
      thumbnailUrl: null,
      creatorName: 'nfl_clips_official',
      durationSeconds: 24,
      viewCount: 38000000,
      likeCount: 3200000,
      publishedAt: DateTime.now().subtract(Duration(hours: 5)),
      tags: ['sports', 'nfl', 'football', 'viral', 'trending'],
      categories: ['Sports'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(hours: 5)),
      updatedAt: DateTime.now().subtract(Duration(hours: 5)),
    ),
    Content(
      id: 'tt_extra_009',
      platform: PlatformType.tiktok,
      platformContentId: 'tiktok_viral_009',
      title: 'The Correct Way to Brush Your Teeth (You\'re Doing It Wrong)',
      description:
          'A dentist breaks down the one technique most people get wrong 🦷 #health #lifehacks #tips #fyp',
      videoUrl: null,
      thumbnailUrl: null,
      creatorName: 'dr_tooth_truth',
      durationSeconds: 35,
      viewCount: 25000000,
      likeCount: 2100000,
      publishedAt: DateTime.now().subtract(Duration(hours: 12)),
      tags: ['health', 'tips', 'lifehacks', 'education', 'viral'],
      categories: ['Education'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(hours: 12)),
      updatedAt: DateTime.now().subtract(Duration(hours: 12)),
    ),
    Content(
      id: 'tt_extra_010',
      platform: PlatformType.tiktok,
      platformContentId: 'tiktok_viral_010',
      title: 'Dog Sees Its Reflection for the First Time',
      description:
          'The funniest confused dog in the universe 🐶😂 #pets #dogs #animals #cute #fyp #viral',
      videoUrl: null,
      thumbnailUrl: null,
      creatorName: 'barkingwithbiscuit',
      durationSeconds: 22,
      viewCount: 71000000,
      likeCount: 5900000,
      publishedAt: DateTime.now().subtract(Duration(hours: 2)),
      tags: ['pets', 'dogs', 'animals', 'cute', 'funny'],
      categories: ['Pets'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(hours: 2)),
      updatedAt: DateTime.now().subtract(Duration(hours: 2)),
    ),

    // ── Extra Instagram Reels ─────────────────────────────────────────────────
    Content(
      id: 'ig_extra_001',
      platform: PlatformType.instagram,
      platformContentId: 'ig_reel_001',
      title: 'Coastal Grandmother Aesthetic — Full Outfit Breakdown',
      description:
          'Linen, neutrals, and effortless elegance 🌊 #fashion #style #outfits #aesthetic #reels',
      videoUrl: null,
      thumbnailUrl: null,
      creatorName: 'grace_style_diary',
      durationSeconds: 42,
      viewCount: 5400000,
      likeCount: 440000,
      publishedAt: DateTime.now().subtract(Duration(hours: 10)),
      tags: ['fashion', 'style', 'outfits', 'aesthetic', 'trends'],
      categories: ['Fashion'],
      contentType: ContentType.reel,
      createdAt: DateTime.now().subtract(Duration(hours: 10)),
      updatedAt: DateTime.now().subtract(Duration(hours: 10)),
    ),
    Content(
      id: 'ig_extra_002',
      platform: PlatformType.instagram,
      platformContentId: 'ig_reel_002',
      title: '60-Second Sourdough Starter Guide',
      description:
          'Everything you need to start your sourdough journey in under a minute 🍞 #cooking #recipe #bread #sourdough',
      videoUrl: null,
      thumbnailUrl: null,
      creatorName: 'the_bread_lab',
      durationSeconds: 60,
      viewCount: 3200000,
      likeCount: 267000,
      publishedAt: DateTime.now().subtract(Duration(days: 1)),
      tags: ['cooking', 'recipe', 'bread', 'food', 'baking'],
      categories: ['Food'],
      contentType: ContentType.reel,
      createdAt: DateTime.now().subtract(Duration(days: 1)),
      updatedAt: DateTime.now().subtract(Duration(days: 1)),
    ),
    Content(
      id: 'ig_extra_003',
      platform: PlatformType.instagram,
      platformContentId: 'ig_reel_003',
      title: 'Sunrise Hike in Patagonia — Worth It?',
      description:
          '4am start, 3 hours of climbing, and THIS view 🏔️ #travel #adventure #patagonia #nature #hiking',
      videoUrl: null,
      thumbnailUrl: null,
      creatorName: 'trails_and_tales',
      durationSeconds: 55,
      viewCount: 7100000,
      likeCount: 590000,
      publishedAt: DateTime.now().subtract(Duration(hours: 18)),
      tags: ['travel', 'adventure', 'nature', 'hiking', 'outdoors'],
      categories: ['Travel', 'Nature'],
      contentType: ContentType.reel,
      createdAt: DateTime.now().subtract(Duration(hours: 18)),
      updatedAt: DateTime.now().subtract(Duration(hours: 18)),
    ),
    Content(
      id: 'ig_extra_004',
      platform: PlatformType.instagram,
      platformContentId: 'ig_reel_004',
      title: 'How I Painted My Kitchen Cabinets for £80',
      description:
          'Full transformation — old oak cabinets to a modern sage green finish 🌿 #diy #home #crafts #interior #reels',
      videoUrl: null,
      thumbnailUrl: null,
      creatorName: 'budget_interiors_uk',
      durationSeconds: 58,
      viewCount: 4600000,
      likeCount: 385000,
      publishedAt: DateTime.now().subtract(Duration(days: 3)),
      tags: ['diy', 'home', 'crafts', 'interior', 'projects'],
      categories: ['DIY'],
      contentType: ContentType.reel,
      createdAt: DateTime.now().subtract(Duration(days: 3)),
      updatedAt: DateTime.now().subtract(Duration(days: 3)),
    ),
    Content(
      id: 'ig_extra_005',
      platform: PlatformType.instagram,
      platformContentId: 'ig_reel_005',
      title: 'Piano Cover: Flowers by Miley Cyrus',
      description:
          'My original piano arrangement of Flowers 🎹🌸 Sheet music in bio. #music #piano #songs #artists #cover',
      videoUrl: null,
      thumbnailUrl: null,
      creatorName: 'keys_and_melody',
      durationSeconds: 48,
      viewCount: 8900000,
      likeCount: 740000,
      publishedAt: DateTime.now().subtract(Duration(hours: 16)),
      tags: ['music', 'piano', 'songs', 'artists', 'cover'],
      categories: ['Music'],
      contentType: ContentType.reel,
      createdAt: DateTime.now().subtract(Duration(hours: 16)),
      updatedAt: DateTime.now().subtract(Duration(hours: 16)),
    ),
    Content(
      id: 'ig_extra_006',
      platform: PlatformType.instagram,
      platformContentId: 'ig_reel_006',
      title: 'Full Body Stretch Routine for Desk Workers',
      description:
          '10-minute full body stretch routine — do this every morning if you sit at a desk all day 💪 #fitness #workout #health #stretch',
      videoUrl: null,
      thumbnailUrl: null,
      creatorName: 'physio_with_emma',
      durationSeconds: 50,
      viewCount: 11200000,
      likeCount: 930000,
      publishedAt: DateTime.now().subtract(Duration(hours: 8)),
      tags: ['fitness', 'workout', 'health', 'stretch', 'exercise'],
      categories: ['Fitness'],
      contentType: ContentType.reel,
      createdAt: DateTime.now().subtract(Duration(hours: 8)),
      updatedAt: DateTime.now().subtract(Duration(hours: 8)),
    ),
    Content(
      id: 'ig_extra_007',
      platform: PlatformType.instagram,
      platformContentId: 'ig_reel_007',
      title: 'Abstract Fluid Art in Slow Motion',
      description:
          'Watching acrylic paint cells form in slow motion is genuinely therapeutic 🎨 #art #painting #satisfying #creative',
      videoUrl: null,
      thumbnailUrl: null,
      creatorName: 'fluid_art_collective',
      durationSeconds: 38,
      viewCount: 16000000,
      likeCount: 1340000,
      publishedAt: DateTime.now().subtract(Duration(hours: 20)),
      tags: ['art', 'painting', 'satisfying', 'creative', 'drawing'],
      categories: ['Art'],
      contentType: ContentType.reel,
      createdAt: DateTime.now().subtract(Duration(hours: 20)),
      updatedAt: DateTime.now().subtract(Duration(hours: 20)),
    ),
    Content(
      id: 'ig_extra_008',
      platform: PlatformType.instagram,
      platformContentId: 'ig_reel_008',
      title: 'Capybara Befriends Every Animal at the Zoo',
      description:
          'Capybaras being universally loved by all species once again 🦆🐊🐾 #pets #animals #capybara #cute #nature',
      videoUrl: null,
      thumbnailUrl: null,
      creatorName: 'zoolife_official',
      durationSeconds: 30,
      viewCount: 42000000,
      likeCount: 3500000,
      publishedAt: DateTime.now().subtract(Duration(hours: 4)),
      tags: ['animals', 'pets', 'nature', 'cute', 'wildlife'],
      categories: ['Pets', 'Nature'],
      contentType: ContentType.reel,
      createdAt: DateTime.now().subtract(Duration(hours: 4)),
      updatedAt: DateTime.now().subtract(Duration(hours: 4)),
    ),
    Content(
      id: 'ig_extra_009',
      platform: PlatformType.instagram,
      platformContentId: 'ig_reel_009',
      title: 'Gordon Ramsay Rates My Scrambled Eggs',
      description:
          'I made Gordon Ramsay\'s scrambled eggs recipe and asked him to critique them. His response... 🍳😬 #cooking #food #gordonramsay #funny',
      videoUrl: null,
      thumbnailUrl: null,
      creatorName: 'cooking_with_confidence',
      durationSeconds: 55,
      viewCount: 6300000,
      likeCount: 525000,
      publishedAt: DateTime.now().subtract(Duration(days: 2)),
      tags: ['cooking', 'food', 'recipe', 'funny', 'comedy'],
      categories: ['Food', 'Comedy'],
      contentType: ContentType.reel,
      createdAt: DateTime.now().subtract(Duration(days: 2)),
      updatedAt: DateTime.now().subtract(Duration(days: 2)),
    ),
    Content(
      id: 'ig_extra_010',
      platform: PlatformType.instagram,
      platformContentId: 'ig_reel_010',
      title: 'Night Sky Timelapse: Milky Way Over the Sahara',
      description:
          'Shot over 6 hours in the Sahara Desert with a Sony A7S III 🌌✨ The stars moved more than I expected. #photography #nature #space #timelapse',
      videoUrl: null,
      thumbnailUrl: null,
      creatorName: 'astrophoto_nomad',
      durationSeconds: 45,
      viewCount: 19000000,
      likeCount: 1580000,
      publishedAt: DateTime.now().subtract(Duration(hours: 26)),
      tags: ['photography', 'nature', 'space', 'science', 'timelapse'],
      categories: ['Photography', 'Nature'],
      contentType: ContentType.reel,
      createdAt: DateTime.now().subtract(Duration(hours: 26)),
      updatedAt: DateTime.now().subtract(Duration(hours: 26)),
    ),

    // ── Extra Facebook Watch ──────────────────────────────────────────────────
    Content(
      id: 'fb_extra_001',
      platform: PlatformType.facebook,
      platformContentId: 'fb_watch_001',
      title: 'Inside the World\'s Largest Vertical Farm',
      description:
          'A behind-the-scenes look at a 10-storey vertical farm in Singapore growing 1,000 tonnes of leafy greens per year without sunlight or soil.',
      videoUrl: null,
      thumbnailUrl: null,
      creatorName: 'Future Food',
      durationSeconds: 1320,
      viewCount: 4200000,
      likeCount: 195000,
      publishedAt: DateTime.now().subtract(Duration(days: 7)),
      tags: ['science', 'food', 'environment', 'tech', 'agriculture'],
      categories: ['Education', 'Technology'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 7)),
      updatedAt: DateTime.now().subtract(Duration(days: 7)),
    ),
    Content(
      id: 'fb_extra_002',
      platform: PlatformType.facebook,
      platformContentId: 'fb_watch_002',
      title: 'Family Road Trip: UK Coast to Coast in 7 Days',
      description:
          'We drove from Whitehaven to Robin Hood\'s Bay — the full 192-mile coast to coast — as a family. Campsites, pubs, sheep, and blisters.',
      videoUrl: null,
      thumbnailUrl: null,
      creatorName: 'The Hartley Family',
      durationSeconds: 2400,
      viewCount: 1800000,
      likeCount: 87000,
      publishedAt: DateTime.now().subtract(Duration(days: 14)),
      tags: ['travel', 'adventure', 'family', 'uk', 'hiking'],
      categories: ['Travel'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 14)),
      updatedAt: DateTime.now().subtract(Duration(days: 14)),
    ),
    Content(
      id: 'fb_extra_003',
      platform: PlatformType.facebook,
      platformContentId: 'fb_watch_003',
      title: 'Community Football Match: Kids vs Parents',
      description:
          'Annual charity match where the kids take on the parents at Wembley Park FC. The score will surprise you ⚽😂',
      videoUrl: null,
      thumbnailUrl: null,
      creatorName: 'Local Sports Network',
      durationSeconds: 1800,
      viewCount: 620000,
      likeCount: 45000,
      publishedAt: DateTime.now().subtract(Duration(days: 5)),
      tags: ['sports', 'football', 'soccer', 'community', 'funny'],
      categories: ['Sports', 'Comedy'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 5)),
      updatedAt: DateTime.now().subtract(Duration(days: 5)),
    ),
    Content(
      id: 'fb_extra_004',
      platform: PlatformType.facebook,
      platformContentId: 'fb_watch_004',
      title: 'How Japan\'s Bullet Trains Are Always On Time',
      description:
          'The obsessive engineering, cultural attitudes, and dedicated workforce that keep Japan\'s Shinkansen network running to within 36-second average delays.',
      videoUrl: null,
      thumbnailUrl: null,
      creatorName: 'Engineering Explained',
      durationSeconds: 1560,
      viewCount: 6100000,
      likeCount: 285000,
      publishedAt: DateTime.now().subtract(Duration(days: 10)),
      tags: ['science', 'tech', 'engineering', 'japan', 'trains'],
      categories: ['Education', 'Technology'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 10)),
      updatedAt: DateTime.now().subtract(Duration(days: 10)),
    ),
    Content(
      id: 'fb_extra_005',
      platform: PlatformType.facebook,
      platformContentId: 'fb_watch_005',
      title: 'Rescue Mission: Stranded Whale on Norfolk Beach',
      description:
          'A team of 40 volunteers spent 8 hours keeping a stranded minke whale hydrated before successfully guiding it back to sea off the Norfolk coast.',
      videoUrl: null,
      thumbnailUrl: null,
      creatorName: 'British Wildlife Trust',
      durationSeconds: 960,
      viewCount: 9800000,
      likeCount: 620000,
      publishedAt: DateTime.now().subtract(Duration(days: 3)),
      tags: ['nature', 'wildlife', 'animals', 'environment', 'ocean'],
      categories: ['Nature'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 3)),
      updatedAt: DateTime.now().subtract(Duration(days: 3)),
    ),
    Content(
      id: 'fb_extra_006',
      platform: PlatformType.facebook,
      platformContentId: 'fb_watch_006',
      title: 'A Day in the Life: NHS Emergency Room Doctor',
      description:
          '24 hours following a senior A&E consultant through a busy weekend shift. Raw, emotional, and inspiring — a tribute to NHS staff everywhere.',
      videoUrl: null,
      thumbnailUrl: null,
      creatorName: 'NHS Stories',
      durationSeconds: 2700,
      viewCount: 3400000,
      likeCount: 198000,
      publishedAt: DateTime.now().subtract(Duration(days: 8)),
      tags: ['education', 'health', 'nhs', 'documentary', 'inspiring'],
      categories: ['Education'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 8)),
      updatedAt: DateTime.now().subtract(Duration(days: 8)),
    ),
    Content(
      id: 'fb_extra_007',
      platform: PlatformType.facebook,
      platformContentId: 'fb_watch_007',
      title: 'Tiny House Build Timelapse — From Foundation to Finished',
      description:
          'A complete 280 sq ft tiny house built in 12 weeks, condensed into 8 minutes. Every stage of construction from the ground up.',
      videoUrl: null,
      thumbnailUrl: null,
      creatorName: 'Tiny Living Movement',
      durationSeconds: 480,
      viewCount: 7300000,
      likeCount: 340000,
      publishedAt: DateTime.now().subtract(Duration(days: 11)),
      tags: ['diy', 'home', 'crafts', 'projects', 'architecture'],
      categories: ['DIY'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 11)),
      updatedAt: DateTime.now().subtract(Duration(days: 11)),
    ),
    Content(
      id: 'fb_extra_008',
      platform: PlatformType.facebook,
      platformContentId: 'fb_watch_008',
      title: 'MrBeast: I Gave Away £1,000,000 to Strangers',
      description:
          'Walking up to random people in a shopping centre and handing them envelopes — they don\'t know what\'s inside until they open it.',
      videoUrl: null,
      thumbnailUrl: null,
      creatorName: 'MrBeast',
      durationSeconds: 900,
      viewCount: 78000000,
      likeCount: 4200000,
      publishedAt: DateTime.now().subtract(Duration(days: 4)),
      tags: ['comedy', 'viral', 'trending', 'funny', 'charity'],
      categories: ['Comedy'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 4)),
      updatedAt: DateTime.now().subtract(Duration(days: 4)),
    ),
    Content(
      id: 'fb_extra_009',
      platform: PlatformType.facebook,
      platformContentId: 'fb_watch_009',
      title: 'Veritasium: The Illusion of Certainty',
      description:
          'Why experts are often wrong — and what that means for how we should think about knowledge, confidence, and decision-making.',
      videoUrl: null,
      thumbnailUrl: null,
      creatorName: 'Veritasium',
      durationSeconds: 1740,
      viewCount: 11000000,
      likeCount: 510000,
      publishedAt: DateTime.now().subtract(Duration(days: 16)),
      tags: ['science', 'education', 'philosophy', 'learning', 'knowledge'],
      categories: ['Education'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 16)),
      updatedAt: DateTime.now().subtract(Duration(days: 16)),
    ),
    Content(
      id: 'fb_extra_010',
      platform: PlatformType.facebook,
      platformContentId: 'fb_watch_010',
      title: 'Linus Tech Tips: We Tested Every Gaming Monitor',
      description:
          'We bought 47 gaming monitors ranging from £100 to £2,500 and tested every single one. Here\'s what we found out about refresh rates, panels, and value.',
      videoUrl: null,
      thumbnailUrl: null,
      creatorName: 'Linus Tech Tips',
      durationSeconds: 2160,
      viewCount: 8500000,
      likeCount: 392000,
      publishedAt: DateTime.now().subtract(Duration(days: 9)),
      tags: ['tech', 'gaming', 'hardware', 'tutorial', 'review'],
      categories: ['Technology', 'Gaming'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 9)),
      updatedAt: DateTime.now().subtract(Duration(days: 9)),
    ),
  ];

  // Live content fetched from YouTube (primary source)
  List<Content> _liveContent = [];

  /// Call once at app startup.
  /// Priority: local API server → youtube_explode_dart → seed data.
  Future<void> initialize() async {
    // 1. Try local API backend first (the "local MCP environment")
    try {
      final apiSvc = ApiContentService.instance;
      final available = await apiSvc.checkHealth();
      if (available) {
        final apiItems = await apiSvc.getFeed(limit: 50);
        if (apiItems.isNotEmpty) {
          _liveContent = apiItems;
          if (kDebugMode)
            debugPrint(
              'ContentService: ${_liveContent.length} items from local API',
            );
          return;
        }
      }
    } catch (e) {
      if (kDebugMode)
        debugPrint(
          'ContentService: local API unavailable ($e), trying YouTube',
        );
    }

    // NOTE: youtube_explode_dart scraping is disabled — it violates YouTube's
    // Developer ToS ("API Clients must not scrape YouTube Applications").
    // Fall through to seed data until YouTube Data API v3 integration is complete.
    if (kDebugMode)
      debugPrint(
        'ContentService: using seed data (YouTube Data API v3 not yet configured)',
      );
  }

  /// Force-refresh live content (call from pull-to-refresh).
  Future<void> refreshContent() async {
    // Prefer local API, fall back to YouTube
    try {
      if (ApiContentService.instance.isAvailable) {
        final items = await ApiContentService.instance.getFeed(limit: 50);
        if (items.isNotEmpty) {
          _liveContent = items;
          return;
        }
      }
    } catch (e) {
      debugPrint('ContentService refresh API error: $e');
    }
    // youtube_explode_dart disabled — see initialize() note above
  }

  /// Primary pool: live data when available, seed data otherwise.
  List<Content> get _allContent =>
      _liveContent.isNotEmpty ? _liveContent : _sampleVideos;

  // Ensure every content item has a creatorId for follow functionality
  List<Content> _withCreatorIds(List<Content> items) {
    return items.map((c) {
      if (c.creatorId != null) return c;
      final id =
          c.creatorName?.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_') ??
          'unknown';
      return c.copyWith(creatorId: id);
    }).toList();
  }

  Future<List<Content>> getVideos({
    PlatformType? platform,
    String? category,
    int limit = 10,
  }) async {
    List<Content> filteredVideos = List.from(_allContent);

    // Filter by platform if specified
    if (platform != null) {
      filteredVideos = filteredVideos
          .where((video) => video.platform == platform)
          .toList();
    }

    // Filter by category/tags if specified
    if (category != null && category.isNotEmpty) {
      filteredVideos = filteredVideos
          .where(
            (video) => video.tags.any(
              (tag) => tag.toLowerCase().contains(category.toLowerCase()),
            ),
          )
          .toList();
    }

    // Shuffle for variety
    filteredVideos.shuffle(Random());

    // Limit results
    return _withCreatorIds(filteredVideos.take(limit).toList());
  }

  /// Returns trending content scored by engagement-velocity (X/Twitter-inspired):
  /// score = engagement / (ageHours^0.8 + 1)  — rewards high-engagement recent content.
  /// [timeWindow]: 'today' (24h) | '7d' | '30d' | '60d' | '1y' | 'all'
  Future<List<Content>> getTrendingVideos({
    int limit = 20,
    String timeWindow = '7d',
  }) async {
    final now = DateTime.now();
    final cutoff = _trendingCutoff(now, timeWindow);

    List<Content> candidates = _allContent.where((c) {
      if (cutoff == null) return true;
      final pub = c.publishedAt ?? c.createdAt;
      return pub.isAfter(cutoff);
    }).toList();

    // Fallback: if window too narrow, use all content
    if (candidates.length < 5) candidates = List.from(_allContent);

    candidates.sort(
      (a, b) => _velocityScore(b, now).compareTo(_velocityScore(a, now)),
    );
    return _withCreatorIds(candidates.take(limit).toList());
  }

  DateTime? _trendingCutoff(DateTime now, String window) {
    switch (window) {
      case 'today':
        return now.subtract(const Duration(hours: 24));
      case '7d':
        return now.subtract(const Duration(days: 7));
      case '30d':
        return now.subtract(const Duration(days: 30));
      case '60d':
        return now.subtract(const Duration(days: 60));
      case '1y':
        return now.subtract(const Duration(days: 365));
      case 'all':
        return null;
      default:
        return now.subtract(const Duration(days: 7));
    }
  }

  /// Engagement-velocity: high engagement + recency → high score.
  double _velocityScore(Content c, DateTime now) {
    final pub = c.publishedAt ?? c.createdAt;
    final ageHours = now.difference(pub).inMinutes / 60.0;
    final engagement = c.viewCount * 0.1 + c.likeCount * 2.0;
    return engagement / ((ageHours + 1.0).clamp(1.0, double.infinity) * 0.8);
  }

  // Get videos by category
  Future<List<Content>> getVideosByCategory(
    String category, {
    int limit = 10,
  }) async {
    return getVideos(category: category, limit: limit);
  }

  Future<List<Content>> searchVideos(String query, {int limit = 10}) async {
    if (query.isEmpty) return [];

    // First check local content
    final q = query.toLowerCase();
    List<Content> localResults = _allContent
        .where(
          (video) =>
              video.title?.toLowerCase().contains(q) == true ||
              video.description?.toLowerCase().contains(q) == true ||
              video.creatorName?.toLowerCase().contains(q) == true ||
              video.tags.any((tag) => tag.toLowerCase().contains(q)),
        )
        .toList();

    if (localResults.length >= limit) {
      return _withCreatorIds(localResults.take(limit).toList());
    }

    // Supplement with API/YouTube search if local results are thin
    try {
      final apiSvc = ApiContentService.instance;
      if (apiSvc.isAvailable) {
        final apiResults = await apiSvc.search(
          query,
          limit: limit - localResults.length,
        );
        final existingIds = localResults
            .map((c) => c.platformContentId)
            .toSet();
        localResults = [
          ...localResults,
          ...apiResults.where(
            (c) => !existingIds.contains(c.platformContentId),
          ),
        ];
      }
      // youtube_explode_dart search disabled — local seed results only
    } catch (e) {
      debugPrint('ContentService search supplement error: $e');
    }

    return _withCreatorIds(localResults.take(limit).toList());
  }

  Future<Content?> getVideoById(String id) async {
    try {
      return _allContent.firstWhere((video) => video.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<List<Content>> getRecommendedVideos(
    String videoId, {
    int limit = 5,
  }) async {
    Content? currentVideo = await getVideoById(videoId);
    if (currentVideo == null) return [];

    List<Content> recommended = _allContent
        .where(
          (video) =>
              video.id != videoId &&
              video.tags.any((tag) => currentVideo.tags.contains(tag)),
        )
        .toList();

    if (recommended.length < limit) {
      List<Content> remaining = _allContent
          .where((video) => video.id != videoId && !recommended.contains(video))
          .toList();
      remaining.shuffle(Random());
      recommended.addAll(remaining.take(limit - recommended.length));
    }

    recommended.shuffle(Random());
    return recommended.take(limit).toList();
  }

  /// Reads the user's preferred locale code (e.g. 'hi', 'es') from
  /// SharedPreferences.  Returns null when the preference has not been set or
  /// when the value is 'en' (English), so callers can treat null as
  /// "no non-English preference active".
  static Future<String?> _getUserLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final locale = prefs.getString('app_locale');
    if (locale == null || locale.isEmpty || locale == 'en') return null;
    return locale;
  }

  /// Applies a locale-awareness sort to [items]:
  ///   - Content whose [Content.language] matches [userLocale] → boosted to front.
  ///   - Content with no language tag (null) → treated as language-neutral,
  ///     kept in their current order (covers all English seed data gracefully).
  ///   - Content explicitly tagged with a *different* language → sorted to back.
  ///
  /// When [userLocale] is null the list is returned unchanged.
  static List<Content> _applyLocaleBoost(
    List<Content> items,
    String? userLocale,
  ) {
    if (userLocale == null || items.isEmpty) return items;

    // Stable partition: matching → neutral → non-matching.
    final matching = <Content>[];
    final neutral = <Content>[];
    final nonMatch = <Content>[];

    for (final item in items) {
      final lang = item.language?.toLowerCase().trim();
      if (lang == null || lang.isEmpty) {
        neutral.add(item);
      } else if (lang == userLocale.toLowerCase()) {
        matching.add(item);
      } else {
        nonMatch.add(item);
      }
    }

    return [...matching, ...neutral, ...nonMatch];
  }

  Future<List<Content>> getFeedContent({int limit = 10}) async {
    try {
      final userLocale = await _getUserLocale();

      List<Content> feedContent = List.from(_allContent);
      feedContent.shuffle(Random());

      feedContent = _applyLocaleBoost(feedContent, userLocale);
      final result = _withCreatorIds(feedContent.take(limit).toList());

      // Persist IDs for offline fallback
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _feedCacheKey,
        result.map((c) => c.id).toList(),
      );
      await prefs.setInt(
        '${_feedCacheKey}_ts',
        DateTime.now().millisecondsSinceEpoch,
      );

      return result;
    } catch (e) {
      if (kDebugMode) debugPrint('getFeedContent error, loading cache: $e');
      final prefs = await SharedPreferences.getInstance();
      final cachedIds = prefs.getStringList(_feedCacheKey);
      if (cachedIds != null && cachedIds.isNotEmpty) {
        final cached = cachedIds
            .map(
              (id) => _allContent.firstWhere(
                (c) => c.id == id,
                orElse: () => _allContent.first,
              ),
            )
            .take(limit)
            .toList();
        if (cached.isNotEmpty) return _withCreatorIds(cached);
      }
      rethrow;
    }
  }

  Future<List<Content>> loadMoreContent(int offset, {int limit = 10}) async {
    List<Content> allContent = List.from(_allContent);
    List<Content> moreContent = [];

    for (int i = 0; i < limit; i++) {
      int index = (offset + i) % allContent.length;
      Content content = allContent[index];
      // Create a copy with modified data to simulate new content
      moreContent.add(
        content.copyWith(
          id: '${content.id}_${offset + i}',
          publishedAt: DateTime.now().subtract(Duration(hours: offset + i)),
        ),
      );
    }

    return moreContent;
  }

  // Get personalized content based on onboarding preferences
  Future<List<Content>> getPersonalizedContent({int limit = 10}) async {
    try {
      final enhancedService = EnhancedRecommendationService.instance;
      final onboardingService = OnboardingService();
      final authService = AuthService.instance;

      // Load locale preference once and reuse for the boost step.
      final userLocale = await _getUserLocale();

      // Check if user is authenticated
      final user = authService.currentUser;
      if (user == null) {
        // Return general trending content for unauthenticated users
        final trending = await getTrendingVideos(limit: limit);
        return _applyLocaleBoost(trending, userLocale);
      }

      // Check if onboarding is completed
      final isOnboardingCompleted = await onboardingService
          .isOnboardingCompleted();
      if (!isOnboardingCompleted) {
        // Return general content if onboarding not completed
        return getFeedContent(
          limit: limit,
        ); // getFeedContent already boosts locale
      }

      // Get personalized recommendations
      final recommendations = await enhancedService
          .getPersonalizedRecommendations(userId: user.id, limit: limit);

      // Convert recommendations to content objects then apply locale boost.
      final items = recommendations.map((rec) => rec.content).toList();
      return _applyLocaleBoost(items, userLocale);
    } catch (e) {
      if (kDebugMode) debugPrint('Error getting personalized content: $e');
      // Fallback to regular feed content (which already applies locale boost)
      return getFeedContent(limit: limit);
    }
  }

  // Get onboarding-based recommendations for new users
  Future<List<Content>> getOnboardingBasedRecommendations({
    int limit = 20,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedGenres =
          prefs.getStringList('onboarding_selected_genres') ?? [];
      final selectedPlatforms =
          prefs.getStringList('onboarding_connected_platforms') ?? [];

      // Read locale preference once for the scoring step.
      final userLocale = await _getUserLocale(); // null when English / unset

      if (selectedGenres.isEmpty) {
        return getFeedContent(
          limit: limit,
        ); // getFeedContent applies locale boost
      }

      // Score all content by genre match
      final scored = _allContent.map((c) {
        double score = 0.0;
        final contentTags = [
          ...c.tags,
          ...c.categories,
        ].join(' ').toLowerCase();
        for (final genre in selectedGenres) {
          if (contentTags.contains(genre.toLowerCase())) score += 1.5;
        }
        // Platform preference boost
        for (final platform in selectedPlatforms) {
          if (c.platform.name.toLowerCase() == platform.toLowerCase())
            score += 0.5;
        }
        // Recency boost
        if (c.publishedAt != null) {
          final ageHours = DateTime.now().difference(c.publishedAt!).inHours;
          if (ageHours < 72) score += 0.3;
        }
        // Language / locale boost: reward content tagged with the user's
        // preferred language; penalise content explicitly tagged with a
        // *different* language (null-language items are left neutral so that
        // English seed data is not penalised).
        if (userLocale != null) {
          final lang = c.language?.toLowerCase().trim();
          if (lang != null && lang.isNotEmpty) {
            if (lang == userLocale.toLowerCase()) {
              score += 1.0; // same language → boost
            } else {
              score -= 0.5; // different language → slight penalty
            }
          }
          // lang == null → no change (neutral; covers all English seed items)
        }
        return MapEntry(c, score);
      }).toList()..sort((a, b) => b.value.compareTo(a.value));

      // Diversity: max 4 items per platform
      final result = <Content>[];
      final platformCounts = <String, int>{};
      for (final entry in scored) {
        final platform = entry.key.platform.name;
        if ((platformCounts[platform] ?? 0) < 4) {
          result.add(entry.key);
          platformCounts[platform] = (platformCounts[platform] ?? 0) + 1;
        }
        if (result.length >= limit) break;
      }

      return result.isEmpty ? getFeedContent(limit: limit) : result;
    } catch (e) {
      debugPrint('getOnboardingBasedRecommendations error: $e');
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

      List<Content> filteredContent = List.from(_allContent);

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
        filteredContent = filteredContent
            .where((content) => content.platform == platform)
            .toList();
      }

      if (category != null && category.isNotEmpty) {
        filteredContent = filteredContent
            .where(
              (content) => content.tags.any(
                (tag) => tag.toLowerCase().contains(category.toLowerCase()),
              ),
            )
            .toList();
      }

      // Apply content preferences if available
      if (preferences != null && preferences.contentInterests.isNotEmpty) {
        filteredContent = filteredContent.where((content) {
          return content.tags.any(
            (tag) => preferences.contentInterests.any(
              (category) => tag.toLowerCase().contains(category.toLowerCase()),
            ),
          );
        }).toList();
      }

      return filteredContent.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting preference filtered content: $e');
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

      // Look up the content to pass its tags/categories as implicit learning signals
      final content = await getVideoById(contentId);
      final interactionData = <String, dynamic>{};
      if (watchTimeSeconds != null)
        interactionData['watchTimeSeconds'] = watchTimeSeconds;
      if (content != null) {
        interactionData['tags'] = content.tags;
        interactionData['categories'] = content.categories;
        interactionData['platform'] = content.platform.name;
      }

      final interaction = ContentInteraction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.id,
        contentId: contentId,
        interactionType: interactionType,
        interactionData: interactionData,
        createdAt: DateTime.now(),
      );

      await enhancedService.trackContentInteraction(interaction.toJson());
    } catch (e) {
      if (kDebugMode) debugPrint('Error tracking content interaction: $e');
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
      debugPrint('Error getting time-based recommendations: $e');
      return getFeedContent(limit: limit);
    }
  }
}
