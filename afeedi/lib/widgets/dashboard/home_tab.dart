import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../core/theme/app_theme.dart';
import '../../services/youtube_data_api_service.dart';
import '../../services/local_auth_service.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with AutomaticKeepAliveClientMixin {
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  final PageController _featuredPageController = PageController();

  List<YouTubeVideo> _trendingVideos = [];
  List<YouTubeVideo> _recommendedVideos = [];
  bool _isLoading = true;
  bool _hasError = false;
  int _featuredPage = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _featuredPageController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Data loading
  // ---------------------------------------------------------------------------

  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final service = YouTubeDataApiService.instance;
      final results = await Future.wait([
        service.fetchTrendingVideos(maxResults: 20),
        service.fetchVideosByQuery(
            query: 'recommended technology', maxResults: 20),
      ]);
      if (mounted) {
        setState(() {
          _trendingVideos = results[0];
          _recommendedVideos = results[1];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadContent();
    _refreshController.refreshCompleted();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _userName() {
    final user = LocalAuthService.instance.currentUser;
    if (user == null) return '';
    // Use email prefix as display name when there is no dedicated display name
    return user.email.split('@').first;
  }

  String _formatViews(int count) {
    if (count >= 1000000000) {
      return '${(count / 1000000000).toStringAsFixed(1)}B views';
    }
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M views';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K views';
    }
    return '$count views';
  }

  String _timeAgo(String publishedAt) {
    if (publishedAt.isEmpty) return '';
    try {
      final published = DateTime.parse(publishedAt);
      final diff = DateTime.now().difference(published);
      if (diff.inDays >= 365) {
        final y = (diff.inDays / 365).floor();
        return '$y ${y == 1 ? 'year' : 'years'} ago';
      }
      if (diff.inDays >= 30) {
        final m = (diff.inDays / 30).floor();
        return '$m ${m == 1 ? 'month' : 'months'} ago';
      }
      if (diff.inDays >= 1) {
        return '${diff.inDays} ${diff.inDays == 1 ? 'day' : 'days'} ago';
      }
      if (diff.inHours >= 1) {
        return '${diff.inHours} ${diff.inHours == 1 ? 'hour' : 'hours'} ago';
      }
      return '${diff.inMinutes} min ago';
    } catch (_) {
      return '';
    }
  }

  Future<void> _openVideo(YouTubeVideo video) async {
    final uri = Uri.parse(video.watchUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open video')),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) return _buildShimmer();
    if (_hasError) return _buildError();

    final featured = _trendingVideos.take(5).toList();

    return SmartRefresher(
      controller: _refreshController,
      onRefresh: _onRefresh,
      header: const WaterDropHeader(
        waterDropColor: AppTheme.primaryCyan,
      ),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildGreeting()),
          SliverToBoxAdapter(child: _buildFeaturedCarousel(featured)),
          SliverToBoxAdapter(child: _buildSectionHeader('Trending Now')),
          SliverToBoxAdapter(child: _buildHorizontalList(_trendingVideos)),
          SliverToBoxAdapter(
              child: _buildSectionHeader('Recommended For You')),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) =>
                  _buildVerticalVideoCard(_recommendedVideos[index]),
              childCount: _recommendedVideos.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Greeting
  // ---------------------------------------------------------------------------

  Widget _buildGreeting() {
    final name = _userName();
    final greeting =
        name.isNotEmpty ? '${_greeting()}, $name' : _greeting();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        greeting,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Featured carousel
  // ---------------------------------------------------------------------------

  Widget _buildFeaturedCarousel(List<YouTubeVideo> videos) {
    if (videos.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        SizedBox(
          height: 210,
          child: PageView.builder(
            controller: _featuredPageController,
            itemCount: videos.length,
            onPageChanged: (i) => setState(() => _featuredPage = i),
            itemBuilder: (context, i) => _buildFeaturedCard(videos[i]),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            videos.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _featuredPage == i ? 20 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: _featuredPage == i
                    ? AppTheme.primaryCyan
                    : Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildFeaturedCard(YouTubeVideo video) {
    return GestureDetector(
      onTap: () => _openVideo(video),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: video.thumbnailUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  color: AppTheme.darkSecondary,
                  child: const Icon(Icons.play_circle_outline,
                      color: Colors.white54, size: 48),
                ),
              ),
              // gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.75),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      video.channelTitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // play icon
              const Center(
                child: Icon(Icons.play_circle_fill,
                    color: Colors.white70, size: 40),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section header
  // ---------------------------------------------------------------------------

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Horizontal trending list
  // ---------------------------------------------------------------------------

  Widget _buildHorizontalList(List<YouTubeVideo> videos) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: videos.length,
        itemBuilder: (context, index) =>
            _buildHorizontalVideoCard(videos[index]),
      ),
    );
  }

  Widget _buildHorizontalVideoCard(YouTubeVideo video) {
    return GestureDetector(
      onTap: () => _openVideo(video),
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: video.thumbnailUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    color: AppTheme.darkSecondary,
                    child: const Icon(Icons.play_circle_outline,
                        color: Colors.white54),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              video.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              video.channelTitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              _formatViews(video.viewCount),
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Vertical recommended list card
  // ---------------------------------------------------------------------------

  Widget _buildVerticalVideoCard(YouTubeVideo video) {
    return GestureDetector(
      onTap: () => _openVideo(video),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 130,
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: video.thumbnailUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      color: AppTheme.darkSecondary,
                      child: const Icon(Icons.play_circle_outline,
                          color: Colors.white54),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    video.channelTitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.65),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_formatViews(video.viewCount)}  •  ${_timeAgo(video.publishedAt)}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shimmer loading state
  // ---------------------------------------------------------------------------

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppTheme.darkSecondary,
      highlightColor: AppTheme.darkSecondary.withOpacity(0.5),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              height: 24,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 210,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              height: 18,
              width: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 5,
                itemBuilder: (_, __) => Container(
                  width: 180,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(
              4,
              (_) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Container(
                      width: 130,
                      height: 73,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 14,
                            color: Colors.white,
                            margin: const EdgeInsets.only(bottom: 6),
                          ),
                          Container(
                            height: 12,
                            width: 100,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Error state
  // ---------------------------------------------------------------------------

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded,
              color: Colors.white.withOpacity(0.5), size: 64),
          const SizedBox(height: 16),
          Text(
            'Could not load content',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check your connection and try again.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadContent,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryCyan,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
