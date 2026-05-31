import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../services/content_service.dart';
import '../../models/content_model.dart';
import '../streaming/responsive_video_player.dart';

class VideosTab extends StatefulWidget {
  const VideosTab({super.key});

  @override
  State<VideosTab> createState() => _VideosTabState();
}

class _VideosTabState extends State<VideosTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final List<Map<String, dynamic>> _categories = [
    {
      'id': 'trending',
      'name': 'Trending',
      'icon': Icons.trending_up,
      'color': const Color(0xFFFF6B6B),
    },
    {
      'id': 'educational',
      'name': 'Educational',
      'icon': Icons.school,
      'color': const Color(0xFF4ECDC4),
    },
    {
      'id': 'entertainment',
      'name': 'Entertainment',
      'icon': Icons.movie,
      'color': const Color(0xFFFFE66D),
    },
    {
      'id': 'music',
      'name': 'Music',
      'icon': Icons.music_note,
      'color': const Color(0xFFA8E6CF),
    },
  ];

  String _selectedCategory = 'trending';
  List<Content> _videos = [];
  bool _isLoading = false;

  /// Whether the grid is in 2-column grid mode (true) or list mode (false).
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  void _loadVideos() async {
    setState(() => _isLoading = true);
    try {
      final videos = await ContentService.instance.getVideosByCategory(
        _selectedCategory,
      );
      setState(() {
        _videos = videos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading videos: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Formatters
  // ---------------------------------------------------------------------------

  String _formatCount(int count) {
    if (count >= 1000000000) {
      return '${(count / 1000000000).toStringAsFixed(1)}B';
    }
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inDays >= 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays >= 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  Color _getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'youtube':
        return const Color(0xFFFF0000);
      case 'instagram':
        return const Color(0xFFE4405F);
      case 'tiktok':
        return const Color(0xFF000000);
      case 'facebook':
        return const Color(0xFF1877F2);
      default:
        return AppTheme.primaryCyan;
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        _buildHeader(),
        _buildCategoryTabs(),
        Expanded(child: _buildVideoContent()),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Header — title + grid/list toggle
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Videos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Discover amazing content from all platforms',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Grid / List toggle
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _buildToggleButton(
                  icon: Icons.grid_view,
                  isActive: _isGridView,
                  onTap: () => setState(() => _isGridView = true),
                  tooltip: 'Grid view',
                ),
                _buildToggleButton(
                  icon: Icons.view_list,
                  isActive: !_isGridView,
                  onTap: () => setState(() => _isGridView = false),
                  tooltip: 'List view',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryCyan : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isActive
                ? Colors.black87
                : Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Category tabs
  // ---------------------------------------------------------------------------

  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category['id'];
          final color = category['color'] as Color;

          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategory = category['id'] as String);
              _loadVideos();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected
                      ? color
                      : Colors.white.withValues(alpha: 0.3),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category['icon'] as IconData,
                    color: isSelected
                        ? color
                        : Colors.white.withValues(alpha: 0.7),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category['name'] as String,
                    style: TextStyle(
                      color: isSelected
                          ? color
                          : Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Video content (grid or list)
  // ---------------------------------------------------------------------------

  Widget _buildVideoContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryCyan),
        ),
      );
    }

    if (_videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 64,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No videos in this category',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    return _isGridView ? _buildGrid() : _buildList();
  }

  Widget _buildGrid() {
    return GridView.builder(
      // 16dp horizontal padding, 8dp grid gaps
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.78,
      ),
      itemCount: _videos.length,
      itemBuilder: (context, index) => _buildVideoCard(_videos[index]),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _videos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _buildVideoListTile(_videos[index]),
    );
  }

  // ---------------------------------------------------------------------------
  // Grid card
  // ---------------------------------------------------------------------------

  Widget _buildVideoCard(Content video) {
    final platformColor = _getPlatformColor(video.platform.name);
    final initial = (video.creatorName ?? 'U').isNotEmpty
        ? (video.creatorName ?? 'U')[0].toUpperCase()
        : 'U';

    return GestureDetector(
      onTap: () => _playVideo(video),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail area
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Thumbnail image with errorBuilder fallback
                    _buildThumbnailImage(video, platformColor, initial),
                    // Play overlay
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    // Duration badge — bottom-right
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: _buildDurationChip(video),
                    ),
                    // Platform badge — top-left
                    Positioned(
                      top: 6,
                      left: 6,
                      child: _buildPlatformChip(video.platform.name),
                    ),
                  ],
                ),
              ),
            ),
            // Info area
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title ?? 'Untitled',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      video.creatorName ?? 'Unknown Creator',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Views + likes row
                    Row(
                      children: [
                        Icon(
                          Icons.visibility,
                          size: 11,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            _formatCount(video.viewCount),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.favorite,
                          size: 11,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            _formatCount(video.likeCount),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (video.publishedAt != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        _formatTimeAgo(video.publishedAt!),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 9,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
  // List tile (list view mode)
  // ---------------------------------------------------------------------------

  Widget _buildVideoListTile(Content video) {
    final platformColor = _getPlatformColor(video.platform.name);
    final initial = (video.creatorName ?? 'U').isNotEmpty
        ? (video.creatorName ?? 'U')[0].toUpperCase()
        : 'U';

    return GestureDetector(
      onTap: () => _playVideo(video),
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
              child: SizedBox(
                width: 140,
                height: 96,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildThumbnailImage(video, platformColor, initial),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: _buildDurationChip(video),
                    ),
                  ],
                ),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title ?? 'Untitled',
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
                      video.creatorName ?? 'Unknown Creator',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      '${_formatCount(video.viewCount)} views'
                      '${video.publishedAt != null ? ' • ${_formatTimeAgo(video.publishedAt!)}' : ''}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
  // Shared sub-widgets
  // ---------------------------------------------------------------------------

  /// Thumbnail image widget with platform-colored fallback on error.
  Widget _buildThumbnailImage(
    Content video,
    Color platformColor,
    String initial,
  ) {
    if (video.thumbnailUrl == null || video.thumbnailUrl!.isEmpty) {
      return _thumbnailFallback(platformColor, initial);
    }
    return CachedNetworkImage(
      imageUrl: video.thumbnailUrl!,
      fit: BoxFit.cover,
      placeholder: (_, __) =>
          Container(color: platformColor.withValues(alpha: 0.2)),
      errorWidget: (_, __, ___) => _thumbnailFallback(platformColor, initial),
    );
  }

  Widget _thumbnailFallback(Color platformColor, String initial) {
    return Container(
      color: platformColor.withValues(alpha: 0.2),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_circle_outline, color: platformColor, size: 32),
            const SizedBox(height: 4),
            Text(
              initial,
              style: TextStyle(
                color: platformColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationChip(Content video) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        video.formattedDuration,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPlatformChip(String platform) {
    final color = _getPlatformColor(platform);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        platform,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Video playback dialog
  // ---------------------------------------------------------------------------

  void _playVideo(Content video) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.95,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          video.title ?? 'Video Player',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                ),
                // Player
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ResponsiveVideoPlayer(
                        content: video,
                        autoPlay: true,
                        showControls: true,
                        showBranding: true,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
