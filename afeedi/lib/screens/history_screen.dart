import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/content_service.dart';
import '../models/content_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Content> _history = [];
  List<Content> _continueWatching = [];
  Map<String, double> _progressMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();

    // Load ordered list of watched content IDs
    final rawIds = prefs.getString('watched_ids');
    List<String> orderedIds = [];
    if (rawIds != null) {
      try {
        orderedIds = List<String>.from(jsonDecode(rawIds) as List);
      } catch (_) {
        orderedIds = [];
      }
    }

    // Load all progress keys
    final keys = prefs.getKeys();
    final Map<String, double> progressMap = {};
    for (final key in keys) {
      if (key.startsWith('watch_progress_')) {
        final id = key.replaceFirst('watch_progress_', '');
        progressMap[id] = prefs.getDouble(key) ?? 0.0;
      }
    }

    // Collect all IDs (union of ordered + those with progress)
    final allIds = <String>{...orderedIds, ...progressMap.keys};

    if (allIds.isEmpty) {
      if (mounted) {
        setState(() {
          _history = [];
          _continueWatching = [];
          _progressMap = {};
          _isLoading = false;
        });
      }
      return;
    }

    final allContent =
        await ContentService.instance.getVideos(limit: 200);
    final contentMap = {for (final c in allContent) c.id: c};

    // Restore order from orderedIds, then append any extras from progressMap
    final extras =
        progressMap.keys.where((id) => !orderedIds.contains(id)).toList();
    final fullOrder = [...orderedIds, ...extras];

    final matched = fullOrder
        .where((id) => allIds.contains(id))
        .map((id) => contentMap[id])
        .whereType<Content>()
        .toList();

    final continueWatching = matched
        .where((c) => (progressMap[c.id] ?? 0.0) < 0.8 &&
            (progressMap[c.id] ?? 0.0) > 0.0)
        .toList();

    final history = matched
        .where((c) =>
            (progressMap[c.id] ?? 0.0) >= 0.8 ||
            progressMap[c.id] == null)
        .toList();

    if (mounted) {
      setState(() {
        _progressMap = progressMap;
        _continueWatching = continueWatching;
        _history = history;
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFromHistory(Content content) async {
    final prefs = await SharedPreferences.getInstance();
    final rawIds = prefs.getString('watched_ids');
    List<String> orderedIds = [];
    if (rawIds != null) {
      try {
        orderedIds = List<String>.from(jsonDecode(rawIds) as List);
      } catch (_) {}
    }
    orderedIds.remove(content.id);
    await prefs.setString('watched_ids', jsonEncode(orderedIds));
    await prefs.remove('watch_progress_${content.id}');

    if (mounted) {
      setState(() {
        _history.removeWhere((c) => c.id == content.id);
        _continueWatching.removeWhere((c) => c.id == content.id);
        _progressMap.remove(content.id);
      });
    }
  }

  Future<void> _clearAllHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Clear Watch History',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will remove all watch history and progress. This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear All',
                style: TextStyle(color: Color(0xFFFF006E))),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('watched_ids');
    final keys = prefs.getKeys().toList();
    for (final key in keys) {
      if (key.startsWith('watch_progress_')) {
        await prefs.remove(key);
      }
    }

    if (mounted) {
      setState(() {
        _history = [];
        _continueWatching = [];
        _progressMap = {};
      });
    }
  }

  String _relativeTime(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    return '${(diff.inDays / 30).floor()} months ago';
  }

  String _timeRemaining(Content content) {
    final progress = _progressMap[content.id] ?? 0.0;
    final totalSeconds = content.durationSeconds ?? 0;
    if (totalSeconds == 0) return '';
    final remaining =
        ((1.0 - progress) * totalSeconds).round();
    final d = Duration(seconds: remaining);
    final mins = d.inMinutes;
    final secs = d.inSeconds.remainder(60);
    return '${mins}m ${secs}s left';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        title: const Text(
          'Watch History',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!_isLoading &&
              (_history.isNotEmpty || _continueWatching.isNotEmpty))
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white70),
              tooltip: 'Clear all history',
              onPressed: _clearAllHistory,
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFF00D4FF)),
              ),
            )
          : (_history.isEmpty && _continueWatching.isEmpty)
              ? _buildEmptyState()
              : _buildBody(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 72,
            color: Colors.white.withOpacity(0.25),
          ),
          const SizedBox(height: 16),
          const Text(
            'No watch history yet.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start watching videos!',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (_continueWatching.isNotEmpty) ...[
          _buildSectionHeader('Continue Watching'),
          _buildContinueWatchingScroll(),
        ],
        if (_history.isNotEmpty) ...[
          _buildSectionHeader('Watch History'),
          ..._history.map(_buildHistoryTile),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
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

  Widget _buildContinueWatchingScroll() {
    return SizedBox(
      height: 195,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _continueWatching.length,
        itemBuilder: (context, index) {
          return _buildContinueWatchingCard(_continueWatching[index]);
        },
      ),
    );
  }

  Widget _buildContinueWatchingCard(Content content) {
    final progress = _progressMap[content.id] ?? 0.0;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: SizedBox(
        width: 160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 160,
                height: 110,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Thumbnail
                    content.thumbnailUrl != null
                        ? CachedNetworkImage(
                            imageUrl: content.thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) =>
                                _buildThumbPlaceholder(content),
                          )
                        : _buildThumbPlaceholder(content),
                    // Dark overlay at bottom for progress bar
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        backgroundColor: Colors.black45,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF00D4FF)),
                        minHeight: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              content.title ?? 'Untitled',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _timeRemaining(content),
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTile(Content content) {
    final isContinueWatching =
        _continueWatching.any((c) => c.id == content.id);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(10),
        border: isContinueWatching
            ? const Border(
                left: BorderSide(
                  color: Color(0xFF00D4FF),
                  width: 3,
                ),
              )
            : null,
      ),
      child: SizedBox(
        height: 80,
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
              child: SizedBox(
                width: 112,
                height: 80,
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
            // Info
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
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
                    const SizedBox(height: 3),
                    Text(
                      content.creatorName ?? 'Unknown',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _relativeTime(content.publishedAt),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.35),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Remove button
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white38, size: 18),
              tooltip: 'Remove from history',
              onPressed: () => _removeFromHistory(content),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbPlaceholder(Content content) {
    return Container(
      color: const Color(0xFF0D0B1E),
      child: Center(
        child: Icon(
          Icons.play_circle_outline,
          color: _getPlatformColor(content.platform).withOpacity(0.4),
          size: 28,
        ),
      ),
    );
  }
}
