import 'package:flutter/material.dart';

import '../models/content_item.dart';
import '../services/recommendation_integration_service.dart';
import '../services/analytics_service.dart';
import '../widgets/content_card.dart';
import '../widgets/platform_icon.dart';
import '../utils/ui_scaling.dart';

/// A widget that displays personalized recommendations based on user preferences
/// collected during onboarding.
class PersonalizedRecommendationsWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final int itemCount;
  final bool showPlatformIcons;
  final bool showRecommendationReason;
  final bool isHorizontal;
  final Function(ContentItem)? onItemTap;
  final String recommendationType;
  
  const PersonalizedRecommendationsWidget({
    Key? key,
    this.title = 'Recommended for You',
    this.subtitle = 'Based on your preferences',
    this.itemCount = 10,
    this.showPlatformIcons = true,
    this.showRecommendationReason = true,
    this.isHorizontal = true,
    this.onItemTap,
    this.recommendationType = 'personalized',
  }) : super(key: key);

  @override
  _PersonalizedRecommendationsWidgetState createState() => _PersonalizedRecommendationsWidgetState();
}

class _PersonalizedRecommendationsWidgetState extends State<PersonalizedRecommendationsWidget> with AutomaticKeepAliveClientMixin {
  final RecommendationIntegrationService _recommendationService = RecommendationIntegrationService.instance;
  final AnalyticsService _analyticsService = AnalyticsService.instance;
  
  late Future<List<ContentItem>> _recommendationsFuture;
  bool _isRefreshing = false;
  
  @override
  bool get wantKeepAlive => true;
  
  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }
  
  Future<void> _loadRecommendations() async {
    setState(() {
      _isRefreshing = true;
    });
    
    // Track recommendation request
    _analyticsService.trackEvent(
      eventName: 'recommendation_request',
      eventType: 'recommendation',
      additionalData: {
        'type': widget.recommendationType,
        'count': widget.itemCount,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    
    // Get appropriate recommendations based on type
    switch (widget.recommendationType) {
      case 'contextual':
        // Temporarily return empty list - contextual recommendations not implemented
        _recommendationsFuture = Future.value(<ContentItem>[]);
        break;
      case 'viewing_habits':
        // Temporarily return empty list - viewing habits not implemented
        _recommendationsFuture = Future.value(<ContentItem>[]);
        break;
      case 'personalized':
      default:
        _recommendationsFuture = _recommendationService.getPersonalizedRecommendations(
          limit: widget.itemCount,
        );
        break;
    }
    
    // Apply personalization settings to recommendations
    // Temporarily disabled - applyPersonalizationSettings not implemented
    // _recommendationsFuture = _recommendationsFuture.then((recommendations) {
    //   return _recommendationService.applyPersonalizationSettings(recommendations);
    // });
    
    setState(() {
      _isRefreshing = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Section header
      Padding(
        padding: EdgeInsets.symmetric(horizontal: UIScaling.padding(context)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            widget.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (widget.subtitle.isNotEmpty)
            Text(
              widget.subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          SizedBox(height: UIScaling.spacing(context, 0.5)),
        ]),
      ),
      
      // Recommendations content
      FutureBuilder<List<ContentItem>>(
        future: _recommendationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingIndicator();
          } else if (snapshot.hasError) {
            return _buildErrorWidget(snapshot.error.toString());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyStateWidget();
          }
          
          final recommendations = snapshot.data!;
          
          // Track successful recommendations load
          _analyticsService.trackEvent(
            eventName: 'recommendations_loaded',
            eventType: 'recommendation',
            additionalData: {
              'type': widget.recommendationType,
              'count': recommendations.length,
              'timestamp': DateTime.now().toIso8601String(),
            },
          );
          
          return widget.isHorizontal
              ? _buildHorizontalList(recommendations)
              : _buildVerticalList(recommendations);
        },
      ),
    ]);
  }
  
  Widget _buildHorizontalList(List<ContentItem> recommendations) {
    return SizedBox(
      height: UIScaling.cardHeight(context, isLarge: true),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: UIScaling.padding(context)),
        itemCount: recommendations.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(right: UIScaling.spacing(context)),
            child: _buildContentCard(recommendations[index]),
          );
        },
      ),
    );
  }
  
  Widget _buildVerticalList(List<ContentItem> recommendations) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: UIScaling.padding(context)),
      itemCount: recommendations.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: UIScaling.spacing(context)),
          child: _buildContentCard(recommendations[index]),
        );
      },
    );
  }
  
  Widget _buildContentCard(ContentItem item) {
    return GestureDetector(
      onTap: () {
        if (widget.onItemTap != null) {
          // Track content selection
          _analyticsService.trackEvent(
            eventName: 'recommendation_selected',
            eventType: 'user_interaction',
            additionalData: {
              'content_id': item.id,
              'content_title': item.title,
              'content_platform': item.platform,
              'recommendation_type': widget.recommendationType,
              'timestamp': DateTime.now().toIso8601String(),
            },
          );
          
          widget.onItemTap!(item);
        }
      },
      child: ContentCard(
        item: item,
        showPlatformIcon: widget.showPlatformIcons,
        showRecommendationReason: widget.showRecommendationReason,
      ),
    );
  }
  
  Widget _buildLoadingIndicator() {
    return Container(
      height: UIScaling.cardHeight(context, isLarge: true),
      alignment: Alignment.center,
      child: CircularProgressIndicator(),
    );
  }
  
  Widget _buildErrorWidget(String error) {
    return Container(
      height: UIScaling.cardHeight(context, isLarge: false),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
          SizedBox(height: UIScaling.spacing(context, 0.5)),
          Text('Could not load recommendations'),
          TextButton(
            onPressed: _loadRecommendations,
            child: Text('Try Again'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyStateWidget() {
    return Container(
      height: UIScaling.cardHeight(context, isLarge: false),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
          SizedBox(height: UIScaling.spacing(context, 0.5)),
          Text('No recommendations available yet'),
          TextButton(
            onPressed: _loadRecommendations,
            child: Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

/// A widget that displays platform-specific recommendations in separate sections
class PlatformRecommendationsWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final int itemsPerPlatform;
  final bool showRecommendationReason;
  final Function(ContentItem)? onItemTap;
  
  const PlatformRecommendationsWidget({
    Key? key,
    this.title = 'From Your Favorite Platforms',
    this.subtitle = 'Content from platforms you prefer',
    this.itemsPerPlatform = 5,
    this.showRecommendationReason = true,
    this.onItemTap,
  }) : super(key: key);

  @override
  _PlatformRecommendationsWidgetState createState() => _PlatformRecommendationsWidgetState();
}

class _PlatformRecommendationsWidgetState extends State<PlatformRecommendationsWidget> {
  final RecommendationIntegrationService _recommendationService = RecommendationIntegrationService.instance;
  final AnalyticsService _analyticsService = AnalyticsService.instance;
  
  late Future<Map<String, List<ContentItem>>> _platformRecommendationsFuture;
  
  @override
  void initState() {
    super.initState();
    _loadPlatformRecommendations();
  }
  
  Future<void> _loadPlatformRecommendations() async {
    // Track recommendation request
    _analyticsService.trackEvent(
      eventName: 'platform_recommendations_request',
      eventType: 'recommendation',
      additionalData: {
        'items_per_platform': widget.itemsPerPlatform,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    
    // Temporarily return empty map - platform recommendations not fully implemented
    _platformRecommendationsFuture = Future.value(<String, List<ContentItem>>{});
    
    setState(() {});
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Section header
      Padding(
        padding: EdgeInsets.symmetric(horizontal: UIScaling.padding(context)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            widget.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (widget.subtitle.isNotEmpty)
            Text(
              widget.subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          SizedBox(height: UIScaling.spacing(context, 0.5)),
        ]),
      ),
      
      // Platform recommendations
      FutureBuilder<Map<String, List<ContentItem>>>(
        future: _platformRecommendationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingIndicator();
          } else if (snapshot.hasError) {
            return _buildErrorWidget(snapshot.error.toString());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyStateWidget();
          }
          
          final platformRecommendations = snapshot.data!;
          
          // Track successful recommendations load
          _analyticsService.trackEvent(
            eventName: 'platform_recommendations_loaded',
            eventType: 'recommendation',
            additionalData: {
              'platform_count': platformRecommendations.length,
              'timestamp': DateTime.now().toIso8601String(),
            },
          );
          
          return Column(
            children: platformRecommendations.entries.map((entry) {
              final platform = entry.key;
              final recommendations = entry.value;
              
              if (recommendations.isEmpty) {
                return SizedBox.shrink();
              }
              
              return _buildPlatformSection(platform, recommendations);
            }).toList(),
          );
        },
      ),
    ]);
  }
  
  Widget _buildPlatformSection(String platform, List<ContentItem> recommendations) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Platform header
      Padding(
        padding: EdgeInsets.symmetric(
          horizontal: UIScaling.padding(context),
          vertical: UIScaling.spacing(context, 0.5),
        ),
        child: Row(
          children: [
            PlatformIcon(platform: platform, size: 24),
            SizedBox(width: UIScaling.spacing(context, 0.5)),
            Text(
              platform,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      
      // Platform content
      SizedBox(
        height: UIScaling.cardHeight(context),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: UIScaling.padding(context)),
          itemCount: recommendations.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.only(right: UIScaling.spacing(context)),
              child: _buildContentCard(recommendations[index]),
            );
          },
        ),
      ),
      
      SizedBox(height: UIScaling.spacing(context)),
    ]);
  }
  
  Widget _buildContentCard(ContentItem item) {
    return GestureDetector(
      onTap: () {
        if (widget.onItemTap != null) {
          // Track content selection
          _analyticsService.trackEvent(
            eventName: 'platform_recommendation_selected',
            eventType: 'user_interaction',
            additionalData: {
              'content_id': item.id,
              'content_title': item.title,
              'content_platform': item.platform,
              'timestamp': DateTime.now().toIso8601String(),
            },
          );
          
          widget.onItemTap!(item);
        }
      },
      child: ContentCard(
        item: item,
        showPlatformIcon: false, // Platform is already shown in the section header
        showRecommendationReason: widget.showRecommendationReason,
      ),
    );
  }
  
  Widget _buildLoadingIndicator() {
    return Container(
      height: UIScaling.cardHeight(context),
      alignment: Alignment.center,
      child: CircularProgressIndicator(),
    );
  }
  
  Widget _buildErrorWidget(String error) {
    return Container(
      height: UIScaling.cardHeight(context),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
          SizedBox(height: UIScaling.spacing(context, 0.5)),
          Text('Could not load platform recommendations'),
          TextButton(
            onPressed: _loadPlatformRecommendations,
            child: Text('Try Again'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyStateWidget() {
    return Container(
      height: UIScaling.cardHeight(context),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
          SizedBox(height: UIScaling.spacing(context, 0.5)),
          Text('No platform recommendations available'),
          TextButton(
            onPressed: _loadPlatformRecommendations,
            child: Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

/// A widget that displays contextual recommendations based on time of day and calendar
class ContextualRecommendationsWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final int itemCount;
  final bool showPlatformIcons;
  final bool showRecommendationReason;
  final Function(ContentItem)? onItemTap;
  
  const ContextualRecommendationsWidget({
    Key? key,
    this.title = 'For Your Current Context',
    this.subtitle = '',
    this.itemCount = 5,
    this.showPlatformIcons = true,
    this.showRecommendationReason = true,
    this.onItemTap,
  }) : super(key: key);

  @override
  _ContextualRecommendationsWidgetState createState() => _ContextualRecommendationsWidgetState();
}

class _ContextualRecommendationsWidgetState extends State<ContextualRecommendationsWidget> {
  final RecommendationIntegrationService _recommendationService = RecommendationIntegrationService.instance;
  
  late Future<List<ContentItem>> _recommendationsFuture;
  String _contextDescription = '';
  
  @override
  void initState() {
    super.initState();
    _loadContextualRecommendations();
  }
  
  Future<void> _loadContextualRecommendations() async {
    // Set context description based on time of day
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      _contextDescription = 'Good morning! Start your day with these:';
    } else if (hour >= 12 && hour < 17) {
      _contextDescription = 'Good afternoon! Take a break with these:';
    } else if (hour >= 17 && hour < 22) {
      _contextDescription = 'Good evening! Wind down with these:';
    } else {
      _contextDescription = 'Late night viewing just for you:';
    }
    
    // Temporarily return empty list - contextual recommendations not implemented
    _recommendationsFuture = Future.value(<ContentItem>[]);
    
    setState(() {});
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Section header
      Padding(
        padding: EdgeInsets.symmetric(horizontal: UIScaling.padding(context)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            widget.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            widget.subtitle.isNotEmpty ? widget.subtitle : _contextDescription,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: UIScaling.spacing(context, 0.5)),
        ]),
      ),
      
      // Recommendations
      FutureBuilder<List<ContentItem>>(
        future: _recommendationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingIndicator();
          } else if (snapshot.hasError) {
            return _buildErrorWidget(snapshot.error.toString());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyStateWidget();
          }
          
          final recommendations = snapshot.data!;
          
          return SizedBox(
            height: UIScaling.cardHeight(context),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: UIScaling.padding(context)),
              itemCount: recommendations.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(right: UIScaling.spacing(context)),
                  child: _buildContentCard(recommendations[index]),
                );
              },
            ),
          );
        },
      ),
    ]);
  }
  
  Widget _buildContentCard(ContentItem item) {
    return GestureDetector(
      onTap: () {
        if (widget.onItemTap != null) {
          widget.onItemTap!(item);
        }
      },
      child: ContentCard(
        item: item,
        showPlatformIcon: widget.showPlatformIcons,
        showRecommendationReason: widget.showRecommendationReason,
      ),
    );
  }
  
  Widget _buildLoadingIndicator() {
    return Container(
      height: UIScaling.cardHeight(context),
      alignment: Alignment.center,
      child: CircularProgressIndicator(),
    );
  }
  
  Widget _buildErrorWidget(String error) {
    return Container(
      height: UIScaling.cardHeight(context),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
          SizedBox(height: UIScaling.spacing(context, 0.5)),
          Text('Could not load contextual recommendations'),
          TextButton(
            onPressed: _loadContextualRecommendations,
            child: Text('Try Again'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyStateWidget() {
    return Container(
      height: UIScaling.cardHeight(context),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
          SizedBox(height: UIScaling.spacing(context, 0.5)),
          Text('No contextual recommendations available'),
          TextButton(
            onPressed: _loadContextualRecommendations,
            child: Text('Refresh'),
          ),
        ],
      ),
    );
  }
}