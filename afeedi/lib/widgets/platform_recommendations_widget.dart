import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/content_item.dart';
import '../services/analytics_service.dart';
import '../services/youtube_data_api_service.dart';
import '../models/analytics_events.dart';
import '../utils/ui_scaling.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';

/// A widget that displays recommendations grouped by platform.
class PlatformRecommendationsWidget extends StatefulWidget {
  /// The number of items to display per platform
  final int itemsPerPlatform;

  /// Whether to show the recommendation reason
  final bool showRecommendationReason;

  /// Callback when an item is tapped
  final Function(ContentItem) onItemTap;

  const PlatformRecommendationsWidget({
    Key? key,
    required this.itemsPerPlatform,
    this.showRecommendationReason = true,
    required this.onItemTap,
  }) : super(key: key);

  @override
  _PlatformRecommendationsWidgetState createState() =>
      _PlatformRecommendationsWidgetState();
}

class _PlatformRecommendationsWidgetState
    extends State<PlatformRecommendationsWidget> {
  final AnalyticsService _analyticsService = AnalyticsService.instance;
  Map<String, List<ContentItem>> _platformRecommendations = {};
  List<String> _platforms = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();

    // Track widget impression
    _analyticsService.trackEvent(
      eventName: 'platform_recommendations_viewed',
      eventType: AnalyticsEvents.contentEngagement,
      additionalData: {
        'items_per_platform': widget.itemsPerPlatform,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ytVideos = await YouTubeDataApiService.instance
          .fetchVideosByQuery(query: 'trending', maxResults: widget.itemsPerPlatform);

      final youtubeItems = ytVideos.map((v) => ContentItem(
            id: v.id,
            title: v.title,
            description: v.channelTitle,
            url: v.watchUrl,
            platform: 'YouTube',
            contentType: 'video',
            creator: v.channelTitle,
            thumbnailUrl: v.thumbnailUrl,
            durationSeconds: 0,
            tags: const [],
            category: 'Trending',
            recommendationReason: 'Trending on YouTube',
            personalizationScore: 0.8,
          )).toList();

      final Map<String, List<ContentItem>> recommendations = {
        'YouTube': youtubeItems,
      };

      if (mounted) {
        setState(() {
          _platformRecommendations = recommendations;
          _platforms = recommendations.keys.toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load recommendations: $e';
          _isLoading = false;
        });
      }
      _analyticsService.trackEvent(
        eventName: 'platform_recommendations_error',
        eventType: AnalyticsEvents.error,
        additionalData: {
          'error_message': e.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingIndicator();
    }

    if (_errorMessage != null) {
      return _buildErrorWidget();
    }

    if (_platformRecommendations.isEmpty) {
      return _buildEmptyStateWidget();
    }

    return _buildPlatformRecommendations();
  }

  Widget _buildPlatformRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: UIScaling.spacing(context, 2),
            vertical: UIScaling.spacing(context, 1),
          ),
          child: Text(
            'Top Picks by Platform',
            style: AppTextStyles.heading2,
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _platforms.length,
          itemBuilder: (context, index) {
            final platform = _platforms[index];
            final recommendations = _platformRecommendations[platform] ?? [];
            return _buildPlatformSection(platform, recommendations, index);
          },
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(
          begin: 0.1,
          end: 0,
          duration: 400.ms,
          curve: Curves.easeOutQuad,
          delay: 100.ms,
        );
  }

  Widget _buildPlatformSection(
      String platform, List<ContentItem> recommendations, int sectionIndex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: UIScaling.spacing(context, 2),
            right: UIScaling.spacing(context, 2),
            top: UIScaling.spacing(context, 2),
            bottom: UIScaling.spacing(context, 1),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: UIScaling.spacing(context, 1),
                  vertical: UIScaling.spacing(context, 0.5),
                ),
                decoration: BoxDecoration(
                  color: AppColors.getPlatformColor(platform),
                  borderRadius: BorderRadius.circular(
                    UIScaling.radius(context, 0.5),
                  ),
                ),
                child: Text(
                  platform,
                  style: AppTextStyles.heading4.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // Track platform view all
                  _analyticsService.trackEvent(
                    eventName: 'platform_view_all_tapped',
                    eventType: AnalyticsEvents.userInteraction,
                    additionalData: {
                      'platform': platform,
                      'timestamp': DateTime.now().toIso8601String(),
                    },
                  );
                  
                  // Navigate to platform page
                  Navigator.of(context).pushNamed(
                    '/platform',
                    arguments: platform,
                  );
                },
                child: Text('View All'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: UIScaling.cardHeight(context),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recommendations.length,
            padding: EdgeInsets.symmetric(
              horizontal: UIScaling.spacing(context, 2),
            ),
            itemBuilder: (context, index) {
              final item = recommendations[index];
              return _buildRecommendationCard(item, index, sectionIndex);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(
      ContentItem item, int index, int sectionIndex) {
    return GestureDetector(
      onTap: () {
        widget.onItemTap(item);
      },
      child: Container(
        width: UIScaling.cardWidth(context),
        margin: EdgeInsets.only(
          right: UIScaling.spacing(context, 1.5),
          bottom: UIScaling.spacing(context, 1),
        ),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(UIScaling.radius(context)),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    item.thumbnailUrl ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.getPlatformColor(item.platform),
                        child: Center(
                          child: Icon(
                            Icons.image,
                            color: AppColors.white,
                            size: 32,
                          ),
                        ),
                      );
                    },
                  ),
                  // Duration badge
                  Positioned(
                    bottom: UIScaling.spacing(context, 1),
                    right: UIScaling.spacing(context, 1),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: UIScaling.spacing(context, 0.75),
                        vertical: UIScaling.spacing(context, 0.25),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(
                          UIScaling.radius(context, 0.5),
                        ),
                      ),
                      child: Text(
                        _formatDuration(
                            Duration(seconds: item.durationSeconds)),
                        style: AppTextStyles.tag.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content details
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(UIScaling.spacing(context, 1)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: AppTextStyles.heading4,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: UIScaling.spacing(context, 0.5)),
                    Text(
                      item.description ?? '',
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.showRecommendationReason &&
                        item.recommendationReason != null)
                      Padding(
                        padding: EdgeInsets.only(
                          top: UIScaling.spacing(context, 0.5),
                        ),
                        child: Text(
                          item.recommendationReason!,
                          style: AppTextStyles.recommendationReason,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(
            duration: 300.ms,
            delay: (100 + sectionIndex * 100 + index * 50).ms,
          ).slideY(
            begin: 0.1,
            end: 0,
            duration: 300.ms,
            curve: Curves.easeOutQuad,
            delay: (100 + sectionIndex * 100 + index * 50).ms,
          ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: EdgeInsets.all(UIScaling.spacing(context, 2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shimmer effect for title
          Container(
            width: 200,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.shimmerBase,
              borderRadius: BorderRadius.circular(UIScaling.radius(context, 0.5)),
            ),
          ),
          SizedBox(height: UIScaling.spacing(context, 2)),
          // Shimmer effect for platform sections
          for (int i = 0; i < 3; i++) ...[  // Show 3 platform sections
            Row(
              children: [
                Container(
                  width: 100,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.shimmerBase,
                    borderRadius: BorderRadius.circular(UIScaling.radius(context, 0.5)),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 60,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.shimmerBase,
                    borderRadius: BorderRadius.circular(UIScaling.radius(context, 0.5)),
                  ),
                ),
              ],
            ),
            SizedBox(height: UIScaling.spacing(context, 1)),
            SizedBox(
              height: UIScaling.cardHeight(context),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                itemBuilder: (context, index) {
                  return Container(
                    width: UIScaling.cardWidth(context),
                    margin: EdgeInsets.only(right: UIScaling.spacing(context, 1.5)),
                    decoration: BoxDecoration(
                      color: AppColors.shimmerBase,
                      borderRadius: BorderRadius.circular(UIScaling.radius(context)),
                    ),
                  ).animate(onPlay: (controller) => controller.repeat()).shimmer(
                        duration: 1500.ms,
                        color: AppColors.shimmerHighlight,
                      );
                },
              ),
            ),
            SizedBox(height: UIScaling.spacing(context, 2)),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      height: 200,
      padding: EdgeInsets.all(UIScaling.spacing(context, 2)),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 48,
            ),
            SizedBox(height: UIScaling.spacing(context, 1)),
            Text(
              'Failed to load platform recommendations',
              style: AppTextStyles.body1,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: UIScaling.spacing(context, 1)),
            ElevatedButton(
              onPressed: _loadRecommendations,
              child: Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateWidget() {
    return Container(
      height: 200,
      padding: EdgeInsets.all(UIScaling.spacing(context, 2)),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              color: AppColors.primary,
              size: 48,
            ),
            SizedBox(height: UIScaling.spacing(context, 1)),
            Text(
              'No platform recommendations available',
              style: AppTextStyles.body1,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}