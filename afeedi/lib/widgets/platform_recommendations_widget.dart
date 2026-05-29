import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/content_item.dart';
import '../services/analytics_service.dart';
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
      // In a real app, this would call a service to get recommendations
      await Future.delayed(const Duration(milliseconds: 800));

      // Sample data
      final recommendations = _getSampleRecommendations();

      setState(() {
        _platformRecommendations = recommendations;
        _platforms = recommendations.keys.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load recommendations: $e';
        _isLoading = false;
      });

      // Track error
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

  Map<String, List<ContentItem>> _getSampleRecommendations() {
    // Sample platforms and recommendations
    return {
      'Netflix': [
        ContentItem(
          id: 'n1',
          title: 'Stranger Things',
          description: 'Sci-fi drama series',
          thumbnailUrl: 'https://example.com/stranger_things.jpg',
          platform: 'Netflix',
          contentType: 'video',
          durationSeconds: 50 * 60,
          recommendationReason: 'Based on your sci-fi preferences',
          tags: ['Sci-Fi', 'Drama', 'Horror'],
          category: 'Entertainment',
        ),
        ContentItem(
          id: 'n2',
          title: 'The Crown',
          description: 'Historical drama about the British royal family',
          thumbnailUrl: 'https://example.com/the_crown.jpg',
          platform: 'Netflix',
          contentType: 'video',
          durationSeconds: 55 * 60,
          recommendationReason: 'Trending in your region',
          tags: ['Drama', 'History', 'Biography'],
          category: 'Entertainment',
        ),
        ContentItem(
          id: 'n3',
          title: 'Money Heist',
          description: 'Spanish heist crime drama series',
          thumbnailUrl: 'https://example.com/money_heist.jpg',
          platform: 'Netflix',
          contentType: 'video',
          durationSeconds: 45 * 60,
          recommendationReason: 'Popular among similar viewers',
          tags: ['Crime', 'Drama', 'Thriller'],
          category: 'Entertainment',
        ),
        ContentItem(
          id: 'n4',
          title: 'The Witcher',
          description: 'Fantasy drama based on book series',
          thumbnailUrl: 'https://example.com/witcher.jpg',
          platform: 'Netflix',
          contentType: 'video',
          durationSeconds: 60 * 60,
          recommendationReason: 'Matches your fantasy interests',
          tags: ['Fantasy', 'Action', 'Adventure'],
          category: 'Entertainment',
        ),
        ContentItem(
          id: 'n5',
          title: 'Ozark',
          description: 'Crime drama thriller series',
          thumbnailUrl: 'https://example.com/ozark.jpg',
          platform: 'Netflix',
          contentType: 'video',
          durationSeconds: 60 * 60,
          recommendationReason: 'Similar to shows you\'ve watched',
          tags: ['Crime', 'Drama', 'Thriller'],
          category: 'Entertainment',
        ),
      ],
      'Hulu': [
        ContentItem(
          id: 'h1',
          title: 'The Handmaid\'s Tale',
          description: 'Dystopian drama series',
          thumbnailUrl: 'https://example.com/handmaids_tale.jpg',
          platform: 'Hulu',
          contentType: 'video',
          durationSeconds: 50 * 60,
          recommendationReason: 'Award-winning series you might enjoy',
          tags: ['Drama', 'Sci-Fi', 'Dystopian'],
          category: 'Entertainment',
        ),
        ContentItem(
          id: 'h2',
          title: 'Only Murders in the Building',
          description: 'Comedy mystery series',
          thumbnailUrl: 'https://example.com/only_murders.jpg',
          platform: 'Hulu',
          contentType: 'video',
          durationSeconds: 30 * 60,
          recommendationReason: 'Matches your comedy preferences',
          tags: ['Comedy', 'Mystery', 'Crime'],
          category: 'Entertainment',
        ),
        ContentItem(
          id: 'h3',
          title: 'The Great',
          description: 'Historical comedy-drama series',
          thumbnailUrl: 'https://example.com/the_great.jpg',
          platform: 'Hulu',
          contentType: 'video',
          durationSeconds: 45 * 60,
          recommendationReason: 'Based on your historical interests',
          tags: ['Comedy', 'Drama', 'History'],
          category: 'Entertainment',
        ),
        ContentItem(
          id: 'h4',
          title: 'Dopesick',
          description: 'Drama miniseries about the opioid crisis',
          thumbnailUrl: 'https://example.com/dopesick.jpg',
          platform: 'Hulu',
          contentType: 'video',
          durationSeconds: 60 * 60,
          recommendationReason: 'Critically acclaimed series',
          tags: ['Drama', 'Crime', 'Biography'],
          category: 'Entertainment',
        ),
        ContentItem(
          id: 'h5',
          title: 'Reservation Dogs',
          description: 'Comedy-drama about Indigenous teenagers',
          thumbnailUrl: 'https://example.com/reservation_dogs.jpg',
          platform: 'Hulu',
          contentType: 'video',
          durationSeconds: 30 * 60,
          recommendationReason: 'Fresh perspective you might enjoy',
          tags: ['Comedy', 'Drama', 'Coming of Age'],
          category: 'Entertainment',
        ),
      ],
      'Disney+': [
        ContentItem(
          id: 'd1',
          title: 'The Mandalorian',
          description: 'Star Wars space western series',
          thumbnailUrl: 'https://example.com/mandalorian.jpg',
          platform: 'Disney+',
          contentType: 'video',
          durationSeconds: 40 * 60,
          recommendationReason: 'Based on your sci-fi preferences',
          tags: ['Sci-Fi', 'Action', 'Adventure'],
          category: 'Entertainment',
        ),
        ContentItem(
          id: 'd2',
          title: 'WandaVision',
          description: 'Marvel superhero miniseries',
          thumbnailUrl: 'https://example.com/wandavision.jpg',
          platform: 'Disney+',
          contentType: 'video',
          durationSeconds: 40 * 60,
          recommendationReason: 'For Marvel fans like you',
          tags: ['Superhero', 'Drama', 'Mystery'],
          category: 'Entertainment',
        ),
        ContentItem(
          id: 'd3',
          title: 'Loki',
          description: 'Marvel series about the God of Mischief',
          thumbnailUrl: 'https://example.com/loki.jpg',
          platform: 'Disney+',
          contentType: 'video',
          durationSeconds: 50 * 60,
          recommendationReason: 'Continues the Marvel storyline',
          tags: ['Superhero', 'Sci-Fi', 'Fantasy'],
          category: 'Entertainment',
        ),
        ContentItem(
          id: 'd4',
          title: 'The Beatles: Get Back',
          description: 'Documentary about The Beatles',
          thumbnailUrl: 'https://example.com/beatles.jpg',
          platform: 'Disney+',
          contentType: 'video',
          durationSeconds: 160 * 60,
          recommendationReason: 'Based on your music interests',
          tags: ['Documentary', 'Music', 'History'],
          category: 'Entertainment',
        ),
        ContentItem(
          id: 'd5',
          title: 'Andor',
          description: 'Star Wars spy thriller series',
          thumbnailUrl: 'https://example.com/andor.jpg',
          platform: 'Disney+',
          contentType: 'video',
          durationSeconds: 45 * 60,
          recommendationReason: 'New addition to Star Wars universe',
          tags: ['Sci-Fi', 'Thriller', 'Action'],
          category: 'Entertainment',
        ),
      ],
      'HBO Max': [
        ContentItem(
          id: 'hbo1',
          title: 'Succession',
          description: 'Drama about a dysfunctional media family',
          thumbnailUrl: 'https://example.com/succession.jpg',
          platform: 'HBO Max',
          contentType: 'video',
          durationSeconds: 60 * 60,
          recommendationReason: 'Award-winning drama series',
          tags: ['Drama', 'Comedy', 'Business'],
          category: 'Entertainment',
        ),
        ContentItem(
          id: 'hbo2',
          title: 'The Last of Us',
          description: 'Post-apocalyptic drama based on video game',
          thumbnailUrl: 'https://example.com/last_of_us.jpg',
          platform: 'HBO Max',
          contentType: 'video',
          durationSeconds: 60 * 60,
          recommendationReason: 'Trending in your region',
          tags: ['Drama', 'Horror', 'Post-Apocalyptic'],
          category: 'Entertainment',
        ),
        ContentItem(
          id: 'hbo3',
          title: 'House of the Dragon',
          description: 'Game of Thrones prequel series',
          thumbnailUrl: 'https://example.com/house_dragon.jpg',
          platform: 'HBO Max',
          contentType: 'video',
          durationSeconds: 60 * 60,
          recommendationReason: 'For Game of Thrones fans',
          tags: ['Fantasy', 'Drama', 'Action'],
          category: 'Entertainment',
        ),
        ContentItem(
          id: 'hbo4',
          title: 'The White Lotus',
          description: 'Social satire set at a tropical resort',
          thumbnailUrl: 'https://example.com/white_lotus.jpg',
          platform: 'HBO Max',
          contentType: 'video',
          durationSeconds: 60 * 60,
          recommendationReason: 'Critically acclaimed series',
          tags: ['Comedy', 'Drama', 'Satire'],
          category: 'Entertainment',
        ),
        ContentItem(
          id: 'hbo5',
          title: 'Euphoria',
          description: 'Teen drama about high school students',
          thumbnailUrl: 'https://example.com/euphoria.jpg',
          platform: 'HBO Max',
          contentType: 'video',
          durationSeconds: 60 * 60,
          recommendationReason: 'Popular among similar viewers',
          tags: ['Drama', 'Coming of Age'],
          category: 'Entertainment',
        ),
      ],
      'Prime Video': [
        ContentItem(
          id: 'p1',
          title: 'The Boys',
          description: 'Superhero dark comedy series',
          thumbnailUrl: 'https://example.com/the_boys.jpg',
          platform: 'Prime Video',
          contentType: 'video',
          durationSeconds: 60 * 60,
          recommendationReason: 'Based on your superhero interests',
          tags: ['Superhero', 'Action', 'Comedy'],
          category: 'Entertainment',
        ),
        ContentItem(
          id: 'p2',
          title: 'The Marvelous Mrs. Maisel',
          description: 'Period comedy-drama series',
          thumbnailUrl: 'https://example.com/maisel.jpg',
          platform: 'Prime Video',
          contentType: 'video',
          durationSeconds: 55 * 60,
          recommendationReason: 'Award-winning series you might enjoy',
          tags: ['Comedy', 'Drama', 'Period'],
          category: 'Entertainment',
        ),
        ContentItem(
          id: 'p3',
          title: 'The Lord of the Rings: The Rings of Power',
          description: 'Fantasy series based on Tolkien\'s works',
          thumbnailUrl: 'https://example.com/rings_power.jpg',
          platform: 'Prime Video',
          contentType: 'video',
          durationSeconds: 60 * 60,
          recommendationReason: 'For fantasy enthusiasts',
          tags: ['Fantasy', 'Adventure', 'Drama'],
          category: 'Entertainment',
        ),
        ContentItem(
          id: 'p4',
          title: 'Fleabag',
          description: 'Comedy-drama series',
          thumbnailUrl: 'https://example.com/fleabag.jpg',
          platform: 'Prime Video',
          contentType: 'video',
          durationSeconds: 30 * 60,
          recommendationReason: 'Critically acclaimed comedy',
          tags: ['Comedy', 'Drama'],
          category: 'Entertainment',
        ),
        ContentItem(
          id: 'p5',
          title: 'The Wheel of Time',
          description: 'Fantasy series based on novel series',
          thumbnailUrl: 'https://example.com/wheel_time.jpg',
          platform: 'Prime Video',
          contentType: 'video',
          durationSeconds: 60 * 60,
          recommendationReason: 'Matches your fantasy preferences',
          tags: ['Fantasy', 'Adventure', 'Drama'],
          category: 'Entertainment',
        ),
      ],
    };
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
              color: AppColors.shadow.withValues(alpha: 0.1),
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
                        color: AppColors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(
                          UIScaling.radius(context, 0.5),
                        ),
                      ),
                      child: Text(
                        _formatDuration(Duration(seconds: item.durationSeconds)),
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
                        item.recommendationReason.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(
                          top: UIScaling.spacing(context, 0.5),
                        ),
                        child: Text(
                          item.recommendationReason,
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