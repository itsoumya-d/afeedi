import 'package:flutter/material.dart';
import '../../models/content_model.dart';
import '../../core/theme/app_theme.dart';
import '../../services/analytics_service.dart';
import '../streaming/responsive_video_player.dart';
import '../streaming/platform_branding_widget.dart';

class EnhancedFeedPostCard extends StatefulWidget {
  final Content content;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final bool showInteractions;
  final bool showPlatformLogo;
  
  const EnhancedFeedPostCard({
    super.key,
    required this.content,
    this.onTap,
    this.onLike,
    this.onComment,
    this.onShare,
    this.showInteractions = true,
    this.showPlatformLogo = true,
  });
  
  @override
  State<EnhancedFeedPostCard> createState() => _EnhancedFeedPostCardState();
}

class _EnhancedFeedPostCardState extends State<EnhancedFeedPostCard> {
  bool _isLiked = false;
  bool _isSaved = false;
  bool _showVideoPlayer = false;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildContent(),
          if (widget.showInteractions) _buildInteractions(),
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Creator avatar
          CircleAvatar(
            radius: 20,
            backgroundImage: widget.content.creatorAvatarUrl != null
                ? NetworkImage(widget.content.creatorAvatarUrl!)
                : null,
            backgroundColor: AppTheme.primaryCyan.withValues(alpha: 0.3),
            child: widget.content.creatorAvatarUrl == null
                ? Text(
                    widget.content.creatorName?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          
          // Creator info and platform
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.content.creatorName ?? 'Unknown Creator',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.showPlatformLogo) ...[
                      const SizedBox(width: 8),
                      _buildPlatformLogo(),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildPlatformBadge(),
                    const SizedBox(width: 8),
                    Text(
                      _getTimeAgo(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                    if (widget.content.durationSeconds != null) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.content.formattedDuration,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // More options
          IconButton(
            onPressed: _showMoreOptions,
            icon: Icon(
              Icons.more_vert,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPlatformLogo() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _getPlatformColor().withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        _getPlatformIcon(),
        size: 16,
        color: _getPlatformColor(),
      ),
    );
  }
  
  Widget _buildPlatformBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getPlatformColor().withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getPlatformColor().withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getPlatformIcon(),
            size: 12,
            color: _getPlatformColor(),
          ),
          const SizedBox(width: 4),
          Text(
            widget.content.platform.name.toUpperCase(),
            style: TextStyle(
              color: _getPlatformColor(),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and description
        if (widget.content.title != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              widget.content.title!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        
        if (widget.content.description != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              widget.content.description!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        
        const SizedBox(height: 12),
        
        // Media content
        _buildMediaContent(),
        
        // Tags
        if (widget.content.tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildTags(),
        ],
      ],
    );
  }
  
  Widget _buildMediaContent() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showVideoPlayer = true;
        });
        _showVideoPlayerModal();
        widget.onTap?.call();
        
        // Track content tap
        AnalyticsService.instance.trackUserInteraction(
          action: 'feed_content_tapped',
          screen: 'feed',
          additionalData: {
            'content_id': widget.content.id,
            'platform': widget.content.platform.name,
            'content_type': widget.content.contentType.name,
          },
        );
      },
      child: Container(
        height: 200,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.black.withValues(alpha: 0.3),
        ),
        child: Stack(
          children: [
            // Thumbnail
            if (widget.content.thumbnailUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.content.thumbnailUrl!,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPlaceholderThumbnail();
                  },
                ),
              )
            else
              _buildPlaceholderThumbnail(),
            
            // Play button overlay
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.content.contentType == ContentType.video
                      ? Icons.play_arrow
                      : Icons.play_circle_filled,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            
            // Duration badge
            if (widget.content.durationSeconds != null)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.content.formattedDuration,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            
            // Platform branding
            Positioned(
              top: 8,
              left: 8,
              child: PlatformBrandingWidget(
                platform: widget.content.platform,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPlaceholderThumbnail() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getPlatformColor().withValues(alpha: 0.3),
            _getPlatformColor().withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getPlatformIcon(),
            size: 48,
            color: _getPlatformColor().withValues(alpha: 0.7),
          ),
          const SizedBox(height: 8),
          Text(
            widget.content.platform.name.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTags() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: widget.content.tags.take(5).map((tag) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryCyan.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '#$tag',
              style: TextStyle(
                color: AppTheme.primaryCyan,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildInteractions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Like button
          _buildInteractionButton(
            icon: _isLiked ? Icons.favorite : Icons.favorite_border,
            label: _formatCount(widget.content.likeCount),
            color: _isLiked ? Colors.red : Colors.white.withValues(alpha: 0.7),
            onTap: () {
              setState(() {
                _isLiked = !_isLiked;
              });
              widget.onLike?.call();
              
              AnalyticsService.instance.trackUserInteraction(
                action: _isLiked ? 'content_liked' : 'content_unliked',
                screen: 'feed',
                additionalData: {
                  'content_id': widget.content.id,
                  'platform': widget.content.platform.name,
                },
              );
            },
          ),
          
          const SizedBox(width: 24),
          
          // Comment button
          _buildInteractionButton(
            icon: Icons.comment_outlined,
            label: _formatCount(widget.content.metadata['comments'] ?? 0),
            color: Colors.white.withValues(alpha: 0.7),
            onTap: () {
              widget.onComment?.call();
              _showCommentsModal();
              
              AnalyticsService.instance.trackUserInteraction(
                action: 'content_comment_opened',
                screen: 'feed',
                additionalData: {
                  'content_id': widget.content.id,
                  'platform': widget.content.platform.name,
                },
              );
            },
          ),
          
          const SizedBox(width: 24),
          
          // Share button
          _buildInteractionButton(
            icon: Icons.share_outlined,
            label: 'Share',
            color: Colors.white.withValues(alpha: 0.7),
            onTap: () {
              widget.onShare?.call();
              _showShareModal();
              
              AnalyticsService.instance.trackUserInteraction(
                action: 'content_share_opened',
                screen: 'feed',
                additionalData: {
                  'content_id': widget.content.id,
                  'platform': widget.content.platform.name,
                },
              );
            },
          ),
          
          const Spacer(),
          
          // Save button
          _buildInteractionButton(
            icon: _isSaved ? Icons.bookmark : Icons.bookmark_border,
            label: '',
            color: _isSaved ? AppTheme.primaryCyan : Colors.white.withValues(alpha: 0.7),
            onTap: () {
              setState(() {
                _isSaved = !_isSaved;
              });
              
              AnalyticsService.instance.trackUserInteraction(
                action: _isSaved ? 'content_saved' : 'content_unsaved',
                screen: 'feed',
                additionalData: {
                  'content_id': widget.content.id,
                  'platform': widget.content.platform.name,
                },
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildInteractionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  void _showVideoPlayerModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.content.title ?? 'Video Content',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            // Video Player
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ResponsiveVideoPlayer(
                      content: widget.content,
                      autoPlay: true,
                      showControls: true,
                      showBranding: true,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showCommentsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Comments',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Comments feature coming soon!',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showShareModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Share Content',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.link, color: Colors.white),
              title: const Text('Copy Link', style: TextStyle(color: Colors.white)),
              onTap: () {
                // Copy video URL or embed URL
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied to clipboard')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.white),
              title: const Text('Share to...', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // Implement native sharing
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.schedule, color: Colors.white),
              title: const Text('Schedule for Later', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
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
  
  // Helper methods
  Color _getPlatformColor() {
    switch (widget.content.platform) {
      case PlatformType.youtube:
        return const Color(0xFFFF0000);
      case PlatformType.instagram:
        return const Color(0xFFE4405F);
      case PlatformType.tiktok:
        return const Color(0xFF000000);
      case PlatformType.facebook:
        return const Color(0xFF1877F2);
      default:
        return AppTheme.primaryCyan;
    }
  }
  
  IconData _getPlatformIcon() {
    switch (widget.content.platform) {
      case PlatformType.youtube:
        return Icons.play_circle;
      case PlatformType.instagram:
        return Icons.camera_alt;
      case PlatformType.tiktok:
        return Icons.music_video;
      case PlatformType.facebook:
        return Icons.facebook;
      default:
        return Icons.video_library;
    }
  }
  
  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
  
  String _getTimeAgo() {
    if (widget.content.publishedAt == null) return 'Recently';
    
    final now = DateTime.now();
    final difference = now.difference(widget.content.publishedAt!);
    
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
}