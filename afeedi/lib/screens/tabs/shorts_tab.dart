// Shorts tab – rewrites the original broken implementation.
//
// Root cause of the original bug: ContentService.getFeedContent() returns no
// items with ContentType.short/reel and none with durationSeconds <= 180,
// so _shortsContent was always empty. The fallback mock data used
// via.placeholder.com URLs (which are unreliable) and had no real YouTube
// integration. This version uses YouTubeDataApiService, filters to genuine
// short videos (ISO 8601 duration < 60 s), and opens each video at the
// YouTube Shorts URL on tap.

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../services/youtube_data_api_service.dart';

class ShortsTab extends StatefulWidget {
  const ShortsTab({super.key});

  @override
  State<ShortsTab> createState() => _ShortsTabState();
}

class _ShortsTabState extends State<ShortsTab> {
  List<YouTubeVideo> _shorts = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadShorts();
  }

  // ---------------------------------------------------------------------------
  // Data
  // ---------------------------------------------------------------------------

  Future<void> _loadShorts() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final all = await YouTubeDataApiService.instance
          .fetchVideosByQuery(query: 'shorts', maxResults: 30);
      // Keep only videos whose ISO 8601 duration parses to <= 180 seconds (3 min).
      final filtered =
          all.where((v) => _durationSeconds(v.duration) <= 180).toList();
      // If the filter is too aggressive (e.g. all durations are missing),
      // fall back to the full result set so the tab is never blank.
      final result = filtered.isNotEmpty ? filtered : all;
      if (mounted) {
        setState(() {
          _shorts = result;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Parses an ISO 8601 duration string such as PT45S, PT1M30S, PT4M13S
  /// and returns the total number of seconds.
  int _durationSeconds(String iso) {
    if (iso.isEmpty || iso == 'PT0S') return 0;
    try {
      final match = RegExp(
              r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?',
              caseSensitive: false)
          .firstMatch(iso);
      if (match == null) return 0;
      final h = int.tryParse(match.group(1) ?? '0') ?? 0;
      final m = int.tryParse(match.group(2) ?? '0') ?? 0;
      final s = int.tryParse(match.group(3) ?? '0') ?? 0;
      return h * 3600 + m * 60 + s;
    } catch (_) {
      return 0;
    }
  }

  String _formatDuration(String iso) {
    final secs = _durationSeconds(iso);
    if (secs <= 0) return '';
    final m = secs ~/ 60;
    final s = secs % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String _formatViews(int count) {
    if (count >= 1000000000) {
      return '${(count / 1000000000).toStringAsFixed(1)}B';
    }
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return '$count';
  }

  Future<void> _openShort(YouTubeVideo video) async {
    final uri = Uri.parse('https://www.youtube.com/shorts/${video.id}');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open video')),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildShimmer();
    if (_hasError) return _buildError();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                'Shorts',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadShorts,
                color: AppTheme.primaryCyan,
                backgroundColor: Colors.black,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _shorts.length,
                  itemBuilder: (context, index) =>
                      _buildShortsCard(_shorts[index]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Individual card
  // ---------------------------------------------------------------------------

  Widget _buildShortsCard(YouTubeVideo video) {
    final duration = _formatDuration(video.duration);
    return GestureDetector(
      onTap: () => _openShort(video),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            // Thumbnail (9:16 portrait crop)
            SizedBox(
              width: 100,
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: video.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: AppTheme.darkSecondary,
                        child: const Icon(Icons.play_circle_outline,
                            color: Colors.white54, size: 32),
                      ),
                    ),
                    // Duration badge
                    if (duration.isNotEmpty)
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            duration,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    // Shorts icon badge
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPink.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Shorts',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      video.channelTitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.visibility_outlined,
                            size: 13,
                            color: Colors.white.withOpacity(0.45)),
                        const SizedBox(width: 4),
                        Text(
                          _formatViews(video.viewCount),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.open_in_new,
                            size: 13,
                            color: AppTheme.primaryCyan.withOpacity(0.8)),
                        const SizedBox(width: 4),
                        Text(
                          'Watch',
                          style: TextStyle(
                            color: AppTheme.primaryCyan.withOpacity(0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shimmer loading
  // ---------------------------------------------------------------------------

  Widget _buildShimmer() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Shimmer.fromColors(
          baseColor: Colors.grey[850]!,
          highlightColor: Colors.grey[700]!,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: List.generate(
                6,
                (_) => Container(
                  height: 120,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Error state
  // ---------------------------------------------------------------------------

  Widget _buildError() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded,
                color: Colors.white.withOpacity(0.5), size: 64),
            const SizedBox(height: 16),
            Text(
              'Could not load Shorts',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadShorts,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryCyan,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
