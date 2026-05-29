import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../feed/feed_post_card.dart';
import '../../models/content_model.dart';
import '../../services/content_service.dart';
import '../../services/analytics_service.dart';
import '../../services/onboarding_service.dart';
import '../../services/auth_service.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  List<Content> _posts = [];
  List<Content> _allPosts = [];
  bool _isLoading = false;
  bool _hasMore = true;
  PlatformType? _selectedPlatform;
  bool _showFollowing = false;
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadInitialPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMorePosts();
    }
  }
  
  Future<void> _loadInitialPosts() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Check if user is authenticated and onboarding is completed
      final authService = AuthService.instance;
      final onboardingService = OnboardingService();
      final user = authService.currentUser;
      
      List<Content> feedContent;
      
      if (user != null) {
        final isOnboardingCompleted = await onboardingService.isOnboardingCompleted();
        
        if (isOnboardingCompleted) {
          // Use personalized content for completed onboarding users
          feedContent = await ContentService.instance.getPersonalizedContent(limit: 15);
        } else {
          // Use onboarding-based recommendations for users in progress
          feedContent = await ContentService.instance.getOnboardingBasedRecommendations(limit: 15);
        }
      } else {
        // Use general trending content for unauthenticated users
        feedContent = await ContentService.instance.getTrendingVideos(limit: 15);
      }
      
      // Ensure we have YouTube content for proper video playback
      final youtubeContent = feedContent.where((content) => 
        content.platform == PlatformType.youtube
      ).toList();
      
      // Mix YouTube content with other platforms for better variety
      final mixedContent = <Content>[];
      mixedContent.addAll(youtubeContent.take(8)); // Prioritize YouTube for video playback
      mixedContent.addAll(feedContent.where((content) => 
        content.platform != PlatformType.youtube
      ).take(7));
      
      setState(() {
        _allPosts = mixedContent;
        _posts = List.from(_allPosts);
        _isLoading = false;
      });
      
      // Track successful content load with personalization info
      await AnalyticsService.instance.trackUserInteraction(
        action: 'home_content_loaded',
        screen: 'home',
        additionalData: {
          'total_content': mixedContent.length,
          'youtube_content': youtubeContent.length,
          'is_personalized': user != null && await onboardingService.isOnboardingCompleted(),
          'user_authenticated': user != null,
        },
      );
    } catch (e) {
      setState(() {
        _allPosts = [];
        _posts = [];
        _isLoading = false;
      });
      
      // Track error
      await AnalyticsService.instance.trackError(
        errorType: 'home_content_load_error',
        errorMessage: e.toString(),
        screen: 'home',
      );
    }
  }
  
  Future<void> _loadMorePosts() async {
    if (_isLoading || !_hasMore) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Use the same personalization logic as initial load
      final authService = AuthService.instance;
      final onboardingService = OnboardingService();
      final user = authService.currentUser;
      
      List<Content> newPosts;
      
      if (user != null) {
        final isOnboardingCompleted = await onboardingService.isOnboardingCompleted();
        
        if (isOnboardingCompleted) {
          // Use personalized content for completed onboarding users
          newPosts = await ContentService.instance.getPersonalizedContent(limit: 8);
        } else {
          // Use onboarding-based recommendations for users in progress
          newPosts = await ContentService.instance.getOnboardingBasedRecommendations(limit: 8);
        }
      } else {
        // Use general content for unauthenticated users
        newPosts = await ContentService.instance.getFeedContent(limit: 8);
      }
      
      setState(() {
        _allPosts.addAll(newPosts);
        // Apply current filter to new posts
        if (_selectedPlatform == null) {
          _posts.addAll(newPosts);
        } else {
          _posts.addAll(newPosts.where((post) => post.platform == _selectedPlatform));
        }
        _isLoading = false;
        _hasMore = _allPosts.length < 50;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _refreshPosts() async {
    setState(() {
      _posts.clear();
      _allPosts.clear();
      _hasMore = true;
    });
    await _loadInitialPosts();
  }
  
  void _handlePlatformFilter(PlatformType? platform) {
    setState(() {
      _selectedPlatform = platform;
      if (platform == null) {
        _posts = List.from(_allPosts);
      } else {
        _posts = _allPosts.where((post) => post.platform == platform).toList();
      }
    });
    
    // Navigate to specific platform content if needed
    if (platform == PlatformType.youtube) {
      _navigateToYouTube();
    } else if (platform == PlatformType.tiktok) {
      _navigateToTikTok();
    }
  }
  
  void _navigateToYouTube() {
    // Navigate to YouTube-specific content or external YouTube
    Navigator.of(context).pushNamed('/dashboard', arguments: {'initialTab': 1, 'filter': 'youtube'});
  }
  
  void _navigateToTikTok() {
    // Navigate to TikTok-specific content (Shorts tab)
    Navigator.of(context).pushNamed('/dashboard', arguments: {'initialTab': 3, 'filter': 'tiktok'});
  }
  


  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Container(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildFeed(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // For You / Following tab switch (YouTube/TikTok/Twitter pattern)
          _buildFeedTabSwitch(),
          const SizedBox(height: 12),
          _buildTrendingTopics(),
          const SizedBox(height: 12),
          _buildQuickFilters(),
        ],
      ),
    );
  }

  Widget _buildFeedTabSwitch() {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              _buildFeedTab('For You', !_showFollowing),
              const SizedBox(width: 24),
              _buildFeedTab('Following', _showFollowing),
            ],
          ),
        ),
        _buildQuickStats(),
      ],
    );
  }

  Widget _buildFeedTab(String label, bool isActive) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showFollowing = label == 'Following';
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.45),
              fontSize: 18,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          if (isActive)
            Container(
              height: 3,
              width: label.length * 10.0,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryCyan, AppTheme.primaryPink],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            )
          else
            const SizedBox(height: 3),
        ],
      ),
    );
  }
  
  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            '24',
            style: TextStyle(
              color: AppTheme.primaryCyan,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'New',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingTopics() {
    final topics = ['#Flutter', '#AI', '#Tech', '#Design'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trending',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 24,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: topics.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPink.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  topics[index],
                  style: TextStyle(
                    color: AppTheme.primaryPink,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickFilters() {
    final filters = [
      {'name': 'For You', 'platform': null, 'icon': Icons.auto_awesome},
      {'name': 'YouTube', 'platform': PlatformType.youtube, 'icon': Icons.play_circle},
      {'name': 'Instagram', 'platform': PlatformType.instagram, 'icon': Icons.camera_alt},
      {'name': 'TikTok', 'platform': PlatformType.tiktok, 'icon': Icons.music_video},
      {'name': 'Facebook', 'platform': PlatformType.facebook, 'icon': Icons.facebook},
    ];

    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedPlatform == filter['platform'];

          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _handlePlatformFilter(filter['platform'] as PlatformType?),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryCyan.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryCyan
                        : Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      filter['icon'] as IconData,
                      size: 14,
                      color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      filter['name'] as String,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildFeed() {
    if (_isLoading && _posts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryCyan),
        ),
      );
    }

    if (!_isLoading && _posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library_outlined, size: 64, color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              'No content yet',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Pull down to refresh',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: _refreshPosts,
              icon: Icon(Icons.refresh, color: AppTheme.primaryCyan),
              label: Text('Refresh', style: TextStyle(color: AppTheme.primaryCyan)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshPosts,
      color: AppTheme.primaryCyan,
      backgroundColor: const Color(0xFF2D1B69),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _posts.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _posts.length) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryCyan),
                ),
              ),
            );
          }
          
          final post = _posts[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: FeedPostCard(
              content: post,
            ),
          );
        },
      ),
    );
  }
}