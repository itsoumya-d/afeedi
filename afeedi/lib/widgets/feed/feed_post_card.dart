import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../models/content_model.dart';
import '../../widgets/streaming/responsive_video_player.dart';
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
            tooltip: 'More options',
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
      case 'vimeo':
        color = const Color(0xFF1AB7EA);
        icon = Icons.videocam;
        break;
      case 'dailymotion':
        color = const Color(0xFF0066CC);
        icon = Icons.video_library;
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
    return Padding(
      padding: const EdgeInsets.all(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(10),
          ),
          child: GestureDetector(
            onTap: () async {
              await ContentService.instance.trackContentInteraction(
                contentId: content.id,
                interactionType: InteractionType.view,
              );
            },
            child: Center(
              child: ResponsiveVideoPlayer(
                content: content,
                autoPlay: false,
                showControls: true,
                showBranding: true,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _buildActionButton(
            icon: Icons.favorite_border,
            count: content.viewCount,
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
            tooltip: 'Save post',
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 3),
            Text(
              count.toString(),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}