import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/content_model.dart';
import '../services/content_service.dart';
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
  bool _isLoading = false;
  bool _hasSearched = false;
  String _query = '';
  late TabController _tabController;

  final List<String> _trendingTopics = [
    'Flutter', 'JavaScript', 'Python', 'React', 'AI', 'Machine Learning',
    'Web Dev', 'Data Science', 'DevOps', 'Mobile Dev',
  ];

  final List<String> _categories = ['All', 'Videos', 'Shorts', 'Reels'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _loadContent();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    final content = await ContentService.instance.getFeedContent(limit: 100);
    if (mounted) setState(() => _allContent = content);
  }

  void _search(String query) {
    setState(() {
      _query = query.trim();
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
  }

  List<Content> get _filteredResults {
    final tab = _tabController.index;
    if (tab == 0) return _results;
    final types = [null, ContentType.video, ContentType.short, ContentType.reel];
    final type = types[tab];
    if (type == null) return _results;
    return _results.where((c) => c.contentType == type).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B1E),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            if (_hasSearched) _buildTabBar(),
            Expanded(
              child: _hasSearched ? _buildResults() : _buildDiscover(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF1A1A2E), const Color(0xFF0D0B1E)],
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
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Search videos, creators, topics...',
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
    final results = _filteredResults;
    if (_isLoading) return const LoadingShimmer();
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 56, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              'No results for "$_query"',
              style: const TextStyle(color: Colors.white54, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try different keywords',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: results.length,
      itemBuilder: (context, i) => _buildResultCard(results[i]),
    );
  }

  Widget _buildResultCard(Content content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: content.thumbnailUrl != null
                    ? Image.network(
                        content.thumbnailUrl!,
                        width: 100,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _thumbnailFallback(),
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
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
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
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      content.formattedViewCount,
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbnailFallback() {
    return Container(
      width: 100,
      height: 64,
      color: const Color(0xFF252545),
      child: const Icon(Icons.play_circle_outline, color: Colors.white38, size: 28),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trending Topics',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _trendingTopics.map((topic) {
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
                      const Icon(Icons.trending_up, size: 14, color: Color(0xFF00D4FF)),
                      const SizedBox(width: 6),
                      Text(topic, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          const Text(
            'Browse by Platform',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _platformChip('YouTube', const Color(0xFFFF0000), Icons.play_circle_filled),
              const SizedBox(width: 10),
              _platformChip('Instagram', const Color(0xFFE1306C), Icons.camera_alt),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _platformChip('TikTok', const Color(0xFF69C9D0), Icons.music_note),
              const SizedBox(width: 10),
              _platformChip('Facebook', const Color(0xFF1877F2), Icons.facebook),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            'Recent Searches',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildRecentSearchItem('flutter tutorial'),
          _buildRecentSearchItem('machine learning'),
          _buildRecentSearchItem('web development 2024'),
        ],
      ),
    );
  }

  Widget _platformChip(String name, Color color, IconData icon) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _searchController.text = name;
          _search(name);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(name, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14)),
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
      title: Text(query, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      trailing: const Icon(Icons.north_west, color: Colors.white24, size: 16),
      onTap: () {
        _searchController.text = query;
        _search(query);
      },
    );
  }
}
