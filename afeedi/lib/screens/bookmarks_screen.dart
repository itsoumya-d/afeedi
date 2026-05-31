import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/analytics_service.dart';
import '../services/content_service.dart';
import '../services/navigation_service.dart';
import '../widgets/common/loading_shimmer.dart';
import '../models/content_model.dart';

enum _SortMode { recentlySaved, alphabetical, byPlatform }

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List<Content> _saved = [];
  List<Content> _displayed = [];
  bool _isLoading = true;
  _SortMode _sortMode = _SortMode.recentlySaved;

  @override
  void initState() {
    super.initState();
    _loadSaved();
    AnalyticsService.instance.trackUserInteraction(
      action: 'screen_view',
      screen: 'bookmarks',
    );
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final savedIds = keys
        .where((k) => k.startsWith('saved_') && prefs.getBool(k) == true)
        .map((k) => k.replaceFirst('saved_', ''))
        .toSet();

    if (savedIds.isEmpty) {
      if (mounted) {
        setState(() {
          _saved = [];
          _displayed = [];
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final allContent = await ContentService.instance.getVideos(limit: 200);
      final matched = allContent.where((c) => savedIds.contains(c.id)).toList();
      if (mounted) {
        setState(() {
          _saved = matched;
          _displayed = List.from(matched);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _unsave(Content content) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('saved_${content.id}', false);
    if (mounted) {
      setState(() {
        _saved.removeWhere((c) => c.id == content.id);
        _displayed.removeWhere((c) => c.id == content.id);
      });
    }
  }

  void _applySort(_SortMode mode) {
    setState(() {
      _sortMode = mode;
      switch (mode) {
        case _SortMode.recentlySaved:
          _displayed = List.from(_saved);
        case _SortMode.alphabetical:
          _displayed = List.from(_saved)
            ..sort((a, b) => (a.title ?? '').compareTo(b.title ?? ''));
        case _SortMode.byPlatform:
          _displayed = List.from(_saved)
            ..sort((a, b) => a.platform.name.compareTo(b.platform.name));
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
        return 'YouTube';
      case PlatformType.instagram:
        return 'Instagram';
      case PlatformType.tiktok:
        return 'TikTok';
      case PlatformType.facebook:
        return 'Facebook';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        title: const Text(
          'Bookmarks',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          PopupMenuButton<_SortMode>(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.filter_list, color: Colors.white),
                if (_sortMode != _SortMode.recentlySaved)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00D4FF),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            color: const Color(0xFF1A1A2E),
            onSelected: _applySort,
            itemBuilder: (context) => [
              _buildMenuItem(
                _SortMode.recentlySaved,
                'Recently Saved',
                Icons.access_time,
              ),
              _buildMenuItem(
                _SortMode.alphabetical,
                'A–Z',
                Icons.sort_by_alpha,
              ),
              _buildMenuItem(
                _SortMode.byPlatform,
                'By Platform',
                Icons.devices,
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isLoading
            ? const LoadingShimmer(itemCount: 3)
            : _displayed.isEmpty
            ? _buildEmptyState()
            : _buildList(),
      ),
    );
  }

  PopupMenuItem<_SortMode> _buildMenuItem(
    _SortMode mode,
    String label,
    IconData icon,
  ) {
    final isSelected = _sortMode == mode;
    return PopupMenuItem(
      value: mode,
      child: Row(
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF00D4FF) : Colors.white70,
            size: 18,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF00D4FF) : Colors.white,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmarks_outlined,
            size: 80,
            color: Colors.white.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'No saved videos yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Tap the bookmark icon on any video to save it here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _displayed.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: Colors.white.withValues(alpha: 0.06),
        indent: 16,
        endIndent: 16,
      ),
      itemBuilder: (context, index) {
        return _buildSavedTile(_displayed[index]);
      },
    );
  }

  Widget _buildSavedTile(Content content) {
    return Semantics(
      label:
          '${content.title ?? 'Untitled'}. ${content.creatorName ?? ''}. Bookmarked.',
      button: true,
      child: Dismissible(
        key: Key('bookmark_${content.id}'),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => _unsave(content),
        background: Container(
          color: Colors.red.withValues(alpha: 0.2),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(
            Icons.bookmark_remove,
            color: Colors.redAccent,
            size: 26,
          ),
        ),
        child: SizedBox(
          height: 80,
          child: ListTile(
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.player,
              arguments: content,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 112,
                height: 72,
                child: content.thumbnailUrl != null
                    ? CachedNetworkImage(
                        imageUrl: content.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) =>
                            _buildThumbPlaceholder(content),
                      )
                    : _buildThumbPlaceholder(content),
              ),
            ),
            title: Text(
              content.title ?? 'Untitled',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Row(
              children: [
                Text(
                  content.creatorName ?? 'Unknown',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: _getPlatformColor(content.platform).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _getPlatformColor(
                        content.platform,
                      ).withValues(alpha: 0.5),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    _getPlatformLabel(content.platform),
                    style: TextStyle(
                      color: _getPlatformColor(content.platform),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(
                Icons.bookmark_remove,
                color: Colors.white38,
                size: 22,
              ),
              tooltip: 'Remove bookmark',
              onPressed: () => _unsave(content),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbPlaceholder(Content content) {
    return Container(
      color: const Color(0xFF1A1A2E),
      child: Center(
        child: Icon(
          Icons.play_circle_outline,
          color: _getPlatformColor(content.platform).withValues(alpha: 0.5),
          size: 28,
        ),
      ),
    );
  }
}
