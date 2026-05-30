import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../models/content_model.dart';
import '../../services/content_service.dart';
import '../../services/analytics_service.dart';
import '../../services/navigation_service.dart';
import '../../services/user_interaction_service.dart';

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
  Set<String> _followedCreators = {};
  Set<String> _likedContent = {};
  Set<String> _savedContent = {};

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

      final allContent = await ContentService.instance.getFeedContent();
      final shorts = allContent.where((content) =>
          content.contentType == ContentType.short ||
          content.contentType == ContentType.reel ||
          (content.durationSeconds != null &&
              content.durationSeconds! <= 180)).toList();

      final followed =
          UserInteractionService.instance.getFollowedCreatorIds().toSet();

      // Pre-populate liked/saved state from the persistence service
      final likedIds = <String>{};
      final savedIds = <String>{};
      for (final c in shorts) {
        if (UserInteractionService.instance.isLiked(c.id)) likedIds.add(c.id);
        if (UserInteractionService.instance.isSaved(c.id)) savedIds.add(c.id);
      }

      setState(() {
        _shortsContent = shorts;
        _isLoading = false;
        _followedCreators = followed;
        _likedContent = likedIds;
        _savedContent = savedIds;
      });

      await AnalyticsService.instance.trackUserInteraction(
        action: 'shorts_tab_viewed',
        screen: 'shorts',
        additionalData: {'shorts_count': shorts.length},
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

  // Fallback mock data shown only when ContentService returns nothing
  final List<Map<String, dynamic>> _mockShortsData = [
    {
      'id': 'dQw4w9WgXcQ',
      'title': 'Never Gonna Give You Up',
      'creator': 'Rick Astley',
      'duration': '0:53',
      'likes': '15.0M',
      'comments': '1.2M',
      'shares': '800K',
      'category': 'Music',
      'thumbnail': 'https://img.youtube.com/vi/dQw4w9WgXcQ/mqdefault.jpg',
      'description': 'The classic hit from Rick Astley.',
    },
    {
      'id': '9bZkp7q19f0',
      'title': 'PSY - GANGNAM STYLE',
      'creator': 'officialpsy',
      'duration': '0:58',
      'likes': '25.0M',
      'comments': '3.5M',
      'shares': '2.0M',
      'category': 'Music',
      'thumbnail': 'https://img.youtube.com/vi/9bZkp7q19f0/mqdefault.jpg',
      'description': 'The video that broke the YouTube view counter.',
    },
    {
      'id': 'kJQP7kiw5Fk',
      'title': 'Despacito',
      'creator': 'Luis Fonsi',
      'duration': '0:55',
      'likes': '50.0M',
      'comments': '5.0M',
      'shares': '3.0M',
      'category': 'Music',
      'thumbnail': 'https://img.youtube.com/vi/kJQP7kiw5Fk/mqdefault.jpg',
      'description': 'The most-streamed song of all time.',
    },
    {
      'id': 'JGwWNGJdvx8',
      'title': 'Shape of You',
      'creator': 'Ed Sheeran',
      'duration': '0:54',
      'likes': '28.0M',
      'comments': '2.8M',
      'shares': '1.5M',
      'category': 'Music',
      'thumbnail': 'https://img.youtube.com/vi/JGwWNGJdvx8/mqdefault.jpg',
      'description': 'Official music video for Shape of You.',
    },
    {
      'id': 'jNQXAC9IVRw',
      'title': 'Me at the zoo',
      'creator': 'jawed',
      'duration': '0:19',
      'likes': '3.5M',
      'comments': '250K',
      'shares': '100K',
      'category': 'History',
      'thumbnail': 'https://img.youtube.com/vi/jNQXAC9IVRw/mqdefault.jpg',
      'description': 'The very first video ever uploaded to YouTube.',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ─── Platform helpers ──────────────────────────────────────────────────────

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
    }
  }

  String _getPlatformLabel(PlatformType platform) {
    switch (platform) {
      case PlatformType.youtube:
        return 'YT';
      case PlatformType.instagram:
        return 'IG';
      case PlatformType.tiktok:
        return 'TT';
      case PlatformType.facebook:
        return 'FB';
    }
  }

  String _formatCount(int count) {
    if (count >= 1000000000) {
      return '${(count / 1000000000).toStringAsFixed(1)}B';
    }
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: _ShimmerFeed(),
      );
    }

    if (_hasError) {
      return _buildErrorState();
    }

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
            itemCount: itemCount,
            itemBuilder: (context, index) {
              if (_shortsContent.isNotEmpty) {
                return _buildShortItemFromContent(_shortsContent[index]);
              } else {
                return _buildMockShortItem(_mockShortsData[index]);
              }
            },
          ),
          // Progress dots overlaid at the top
          _buildProgressDots(itemCount),
        ],
      ),
    );
  }

  // ─── Error / empty states ──────────────────────────────────────────────────

  Widget _buildErrorState() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white54, size: 64),
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

  Widget _buildEmptyState() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_off_outlined,
              color: Colors.white.withValues(alpha: 0.4),
              size: 72,
            ),
            const SizedBox(height: 20),
            const Text(
              'No shorts available',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check back later for new content',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: _loadShortsContent,
              icon: const Icon(Icons.refresh, color: AppTheme.primaryCyan),
              label: const Text(
                'Refresh',
                style: TextStyle(color: AppTheme.primaryCyan),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Progress dots (animated pill indicators) ──────────────────────────────

  Widget _buildProgressDots(int count) {
    // Cap dots at 10 to avoid horizontal overflow on long feeds
    final displayCount = count.clamp(0, 10);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(displayCount, (i) {
            final active = i == _currentIndex.clamp(0, displayCount - 1);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: active ? 16 : 6,
              height: 4,
              decoration: BoxDecoration(
                color: active
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ─── Content short card ────────────────────────────────────────────────────

  Widget _buildShortItemFromContent(Content content) {
    final platformColor = _getPlatformColor(content.platform);
    final isLiked = _likedContent.contains(content.id);
    final isSaved = _savedContent.contains(content.id);
    final likeCount = UserInteractionService.instance
        .getLikeCount(content.id, baseCount: content.likeCount);

    return GestureDetector(
      onTap: () async {
        if (content.platform == PlatformType.youtube) {
          Navigator.pushNamed(context, AppRoutes.player, arguments: content);
        } else {
          final url = content.videoUrl;
          if (url != null && url.isNotEmpty) {
            final uri = Uri.tryParse(url);
            if (uri != null) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          }
        }
      },
      onDoubleTap: () => _handleLike(content),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Full-screen thumbnail ──────────────────────────────────────────
          _buildThumbnail(content, platformColor),

          // ── Bottom-to-top gradient overlay for readability ─────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.4, 1.0],
                ),
              ),
            ),
          ),

          // ── Platform badge (top-right, below safe area) ────────────────────
          Positioned(
            top: 56,
            right: 16,
            child: _buildPlatformBadge(content.platform, platformColor),
          ),

          // ── Right-side action buttons ──────────────────────────────────────
          Positioned(
            right: 10,
            bottom: 110,
            child: _buildInteractionButtons(
              content: content,
              isLiked: isLiked,
              isSaved: isSaved,
              likeCount: likeCount,
            ),
          ),

          // ── Bottom-left content info ───────────────────────────────────────
          Positioned(
            left: 14,
            right: 80,
            bottom: 110,
            child: _buildContentInfo(content),
          ),
        ],
      ),
    );
  }

  // ─── Thumbnail ─────────────────────────────────────────────────────────────

  Widget _buildThumbnail(Content content, Color platformColor) {
    final url = content.thumbnailUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        semanticLabel: content.title ?? 'Short video thumbnail',
        errorBuilder: (_, __, ___) =>
            _buildThumbnailFallback(content, platformColor),
      );
    }
    return _buildThumbnailFallback(content, platformColor);
  }

  Widget _buildThumbnailFallback(Content content, Color platformColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black,
            platformColor.withValues(alpha: 0.55),
            Colors.black,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.play_circle_outline,
              size: 72,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            if (content.title != null) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  content.title!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Platform badge ────────────────────────────────────────────────────────

  Widget _buildPlatformBadge(PlatformType platform, Color color) {
    final isInstagram = platform == PlatformType.instagram;
    final label = _getPlatformLabel(platform);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: isInstagram
            ? const LinearGradient(
                colors: [
                  Color(0xFF833AB4),
                  Color(0xFFE1306C),
                  Color(0xFFFD1D1D),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isInstagram ? null : color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // ─── Right-side interaction buttons ────────────────────────────────────────

  Widget _buildInteractionButtons({
    required Content content,
    required bool isLiked,
    required bool isSaved,
    required int likeCount,
  }) {
    final creatorId = content.creatorId ?? content.creatorName ?? content.id;
    final isFollowed = _followedCreators.contains(creatorId);
    final commentCount =
        (content.metadata['comments'] as num?)?.toInt() ?? 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Creator avatar with follow "+" badge at the top of the button stack
        _buildCreatorAvatarButton(content, creatorId, isFollowed),
        const SizedBox(height: 22),

        // Like — filled red when liked
        _buildActionButton(
          icon: isLiked ? Icons.favorite : Icons.favorite_border,
          label: _formatCount(likeCount),
          onTap: () => _handleLike(content),
          iconColor: isLiked ? Colors.red : Colors.white,
          semanticLabel: isLiked ? 'Unlike' : 'Like',
        ),
        const SizedBox(height: 22),

        // Comment
        _buildActionButton(
          icon: Icons.chat_bubble_outline,
          label: _formatCount(commentCount),
          onTap: () => _handleComment(content),
          semanticLabel: 'Comment',
        ),
        const SizedBox(height: 22),

        // Share — launches content URL externally
        _buildActionButton(
          icon: Icons.reply_outlined,
          label: 'Share',
          onTap: () => _handleShare(content),
          semanticLabel: 'Share',
        ),
        const SizedBox(height: 22),

        // Save / Bookmark
        _buildActionButton(
          icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
          label: isSaved ? 'Saved' : 'Save',
          onTap: () => _handleSave(content),
          iconColor: isSaved ? AppTheme.primaryCyan : Colors.white,
          semanticLabel: isSaved ? 'Remove bookmark' : 'Save to bookmarks',
        ),
      ],
    );
  }

  /// Creator avatar circle (40 dp) with a "+" or check follow badge overlaid.
  Widget _buildCreatorAvatarButton(
      Content content, String creatorId, bool isFollowed) {
    final avatarUrl = content.creatorAvatarUrl;
    final initial = (content.creatorName ?? '?')[0].toUpperCase();

    return Semantics(
      label: isFollowed ? 'Unfollow creator' : 'Follow creator',
      button: true,
      child: GestureDetector(
      onTap: () => _handleFollow(creatorId),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 52,
        height: 56,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // Avatar circle — 40 dp diameter as required
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                color: AppTheme.darkSecondary,
              ),
              clipBehavior: Clip.antiAlias,
              child: avatarUrl != null && avatarUrl.isNotEmpty
                  ? Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
            ),
            // Follow badge at the bottom of the avatar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: isFollowed ? Colors.green.shade600 : Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isFollowed ? Icons.check : Icons.add,
                    color: Colors.white,
                    size: 11,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  /// Single action button with minimum 44×44 dp touch target.
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
    String? semanticLabel,
  }) {
    return Semantics(
      label: semanticLabel ?? label,
      button: true,
      child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 52,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: Icon(icon, color: iconColor, size: 26),
              ),
            ),
            if (label.isNotEmpty)
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
      ),
    );
  }

  // ─── Content info (bottom-left overlay) ────────────────────────────────────

  Widget _buildContentInfo(Content content) {
    final creatorId = content.creatorId ?? content.creatorName ?? content.id;
    final isFollowed = _followedCreators.contains(creatorId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Creator name + inline follow button
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                '@${content.creatorName ?? 'Unknown'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _buildInlineFollowButton(creatorId, isFollowed),
          ],
        ),
        const SizedBox(height: 6),

        // Title — maxLines 2
        if (content.title != null)
          Text(
            content.title!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

        // Hashtags from content.tags — maxLines 1
        if (content.tags.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            content.tags.take(4).map((t) => '#$t').join(' '),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],

        // Audio info row
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.music_note, color: Colors.white70, size: 13),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                'Original audio · @${content.creatorName ?? 'Unknown'}',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInlineFollowButton(String creatorId, bool isFollowed) {
    return GestureDetector(
      onTap: () => _handleFollow(creatorId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isFollowed
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.transparent,
          border: Border.all(color: Colors.white, width: 1.5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          isFollowed ? 'Following' : 'Follow',
          style: TextStyle(
            color: isFollowed ? Colors.white70 : Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ─── Mock short card (shown when service returns 0 results) ───────────────

  Widget _buildMockShortItem(Map<String, dynamic> shortData) {
    final thumbnailUrl = shortData['thumbnail'] as String?;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background thumbnail or gradient fallback
        if (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
          Image.network(
            thumbnailUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildMockFallbackBg(),
          )
        else
          _buildMockFallbackBg(),

        // Gradient overlay
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.75),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.4, 1.0],
              ),
            ),
          ),
        ),

        // Centre play button
        Positioned.fill(
          child: Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        ),

        // Right-side actions
        Positioned(
          right: 10,
          bottom: 110,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActionButton(
                icon: Icons.favorite_border,
                label: shortData['likes'] as String? ?? '',
                onTap: () {},
              ),
              const SizedBox(height: 22),
              _buildActionButton(
                icon: Icons.chat_bubble_outline,
                label: shortData['comments'] as String? ?? '',
                onTap: () {},
              ),
              const SizedBox(height: 22),
              _buildActionButton(
                icon: Icons.reply_outlined,
                label: shortData['shares'] as String? ?? '',
                onTap: () {},
              ),
              const SizedBox(height: 22),
              _buildActionButton(
                icon: Icons.bookmark_border,
                label: 'Save',
                onTap: () {},
              ),
            ],
          ),
        ),

        // Bottom-left info
        Positioned(
          left: 14,
          right: 80,
          bottom: 110,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.primaryCyan,
                    child: Text(
                      ((shortData['creator'] as String?) ?? '?')[0]
                          .toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '@${shortData['creator'] ?? 'Unknown'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 1.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Follow',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                shortData['description'] as String? ?? '',
                style: const TextStyle(color: Colors.white, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  const Icon(Icons.music_note, color: Colors.white70, size: 13),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Original audio · @${shortData['creator'] ?? 'Unknown'}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMockFallbackBg() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkPrimary,
            AppTheme.primaryCyan.withValues(alpha: 0.25),
            AppTheme.darkPrimary,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  // ─── Interaction handlers ──────────────────────────────────────────────────

  /// Toggles the like state for [content] and persists via [UserInteractionService].
  void _handleLike(Content content) {
    final wasLiked = _likedContent.contains(content.id);
    setState(() {
      if (wasLiked) {
        _likedContent.remove(content.id);
      } else {
        _likedContent.add(content.id);
      }
    });
    UserInteractionService.instance
        .toggleLike(content.id, baseCount: content.likeCount);
    AnalyticsService.instance.trackUserInteraction(
      action: wasLiked ? 'short_unliked' : 'short_liked',
      screen: 'shorts',
      additionalData: {
        'content_id': content.id,
        'platform': content.platform.name,
      },
    );
  }

  Future<void> _handleSave(Content content) async {
    final wasSaved = _savedContent.contains(content.id);
    setState(() {
      if (wasSaved) {
        _savedContent.remove(content.id);
      } else {
        _savedContent.add(content.id);
      }
    });
    await UserInteractionService.instance.toggleSave(content.id);
    await AnalyticsService.instance.trackUserInteraction(
      action: wasSaved ? 'short_unsaved' : 'short_saved',
      screen: 'shorts',
      additionalData: {
        'content_id': content.id,
        'platform': content.platform.name,
      },
    );
  }

  Future<void> _handleFollow(String creatorId) async {
    final wasFollowed = _followedCreators.contains(creatorId);
    final next = await UserInteractionService.instance.toggleFollow(creatorId);
    setState(() {
      if (next) {
        _followedCreators.add(creatorId);
      } else {
        _followedCreators.remove(creatorId);
      }
    });
    await AnalyticsService.instance.trackUserInteraction(
      action: wasFollowed ? 'creator_unfollowed' : 'creator_followed',
      screen: 'shorts',
      additionalData: {'creator_id': creatorId},
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
    // TODO: Open comments bottom sheet
  }

  /// Tracks the share, then launches the content URL in an external browser.
  Future<void> _handleShare(Content content) async {
    await UserInteractionService.instance.trackShare(content.id);
    await AnalyticsService.instance.trackUserInteraction(
      action: 'short_shared',
      screen: 'shorts',
      additionalData: {
        'content_id': content.id,
        'platform': content.platform.name,
      },
    );

    final shareUrl = content.videoUrl ?? content.embedUrl;
    if (shareUrl != null && shareUrl.isNotEmpty) {
      final uri = Uri.tryParse(shareUrl);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }
}

// ─── Shimmer loading placeholder (shown while content is fetching) ─────────

class _ShimmerFeed extends StatelessWidget {
  const _ShimmerFeed();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade900,
      highlightColor: Colors.grey.shade700,
      child: Stack(
        children: [
          // Fake full-screen card background
          Container(color: Colors.grey.shade900),

          // Right-side action button stubs
          Positioned(
            right: 10,
            bottom: 120,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(4, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 22),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),
            ),
          ),

          // Bottom-left text stubs
          Positioned(
            left: 14,
            right: 80,
            bottom: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 120, height: 14, color: Colors.white),
                const SizedBox(height: 8),
                Container(
                    width: double.infinity, height: 12, color: Colors.white),
                const SizedBox(height: 6),
                Container(width: 160, height: 10, color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
