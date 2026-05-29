import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../models/content_model.dart';
import '../../services/content_service.dart';

class FeedPostCard extends StatelessWidget {
  final Content content;

  const FeedPostCard({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildContent(),
          _buildVideoPlayer(),
          _buildActions(),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000000) return '${(count / 1000000000).toStringAsFixed(1)}B';
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays >= 365) {
      final years = (difference.inDays / 365).floor();
      return '${years}y ago';
    } else if (difference.inDays >= 30) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: content.thumbnailUrl != null 
                ? CachedNetworkImageProvider(content.thumbnailUrl!)
                : null,
            backgroundColor: AppTheme.primaryCyan.withOpacity(0.1),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      content.creatorName ?? 'Unknown Creator',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildPlatformBadge(content.platform.name),
                  ],
                ),
                Text(
                  content.publishedAt != null 
                      ? _formatTimeAgo(content.publishedAt!)
                      : 'Unknown time',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Show more options
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformBadge(String platform) {
    Color color;
    IconData icon;
    
    switch (platform.toLowerCase()) {
      case 'youtube':
        color = const Color(0xFFFF0000);
        icon = Icons.play_circle_outline;
        break;
      case 'instagram':
        color = const Color(0xFFE4405F);
        icon = Icons.camera_alt;
        break;
      case 'tiktok':
        color = const Color(0xFF69C9D0);
        icon = Icons.music_note;
        break;
      case 'facebook':
        color = const Color(0xFF1877F2);
        icon = Icons.facebook;
        break;
      case 'twitter':
        color = const Color(0xFF1DA1F2);
        icon = Icons.alternate_email;
        break;
      case 'vimeo':
        color = const Color(0xFF1AB7EA);
        icon = Icons.videocam;
        break;
      default:
        color = AppTheme.primaryCyan;
        icon = Icons.play_arrow;
    }

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
          Icon(
            icon,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            platform,
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

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        content.title ?? 'No title',
        style: const TextStyle(
          fontSize: 13,
          height: 1.3,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    final Color platformColor = _getPlatformColor(content.platform);
    final String durationText = content.durationSeconds != null
        ? _formatDuration(content.durationSeconds!)
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GestureDetector(
        onTap: () async {
          await ContentService.instance.trackContentInteraction(
            contentId: content.id,
            interactionType: InteractionType.view,
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              // Thumbnail
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      platformColor.withOpacity(0.8),
                      platformColor.withOpacity(0.4),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: content.thumbnailUrl != null
                    ? Image.network(
                        content.thumbnailUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 200,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      )
                    : null,
              ),
              // Dark overlay for play button visibility
              Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              // Play button
              Positioned.fill(
                child: Center(
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
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
              // Duration badge
              if (durationText.isNotEmpty)
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
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

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _buildActionButton(
            icon: Icons.favorite_border,
            label: _formatCount(content.viewCount),
            onTap: () async {
              await ContentService.instance.trackContentInteraction(
                contentId: content.id,
                interactionType: InteractionType.like,
              );
            },
          ),
          const SizedBox(width: 20),
          _buildActionButton(
            icon: Icons.chat_bubble_outline,
            count: 0, // Comments not available in Content model
            onTap: () async {
              await ContentService.instance.trackContentInteraction(
                contentId: content.id,
                interactionType: InteractionType.share,
              );
            },
          ),
          const SizedBox(width: 20),
          _buildActionButton(
            icon: Icons.share_outlined,
            count: 0, // Shares not available in Content model
            onTap: () async {
              await ContentService.instance.trackContentInteraction(
                contentId: content.id,
                interactionType: InteractionType.share,
              );
            },
          ),
          const Spacer(),
          Text(
            content.formattedDuration,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.bookmark_border),
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
    String? label,
    int count = 0,
    required VoidCallback onTap,
  }) {
    final displayLabel = label ?? (count > 0 ? _formatCount(count) : '0');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 3),
            Text(
              displayLabel,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}