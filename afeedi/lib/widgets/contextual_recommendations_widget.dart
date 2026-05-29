import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/content_item.dart';
import '../services/analytics_service.dart';
import '../models/analytics_events.dart';
import '../utils/ui_scaling.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';

/// A widget that displays contextual recommendations based on time of day
/// and calendar events.
class ContextualRecommendationsWidget extends StatefulWidget {
  /// The number of items to display
  final int itemCount;

  /// Whether to show the recommendation reason
  final bool showRecommendationReason;

  /// Callback when an item is tapped
  final Function(ContentItem) onItemTap;

  const ContextualRecommendationsWidget({
    Key? key,
    required this.itemCount,
    this.showRecommendationReason = true,
    required this.onItemTap,
  }) : super(key: key);

  @override
  _ContextualRecommendationsWidgetState createState() =>
      _ContextualRecommendationsWidgetState();
}

class _ContextualRecommendationsWidgetState
    extends State<ContextualRecommendationsWidget> {
  final AnalyticsService _analyticsService = AnalyticsService.instance;
  List<ContentItem> _recommendations = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _contextType = 'time'; // 'time' or 'calendar'

  @override
  void initState() {
    super.initState();
    _loadRecommendations();

    // Track widget impression
    _analyticsService.trackEvent(
      eventName: 'contextual_recommendations_viewed',
      eventType: AnalyticsEvents.contentEngagement,
      additionalData: {
        'context_type': _contextType,
        'item_count': widget.itemCount,
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
      // Determine context type (time or calendar)
      _determineContextType();

      // In a real app, this would call a service to get recommendations
      await Future.delayed(const Duration(milliseconds: 800));

      // Sample data
      final recommendations = _getSampleRecommendations();

      setState(() {
        _recommendations = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load recommendations: $e';
        _isLoading = false;
      });

      // Track error
      _analyticsService.trackEvent(
        eventName: 'contextual_recommendations_error',
        eventType: AnalyticsEvents.error,
        additionalData: {
          'error_message': e.toString(),
          'context_type': _contextType,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    }
  }

  void _determineContextType() {
    // Check if there are any relevant calendar events
    final hasCalendarEvents = DateTime.now().hour > 12; // Just a sample logic

    setState(() {
      _contextType = hasCalendarEvents ? 'calendar' : 'time';
    });
  }

  List<ContentItem> _getSampleRecommendations() {
    final now = DateTime.now();
    final hour = now.hour;

    String timeContext;
    if (hour >= 5 && hour < 12) {
      timeContext = 'morning';
    } else if (hour >= 12 && hour < 17) {
      timeContext = 'afternoon';
    } else if (hour >= 17 && hour < 21) {
      timeContext = 'evening';
    } else {
      timeContext = 'night';
    }

    // Sample recommendations based on time of day
    if (_contextType == 'time') {
      return [
        ContentItem(
          id: 'c1',
          title: 'Morning News Briefing',
          description: 'Start your day with the latest news',
          thumbnailUrl: 'https://example.com/news.jpg',
          platform: 'News App',
          contentType: 'video',
          durationSeconds: 15 * 60,
          recommendationReason: 'Perfect for your $timeContext routine',
          tags: ['News', 'Current Events'],
          category: 'Entertainment',
        ),
        ContentItem(
          id: 'c2',
          title: '$timeContext Playlist',
          description: 'Curated music for your $timeContext',
          thumbnailUrl: 'https://example.com/music.jpg',
          platform: 'Music App',
          contentType: 'video',
          durationSeconds: 45 * 60,
          recommendationReason: 'Matches your $timeContext mood',
          tags: ['Music', 'Playlist'],
          category: 'Entertainment',
        ),
        ContentItem(
          id: 'c3',
          title: '$timeContext Meditation',
          description: 'Guided meditation for $timeContext',
          thumbnailUrl: 'https://example.com/meditation.jpg',
          platform: 'Wellness App',
          contentType: 'video',
          durationSeconds: 10 * 60,
          recommendationReason: 'Perfect for your $timeContext schedule',
          tags: ['Wellness', 'Meditation'],
          category: 'Entertainment',
        ),
        ContentItem(
          id: 'c4',
          title: 'Quick $timeContext Workout',
          description: '15-minute workout for $timeContext',
          thumbnailUrl: 'https://example.com/workout.jpg',
          platform: 'Fitness App',
          contentType: 'video',
          durationSeconds: 15 * 60,
          recommendationReason: 'Fits your $timeContext schedule',
          tags: ['Fitness', 'Workout'],
          category: 'Entertainment',
        ),
        ContentItem(
          id: 'c5',
          title: '$timeContext Podcast',
          description: 'Popular podcast for $timeContext listening',
          thumbnailUrl: 'https://example.com/podcast.jpg',
          platform: 'Podcast App',
          contentType: 'video',
          durationSeconds: 30 * 60,
          recommendationReason: 'Trending for $timeContext listening',
          tags: ['Podcast', 'Talk'],
          category: 'Entertainment',
        ),
      ];
    } else {
      // Calendar-based recommendations
      return [
        ContentItem(
          id: 'c6',
          title: 'Pre-Meeting Prep',
          description: 'Quick tips before your upcoming meeting',
          thumbnailUrl: 'https://example.com/meeting.jpg',
          platform: 'Productivity App',
          contentType: 'video',
          durationSeconds: 5 * 60,
          recommendationReason: 'You have a meeting in 30 minutes',
          tags: ['Productivity', 'Business'],
          category: 'Entertainment',
        ),
        ContentItem(
          id: 'c7',
          title: 'Commute Entertainment',
          description: 'Perfect for your drive home',
          thumbnailUrl: 'https://example.com/commute.jpg',
          platform: 'Entertainment App',
          contentType: 'video',
          durationSeconds: 25 * 60,
          recommendationReason: 'Matches your commute time',
          tags: ['Entertainment', 'Comedy'],
          category: 'Entertainment',
        ),
        ContentItem(
          id: 'c8',
          title: 'Workout Playlist',
          description: 'Energetic music for your scheduled workout',
          thumbnailUrl: 'https://example.com/workout_music.jpg',
          platform: 'Music App',
          contentType: 'video',
          durationSeconds: 45 * 60,
          recommendationReason: 'For your 5PM workout',
          tags: ['Music', 'Fitness'],
          category: 'Entertainment',
        ),
        ContentItem(
          id: 'c9',
          title: 'Dinner Recipe',
          description: 'Quick and easy dinner ideas',
          thumbnailUrl: 'https://example.com/recipe.jpg',
          platform: 'Cooking App',
          contentType: 'video',
          durationSeconds: 10 * 60,
          recommendationReason: 'It\'s almost dinner time',
          tags: ['Cooking', 'Food'],
          category: 'Entertainment',
        ),
        ContentItem(
          id: 'c10',
          title: 'Evening Wind Down',
          description: 'Relaxing content before bed',
          thumbnailUrl: 'https://example.com/relax.jpg',
          platform: 'Wellness App',
          contentType: 'video',
          durationSeconds: 15 * 60,
          recommendationReason: 'Based on your bedtime routine',
          tags: ['Wellness', 'Sleep'],
          category: 'Entertainment',
        ),
      ];
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

    if (_recommendations.isEmpty) {
      return _buildEmptyStateWidget();
    }

    return _buildRecommendationsWidget();
  }

  Widget _buildRecommendationsWidget() {
    final contextTitle = _contextType == 'time'
        ? _getTimeBasedTitle()
        : 'Based on Your Calendar';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: UIScaling.spacing(context, 2),
            vertical: UIScaling.spacing(context, 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                contextTitle,
                style: AppTextStyles.heading2,
              ),
              SizedBox(height: UIScaling.spacing(context, 0.5)),
              Text(
                _getSubtitle(),
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: UIScaling.spacing(context, 1)),
        SizedBox(
          height: UIScaling.cardHeight(context, isLarge: true),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _recommendations.length,
            padding: EdgeInsets.symmetric(
              horizontal: UIScaling.spacing(context, 2),
            ),
            itemBuilder: (context, index) {
              final item = _recommendations[index];
              return _buildRecommendationCard(item, index);
            },
          ),
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

  String _getTimeBasedTitle() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    } else if (hour >= 17 && hour < 21) {
      return 'Good Evening';
    } else {
      return 'Tonight\'s Picks';
    }
  }

  String _getSubtitle() {
    if (_contextType == 'time') {
      final hour = DateTime.now().hour;

      if (hour >= 5 && hour < 12) {
        return 'Start your day with these recommendations';
      } else if (hour >= 12 && hour < 17) {
        return 'Perfect for your afternoon';
      } else if (hour >= 17 && hour < 21) {
        return 'Unwind with these evening picks';
      } else {
        return 'Recommendations for late-night viewing';
      }
    } else {
      return 'Recommendations based on your schedule';
    }
  }

  Widget _buildRecommendationCard(ContentItem item, int index) {
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
                  // Platform badge
                  Positioned(
                    top: UIScaling.spacing(context, 1),
                    left: UIScaling.spacing(context, 1),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: UIScaling.spacing(context, 0.75),
                        vertical: UIScaling.spacing(context, 0.25),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.getPlatformColor(item.platform),
                        borderRadius: BorderRadius.circular(
                          UIScaling.radius(context, 0.5),
                        ),
                      ),
                      child: Text(
                        item.platform,
                        style: AppTextStyles.tag.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                    ),
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
      ).animate().fadeIn(duration: 300.ms, delay: (100 + index * 50).ms).slideY(
            begin: 0.1,
            end: 0,
            duration: 300.ms,
            curve: Curves.easeOutQuad,
            delay: (100 + index * 50).ms,
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
      height: UIScaling.cardHeight(context, isLarge: true) + 80,
      padding: EdgeInsets.all(UIScaling.spacing(context, 2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shimmer effect for title
          Container(
            width: 150,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.shimmerBase,
              borderRadius: BorderRadius.circular(UIScaling.radius(context, 0.5)),
            ),
          ),
          SizedBox(height: UIScaling.spacing(context, 0.5)),
          // Shimmer effect for subtitle
          Container(
            width: 250,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.shimmerBase,
              borderRadius: BorderRadius.circular(UIScaling.radius(context, 0.5)),
            ),
          ),
          SizedBox(height: UIScaling.spacing(context, 2)),
          // Shimmer effect for cards
          Expanded(
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
              'Failed to load contextual recommendations',
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
              'No contextual recommendations available',
              style: AppTextStyles.body1,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}