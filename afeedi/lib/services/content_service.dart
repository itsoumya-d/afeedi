import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/content_model.dart';
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

    // Additional YouTube educational & entertainment content
    Content(
      id: 'yt_7',
      platform: PlatformType.youtube,
      platformContentId: 'aircAruvnKk',
      title: 'But what is a neural network?',
      description: 'The math of deep learning visualized — neurons, layers, and activation functions.',
      videoUrl: 'https://www.youtube.com/embed/aircAruvnKk',
      thumbnailUrl: 'https://img.youtube.com/vi/aircAruvnKk/mqdefault.jpg',
      creatorName: '3Blue1Brown',
      durationSeconds: 1918,
      viewCount: 15000000,
      likeCount: 410000,
      publishedAt: DateTime.now().subtract(Duration(days: 365 * 6)),
      tags: ['ai', 'neural-networks', 'deep-learning', 'math'],
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
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(days: 365 * 3)),
      updatedAt: DateTime.now().subtract(Duration(days: 14)),
    ),
    Content(
      id: 'yt_9',
      platform: PlatformType.youtube,
      platformContentId: 'x7X9w_GIm1s',
      title: 'Python in 100 Seconds',
      description: 'Everything you need to know about Python in under 2 minutes.',
      videoUrl: 'https://www.youtube.com/embed/x7X9w_GIm1s',
      thumbnailUrl: 'https://img.youtube.com/vi/x7X9w_GIm1s/mqdefault.jpg',
      creatorName: 'Fireship',
      durationSeconds: 115,
      viewCount: 3900000,
      likeCount: 162000,
      publishedAt: DateTime.now().subtract(Duration(days: 365 * 3)),
      tags: ['python', 'programming', '100seconds', 'beginner'],
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
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(days: 365 * 2)),
      updatedAt: DateTime.now().subtract(Duration(days: 7)),
    ),
    Content(
      id: 'yt_11',
      platform: PlatformType.youtube,
      platformContentId: 'vIRkjTMhFvs',
      title: 'Why Planes Don\'t Fly Over the Pacific',
      description: 'The surprising reason why transpacific flights avoid a straight path over the ocean.',
      videoUrl: 'https://www.youtube.com/embed/vIRkjTMhFvs',
      thumbnailUrl: 'https://img.youtube.com/vi/vIRkjTMhFvs/mqdefault.jpg',
      creatorName: 'Wendover Productions',
      durationSeconds: 912,
      viewCount: 10500000,
      likeCount: 287000,
      publishedAt: DateTime.now().subtract(Duration(days: 365 * 5)),
      tags: ['science', 'aviation', 'geography', 'education'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 365 * 5)),
      updatedAt: DateTime.now().subtract(Duration(days: 60)),
    ),
    Content(
      id: 'yt_12',
      platform: PlatformType.youtube,
      platformContentId: 'e-P5IFTqB98',
      title: 'Genetic Engineering Will Change Everything Forever',
      description: 'How CRISPR gene editing could eliminate disease and change what it means to be human.',
      videoUrl: 'https://www.youtube.com/embed/e-P5IFTqB98',
      thumbnailUrl: 'https://img.youtube.com/vi/e-P5IFTqB98/mqdefault.jpg',
      creatorName: 'Kurzgesagt',
      durationSeconds: 1623,
      viewCount: 24000000,
      likeCount: 680000,
      publishedAt: DateTime.now().subtract(Duration(days: 365 * 7)),
      tags: ['science', 'genetics', 'crispr', 'biology', 'education'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 365 * 7)),
      updatedAt: DateTime.now().subtract(Duration(days: 45)),
    ),
    Content(
      id: 'yt_13',
      platform: PlatformType.youtube,
      platformContentId: 'wjZofJX0v4M',
      title: 'The Entire History of the Universe',
      description: 'From the Big Bang to today — 13.8 billion years in one video.',
      videoUrl: 'https://www.youtube.com/embed/wjZofJX0v4M',
      thumbnailUrl: 'https://img.youtube.com/vi/wjZofJX0v4M/mqdefault.jpg',
      creatorName: 'Kurzgesagt',
      durationSeconds: 1920,
      viewCount: 18000000,
      likeCount: 520000,
      publishedAt: DateTime.now().subtract(Duration(days: 365 * 4)),
      tags: ['science', 'space', 'universe', 'education', 'history'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 365 * 4)),
      updatedAt: DateTime.now().subtract(Duration(days: 20)),
    ),
    Content(
      id: 'yt_14',
      platform: PlatformType.youtube,
      platformContentId: 'ZHwVBirqD2s',
      title: 'Advanced Flutter State Management',
      description: 'A deep dive into Riverpod, Bloc, and Provider patterns for large-scale Flutter apps.',
      videoUrl: 'https://www.youtube.com/embed/ZHwVBirqD2s',
      thumbnailUrl: 'https://img.youtube.com/vi/ZHwVBirqD2s/mqdefault.jpg',
      creatorName: 'Flutter Dev',
      durationSeconds: 2790,
      viewCount: 340000,
      likeCount: 18000,
      publishedAt: DateTime.now().subtract(Duration(days: 90)),
      tags: ['flutter', 'state-management', 'riverpod', 'bloc'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 90)),
      updatedAt: DateTime.now().subtract(Duration(days: 5)),
    ),
    Content(
      id: 'yt_15',
      platform: PlatformType.youtube,
      platformContentId: 'rdSJBd4YhA4',
      title: 'Glitter Bomb 5.0 vs Package Thieves',
      description: 'The fifth generation glitter bomb package designed to catch porch pirates.',
      videoUrl: 'https://www.youtube.com/embed/rdSJBd4YhA4',
      thumbnailUrl: 'https://img.youtube.com/vi/rdSJBd4YhA4/mqdefault.jpg',
      creatorName: 'Mark Rober',
      durationSeconds: 1020,
      viewCount: 38000000,
      likeCount: 900000,
      publishedAt: DateTime.now().subtract(Duration(days: 365 * 2)),
      tags: ['engineering', 'comedy', 'viral', 'invention'],
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
      description: 'Secret spots in Bali that tourists never find 🌴✨ #bali #travel #hidden',
      videoUrl: 'https://www.instagram.com/p/CAbC4dEf5gH/',
      thumbnailUrl: null,
      creatorName: 'wanderlust_vibes',
      durationSeconds: 60,
      viewCount: 420000,
      likeCount: 31000,
      publishedAt: DateTime.now().subtract(Duration(hours: 14)),
      tags: ['travel', 'bali', 'indonesia', 'hidden-gems'],
      contentType: ContentType.reel,
      createdAt: DateTime.now().subtract(Duration(hours: 14)),
      updatedAt: DateTime.now().subtract(Duration(hours: 14)),
    ),
    Content(
      id: 'ig_5',
      platform: PlatformType.instagram,
      platformContentId: 'CBdE5fGh6iJ',
      title: 'Beginner Photography Tips',
      description: '5 camera settings that instantly improve your photos 📸 #photography #tips #beginner',
      videoUrl: 'https://www.instagram.com/p/CBdE5fGh6iJ/',
      thumbnailUrl: null,
      creatorName: 'photo_academy',
      durationSeconds: 55,
      viewCount: 280000,
      likeCount: 22000,
      publishedAt: DateTime.now().subtract(Duration(days: 2)),
      tags: ['photography', 'camera', 'tips', 'beginner'],
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
      description: 'The Pomodoro technique changed my grades! 📚⏱️ #studyhack #pomodoro #student #fyp',
      videoUrl: 'https://www.tiktok.com/@studytips/video/7567890123456789012',
      thumbnailUrl: null,
      creatorName: 'study_pro',
      durationSeconds: 35,
      viewCount: 1800000,
      likeCount: 142000,
      publishedAt: DateTime.now().subtract(Duration(hours: 20)),
      tags: ['study', 'productivity', 'pomodoro', 'student'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(Duration(hours: 20)),
      updatedAt: DateTime.now().subtract(Duration(hours: 20)),
    ),
    Content(
      id: 'tt_5',
      platform: PlatformType.tiktok,
      platformContentId: '7678901234567890123',
      title: 'DIY Home Decor on a Budget',
      description: 'Thrift store flip that cost me £8 and looks amazing! 🏠✨ #diy #homeDecor #thrift',
      videoUrl: 'https://www.tiktok.com/@diy_home/video/7678901234567890123',
      thumbnailUrl: null,
      creatorName: 'diy_crafts',
      durationSeconds: 42,
      viewCount: 950000,
      likeCount: 78000,
      publishedAt: DateTime.now().subtract(Duration(days: 1, hours: 4)),
      tags: ['diy', 'home-decor', 'budget', 'thrift'],
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
      description: 'Are EVs actually good for the environment? We look at the real data on battery lifecycle, charging infrastructure, and emissions comparison.',
      videoUrl: 'https://www.facebook.com/video.php?v=3456789012345678',
      thumbnailUrl: null,
      creatorName: 'Science Explained',
      durationSeconds: 780,
      viewCount: 215000,
      likeCount: 11500,
      publishedAt: DateTime.now().subtract(Duration(days: 9)),
      tags: ['ev', 'electric-vehicles', 'environment', 'science'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 9)),
      updatedAt: DateTime.now().subtract(Duration(days: 9)),
    ),
  ];

  // Ensure every content item has a creatorId for follow functionality
  List<Content> _withCreatorIds(List<Content> items) {
    return items.map((c) {
      if (c.creatorId != null) return c;
      final id = c.creatorName?.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_') ?? 'unknown';
      return c.copyWith(creatorId: id);
    }).toList();
  }

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
    return _withCreatorIds(filteredVideos.take(limit).toList());
  }

  Future<List<Content>> getTrendingVideos({int limit = 5}) async {
    
    // Sort by views and likes for trending
    List<Content> trending = List.from(_sampleVideos);
    trending.sort((a, b) => (b.viewCount + b.likeCount).compareTo(a.viewCount + a.likeCount));
    
    return _withCreatorIds(trending.take(limit).toList());
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
    
    return _withCreatorIds(searchResults.take(limit).toList());
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

    return _withCreatorIds(feedContent.take(limit).toList());
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
      debugPrint('Error getting personalized content: $e');
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
      debugPrint('Error getting onboarding-based recommendations: $e');
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