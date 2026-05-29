import 'package:flutter/material.dart';
import '../models/content_item.dart';
import '../utils/ui_scaling.dart';
import 'platform_icon.dart';

/// A card widget that displays content item information
class ContentCard extends StatelessWidget {
  final ContentItem item;
  final bool showPlatformIcon;
  final bool showRecommendationReason;
  final bool isCompact;
  
  const ContentCard({
    Key? key,
    required this.item,
    this.showPlatformIcon = true,
    this.showRecommendationReason = true,
    this.isCompact = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: isCompact ? UIScaling.cardWidth(context) * 0.8 : UIScaling.cardWidth(context),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          _buildThumbnail(context),
          
          // Content info
          Padding(
            padding: EdgeInsets.all(UIScaling.spacing(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and platform
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (showPlatformIcon) SizedBox(width: UIScaling.spacing(context, 0.5)),
                    if (showPlatformIcon) PlatformIcon(platform: item.platform, size: 16),
                  ],
                ),
                
                SizedBox(height: UIScaling.spacing(context, 0.5)),
                
                // Creator
                if (item.creator != null && item.creator!.isNotEmpty)
                  Text(
                    item.creator!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                
                // Metadata (views, likes)
                if (_getViewCount(item) > 0 || _getLikeCount(item) > 0)
                  Padding(
                    padding: EdgeInsets.only(top: UIScaling.spacing(context, 0.5)),
                    child: Row(
                      children: [
                        if (_getViewCount(item) > 0) ...[                          Icon(
                            Icons.visibility,
                            size: 12,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          SizedBox(width: 2),
                          Text(
                            _formatCount(_getViewCount(item)),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                        if (_getViewCount(item) > 0 && _getLikeCount(item) > 0)
                          SizedBox(width: 8),
                        if (_getLikeCount(item) > 0) ...[                          Icon(
                            Icons.favorite,
                            size: 12,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          SizedBox(width: 2),
                          Text(
                            _formatCount(_getLikeCount(item)),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                
                // Tags
                if (item.tags.isNotEmpty && !isCompact)
                  Padding(
                    padding: EdgeInsets.only(top: UIScaling.spacing(context, 0.5)),
                    child: Wrap(
                      spacing: UIScaling.spacing(context, 0.5),
                      runSpacing: UIScaling.spacing(context, 0.25),
                      children: item.tags.take(3).map((tag) => _buildTag(context, tag)).toList(),
                    ),
                  ),
                
                // Recommendation reason
                if (showRecommendationReason &&
                    item.recommendationReason.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: UIScaling.spacing(context, 0.5)),
                    child: Text(
                      item.recommendationReason,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildThumbnail(BuildContext context) {
    return Stack(
      children: [
        // Thumbnail image
        Container(
          height: isCompact ? 90 : 120,
          width: double.infinity,
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty
            ? Image.network(
                item.thumbnailUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.image_not_supported_outlined,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              )
            : Icon(
                _getContentTypeIcon(),
                size: 32,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
        ),
        
        // Duration badge
        if (item.durationSeconds > 0)
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _formatDuration(item.durationSeconds),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          
        // New badge
        if (item.isNew)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'NEW',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildTag(BuildContext context, String tag) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        tag,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSecondaryContainer,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
  
  IconData _getContentTypeIcon() {
    switch (item.contentType.toLowerCase()) {
      case 'video':
        return Icons.videocam_outlined;
      case 'article':
        return Icons.article_outlined;
      case 'podcast':
        return Icons.headset_outlined;
      case 'course':
        return Icons.school_outlined;
      case 'live':
        return Icons.live_tv_outlined;
      default:
        return Icons.play_circle_outline;
    }
  }
  
  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    } else {
      return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
    }
  }

  int _getViewCount(ContentItem item) {
    return item.engagementMetrics?['views'] ?? 0;
  }

  int _getLikeCount(ContentItem item) {
    return item.engagementMetrics?['likes'] ?? 0;
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }
}