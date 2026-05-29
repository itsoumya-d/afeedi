import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/content_model.dart';
import '../../services/content_service.dart';
import '../../services/analytics_service.dart';

class ShortsTab extends StatefulWidget {
  const ShortsTab({super.key});

  @override
  State<ShortsTab> createState() => _ShortsTabState();
}

class _ShortsTabState extends State<ShortsTab> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  List<Content> _shortsContent = [];
  bool _isLoading = true;
  bool _hasError = false;

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
      final shorts = allContent.where((content) => 
        content.contentType == ContentType.short || 
        content.contentType == ContentType.reel ||
        (content.durationSeconds != null && content.durationSeconds! <= 180)
      ).toList();
      
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
      'thumbnail': 'https://via.placeholder.com/300x400/FF6B6B/FFFFFF?text=Cooking+Tips',
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
      'thumbnail': 'https://via.placeholder.com/300x400/4ECDC4/FFFFFF?text=Tech+Review',
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
      'thumbnail': 'https://via.placeholder.com/300x400/45B7D1/FFFFFF?text=Fitness',
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
      'thumbnail': 'https://via.placeholder.com/300x400/96CEB4/FFFFFF?text=Art+Tutorial',
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
      'thumbnail': 'https://via.placeholder.com/300x400/FFEAA7/FFFFFF?text=Travel',
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
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryCyan),
          ),
        ),
      );
    }
    
    if (_hasError) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Failed to load shorts',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadShortsContent,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
          
          // Track short view
          if (_shortsContent.isNotEmpty && index < _shortsContent.length) {
            AnalyticsService.instance.trackUserInteraction(
              action: 'short_viewed',
              screen: 'shorts',
              additionalData: {
                'content_id': _shortsContent[index].id,
                'platform': _shortsContent[index].platform.name,
                'index': index,
              },
            );
          }
        },
        itemCount: _shortsContent.isNotEmpty ? _shortsContent.length : _mockShortsData.length,
        itemBuilder: (context, index) {
          if (_shortsContent.isNotEmpty) {
            return _buildShortItemFromContent(_shortsContent[index]);
          } else {
            return _buildShortItem(_mockShortsData[index]);
          }
        },
      ),
    );
  }
  
  Color _getPlatformColor(PlatformType platform) {
    switch (platform) {
      case PlatformType.youtube:
        return const Color(0xFFFF0000);
      case PlatformType.instagram:
        return const Color(0xFFE1306C);
      case PlatformType.tiktok:
        return const Color(0xFF010101);
      case PlatformType.facebook:
        return const Color(0xFF1877F2);
      default:
        return AppTheme.primaryCyan;
    }
  }

  Widget _buildShortItemFromContent(Content content) {
    final platformColor = _getPlatformColor(content.platform);

    return Stack(
      children: [
        // Background: thumbnail image with gradient fallback
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black,
                  platformColor.withOpacity(0.4),
                  Colors.black,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: content.thumbnailUrl != null
                ? Image.network(
                    content.thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  )
                : null,
          ),
        ),

        // Dark gradient overlay at bottom for readability
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                begin: Alignment.center,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),

        // Platform logo top-right
        Positioned(
          top: 48,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: platformColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              content.platform.name.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),

        // Play button in center
        Positioned.fill(
          child: Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
            ),
          ),
        ),

        // Interaction buttons right side
        Positioned(
          right: 12,
          bottom: 100,
          child: _buildInteractionButtons(content),
        ),

        // Content info bottom left
        Positioned(
          left: 12,
          bottom: 100,
          right: 80,
          child: _buildContentInfo(content),
        ),
      ],
    );
  }
  
  String _formatCount(int count) {
    if (count >= 1000000000) return '${(count / 1000000000).toStringAsFixed(1)}B';
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  Widget _buildInteractionButtons(Content content) {
    return Column(
      children: [
        _buildActionButton(
          icon: Icons.favorite_border,
          label: _formatCount(content.likeCount),
          onTap: () => _handleLike(content),
        ),
        const SizedBox(height: 20),
        _buildActionButton(
          icon: Icons.comment,
          label: '${content.metadata['comments'] ?? 0}',
          onTap: () => _handleComment(content),
        ),
        const SizedBox(height: 20),
        _buildActionButton(
          icon: Icons.share,
          label: 'Share',
          onTap: () => _handleShare(content),
        ),
        const SizedBox(height: 20),
        _buildActionButton(
          icon: Icons.more_vert,
          label: '',
          onTap: () => _showMoreOptions(content),
        ),
      ],
    );
  }
  
  Widget _buildContentInfo(Content content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Creator name + Follow button (Instagram Reels / YouTube Shorts pattern)
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '@${content.creatorName ?? 'Unknown'}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 1.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Follow',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (content.title != null)
          Text(
            content.title!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        if (content.description != null) ...[
          const SizedBox(height: 3),
          Text(
            content.description!,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        // Music info line (Instagram Reels pattern)
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.music_note, color: Colors.white70, size: 12),
            const SizedBox(width: 4),
            Text(
              '${content.creatorName ?? 'Original'} · Original Audio',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
  
  void _handleLike(Content content) {
    AnalyticsService.instance.trackUserInteraction(
      action: 'short_liked',
      screen: 'shorts',
      additionalData: {
        'content_id': content.id,
        'platform': content.platform.name,
      },
    );
  }
  
  void _handleComment(Content content) {
    AnalyticsService.instance.trackUserInteraction(
      action: 'short_comment_opened',
      screen: 'shorts',
      additionalData: {
        'content_id': content.id,
        'platform': content.platform.name,
      },
    );
    // TODO: Open comment sheet
  }
  
  void _handleShare(Content content) {
    AnalyticsService.instance.trackUserInteraction(
      action: 'short_shared',
      screen: 'shorts',
      additionalData: {
        'content_id': content.id,
        'platform': content.platform.name,
      },
    );
    // TODO: Implement share functionality
  }
  
  void _showMoreOptions(Content content) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.report, color: Colors.white),
              title: const Text('Report', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.white),
              title: const Text('Not Interested', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortItem(Map<String, dynamic> shortData) {
    return Stack(
      children: [
        // Video/Content Background
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.black.withOpacity(0.7),
              ],
            ),
          ),
          child: Center(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.primaryCyan.withOpacity(0.1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.play_circle_outline,
                    size: 80,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    shortData['title'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPink,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      shortData['category'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Right Side Actions
        Positioned(
          right: 12,
          bottom: 100,
          child: Column(
            children: [
              _buildActionButton(
                icon: Icons.favorite_border,
                label: shortData['likes'],
                onTap: () {},
              ),
              const SizedBox(height: 20),
              _buildActionButton(
                icon: Icons.comment_outlined,
                label: shortData['comments'],
                onTap: () {},
              ),
              const SizedBox(height: 20),
              _buildActionButton(
                icon: Icons.share_outlined,
                label: shortData['shares'],
                onTap: () {},
              ),
              const SizedBox(height: 20),
              _buildActionButton(
                icon: Icons.bookmark_border,
                label: '',
                onTap: () {},
              ),
            ],
          ),
        ),

        // Bottom Content Info
        Positioned(
          left: 12,
          right: 80,
          bottom: 100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.primaryCyan,
                    child: Text(
                      shortData['creator'][0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    shortData['creator'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Follow',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                shortData['description'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    shortData['duration'],
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Top Safe Area with Progress Indicators
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: List.generate(
                        _shortsContent.isNotEmpty ? _shortsContent.length : _mockShortsData.length,
                        (index) => Expanded(
                          child: Container(
                            height: 2,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: index <= _currentIndex
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          if (label.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ]
        ],
      ),
    );
  }
}