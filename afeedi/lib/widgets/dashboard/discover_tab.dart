import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../services/content_service.dart';
import '../../models/content_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/responsive/responsive_layout.dart';

class DiscoverTab extends StatefulWidget {
  const DiscoverTab({super.key});

  @override
  State<DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends State<DiscoverTab> {
  String _selectedCategory = 'All';
  String _selectedTimeWindow = '7d';
  List<Content> _content = [];
  List<Content> _trending = [];
  bool _isLoading = true;

  static const Map<String, String> _timeWindowLabels = {
    'today': 'Today',
    '7d':    'Last 7 Days',
    '30d':   'Last Month',
    '60d':   'Last 60 Days',
    '1y':    'Last Year',
  };

  static const List<String> _categories = [
    'All',
    'Trending',
    'Gaming',
    'Music',
    'Tech',
    'Food',
    'Fitness',
    'Travel',
    'Art',
    'Comedy',
    'Fashion',
    'Education',
    'Sports',
  ];

  static const Map<String, IconData> _categoryIcons = {
    'Gaming': Icons.sports_esports,
    'Music': Icons.music_note,
    'Tech': Icons.computer,
    'Food': Icons.restaurant,
    'Fitness': Icons.fitness_center,
    'Travel': Icons.flight,
    'Art': Icons.palette,
    'Comedy': Icons.sentiment_very_satisfied,
    'Fashion': Icons.checkroom,
    'Education': Icons.school,
    'Sports': Icons.sports_soccer,
  };

  static const Map<String, Color> _categoryColors = {
    'Gaming': Color(0xFF7B61FF),
    'Music': Color(0xFFFF6B9D),
    'Tech': Color(0xFF00D4FF),
    'Food': Color(0xFFFF9500),
    'Fitness': Color(0xFF32D74B),
    'Travel': Color(0xFF30B0C7),
    'Art': Color(0xFFFF453A),
    'Comedy': Color(0xFFFFD60A),
    'Fashion': Color(0xFFBF5AF2),
    'Education': Color(0xFF0A84FF),
    'Sports': Color(0xFF30D158),
  };

  @override
  void initState() {
    super.initState();
    ContentService.instance
        .getTrendingVideos(limit: 20, timeWindow: _selectedTimeWindow)
        .then((data) {
      if (mounted) {
        setState(() {
          _trending = data;
          _content = data;
          _isLoading = false;
        });
      }
    });
  }

  void _onTimeWindowSelected(String window) {
    setState(() {
      _selectedTimeWindow = window;
      _isLoading = true;
    });
    ContentService.instance
        .getTrendingVideos(limit: 20, timeWindow: window)
        .then((data) {
      if (mounted) {
        setState(() {
          _trending = data;
          _isLoading = false;
        });
      }
    });
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
    if (category == 'All' || category == 'Trending') return;
    ContentService.instance
        .getVideos(category: category.toLowerCase(), limit: 20)
        .then((data) {
      if (mounted) {
        setState(() {
          _content = data.isEmpty
              ? _trending
                  .where((c) =>
                      c.categories.any(
                          (cat) => cat.toLowerCase() == category.toLowerCase()) ||
                      c.tags
                          .any((t) => t.toLowerCase() == category.toLowerCase()))
                  .toList()
              : data;
        });
      }
    });
  }

  Color _getPlatformColor(PlatformType platform) {
    switch (platform) {
      case PlatformType.youtube:
        return const Color(0xFFFF0000);
      case PlatformType.instagram:
        return const Color(0xFFE1306C);
      case PlatformType.tiktok:
        return const Color(0xFF69C9D0);
      case PlatformType.facebook:
        return const Color(0xFF1877F2);
    }
  }

  String _getPlatformLabel(PlatformType platform) {
    switch (platform) {
      case PlatformType.youtube:
        return 'YT';
      case PlatformType.instagram:
        return 'IG';
      case PlatformType.tiktok:
        return 'TT';
      case PlatformType.facebook:
        return 'FB';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D0B1E),
      child: Column(
        children: [
          _buildSearchBar(),
          _buildCategoryChips(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/search'),
        child: AbsorbPointer(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                const Icon(
                  Icons.search,
                  color: Colors.white54,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  'Search videos, creators, topics...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: GestureDetector(
              onTap: () => _onCategorySelected(category),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color:
                      isSelected ? AppTheme.primaryCyan : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryCyan
                        : Colors.white.withOpacity(0.15),
                    width: 1,
                  ),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.w400,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) return _buildShimmerGrid();
    if (_selectedCategory == 'Trending') return _buildTrendingSection();
    return _buildDiscoverGrid();
  }

  Widget _buildShimmerGrid() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1A1A2E),
      highlightColor: const Color(0xFF2A2A3E),
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: ResponsiveLayout.gridColumns(context),
          childAspectRatio: 0.75,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrendingSection() {
    final risingContent = _trending.skip(5).take(10).toList();
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildTimeWindowChips(),
        _buildSectionHeader('🔥 Trending Now'),
        _buildTrendingHorizontalScroll(),
        _buildSectionHeader('📈 Rising'),
        _buildVideoGrid(risingContent),
        _buildSectionHeader('🎯 Popular Categories'),
        _buildCategoryGrid(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTimeWindowChips() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: _timeWindowLabels.entries.map((entry) {
          final isSelected = _selectedTimeWindow == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _onTimeWindowSelected(entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFF4500) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFFF4500) : Colors.white24,
                  ),
                ),
                child: Text(
                  entry.value,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white60,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildTrendingHorizontalScroll() {
    final trendingItems = _trending.take(10).toList();
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: trendingItems.length,
        itemBuilder: (context, index) {
          final content = trendingItems[index];
          return _buildTrendingCard(content);
        },
      ),
    );
  }

  Widget _buildTrendingCard(Content content) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 140,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Thumbnail background
              Container(
                color: const Color(0xFF1A1A2E),
                child: content.thumbnailUrl != null
                    ? CachedNetworkImage(
                        imageUrl: content.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) =>
                            _buildThumbnailPlaceholder(content),
                      )
                    : _buildThumbnailPlaceholder(content),
              ),
              // Gradient overlay at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.85),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        content.title ?? 'Untitled',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '🔥 trending',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Platform color dot top-right
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getPlatformColor(content.platform),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:
                            _getPlatformColor(content.platform).withOpacity(0.6),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnailPlaceholder(Content content) {
    final guessedCategory = _getCategoryForContent(content);
    return Container(
      color: const Color(0xFF1A1A2E),
      child: Center(
        child: Icon(
          _categoryIcons[guessedCategory] ?? Icons.play_circle,
          color: _getPlatformColor(content.platform).withOpacity(0.5),
          size: 40,
        ),
      ),
    );
  }

  String _getCategoryForContent(Content content) {
    final tags = content.tags.map((t) => t.toLowerCase()).toList();
    if (tags.contains('gaming') || tags.contains('esports')) return 'Gaming';
    if (tags.contains('music')) return 'Music';
    if (tags.contains('fitness') || tags.contains('workout')) return 'Fitness';
    if (tags.contains('travel')) return 'Travel';
    if (tags.contains('art') || tags.contains('painting')) return 'Art';
    if (tags.contains('funny') || tags.contains('comedy')) return 'Comedy';
    if (tags.contains('fashion') || tags.contains('style')) return 'Fashion';
    if (tags.contains('education') || tags.contains('school')) return 'Education';
    if (tags.contains('sports') || tags.contains('football')) return 'Sports';
    return 'Tech';
  }

  Widget _buildVideoGrid(List<Content> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveLayout.gridColumns(context),
        childAspectRatio: 0.75,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildContentCard(items[index]);
      },
    );
  }

  Widget _buildCategoryGrid() {
    final categoryEntries = _categoryIcons.entries.toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveLayout.gridColumns(context),
        childAspectRatio: 2.0,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: categoryEntries.length,
      itemBuilder: (context, index) {
        final entry = categoryEntries[index];
        final name = entry.key;
        final icon = entry.value;
        final color = _categoryColors[name] ?? AppTheme.primaryCyan;
        return GestureDetector(
          onTap: () => _onCategorySelected(name),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.8),
                  color.withOpacity(0.4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDiscoverGrid() {
    if (_content.isEmpty) {
      return const Center(
        child: Text(
          'No content found.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveLayout.gridColumns(context),
        childAspectRatio: 0.72,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _content.length,
      itemBuilder: (context, index) {
        return _buildContentCard(_content[index]);
      },
    );
  }

  Widget _buildContentCard(Content content) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                content.thumbnailUrl != null
                    ? CachedNetworkImage(
                        imageUrl: content.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) =>
                            _buildThumbnailPlaceholder(content),
                      )
                    : _buildThumbnailPlaceholder(content),
                // Platform badge
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getPlatformColor(content.platform),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getPlatformLabel(content.platform),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Info below thumbnail
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content.title ?? 'Untitled',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  content.creatorName ?? 'Unknown',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
