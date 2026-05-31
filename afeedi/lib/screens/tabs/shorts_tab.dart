import 'package:flutter/material.dart';
import '../../models/content_model.dart';
import '../../services/content_service.dart';
import '../../widgets/streaming/responsive_video_player.dart';
import '../../services/analytics_service.dart';

class ShortsTab extends StatefulWidget {
  const ShortsTab({super.key});

  @override
  State<ShortsTab> createState() => _ShortsTabState();
}

class _ShortsTabState extends State<ShortsTab>
    with AutomaticKeepAliveClientMixin {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  List<Content> _shortsContent = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadShortsContent();
  }

  Future<void> _loadShortsContent() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Load short-form content from ContentService
      final allContent = await ContentService.instance.getFeedContent();
      final shorts = allContent
          .where((content) =>
              content.contentType == ContentType.short ||
              content.contentType == ContentType.reel ||
              (content.durationSeconds != null &&
                  content.durationSeconds! <= 180))
          .toList();

      setState(() {
        _shortsContent = shorts;
        _isLoading = false;
      });

      // Track shorts tab view
      await AnalyticsService.instance.trackUserInteraction(
        action: 'shorts_tab_viewed',
        screen: 'shorts',
        additionalData: {
          'shorts_count': shorts.length,
        },
      );
    } catch (error) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });

      await AnalyticsService.instance.trackError(
        errorType: 'shorts_loading_error',
        errorMessage: error.toString(),
        screen: 'shorts',
      );
    }
  }

  // Fallback mock data for demonstration
  final List<Map<String, dynamic>> _mockShortsData = [
    {
      'id': '1',
      'title': 'Quick Cooking Tips',
      'creator': 'Chef Maria',
      'duration': '0:45',
      'likes': '12.5K',
      'comments': '234',
      'shares': '89',
      'category': 'Food',
      'thumbnail':
          'https://via.placeholder.com/300x400/FF6B6B/FFFFFF?text=Cooking+Tips',
      'description': 'Learn how to make perfect pasta in under 10 minutes!',
    },
    {
      'id': '2',
      'title': 'Tech Review: Latest Gadgets',
      'creator': 'TechGuru',
      'duration': '1:20',
      'likes': '8.9K',
      'comments': '156',
      'shares': '67',
      'category': 'Technology',
      'thumbnail':
          'https://via.placeholder.com/300x400/4ECDC4/FFFFFF?text=Tech+Review',
      'description': 'Unboxing and reviewing the newest smartphone features.',
    },
    {
      'id': '3',
      'title': 'Fitness Challenge',
      'creator': 'FitLife',
      'duration': '0:30',
      'likes': '15.2K',
      'comments': '445',
      'shares': '123',
      'category': 'Health',
      'thumbnail':
          'https://via.placeholder.com/300x400/45B7D1/FFFFFF?text=Fitness',
      'description': '30-second workout that you can do anywhere!',
    },
    {
      'id': '4',
      'title': 'Art Tutorial',
      'creator': 'ArtisticSoul',
      'duration': '2:15',
      'likes': '6.7K',
      'comments': '89',
      'shares': '45',
      'category': 'Art',
      'thumbnail':
          'https://via.placeholder.com/300x400/96CEB4/FFFFFF?text=Art+Tutorial',
      'description': 'Learn watercolor techniques for beginners.',
    },
    {
      'id': '5',
      'title': 'Travel Vlog',
      'creator': 'Wanderlust',
      'duration': '1:45',
      'likes': '22.1K',
      'comments': '567',
      'shares': '234',
      'category': 'Travel',
      'thumbnail':
          'https://via.placeholder.com/300x400/FFEAA7/FFFFFF?text=Travel',
      'description': 'Hidden gems in Tokyo that tourists never see!',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
            child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_hasError) {
      return _buildErrorState();
    }

    // Use mock data if real content is empty
    final itemCount = _shortsContent.isNotEmpty
        ? _shortsContent.length
        : _mockShortsData.length;

    if (itemCount == 0) {
      return _buildEmptyState();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
              AnalyticsService.instance.trackUserInteraction(
                action: 'short_viewed',
                screen: 'shorts',
                additionalData: {'index': index},
              );
            },
            itemCount: itemCount,
            itemBuilder: (context, index) {
              if (_shortsContent.isNotEmpty) {
                return _buildContentShortCard(_shortsContent[index], index);
              } else {
                return _buildMockShortCard(_mockShortsData[index], index);
              }
            },
          ),
          // Top overlay with tab title
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 8, 16, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black.withOpacity(0.7), Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Shorts',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMockShortCard(Map<String, dynamic> short, int index) {
    // Use gradient colors based on category
    final gradients = [
      [const Color(0xFF1A0A3E), const Color(0xFF3D1B6E)],
      [const Color(0xFF0D1B2A), const Color(0xFF1A3A5C)],
      [const Color(0xFF1A0A2E), const Color(0xFF3D0A4E)],
      [const Color(0xFF0A1A1A), const Color(0xFF0A3A2A)],
    ];
    final gradient = gradients[index % gradients.length];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // Play icon in center
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow,
                  color: Colors.white, size: 48),
            ),
          ),
          // Bottom info
          Positioned(
            left: 16,
            bottom: 100,
            right: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        short['category'] as String? ?? 'Video',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '@${(short['creator'] as String? ?? 'Creator').toLowerCase().replaceAll(' ', '')}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  short['title'] as String? ?? 'Short Video',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.9), fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.music_note,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Original Sound • ${short['creator']}',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Right side actions
          Positioned(
            right: 12,
            bottom: 100,
            child: Column(
              children: [
                _buildActionButton(
                    Icons.favorite, short['likes'] as String? ?? '0'),
                const SizedBox(height: 20),
                _buildActionButton(
                    Icons.comment, short['comments'] as String? ?? '0'),
                const SizedBox(height: 20),
                _buildActionButton(
                    Icons.share, short['shares'] as String? ?? '0'),
                const SizedBox(height: 20),
                _buildActionButton(Icons.bookmark_border, 'Save'),
                const SizedBox(height: 20),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  child: const Icon(Icons.more_horiz,
                      color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
          // Duration badge
          Positioned(
            bottom: 80,
            left: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                short['duration'] as String? ?? '0:30',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildContentShortCard(Content content, int index) {
    return Stack(
      children: [
        // Video player
        Positioned.fill(
          child: ResponsiveVideoPlayer(
            content: content,
            autoPlay: true,
            showControls: false,
            showBranding: true,
          ),
        ),

        // Right side interaction buttons
        Positioned(
          right: 12,
          bottom: 100,
          child: _buildInteractionButtons(content),
        ),

        // Bottom content info
        Positioned(
          left: 12,
          bottom: 100,
          right: 80,
          child: _buildContentInfo(content),
        ),
      ],
    );
  }

  Widget _buildInteractionButtons(Content content) {
    return Column(
      children: [
        _buildActionButton(
          Icons.favorite_border,
          content.formattedLikeCount,
        ),
        const SizedBox(height: 20),
        _buildActionButton(
          Icons.comment,
          '${content.metadata['comments'] ?? 0}',
        ),
        const SizedBox(height: 20),
        _buildActionButton(
          Icons.share,
          'Share',
        ),
        const SizedBox(height: 20),
        _buildActionButton(
          Icons.bookmark_border,
          'Save',
        ),
      ],
    );
  }

  Widget _buildContentInfo(Content content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '@${content.creatorName ?? 'Unknown'}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        if (content.title != null)
          Text(
            content.title!,
            style: TextStyle(
                color: Colors.white.withOpacity(0.9), fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        if (content.description != null) ...[
          const SizedBox(height: 4),
          Text(
            content.description!,
            style: TextStyle(
                color: Colors.white.withOpacity(0.7), fontSize: 12),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.music_note, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text(
              'Original Sound • ${content.creatorName ?? 'Unknown'}',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.8), fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library_outlined,
                color: Colors.white30, size: 64),
            SizedBox(height: 16),
            Text('No shorts available',
                style: TextStyle(color: Colors.white70, fontSize: 18)),
            SizedBox(height: 8),
            Text('Check back later for new content',
                style: TextStyle(color: Colors.white38, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.orange, size: 64),
            const SizedBox(height: 16),
            const Text('Failed to load',
                style: TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadShortsContent,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
