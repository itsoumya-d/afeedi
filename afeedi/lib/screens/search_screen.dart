import 'dart:convert';
import 'dart:math' show min;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../models/content_model.dart';
import '../services/content_service.dart';
import '../services/navigation_service.dart';
import '../widgets/common/loading_shimmer.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<Content> _allContent = [];
  List<Content> _results = [];
  List<Content> _trendingContent = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  bool _hasError = false;
  String _query = '';
  late TabController _tabController;
  List<String> _recentSearches = [];

  // Filter state
  PlatformType? _selectedPlatform;
  String? _selectedCategory;

  final List<String> _trendingTopics = [
    'Flutter', 'JavaScript', 'Python', 'React', 'AI', 'Machine Learning',
    'Web Dev', 'Data Science', 'DevOps', 'Mobile Dev',
  ];

  // Genre chips with their matching tag keywords
  final List<Map<String, dynamic>> _genres = [
    {'label': 'Gaming', 'icon': Icons.sports_esports, 'keywords': ['gaming', 'game', 'esports', 'gameplay', 'streaming', 'minecraft', 'fortnite']},
    {'label': 'Music', 'icon': Icons.music_note, 'keywords': ['music', 'pop', 'kpop', 'latin', 'dance', 'song', 'audio']},
    {'label': 'Food', 'icon': Icons.restaurant, 'keywords': ['cooking', 'food', 'recipe', 'pasta', 'italian', 'chef', 'hack']},
    {'label': 'Fitness', 'icon': Icons.fitness_center, 'keywords': ['workout', 'fitness', 'health', 'exercise', 'gym', 'abs']},
    {'label': 'Travel', 'icon': Icons.flight, 'keywords': ['travel', 'destinations', 'adventure', 'culture', 'vlog']},
    {'label': 'Tech', 'icon': Icons.computer, 'keywords': ['tech', 'ai', 'programming', 'javascript', 'python', 'flutter', 'react']},
    {'label': 'Art', 'icon': Icons.palette, 'keywords': ['art', 'drawing', 'painting', 'creative', 'watercolour', 'acrylic']},
    {'label': 'Nature', 'icon': Icons.eco, 'keywords': ['nature', 'outdoors', 'wildlife', 'environment', 'animals']},
    {'label': 'Comedy', 'icon': Icons.sentiment_very_satisfied, 'keywords': ['funny', 'humor', 'comedy', 'jokes', 'memes', 'relatable']},
    {'label': 'Fashion', 'icon': Icons.checkroom, 'keywords': ['fashion', 'style', 'outfits', 'trends']},
  ];

  final List<String> _categories = ['All', 'Videos', 'Shorts', 'Reels'];

  int get _activeFilterCount =>
      (_selectedPlatform != null ? 1 : 0) + (_selectedCategory != null ? 1 : 0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _loadContent();
    _loadRecentSearches();
    _loadTrending();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final content = await ContentService.instance.getFeedContent(limit: 100);
      if (mounted) setState(() => _allContent = content);
    } catch (_) {
      if (mounted) setState(() { _hasError = true; _isLoading = false; });
      return;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTrending() async {
    try {
      final trending = await ContentService.instance.getTrendingVideos(limit: 10);
      if (mounted) setState(() => _trendingContent = trending);
    } catch (_) {
      if (mounted) setState(() => _trendingContent = []);
    }
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('recent_searches');
    if (raw != null && mounted) {
      final list = List<String>.from(jsonDecode(raw) as List);
      setState(() => _recentSearches = list);
    }
  }

  Future<void> _saveRecentSearch(String query) async {
    if (query.isEmpty) return;
    _recentSearches.remove(query);
    _recentSearches.insert(0, query);
    if (_recentSearches.length > 5) _recentSearches = _recentSearches.take(5).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('recent_searches', jsonEncode(_recentSearches));
  }

  /// Sanitize a raw search query:
  /// - Trim surrounding whitespace
  /// - Strip HTML/script tags (prevent XSS-style injection into downstream systems)
  /// - Limit to 200 characters maximum
  String _sanitizeQuery(String raw) {
    final stripped = raw.trim().replaceAll(RegExp(r'<[^>]*>'), '');
    return stripped.substring(0, min(stripped.length, 200));
  }

  void _search(String query) {
    final sanitized = _sanitizeQuery(query);
    setState(() {
      _hasError = false;
      _selectedPlatform = null;
      _selectedCategory = null;
      _query = sanitized;
      _hasSearched = _query.isNotEmpty;
      if (_query.isEmpty) {
        _results = [];
        return;
      }
      final q = _query.toLowerCase();
      _results = _allContent.where((c) {
        return (c.title?.toLowerCase().contains(q) ?? false) ||
            (c.description?.toLowerCase().contains(q) ?? false) ||
            (c.creatorName?.toLowerCase().contains(q) ?? false) ||
            c.tags.any((t) => t.toLowerCase().contains(q));
      }).toList();
    });
    if (sanitized.isNotEmpty) {
      _saveRecentSearch(sanitized);
      setState(() => _recentSearches = _recentSearches);
    }
  }

  void _clearAllFilters() {
    setState(() {
      _selectedPlatform = null;
      _selectedCategory = null;
    });
  }

  bool _contentMatchesCategory(Content c, String category) {
    final keywords = (_genres.firstWhere(
      (g) => g['label'] == category,
      orElse: () => {'keywords': <String>[]},
    )['keywords'] as List<String>);
    return c.tags.any((t) => keywords.any((k) => t.toLowerCase().contains(k))) ||
        c.categories.any((cat) => keywords.any((k) => cat.toLowerCase().contains(k)));
  }

  List<Content> get _filteredResults {
    var results = _results;

    // Apply platform filter
    if (_selectedPlatform != null) {
      results = results.where((c) => c.platform == _selectedPlatform).toList();
    }

    // Apply category/genre filter
    if (_selectedCategory != null) {
      results = results.where((c) => _contentMatchesCategory(c, _selectedCategory!)).toList();
    }

    // Apply content type filter (tab)
    final tab = _tabController.index;
    if (tab == 0) return results;
    final types = [null, ContentType.video, ContentType.short, ContentType.reel];
    final type = types[tab];
    if (type == null) return results;
    return results.where((c) => c.contentType == type).toList();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0B1E),
        body: SafeArea(
          child: Column(
            children: [
              _buildSearchBar(),
              if (_hasSearched) ...[
                _buildPlatformFilterRow(),
                _buildGenreFilterRow(),
                if (_activeFilterCount > 0) _buildActiveFilterBanner(),
                _buildTabBar(),
              ],
              Expanded(
                child: _hasSearched ? _buildResults() : _buildDiscover(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A2E), Color(0xFF0D0B1E)],
        ),
      ),
      child: Row(
        children: [
          if (Navigator.canPop(context))
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E3A),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Semantics(
                label: 'Search videos, creators, topics',
                child: TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: '${AppLocalizations.of(context)!.search} videos, creators, topics...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 15),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF00D4FF), size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _search('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: _search,
                onSubmitted: _search,
              ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformFilterRow() {
    const platforms = [
      {'label': 'All', 'platform': null, 'color': Color(0xFF00D4FF)},
      {'label': 'YouTube', 'platform': PlatformType.youtube, 'color': Color(0xFFFF0000)},
      {'label': 'TikTok', 'platform': PlatformType.tiktok, 'color': Color(0xFF69C9D0)},
      {'label': 'Instagram', 'platform': PlatformType.instagram, 'color': Color(0xFFE1306C)},
      {'label': 'Facebook', 'platform': PlatformType.facebook, 'color': Color(0xFF1877F2)},
    ];
    return SizedBox(
      height: 44,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        scrollDirection: Axis.horizontal,
        children: platforms.map((p) {
          final platform = p['platform'] as PlatformType?;
          final color = p['color'] as Color;
          final label = p['label'] as String;
          final isSelected = platform == null
              ? _selectedPlatform == null
              : _selectedPlatform == platform;
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedPlatform = platform),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.25) : const Color(0xFF1E1E3A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? color : Colors.white.withValues(alpha: 0.15),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? color : Colors.white54,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGenreFilterRow() {
    return SizedBox(
      height: 40,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        children: _genres.map((genre) {
          final label = genre['label'] as String;
          final icon = genre['icon'] as IconData;
          final isSelected = _selectedCategory == label;
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: GestureDetector(
              onTap: () => setState(() {
                _selectedCategory = isSelected ? null : label;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF00D4FF).withValues(alpha: 0.2)
                      : const Color(0xFF1E1E3A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF00D4FF)
                        : Colors.white.withValues(alpha: 0.1),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 13,
                        color: isSelected ? const Color(0xFF00D4FF) : Colors.white54),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? const Color(0xFF00D4FF) : Colors.white54,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActiveFilterBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF00D4FF).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.filter_list, size: 13, color: Color(0xFF00D4FF)),
                const SizedBox(width: 4),
                Text(
                  '$_activeFilterCount filter${_activeFilterCount == 1 ? '' : 's'} active',
                  style: const TextStyle(
                    color: Color(0xFF00D4FF),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _clearAllFilters,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.close, size: 12, color: Colors.white54),
                  SizedBox(width: 3),
                  Text(
                    'Clear all',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (_, __) => TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: const Color(0xFF00D4FF),
        unselectedLabelColor: Colors.white54,
        indicatorColor: const Color(0xFF00D4FF),
        indicatorWeight: 2,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        onTap: (_) => setState(() {}),
        tabs: _categories.map((c) => Tab(text: c)).toList(),
      ),
    );
  }

  Widget _buildResults() {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.white24),
            const SizedBox(height: 16),
            const Text(
              'Failed to load results',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _search(_query),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    final results = _filteredResults;
    if (_isLoading) return const LoadingShimmer();
    if (results.isEmpty) {
      const suggestionTopics = ['Gaming', 'Comedy', 'Music', 'News'];
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search, size: 80, color: Colors.white30),
              const SizedBox(height: 20),
              Text(
                'No results for "$_query"',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Try different keywords or adjust filters',
                style: TextStyle(color: Colors.white54, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: suggestionTopics.map((topic) {
                  return GestureDetector(
                    onTap: () {
                      _searchController.text = topic;
                      _search(topic);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E3A),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF00D4FF).withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        topic,
                        style: const TextStyle(
                          color: Color(0xFF00D4FF),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_activeFilterCount > 0) ...[
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _clearAllFilters,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D4FF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF00D4FF).withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Text(
                      'Clear filters',
                      style: TextStyle(
                        color: Color(0xFF00D4FF),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    final filterSuffix = _activeFilterCount > 0
        ? ' · $_activeFilterCount filter${_activeFilterCount == 1 ? '' : 's'} active'
        : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Text(
            '${results.length} result${results.length == 1 ? '' : 's'}$filterSuffix',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: results.length,
            itemBuilder: (context, i) => _buildResultCard(results[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(Content content) {
    return Semantics(
      label: '${content.title ?? 'Untitled'}. ${content.creatorName ?? ''}. ${content.platform.name}',
      button: true,
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.player,
          arguments: content,
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: content.thumbnailUrl != null
                    ? CachedNetworkImage(
                        imageUrl: content.thumbnailUrl!,
                        width: 100,
                        height: 64,
                        fit: BoxFit.cover,
                        placeholder: (ctx, url) => Container(color: Colors.grey[900]),
                        errorWidget: (ctx, url, err) => _thumbnailFallback(),
                      )
                    : _thumbnailFallback(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content.title ?? 'Untitled',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _platformColor(content.platform).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            content.platform.name.toUpperCase(),
                            style: TextStyle(
                              color: _platformColor(content.platform),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            content.creatorName ?? '',
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      content.formattedViewCount,
                      style: const TextStyle(color: Colors.white60, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _thumbnailFallback() {
    return Container(
      width: 100,
      height: 64,
      color: const Color(0xFF1A1A2E),
      child: const Icon(Icons.image_not_supported, color: Colors.white38, size: 28),
    );
  }

  Color _platformColor(PlatformType platform) {
    switch (platform) {
      case PlatformType.youtube: return const Color(0xFFFF0000);
      case PlatformType.instagram: return const Color(0xFFE1306C);
      case PlatformType.tiktok: return const Color(0xFF69C9D0);
      case PlatformType.facebook: return const Color(0xFF1877F2);
    }
  }

  Widget _buildDiscover() {
    const popularTopics = ['Gaming', 'Tech', 'Comedy', 'Music', 'News', 'Sports', 'Food', 'Travel'];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Searches section
          const Text(
            'Recent Searches',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (_recentSearches.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: const Text(
                'No recent searches yet',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
            )
          else
            ..._recentSearches.take(5).map(_buildRecentSearchItem),
          const SizedBox(height: 20),

          // Popular topics
          const Text(
            'Popular Topics',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: popularTopics.map((topic) {
              return GestureDetector(
                onTap: () {
                  _searchController.text = topic;
                  _search(topic);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E3A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF00D4FF).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.tag, size: 13, color: Color(0xFF00D4FF)),
                      const SizedBox(width: 5),
                      Text(
                        topic,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          // Trending section from ContentService
          if (_trendingContent.isNotEmpty) ...[
            Text(
              AppLocalizations.of(context)!.trending,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _trendingContent.length,
                itemBuilder: (context, i) => _buildTrendingCard(_trendingContent[i]),
              ),
            ),
            const SizedBox(height: 28),
          ],

          const Text(
            'Browse by Platform',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _platformChip('YouTube', const Color(0xFFFF0000), Icons.play_circle_filled, PlatformType.youtube),
              const SizedBox(width: 10),
              _platformChip('Instagram', const Color(0xFFE1306C), Icons.camera_alt, PlatformType.instagram),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _platformChip('TikTok', const Color(0xFF69C9D0), Icons.music_note, PlatformType.tiktok),
              const SizedBox(width: 10),
              _platformChip('Facebook', const Color(0xFF1877F2), Icons.facebook, PlatformType.facebook),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTrendingCard(Content content) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.player, arguments: content),
      child: Container(
        width: 140,
        margin: const EdgeInsetsDirectional.only(end: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              child: content.thumbnailUrl != null
                  ? CachedNetworkImage(
                      imageUrl: content.thumbnailUrl!,
                      width: 140,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: (ctx, url) => Container(color: Colors.grey[900]),
                      errorWidget: (ctx, url, err) => Container(
                        width: 140,
                        height: 80,
                        color: const Color(0xFF1A1A2E),
                        child: const Icon(Icons.image_not_supported, color: Colors.white38),
                      ),
                    )
                  : Container(
                      width: 140,
                      height: 80,
                      color: const Color(0xFF252545),
                      child: const Icon(Icons.play_circle_outline, color: Colors.white38, size: 28),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                content.title ?? 'Untitled',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _platformChip(String name, Color color, IconData icon, PlatformType platform) {
    final isSelected = _selectedPlatform == platform;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPlatform = isSelected ? null : platform;
          });
          if (_query.isNotEmpty) _search(_query);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.25) : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : color.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  name,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 4),
                Icon(Icons.check_circle, color: color, size: 14),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSearchItem(String query) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.history, color: Colors.white38, size: 20),
      title: Text(
        query,
        style: const TextStyle(color: Colors.white70, fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.north_west, color: Colors.white24, size: 16),
      onTap: () {
        _searchController.text = query;
        _search(query);
      },
    );
  }
}
