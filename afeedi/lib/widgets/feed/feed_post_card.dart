import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/content_model.dart';
import '../../services/content_service.dart';
import '../../screens/creator_profile_sheet.dart';
import '../../services/navigation_service.dart';

class FeedPostCard extends StatefulWidget {
  final Content content;
  final bool isHero;
  final int index;
  final bool isAiRecommended;

  const FeedPostCard({
    super.key,
    required this.content,
    this.isHero = false,
    this.index = 0,
    this.isAiRecommended = false,
  });

  @override
  State<FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends State<FeedPostCard> {
  bool _isLiked = false;
  bool _isSaved = false;
  bool _likeAnimating = false;
  bool _saveAnimating = false;

  // ---------------------------------------------------------------------------
  // Formatters
  // ---------------------------------------------------------------------------

  String _formatCount(int count) {
    if (count >= 1000000000)
      return '${(count / 1000000000).toStringAsFixed(1)}B';
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays >= 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays >= 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  // ---------------------------------------------------------------------------
  // Platform helpers
  // ---------------------------------------------------------------------------

  Color _platformColor(PlatformType platform) {
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

  String _platformLabel(PlatformType platform) {
    switch (platform) {
      case PlatformType.youtube:
        return 'YouTube';
      case PlatformType.instagram:
        return 'Instagram';
      case PlatformType.tiktok:
        return 'TikTok';
      case PlatformType.facebook:
        return 'Facebook';
    }
  }

  IconData _platformIcon(PlatformType platform) {
    switch (platform) {
      case PlatformType.youtube:
        return Icons.play_circle_outline;
      case PlatformType.instagram:
        return Icons.camera_alt;
      case PlatformType.tiktok:
        return Icons.music_note;
      case PlatformType.facebook:
        return Icons.facebook;
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final delay = Duration(milliseconds: widget.index * 50);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      // ignore: avoid_types_on_closure_parameters
      builder: (context, value, child) {
        // Apply stagger by delaying the start: treat values < delay-fraction as 0
        final totalMs = 300 + delay.inMilliseconds;
        final delayFraction = delay.inMilliseconds / totalMs;
        final progress = ((value - delayFraction) / (1.0 - delayFraction))
            .clamp(0.0, 1.0);
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, (1.0 - progress) * 20),
            child: child,
          ),
        );
      },
      child: widget.isHero ? _buildHeroCard() : _buildRegularCard(),
    );
  }

  Widget _buildRegularCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildTitleRow(),
          _buildThumbnail(),
          _buildEngagementRow(),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    final platform = widget.content.platform;
    final platformColor = _platformColor(platform);
    final initial = (widget.content.creatorName ?? 'U').isNotEmpty
        ? (widget.content.creatorName ?? 'U')[0].toUpperCase()
        : 'U';

    return GestureDetector(
      onTap: () {
        ContentService.instance.trackContentInteraction(
          contentId: widget.content.id,
          interactionType: InteractionType.view,
        );
        Navigator.pushNamed(
          context,
          AppRoutes.player,
          arguments: widget.content,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 220,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Full-bleed thumbnail
              if (widget.content.thumbnailUrl != null)
                CachedNetworkImage(
                  imageUrl: widget.content.thumbnailUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          platformColor.withValues(alpha: 0.6),
                          platformColor.withValues(alpha: 0.3),
                        ],
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) =>
                      Container(color: platformColor.withValues(alpha: 0.2)),
                )
              else
                Container(color: platformColor.withValues(alpha: 0.2)),

              // Full-width gradient overlay (top → bottom)
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87],
                    ),
                  ),
                ),
              ),

              // FEATURED badge — top-left
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D4FF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'FEATURED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),

              // Creator avatar — top-right
              Positioned(
                top: 10,
                right: 12,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    color: platformColor.withValues(alpha: 0.3),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: widget.content.creatorAvatarUrl != null
                      ? CachedNetworkImage(
                          imageUrl: widget.content.creatorAvatarUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Center(
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Center(
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
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
                              fontSize: 14,
                            ),
                          ),
                        ),
                ),
              ),

              // Bottom info: title + Watch Now CTA
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        widget.content.title ?? 'Featured Video',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 6),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D4FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '▶ Watch Now',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header: creator avatar + name + platform badge + time
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    final platform = widget.content.platform;
    final color = _platformColor(platform);
    final initial = (widget.content.creatorName ?? 'U').isNotEmpty
        ? (widget.content.creatorName ?? 'U')[0].toUpperCase()
        : 'U';

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Creator avatar (24 dp radius circle) — taps open creator profile
          GestureDetector(
            onTap: () => CreatorProfileSheet.show(context, widget.content),
            child: Semantics(
              label: 'View creator: ${widget.content.creatorName ?? 'Unknown'}',
              button: true,
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: widget.content.creatorAvatarUrl != null
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: widget.content.creatorAvatarUrl!,
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                _avatarInitial(initial, color),
                            errorWidget: (_, __, ___) =>
                                _avatarInitial(initial, color),
                          ),
                        )
                      : _avatarInitial(initial, color),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.content.creatorName ?? 'Unknown Creator',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildHeaderPlatformBadge(platform),
                  ],
                ),
                Row(
                  children: [
                    if (widget.isAiRecommended)
                      Semantics(
                        label: 'AI personalized pick',
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7B2FBE),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'AI Pick',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    Flexible(
                      child: Text(
                        widget.content.publishedAt != null
                            ? _formatTimeAgo(widget.content.publishedAt!)
                            : 'Unknown time',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More options',
            onPressed: () => _showMoreOptions(context),
          ),
        ],
      ),
    );
  }

  Widget _avatarInitial(String initial, Color color) {
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Small pill badge in the header row (icon + label, outline style).
  Widget _buildHeaderPlatformBadge(PlatformType platform) {
    final color = _platformColor(platform);
    final label = _platformLabel(platform);
    final icon = _platformIcon(platform);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Title
  // ---------------------------------------------------------------------------

  Widget _buildTitleRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        widget.content.title ?? 'No title',
        style: const TextStyle(
          fontSize: 15,
          height: 1.35,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Thumbnail with platform pill (top-right) and duration chip (bottom-right)
  // ---------------------------------------------------------------------------

  Widget _buildThumbnail() {
    final platform = widget.content.platform;
    final platformColor = _platformColor(platform);
    final durationText =
        widget.content.durationSeconds != null &&
            widget.content.durationSeconds! > 0
        ? _formatDuration(widget.content.durationSeconds!)
        : '';
    final initial = (widget.content.creatorName ?? 'U').isNotEmpty
        ? (widget.content.creatorName ?? 'U')[0].toUpperCase()
        : 'U';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: GestureDetector(
        onTap: () async {
          await ContentService.instance.trackContentInteraction(
            contentId: widget.content.id,
            interactionType: InteractionType.view,
          );
          if (context.mounted) {
            Navigator.pushNamed(
              context,
              AppRoutes.player,
              arguments: widget.content,
            );
          }
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              // Base gradient + thumbnail image
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      platformColor.withValues(alpha: 0.8),
                      platformColor.withValues(alpha: 0.4),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: widget.content.thumbnailUrl != null
                    ? Semantics(
                        label: widget.content.title ?? 'Video thumbnail',
                        child: CachedNetworkImage(
                          imageUrl: widget.content.thumbnailUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 200,
                          placeholder: (_, __) => const SizedBox.shrink(),
                          errorWidget: (_, __, ___) =>
                              _buildThumbnailFallback(platformColor, initial),
                        ),
                      )
                    : _buildThumbnailFallback(platformColor, initial),
              ),
              // Bottom gradient overlay for title legibility (Netflix/YouTube style)
              Container(
                height: 200,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black54],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.4, 1.0],
                  ),
                ),
              ),
              // Platform pill — top-right corner
              Positioned(
                top: 8,
                right: 8,
                child: _buildThumbnailPlatformPill(platform),
              ),
              // Play button — centered
              Positioned.fill(
                child: Center(
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: platformColor,
                      size: 32,
                    ),
                  ),
                ),
              ),
              // Duration chip — bottom-right corner
              if (durationText.isNotEmpty)
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      durationText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
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

  /// Platform-colored fallback shown when the thumbnail fails to load.
  Widget _buildThumbnailFallback(Color platformColor, String initial) {
    return Container(
      color: platformColor.withValues(alpha: 0.2),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_circle_outline, color: platformColor, size: 48),
            const SizedBox(height: 8),
            Text(
              initial,
              style: TextStyle(
                color: platformColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Colored pill overlaid on the thumbnail — solid fill for YouTube/TikTok/Facebook,
  /// gradient for Instagram.
  Widget _buildThumbnailPlatformPill(PlatformType platform) {
    final label = _platformLabel(platform);

    if (platform == PlatformType.instagram) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF833AB4), Color(0xFFE1306C), Color(0xFFF77737)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _platformColor(platform),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Engagement row: "1.2M views • 45K likes • 3d ago"
  // ---------------------------------------------------------------------------

  Widget _buildEngagementRow() {
    final timeAgo = widget.content.publishedAt != null
        ? _formatTimeAgo(widget.content.publishedAt!)
        : null;

    final viewsStr = '${_formatCount(widget.content.viewCount)} views';
    final parts = <String>[viewsStr, if (timeAgo != null) timeAgo];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Text(
        parts.join(' • '),
        style: const TextStyle(color: Colors.white54, fontSize: 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Action bar: like, bookmark, share, duration
  // ---------------------------------------------------------------------------

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Like
          Semantics(
            label: _isLiked ? 'Unlike' : 'Like',
            button: true,
            child: _buildActionButton(
              icon: _isLiked ? Icons.favorite : Icons.favorite_border,
              iconColor: _isLiked ? Colors.red : null,
              label: _formatCount(
                widget.content.likeCount + (_isLiked ? 1 : 0),
              ),
              animating: _likeAnimating,
              onTap: () async {
                HapticFeedback.lightImpact();
                setState(() {
                  _isLiked = !_isLiked;
                  _likeAnimating = true;
                });
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) setState(() => _likeAnimating = false);
                });
                await ContentService.instance.trackContentInteraction(
                  contentId: widget.content.id,
                  interactionType: InteractionType.like,
                );
              },
            ),
          ),
          const SizedBox(width: 20),
          // Share
          Semantics(
            label: 'Share',
            button: true,
            child: _buildActionButton(
              icon: Icons.share_outlined,
              label: 'Share',
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                await ContentService.instance.trackContentInteraction(
                  contentId: widget.content.id,
                  interactionType: InteractionType.share,
                );
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Link copied!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
          const Spacer(),
          // Duration label
          Text(
            widget.content.formattedDuration,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(width: 8),
          // Save / bookmark
          Semantics(
            label: _isSaved ? 'Remove bookmark' : 'Save to bookmarks',
            button: true,
            child: AnimatedScale(
              scale: _saveAnimating ? 1.3 : 1.0,
              duration: const Duration(milliseconds: 150),
              curve: Curves.elasticOut,
              child: IconButton(
                icon: Icon(
                  _isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: _isSaved ? Colors.cyan : null,
                ),
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _isSaved = !_isSaved;
                    _saveAnimating = true;
                  });
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (mounted) setState(() => _saveAnimating = false);
                  });
                  await ContentService.instance.trackContentInteraction(
                    contentId: widget.content.id,
                    interactionType: InteractionType.save,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            _moreOption(Icons.share_outlined, 'Share', () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Link copied!'),
                  duration: Duration(seconds: 2),
                ),
              );
            }),
            _moreOption(
              _isSaved ? Icons.bookmark : Icons.bookmark_border,
              _isSaved ? 'Remove bookmark' : 'Save to Watch Later',
              () async {
                Navigator.pop(context);
                setState(() => _isSaved = !_isSaved);
                await ContentService.instance.trackContentInteraction(
                  contentId: widget.content.id,
                  interactionType: InteractionType.save,
                );
              },
            ),
            _moreOption(
              Icons.not_interested,
              'Not interested',
              () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _moreOption(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 15),
      ),
      onTap: onTap,
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    Color? iconColor,
    required String label,
    required VoidCallback onTap,
    bool animating = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: animating ? 1.3 : 1.0,
              duration: const Duration(milliseconds: 150),
              curve: Curves.elasticOut,
              child: Icon(icon, size: 22, color: iconColor),
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
