import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../feed/feed_post_card.dart';
import '../../models/content_model.dart';
import '../../services/content_service.dart';
import '../../services/analytics_service.dart';
import '../../services/onboarding_service.dart';
import '../../services/auth_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/user_interaction_service.dart';
import '../../services/navigation_service.dart';
import '../../services/subscription_service.dart';
import '../ads/in_feed_ad_card.dart';

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
  bool _showFollowSuggestion = false;
  String _dateFilter = 'all';
  ContentType? _contentTypeFilter;
  List<({Content content, double progress})> _continueWatching = [];

  List<Content> get _filteredPosts {
    var posts = _posts;
    if (_contentTypeFilter != null) {
      posts = posts.where((p) => p.contentType == _contentTypeFilter).toList();
    }
    if (_dateFilter != 'all') {
      final now = DateTime.now();
      final DateTime cutoff;
      switch (_dateFilter) {
        case 'today':
          cutoff = DateTime(now.year, now.month, now.day);
        case 'week':
          cutoff = now.subtract(const Duration(days: 7));
        case 'month':
          cutoff = now.subtract(const Duration(days: 30));
        default:
          cutoff = DateTime(2000);
      }
      posts = posts.where((p) => p.publishedAt == null || p.publishedAt!.isAfter(cutoff)).toList();
    }
    return posts;
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedPlatform != null) count++;
    if (_contentTypeFilter != null) count++;
    if (_dateFilter != 'all') count++;
    return count;
  }
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadInitialPosts();
    _loadContinueWatching();
    _scrollController.addListener(_onScroll);
    _checkConnectivity();
    _checkProactivePaywall();
  }

  Future<void> _checkProactivePaywall() async {
    final shouldShow = await SubscriptionService.instance.shouldShowProactivePaywall();
    if (shouldShow && mounted) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.of(context).pushNamed(AppRoutes.premium);
    }
  }

  Future<void> _loadContinueWatching() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('watch_progress_'));
    final items = <({Content content, double progress})>[];
    for (final key in keys.take(10)) {
      final progress = prefs.getDouble(key) ?? 0.0;
      if (progress > 0.05 && progress < 0.9) {
        final id = key.replaceFirst('watch_progress_', '');
        final content = await ContentService.instance.getVideoById(id);
        if (content != null) items.add((content: content, progress: progress));
      }
    }
    if (mounted && items.isNotEmpty) setState(() => _continueWatching = items);
  }

  Future<void> _checkConnectivity() async {
    final connected = await ConnectivityService.instance.isConnected();
    if (!connected && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No internet connection - showing cached content'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  void _onScroll() {
    final pos = _scrollController.position;
    // Preload thumbnails for the items roughly 2 screen-heights ahead
    if (_posts.isNotEmpty) {
      final approxItemHeight = 320.0;
      final currentIndex = (pos.pixels / approxItemHeight).floor();
      _preloadThumbnails(currentIndex + 3);
    }
    if (pos.pixels >= pos.maxScrollExtent - 200) {
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
      
      final followingCount = UserInteractionService.instance.getFollowedCreatorIds().length;
      setState(() {
        _allPosts = feedContent;
        _posts = List.from(_allPosts);
        _isLoading = false;
        _showFollowSuggestion = followingCount == 0;
      });
      // Preload the first 5 thumbnails immediately after load
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _preloadThumbnails(0, count: 5);
      });
      
      // Track successful content load with personalization info
      await AnalyticsService.instance.trackUserInteraction(
        action: 'home_content_loaded',
        screen: 'home',
        additionalData: {
          'total_content': feedContent.length,
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
    // Trigger a live refresh from YouTube so pull-to-refresh fetches new data
    await ContentService.instance.refreshContent();
    await _loadInitialPosts();
  }

  /// Preload thumbnails for the next [count] posts beyond [startIndex].
  /// Runs in the background — no await needed at call site.
  void _preloadThumbnails(int startIndex, {int count = 5}) {
    final end = (startIndex + count).clamp(0, _posts.length);
    for (int i = startIndex; i < end; i++) {
      final url = _posts[i].thumbnailUrl;
      if (url != null && url.isNotEmpty) {
        precacheImage(CachedNetworkImageProvider(url), context);
      }
    }
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
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FilterBottomSheet(
        selectedPlatform: _selectedPlatform,
        dateFilter: _dateFilter,
        contentTypeFilter: _contentTypeFilter,
        onApply: (platform, dateFilter, contentType) {
          setState(() {
            _selectedPlatform = platform;
            _dateFilter = dateFilter;
            _contentTypeFilter = contentType;
            if (platform == null) {
              _posts = List.from(_allPosts);
            } else {
              _posts = _allPosts.where((p) => p.platform == platform).toList();
            }
          });
        },
      ),
    );
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
        Semantics(
          label: _activeFilterCount > 0
              ? 'Open filters. $_activeFilterCount active'
              : 'Open filters',
          button: true,
          child: GestureDetector(
          onTap: _showFilterSheet,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _activeFilterCount > 0
                      ? AppTheme.primaryCyan.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _activeFilterCount > 0
                        ? AppTheme.primaryCyan
                        : Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(
                  Icons.tune,
                  color: _activeFilterCount > 0 ? AppTheme.primaryCyan : Colors.white70,
                  size: 20,
                ),
              ),
              if (_activeFilterCount > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryCyan,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$_activeFilterCount',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        ),
        const SizedBox(width: 8),
        _buildQuickStats(),
      ],
    );
  }

  Widget _buildFeedTab(String label, bool isActive) {
    return Semantics(
      label: '$label tab',
      selected: isActive,
      button: true,
      child: GestureDetector(
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
              width: 32,
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
                      ? AppTheme.primaryCyan
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
                      color: isSelected ? Colors.black87 : Colors.white.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      filter['name'] as String,
                      style: TextStyle(
                        color: isSelected ? Colors.black87 : Colors.white.withValues(alpha: 0.7),
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
    final displayPosts = _filteredPosts;

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
            const Icon(Icons.video_library_outlined, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            const Text(
              'No content available',
              style: TextStyle(color: Colors.white54, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pull down to refresh',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadInitialPosts,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    if (!_isLoading && _posts.isNotEmpty && displayPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.filter_alt_off, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            const Text(
              'No content matches your filters',
              style: TextStyle(color: Colors.white54, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try changing or clearing your filters',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedPlatform = null;
                  _dateFilter = 'all';
                  _contentTypeFilter = null;
                  _posts = List.from(_allPosts);
                });
              },
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      );
    }

    final continueSection = _continueWatching.isNotEmpty
        ? _buildContinueWatchingSection()
        : null;

    // Build mixed list: inject ad slot (null) every 6 content cards for free users
    final isPremium = SubscriptionService.instance.isPremium;
    final List<Content?> mixedList = [];
    for (int i = 0; i < displayPosts.length; i++) {
      mixedList.add(displayPosts[i]);
      if (!isPremium && (i + 1) % 6 == 0) {
        mixedList.add(null); // null = ad slot
      }
    }

    final extraItems = (continueSection != null ? 1 : 0) +
        (_isLoading ? 1 : 0) +
        (_showFollowSuggestion ? 1 : 0);

    return RefreshIndicator(
      onRefresh: _refreshPosts,
      color: AppTheme.primaryCyan,
      backgroundColor: const Color(0xFF2D1B69),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: mixedList.length + extraItems,
        addRepaintBoundaries: false, // we add our own RepaintBoundary per card
        addAutomaticKeepAlives: false,
        itemBuilder: (context, index) {
          // First item: continue watching
          if (continueSection != null && index == 0) return continueSection;
          final offsetIndex = continueSection != null ? index - 1 : index;

          // Insert follow suggestion banner after the 2nd post (YouTube/TikTok pattern)
          if (_showFollowSuggestion && offsetIndex == 2) {
            return _buildFollowSuggestionBanner(context);
          }
          // Adjust index for the injected banner
          final listIndex = _showFollowSuggestion && offsetIndex > 2
              ? offsetIndex - 1
              : offsetIndex;

          if (listIndex >= mixedList.length) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryCyan),
                ),
              ),
            );
          }

          final item = mixedList[listIndex];
          if (item == null) {
            // Ad slot — render native in-feed ad
            return const InFeedAdCard();
          }

          return RepaintBoundary(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: FeedPostCard(content: item),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContinueWatchingSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Continue Watching',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _continueWatching.length,
              itemBuilder: (context, i) {
                final item = _continueWatching[i];
                return Semantics(
                  label: 'Continue watching ${item.content.title ?? ""}',
                  button: true,
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(context, AppRoutes.player,
                        arguments: item.content),
                    child: Container(
                      width: 180,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFF1A1A2E),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          if (item.content.thumbnailUrl != null)
                            CachedNetworkImage(
                              imageUrl: item.content.thumbnailUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorWidget: (_, __, ___) => Container(color: const Color(0xFF252545)),
                            ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Column(
                              children: [
                                LinearProgressIndicator(
                                  value: item.progress,
                                  backgroundColor: Colors.white24,
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                      AppTheme.primaryCyan),
                                  minHeight: 3,
                                ),
                                Container(
                                  padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
                                  width: double.infinity,
                                  color: Colors.black54,
                                  child: Text(
                                    item.content.title ?? '',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.play_arrow,
                                  color: Colors.white, size: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowSuggestionBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF001A2E), Color(0xFF1A0A2E)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF00D4FF).withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.people_outline, color: Color(0xFF00D4FF), size: 20),
              SizedBox(width: 8),
              Text(
                'Discover creators to follow',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Follow creators to surface their content first in your feed. Tap Follow on any video.',
            style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() => _showFollowSuggestion = false);
                  Navigator.pushNamed(context, AppRoutes.search);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D4FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Find creators', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => setState(() => _showFollowSuggestion = false),
                child: const Text('Dismiss', style: TextStyle(color: Colors.white38, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  final PlatformType? selectedPlatform;
  final String dateFilter;
  final ContentType? contentTypeFilter;
  final void Function(PlatformType? platform, String dateFilter, ContentType? contentType) onApply;

  const _FilterBottomSheet({
    required this.selectedPlatform,
    required this.dateFilter,
    required this.contentTypeFilter,
    required this.onApply,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late PlatformType? _platform;
  late String _dateFilter;
  late ContentType? _contentType;

  @override
  void initState() {
    super.initState();
    _platform = widget.selectedPlatform;
    _dateFilter = widget.dateFilter;
    _contentType = widget.contentTypeFilter;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Filters', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _platform = null;
                        _dateFilter = 'all';
                        _contentType = null;
                      });
                    },
                    child: const Text('Reset All', style: TextStyle(color: Color(0xFF00D4FF))),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Platform', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterChip('All', _platform == null, () => setState(() => _platform = null)),
                  _buildPlatformChip('YouTube', PlatformType.youtube, const Color(0xFFFF0000)),
                  _buildPlatformChip('Instagram', PlatformType.instagram, const Color(0xFFE1306C)),
                  _buildPlatformChip('TikTok', PlatformType.tiktok, const Color(0xFF69C9D0)),
                  _buildPlatformChip('Facebook', PlatformType.facebook, const Color(0xFF1877F2)),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Time Range', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterChip('All Time', _dateFilter == 'all', () => setState(() => _dateFilter = 'all')),
                  _buildFilterChip('Today', _dateFilter == 'today', () => setState(() => _dateFilter = 'today')),
                  _buildFilterChip('This Week', _dateFilter == 'week', () => setState(() => _dateFilter = 'week')),
                  _buildFilterChip('This Month', _dateFilter == 'month', () => setState(() => _dateFilter = 'month')),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Content Type', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterChip('All', _contentType == null, () => setState(() => _contentType = null)),
                  _buildFilterChip('Videos', _contentType == ContentType.video, () => setState(() => _contentType = ContentType.video)),
                  _buildFilterChip('Shorts', _contentType == ContentType.short, () => setState(() => _contentType = ContentType.short)),
                  _buildFilterChip('Reels', _contentType == ContentType.reel, () => setState(() => _contentType = ContentType.reel)),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(_platform, _dateFilter, _contentType);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D4FF),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00D4FF).withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF00D4FF) : Colors.white.withValues(alpha: 0.2)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF00D4FF) : Colors.white70,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildPlatformChip(String label, PlatformType platform, Color color) {
    final isSelected = _platform == platform;
    return GestureDetector(
      onTap: () => setState(() => _platform = platform),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : Colors.white.withValues(alpha: 0.2)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : Colors.white70,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}