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
      thumbnailUrl: 'https://img.youtube.com/vi/1ukSR1GRtMU/maxresdefault.jpg',
      creatorName: 'Flutter',
      creatorAvatarUrl: 'https://yt3.ggpht.com/ytc/AKedOLQJXUqKkKlhx_9H8m9s8c8VfE7rWv8c8c8c8c8=s88-c-k-c0x00ffffff-no-rj',
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
      thumbnailUrl: 'https://img.youtube.com/vi/X8ipUgXH6jw/maxresdefault.jpg',
      creatorName: 'Tech Explained',
      creatorAvatarUrl: 'https://yt3.ggpht.com/ytc/AKedOLQJXUqKkKlhx_9H8m9s8c8VfE7rWv8c8c8c8c8=s88-c-k-c0x00ffffff-no-rj',
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
      thumbnailUrl: 'https://img.youtube.com/vi/NCwa_xi0Uuc/maxresdefault.jpg',
      creatorName: 'JavaScript Mastery',
      creatorAvatarUrl: 'https://yt3.ggpht.com/ytc/AKedOLQJXUqKkKlhx_9H8m9s8c8VfE7rWv8c8c8c8c8=s88-c-k-c0x00ffffff-no-rj',
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
      thumbnailUrl: 'https://img.youtube.com/vi/vmEHCJofslg/maxresdefault.jpg',
      creatorName: 'Data Science Pro',
      creatorAvatarUrl: 'https://yt3.ggpht.com/ytc/AKedOLQJXUqKkKlhx_9H8m9s8c8VfE7rWv8c8c8c8c8=s88-c-k-c0x00ffffff-no-rj',
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
      thumbnailUrl: 'https://img.youtube.com/vi/ysEN5RaKOlA/maxresdefault.jpg',
      creatorName: 'Web Dev Simplified',
      creatorAvatarUrl: 'https://yt3.ggpht.com/ytc/AKedOLQJXUqKkKlhx_9H8m9s8c8VfE7rWv8c8c8c8c8=s88-c-k-c0x00ffffff-no-rj',
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
      videoUrl: 'https://www.youtube.com/embed/ukzFI9rgwfU',
      thumbnailUrl: 'https://img.youtube.com/vi/ukzFI9rgwfU/maxresdefault.jpg',
      creatorName: 'AI Academy',
      creatorAvatarUrl: 'https://yt3.ggpht.com/ytc/placeholder=s88-c-k',
      durationSeconds: 2550,
      viewCount: 1800000,
      likeCount: 67000,
      publishedAt: DateTime.now().subtract(Duration(days: 8)),
      tags: ['machine-learning', 'ai', 'algorithms'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 8)),
      updatedAt: DateTime.now().subtract(Duration(days: 8)),
    ),

    // Tech/Programming
    Content(
      id: 'yt_7',
      platform: PlatformType.youtube,
      platformContentId: 'rFejpH_tAHM',
      title: '100+ JavaScript Concepts you Need to Know',
      description: 'Master the most important JavaScript concepts in one video — from closures to promises and beyond.',
      videoUrl: 'https://www.youtube.com/embed/rFejpH_tAHM',
      thumbnailUrl: 'https://img.youtube.com/vi/rFejpH_tAHM/maxresdefault.jpg',
      creatorName: 'Fireship',
      creatorAvatarUrl: 'https://yt3.ggpht.com/ytc/placeholder=s88-c-k',
      durationSeconds: 660,
      viewCount: 5200000,
      likeCount: 198000,
      publishedAt: DateTime.now().subtract(Duration(days: 14)),
      tags: ['javascript', 'programming', 'web-development', 'concepts'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 14)),
      updatedAt: DateTime.now().subtract(Duration(days: 14)),
    ),
    Content(
      id: 'yt_8',
      platform: PlatformType.youtube,
      platformContentId: 'qnQ5RyxVOoQ',
      title: 'Python Full Course for Beginners',
      description: 'Learn Python programming from scratch in this comprehensive 6-hour full course covering all fundamentals.',
      videoUrl: 'https://www.youtube.com/embed/qnQ5RyxVOoQ',
      thumbnailUrl: 'https://img.youtube.com/vi/qnQ5RyxVOoQ/maxresdefault.jpg',
      creatorName: 'Programming with Mosh',
      creatorAvatarUrl: 'https://yt3.ggpht.com/ytc/placeholder=s88-c-k',
      durationSeconds: 21600,
      viewCount: 18000000,
      likeCount: 520000,
      publishedAt: DateTime.now().subtract(Duration(days: 30)),
      tags: ['python', 'programming', 'beginners', 'tutorial'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 30)),
      updatedAt: DateTime.now().subtract(Duration(days: 30)),
    ),
    Content(
      id: 'yt_9',
      platform: PlatformType.youtube,
      platformContentId: 'huGgT9XBTJM',
      title: 'Flutter Crash Course for Beginners 2024',
      description: 'Build your first Flutter app from scratch in this 4-hour crash course for absolute beginners.',
      videoUrl: 'https://www.youtube.com/embed/huGgT9XBTJM',
      thumbnailUrl: 'https://img.youtube.com/vi/huGgT9XBTJM/maxresdefault.jpg',
      creatorName: 'Traversy Media',
      creatorAvatarUrl: 'https://yt3.ggpht.com/ytc/placeholder=s88-c-k',
      durationSeconds: 14400,
      viewCount: 890000,
      likeCount: 31000,
      publishedAt: DateTime.now().subtract(Duration(days: 20)),
      tags: ['flutter', 'mobile', 'beginners', 'crash-course', '2024'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 20)),
      updatedAt: DateTime.now().subtract(Duration(days: 20)),
    ),
    Content(
      id: 'yt_10',
      platform: PlatformType.youtube,
      platformContentId: 'mTz0GXj8NN0',
      title: 'NextJS 14 Full Course',
      description: 'Complete Next.js 14 full course — server components, app router, data fetching and deployment.',
      videoUrl: 'https://www.youtube.com/embed/mTz0GXj8NN0',
      thumbnailUrl: 'https://img.youtube.com/vi/mTz0GXj8NN0/maxresdefault.jpg',
      creatorName: 'Dave Gray',
      creatorAvatarUrl: 'https://yt3.ggpht.com/ytc/placeholder=s88-c-k',
      durationSeconds: 7200,
      viewCount: 1100000,
      likeCount: 38000,
      publishedAt: DateTime.now().subtract(Duration(days: 18)),
      tags: ['nextjs', 'react', 'web-development', 'full-stack'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 18)),
      updatedAt: DateTime.now().subtract(Duration(days: 18)),
    ),

    // Science/Education
    Content(
      id: 'yt_11',
      platform: PlatformType.youtube,
      platformContentId: 'rhgwIhB5-oE',
      title: 'What Is the Turing Test?',
      description: 'Can machines think? Kurzgesagt explains the famous Turing Test and what it means for artificial intelligence.',
      videoUrl: 'https://www.youtube.com/embed/rhgwIhB5-oE',
      thumbnailUrl: 'https://img.youtube.com/vi/rhgwIhB5-oE/maxresdefault.jpg',
      creatorName: 'Kurzgesagt',
      creatorAvatarUrl: 'https://yt3.ggpht.com/ytc/placeholder=s88-c-k',
      durationSeconds: 480,
      viewCount: 2300000,
      likeCount: 89000,
      publishedAt: DateTime.now().subtract(Duration(days: 45)),
      tags: ['ai', 'turing-test', 'science', 'education', 'technology'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 45)),
      updatedAt: DateTime.now().subtract(Duration(days: 45)),
    ),
    Content(
      id: 'yt_12',
      platform: PlatformType.youtube,
      platformContentId: 'Xjv1sY630IY',
      title: 'The Web Is Not the Net',
      description: 'Vsauce explores the difference between the internet and the World Wide Web — and how it all works.',
      videoUrl: 'https://www.youtube.com/embed/Xjv1sY630IY',
      thumbnailUrl: 'https://img.youtube.com/vi/Xjv1sY630IY/maxresdefault.jpg',
      creatorName: 'Vsauce',
      creatorAvatarUrl: 'https://yt3.ggpht.com/ytc/placeholder=s88-c-k',
      durationSeconds: 780,
      viewCount: 7800000,
      likeCount: 312000,
      publishedAt: DateTime.now().subtract(Duration(days: 90)),
      tags: ['internet', 'web', 'education', 'science', 'technology'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 90)),
      updatedAt: DateTime.now().subtract(Duration(days: 90)),
    ),
    Content(
      id: 'yt_13',
      platform: PlatformType.youtube,
      platformContentId: '8Q9isOI7Fvo',
      title: 'How Does GPS Work?',
      description: 'SciShow breaks down the science and engineering behind the Global Positioning System we rely on every day.',
      videoUrl: 'https://www.youtube.com/embed/8Q9isOI7Fvo',
      thumbnailUrl: 'https://img.youtube.com/vi/8Q9isOI7Fvo/maxresdefault.jpg',
      creatorName: 'SciShow',
      creatorAvatarUrl: 'https://yt3.ggpht.com/ytc/placeholder=s88-c-k',
      durationSeconds: 360,
      viewCount: 4100000,
      likeCount: 95000,
      publishedAt: DateTime.now().subtract(Duration(days: 60)),
      tags: ['gps', 'science', 'technology', 'engineering', 'education'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 60)),
      updatedAt: DateTime.now().subtract(Duration(days: 60)),
    ),

    // Design/Creative
    Content(
      id: 'yt_14',
      platform: PlatformType.youtube,
      platformContentId: 'c9Wg6Cb_YlU',
      title: 'Figma UI Design Tutorial',
      description: 'Complete Figma tutorial for beginners — learn components, auto layout, prototyping and design systems.',
      videoUrl: 'https://www.youtube.com/embed/c9Wg6Cb_YlU',
      thumbnailUrl: 'https://img.youtube.com/vi/c9Wg6Cb_YlU/maxresdefault.jpg',
      creatorName: 'DesignCourse',
      creatorAvatarUrl: 'https://yt3.ggpht.com/ytc/placeholder=s88-c-k',
      durationSeconds: 3600,
      viewCount: 1600000,
      likeCount: 62000,
      publishedAt: DateTime.now().subtract(Duration(days: 25)),
      tags: ['figma', 'ui-design', 'design', 'tutorial', 'ux'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 25)),
      updatedAt: DateTime.now().subtract(Duration(days: 25)),
    ),
    Content(
      id: 'yt_15',
      platform: PlatformType.youtube,
      platformContentId: 'o1aFLNDkXYs',
      title: 'UI Design for Beginners',
      description: 'Learn the principles of great UI design from scratch — color theory, typography, layout and real project walkthroughs.',
      videoUrl: 'https://www.youtube.com/embed/o1aFLNDkXYs',
      thumbnailUrl: 'https://img.youtube.com/vi/o1aFLNDkXYs/maxresdefault.jpg',
      creatorName: 'developedbyed',
      creatorAvatarUrl: 'https://yt3.ggpht.com/ytc/placeholder=s88-c-k',
      durationSeconds: 7200,
      viewCount: 3200000,
      likeCount: 118000,
      publishedAt: DateTime.now().subtract(Duration(days: 35)),
      tags: ['ui-design', 'design', 'beginners', 'color-theory', 'typography'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 35)),
      updatedAt: DateTime.now().subtract(Duration(days: 35)),
    ),

    // News/Current Events
    Content(
      id: 'yt_16',
      platform: PlatformType.youtube,
      platformContentId: 'FJ3N_2r6R-o',
      title: 'The AI Revolution: How ChatGPT Changed Everything',
      description: 'CNBC explores how ChatGPT and large language models are transforming industries, jobs, and daily life.',
      videoUrl: 'https://www.youtube.com/embed/FJ3N_2r6R-o',
      thumbnailUrl: 'https://img.youtube.com/vi/FJ3N_2r6R-o/maxresdefault.jpg',
      creatorName: 'CNBC',
      creatorAvatarUrl: 'https://yt3.ggpht.com/ytc/placeholder=s88-c-k',
      durationSeconds: 720,
      viewCount: 3400000,
      likeCount: 72000,
      publishedAt: DateTime.now().subtract(Duration(days: 12)),
      tags: ['ai', 'chatgpt', 'technology', 'news', 'business'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 12)),
      updatedAt: DateTime.now().subtract(Duration(days: 12)),
    ),

    // Lifestyle/Vlog
    Content(
      id: 'yt_17',
      platform: PlatformType.youtube,
      platformContentId: 'UHlEPyqhJQA',
      title: 'Morning Routine for Productivity 2024',
      description: 'Matt D\'Avella shares his evidence-based morning routine for maximising focus and creative output throughout the day.',
      videoUrl: 'https://www.youtube.com/embed/UHlEPyqhJQA',
      thumbnailUrl: 'https://img.youtube.com/vi/UHlEPyqhJQA/maxresdefault.jpg',
      creatorName: 'Matt D\'Avella',
      creatorAvatarUrl: 'https://yt3.ggpht.com/ytc/placeholder=s88-c-k',
      durationSeconds: 540,
      viewCount: 8700000,
      likeCount: 340000,
      publishedAt: DateTime.now().subtract(Duration(days: 9)),
      tags: ['productivity', 'morning-routine', 'lifestyle', 'habits', '2024'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 9)),
      updatedAt: DateTime.now().subtract(Duration(days: 9)),
    ),
    Content(
      id: 'yt_18',
      platform: PlatformType.youtube,
      platformContentId: 'LLDqvvBpHe4',
      title: 'I Learned to Code in 30 Days',
      description: 'Traversy Media documents the journey of learning to code from absolute zero in just 30 days — the highs, lows, and lessons.',
      videoUrl: 'https://www.youtube.com/embed/LLDqvvBpHe4',
      thumbnailUrl: 'https://img.youtube.com/vi/LLDqvvBpHe4/maxresdefault.jpg',
      creatorName: 'Traversy Media',
      creatorAvatarUrl: 'https://yt3.ggpht.com/ytc/placeholder=s88-c-k',
      durationSeconds: 900,
      viewCount: 2100000,
      likeCount: 87000,
      publishedAt: DateTime.now().subtract(Duration(days: 6)),
      tags: ['coding', 'programming', 'vlog', 'beginners', 'challenge'],
      contentType: ContentType.video,
      createdAt: DateTime.now().subtract(Duration(days: 6)),
      updatedAt: DateTime.now().subtract(Duration(days: 6)),
    ),

    // TikTok-style short content
    Content(
      id: 'tk_1',
      platform: PlatformType.tiktok,
      platformContentId: 'tiktok_1',
      title: 'Quick Flutter Tip: Using const Constructors',
      description: 'Speed up your Flutter app with this simple tip',
      videoUrl: 'https://www.tiktok.com/@flutterdev/video/example',
      thumbnailUrl: 'https://picsum.photos/360/640?random=101',
      creatorName: 'FlutterDev',
      creatorAvatarUrl: 'https://yt3.ggpht.com/ytc/placeholder=s88-c-k',
      durationSeconds: 58,
      viewCount: 234000,
      likeCount: 12400,
      publishedAt: DateTime.now().subtract(const Duration(hours: 6)),
      tags: ['flutter', 'programming', 'tips'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    Content(
      id: 'tk_2',
      platform: PlatformType.tiktok,
      platformContentId: 'tiktok_2',
      title: 'I learned this productivity hack and saved 2 hours/day',
      description: 'Simple productivity tip that changed my work habits',
      videoUrl: 'https://www.tiktok.com/@productivityhacks/video/example2',
      thumbnailUrl: 'https://picsum.photos/360/640?random=102',
      creatorName: 'ProductivityHacks',
      creatorAvatarUrl: 'https://yt3.ggpht.com/ytc/placeholder=s88-c-k',
      durationSeconds: 45,
      viewCount: 892000,
      likeCount: 67000,
      publishedAt: DateTime.now().subtract(const Duration(hours: 12)),
      tags: ['productivity', 'lifestyle', 'tips'],
      contentType: ContentType.short,
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
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

  // Get trending videos
  Future<List<Content>> getTrendingVideos({int limit = 5}) async {
    await Future.delayed(Duration(milliseconds: 300));

    // Sort by viewCount descending — most-watched content surfaces first
    List<Content> trending = List.from(_sampleVideos);
    trending.sort((a, b) => b.viewCount.compareTo(a.viewCount));

    return trending.take(limit).toList();
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
    // Use a session-consistent seed so order is stable within a session
    // but varies across sessions for fresh variety
    final seed = DateTime.now().millisecondsSinceEpoch ~/ 600000; // changes every 10 min
    feedContent.shuffle(Random(seed));

    // Deduplicate by platformContentId
    final seen = <String>{};
    feedContent = feedContent.where((c) => seen.add(c.platformContentId)).toList();

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
        // Return recent-first content for unauthenticated users
        return _getRecentPrioritizedContent(limit: limit);
      }

      // Check if onboarding is completed
      final isOnboardingCompleted = await onboardingService.isOnboardingCompleted();
      if (!isOnboardingCompleted) {
        // Return recent-first content if onboarding not completed
        return _getRecentPrioritizedContent(limit: limit);
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
      // Fallback to recent-prioritized feed content
      return _getRecentPrioritizedContent(limit: limit);
    }
  }

  // Helper: return content sorted so items published within the last 7 days come first,
  // then the remainder sorted by viewCount descending.
  List<Content> _getRecentPrioritizedContent({int limit = 10}) {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 7));

    final recent = _sampleVideos
        .where((c) => c.publishedAt != null && c.publishedAt!.isAfter(cutoff))
        .toList()
      ..sort((a, b) => (b.publishedAt ?? now).compareTo(a.publishedAt ?? now));

    final older = _sampleVideos
        .where((c) => c.publishedAt == null || !c.publishedAt!.isAfter(cutoff))
        .toList()
      ..sort((a, b) => b.viewCount.compareTo(a.viewCount));

    return [...recent, ...older].take(limit).toList();
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

  // Get short-form content (shorts, reels, TikToks, and videos <= 3 min)
  Future<List<Content>> getShortContent({int limit = 20}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final shorts = _sampleVideos.where((v) =>
      v.contentType == ContentType.short ||
      v.contentType == ContentType.reel ||
      (v.durationSeconds != null && v.durationSeconds! <= 180)
    ).toList();
    shorts.shuffle();
    return shorts.take(limit).toList();
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