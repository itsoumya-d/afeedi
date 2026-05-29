import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/navigation_service.dart';

class ContentWidgets extends StatelessWidget {
  const ContentWidgets({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const _RecentContentSection(),
        const SizedBox(height: 24),
        Text(
          'Trending Topics',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const _TrendingTopicsSection(),
      ],
    );
  }
}

class _RecentContentSection extends StatelessWidget {
  const _RecentContentSection();

  @override
  Widget build(BuildContext context) {
    final recentPosts = [
      {
        'title': 'My latest adventure in the mountains',
        'platform': 'Instagram',
        'time': '2 hours ago',
        'engagement': '24 likes',
        'icon': Icons.photo_camera,
      },
      {
        'title': 'Thoughts on the latest tech trends',
        'platform': 'Twitter',
        'time': '5 hours ago',
        'engagement': '12 retweets',
        'icon': Icons.chat_bubble_outline,
      },
      {
        'title': 'Recipe for the perfect weekend brunch',
        'platform': 'Facebook',
        'time': '1 day ago',
        'engagement': '45 reactions',
        'icon': Icons.restaurant,
      },
    ];

    return Column(
      children: recentPosts.map((post) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ContentCard(
            title: post['title'] as String,
            platform: post['platform'] as String,
            time: post['time'] as String,
            engagement: post['engagement'] as String,
            icon: post['icon'] as IconData,
          ),
        );
      }).toList(),
    );
  }
}

class _ContentCard extends StatelessWidget {
  final String title;
  final String platform;
  final String time;
  final String engagement;
  final IconData icon;

  const _ContentCard({
    required this.title,
    required this.platform,
    required this.time,
    required this.engagement,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: () {
          NavigationService.pushNamed(AppRoutes.feed);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryCyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryCyan,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            platform,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.primaryPink,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            ' • $time',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      engagement,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendingTopicsSection extends StatelessWidget {
  const _TrendingTopicsSection();

  @override
  Widget build(BuildContext context) {
    final trendingTopics = [
      {'name': '#TechTrends2024', 'posts': '1.2K posts'},
      {'name': '#SustainableLiving', 'posts': '856 posts'},
      {'name': '#DigitalWellness', 'posts': '642 posts'},
      {'name': '#CreativeLife', 'posts': '423 posts'},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: trendingTopics.map((topic) {
        return _TrendingChip(
          name: topic['name'] as String,
          posts: topic['posts'] as String,
        );
      }).toList(),
    );
  }
}

class _TrendingChip extends StatelessWidget {
  final String name;
  final String posts;

  const _TrendingChip({
    required this.name,
    required this.posts,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        NavigationService.pushNamed(AppRoutes.search);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primaryCyan, AppTheme.primaryPink],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            Text(
              posts,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}