import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../models/content_model.dart';
import '../../services/content_service.dart';

class FeedPostCard extends StatelessWidget {
  final Content content;

  const FeedPostCard({super.key, required this.content});

  // ---------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  bool get _isNew {
    if (content.publishedAt == null) return false;
    return DateTime.now().difference(content.publishedAt!).inHours < 24;
  }

  String _formatViewCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M views';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K views';
    }
    return '$count views';
  }

  // ---------------------------------------------------------------
  // Platform branding
  // ---------------------------------------------------------------

  Color _platformColor(PlatformType platform) {
    switch (platform) {
      case PlatformType.youtube:
        return const Color(0xFFFF0000);
      case PlatformType.instagram:
        return const Color(0xFFE4405F);
      case PlatformType.tiktok:
        return const Color(0xFF000000);
      case PlatformType.facebook:
        return const Color(0xFF1877F2);
    }
  }

  IconData _platformIcon(PlatformType platform) {
    switch (platform) {
      case PlatformType.youtube:
        return Icons.play_circle_outline;
      case PlatformType.instagram:
        return Icons.camera_alt_outlined;
      case PlatformType.tiktok:
        return Icons.music_video_outlined;
      case PlatformType.facebook:
        return Icons.facebook;
    }
  }

  String _platformName(PlatformType platform) {
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

  // ---------------------------------------------------------------
  // Video open
  // ---------------------------------------------------------------

  Future<void> _openVideo(BuildContext context) async {
    await ContentService.instance.trackContentInteraction(
      contentId: content.id,
      interactionType: InteractionType.view,
    );

    final Uri url;
    switch (content.platform) {
      case PlatformType.youtube:
        url = Uri.parse(
            'https://www.youtube.com/watch?v=${content.platformContentId}');
        break;
      default:
        final raw = content.videoUrl ?? content.embedUrl ?? '';
        if (raw.isEmpty) {
          _showSnackbar(
              context, 'No video URL available for ${_platformName(content.platform)}');
          return;
        }
        url = Uri.parse(raw);
    }

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _showSnackbar(
          context, 'Unable to open ${_platformName(content.platform)}. Please try again.');
    }
  }

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _platformColor(content.platform),
      ),
    );
  }

  // ---------------------------------------------------------------
  // Schedule
  // ---------------------------------------------------------------

  Future<void> _scheduleVideo(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'Schedule for Later',
    );

    if (pickedTime != null && context.mounted) {
      await ContentService.instance.trackContentInteraction(
        contentId: content.id,
        interactionType: InteractionType.schedule,
      );

      final now = DateTime.now();
      final scheduled = DateTime(
          now.year, now.month, now.day, pickedTime.hour, pickedTime.minute);
      final formatted =
          '${pickedTime.format(context)} – "${content.title ?? 'Video'}" scheduled!';
      _showSnackbar(context, formatted);
    }
  }

  // ---------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          _buildThumbnail(context),
          _buildInfo(context),
          _buildActions(context),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // Header row: avatar + creator + platform badge + time + menu
  // ---------------------------------------------------------------

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: content.creatorAvatarUrl != null
                ? CachedNetworkImageProvider(content.creatorAvatarUrl!)
                : null,
            backgroundColor: _platformColor(content.platform).withOpacity(0.15),
            child: content.creatorAvatarUrl == null
                ? Icon(_platformIcon(content.platform),
                    size: 18, color: _platformColor(content.platform))
                : null,
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
                        content.creatorName ?? 'Unknown Creator',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _buildPlatformBadge(content.platform),
                    if (_isNew) ...[
                      const SizedBox(width: 6),
                      _buildNewBadge(),
                    ],
                  ],
                ),
                Text(
                  content.publishedAt != null
                      ? _formatTimeAgo(content.publishedAt!)
                      : 'Unknown time',
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformBadge(PlatformType platform) {
    final color = _platformColor(platform);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_platformIcon(platform), size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            _platformName(platform),
            style: TextStyle(
                color: color, fontSize: 9, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildNewBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'NEW',
        style: TextStyle(
            color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ---------------------------------------------------------------
  // Thumbnail with overlays
  // ---------------------------------------------------------------

  Widget _buildThumbnail(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GestureDetector(
        onTap: () => _openVideo(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Thumbnail image
                _buildThumbnailImage(),

                // Bottom gradient for readability
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 60,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                ),

                // Play button overlay
                Center(
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: _platformColor(content.platform),
                      size: 36,
                    ),
                  ),
                ),

                // Duration badge — bottom left
                if (content.durationSeconds != null)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        content.formattedDuration,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                // Schedule (clock) button — bottom right
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _scheduleVideo(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.schedule,
                          color: Colors.white,
                          size: 18,
                        ),
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

  Widget _buildThumbnailImage() {
    if (content.thumbnailUrl != null && content.thumbnailUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: content.thumbnailUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => _thumbnailPlaceholder(),
        errorWidget: (context, url, error) => _thumbnailPlaceholder(),
      );
    }
    return _thumbnailPlaceholder();
  }

  Widget _thumbnailPlaceholder() {
    return Container(
      color: Colors.grey[900],
      child: Center(
        child: Icon(
          _platformIcon(content.platform),
          color: _platformColor(content.platform).withOpacity(0.5),
          size: 48,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // Info: title + view count
  // ---------------------------------------------------------------

  Widget _buildInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            content.title ?? 'No title',
            style: const TextStyle(
                fontSize: 13, height: 1.3, fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // View count
          Text(
            _formatViewCount(content.viewCount),
            style: TextStyle(color: Colors.grey[600], fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // Actions row
  // ---------------------------------------------------------------

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Row(
        children: [
          _buildActionButton(
            icon: Icons.favorite_border,
            count: content.likeCount,
            onTap: () async {
              await ContentService.instance.trackContentInteraction(
                contentId: content.id,
                interactionType: InteractionType.like,
              );
            },
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: Icons.share_outlined,
            count: 0,
            onTap: () async {
              await ContentService.instance.trackContentInteraction(
                contentId: content.id,
                interactionType: InteractionType.share,
              );
            },
          ),
          const Spacer(),
          // Watch button
          TextButton.icon(
            onPressed: () => _openVideo(context),
            icon: Icon(
              Icons.play_arrow_rounded,
              size: 18,
              color: _platformColor(content.platform),
            ),
            label: Text(
              'Watch',
              style: TextStyle(
                color: _platformColor(content.platform),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            iconSize: 20,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            onPressed: () async {
              await ContentService.instance.trackContentInteraction(
                contentId: content.id,
                interactionType: InteractionType.save,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required int count,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 3),
            Text(_formatViewCount(count).replaceAll(' views', ''),
                style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
