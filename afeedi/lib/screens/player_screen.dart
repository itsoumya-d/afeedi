import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/content_model.dart';
import '../services/content_service.dart';
import '../services/navigation_service.dart';
import '../widgets/streaming/enhanced_youtube_player.dart';
import '../widgets/streaming/social_media_video_player.dart';

class PlayerScreen extends StatefulWidget {
  final Content content;

  const PlayerScreen({super.key, required this.content});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with WidgetsBindingObserver {
  bool _isLiked = false;
  bool _isSaved = false;
  bool _isFullscreen = false;
  bool _isDescriptionExpanded = false;
  late DateTime _watchStartTime;
  List<Content> _relatedContent = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _watchStartTime = DateTime.now();
    _incrementVideoCount();
    _loadRelatedContent();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _saveWatchTime();
    }
  }

  void _toggleFullscreen() {
    if (_isFullscreen) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
    setState(() => _isFullscreen = !_isFullscreen);
  }

  Future<void> _incrementVideoCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt('stat_videos_watched') ?? 0) + 1;
    await prefs.setInt('stat_videos_watched', count);
  }

  Future<void> _loadRelatedContent() async {
    try {
      final tags = widget.content.tags;
      final category = widget.content.categories.isNotEmpty
          ? widget.content.categories.first
          : (tags.isNotEmpty ? tags.first : null);
      final all = await ContentService.instance.getVideos(
        category: category,
        limit: 12,
      );
      final related = all
          .where((c) => c.id != widget.content.id)
          .take(8)
          .toList();
      if (mounted) setState(() => _relatedContent = related);
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _saveWatchTime();
    super.dispose();
  }

  Future<void> _saveWatchTime() async {
    final prefs = await SharedPreferences.getInstance();
    final elapsed = DateTime.now().difference(_watchStartTime).inSeconds;
    final minutes = prefs.getInt('stat_watch_minutes') ?? 0;
    await prefs.setInt('stat_watch_minutes', minutes + (elapsed ~/ 60));

    final duration = widget.content.durationSeconds ?? 300;
    final progress = elapsed / duration.clamp(1, duration);
    if (progress > 0.01) {
      final key = 'watch_progress_${widget.content.id}';
      if (progress >= 0.9) {
        await prefs.remove(key);
      } else {
        await prefs.setDouble(key, progress.clamp(0.0, 1.0));
      }
    }
    final watchedList = prefs.getStringList('watched_ids') ?? [];
    watchedList.remove(widget.content.id);
    watchedList.insert(0, widget.content.id);
    await prefs.setStringList('watched_ids', watchedList.take(100).toList());
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  void _share() {
    final url = widget.content.videoUrl ?? widget.content.embedUrl;
    if (url != null && url.isNotEmpty) {
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── App bar ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    tooltip: 'Back',
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.share_outlined, color: Colors.white),
                    tooltip: 'Share',
                    onPressed: _share,
                  ),
                ],
              ),
            ),

            // ── Video player ─────────────────────────────────────────────────
            AspectRatio(
              aspectRatio: 16 / 9,
              child: widget.content.platform == PlatformType.youtube
                  ? EnhancedYouTubePlayer(content: widget.content, autoPlay: true)
                  : SocialMediaVideoPlayer(
                      content: widget.content,
                      autoPlay: true,
                      onFullscreen: _toggleFullscreen,
                    ),
            ),

            // ── Scrollable info + Up Next ────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  color: const Color(0xFF0D0B1E),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info section
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Text(
                              widget.content.title ?? 'Untitled',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),

                            // View count + creator
                            Row(
                              children: [
                                Icon(Icons.visibility_outlined,
                                    color: Colors.white38, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '${_formatCount(widget.content.viewCount)} views',
                                  style: const TextStyle(
                                      color: Colors.white38, fontSize: 12),
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Text(
                                    widget.content.creatorName ?? '',
                                    style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.7),
                                        fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Action buttons row
                            Row(
                              children: [
                                _ActionButton(
                                  icon: _isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: _isLiked ? Colors.red : Colors.white,
                                  label: _formatCount(widget.content.likeCount),
                                  onTap: () async {
                                    await ContentService.instance
                                        .trackContentInteraction(
                                      contentId: widget.content.id,
                                      interactionType: InteractionType.like,
                                    );
                                    setState(() => _isLiked = !_isLiked);
                                  },
                                ),
                                const SizedBox(width: 20),
                                _ActionButton(
                                  icon: _isSaved
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                  color: _isSaved
                                      ? const Color(0xFF00D4FF)
                                      : Colors.white,
                                  label: _isSaved ? 'Saved' : 'Save',
                                  onTap: () async {
                                    await ContentService.instance
                                        .trackContentInteraction(
                                      contentId: widget.content.id,
                                      interactionType: InteractionType.save,
                                    );
                                    setState(() => _isSaved = !_isSaved);
                                  },
                                ),
                                const SizedBox(width: 20),
                                _ActionButton(
                                  icon: Icons.share_outlined,
                                  color: Colors.white,
                                  label: 'Share',
                                  onTap: _share,
                                ),
                              ],
                            ),

                            // Description
                            if (widget.content.description != null &&
                                widget.content.description!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              GestureDetector(
                                onTap: () => setState(() =>
                                    _isDescriptionExpanded =
                                        !_isDescriptionExpanded),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.content.description!,
                                      style: const TextStyle(
                                          color: Colors.white54, fontSize: 13, height: 1.5),
                                      maxLines: _isDescriptionExpanded ? null : 2,
                                      overflow: _isDescriptionExpanded
                                          ? null
                                          : TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      _isDescriptionExpanded
                                          ? 'Show less'
                                          : 'Show more',
                                      style: const TextStyle(
                                          color: Color(0xFF00D4FF),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // ── Up Next ────────────────────────────────────────────
                      if (_relatedContent.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            'Up Next',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        ..._relatedContent.map((c) => _RelatedCard(content: c)),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Action button ────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Related / Up Next card ───────────────────────────────────────────────────
class _RelatedCard extends StatelessWidget {
  final Content content;
  const _RelatedCard({required this.content});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: content.title ?? 'Video',
      button: true,
      child: InkWell(
        onTap: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => PlayerScreen(content: content)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 120,
                  height: 68,
                  child: content.thumbnailUrl != null
                      ? CachedNetworkImage(
                          imageUrl: content.thumbnailUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: const Color(0xFF1A1A2E),
                            child: const Icon(Icons.play_circle_outline,
                                color: Colors.white24),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: const Color(0xFF1A1A2E),
                            child: const Icon(Icons.play_circle_outline,
                                color: Colors.white24),
                          ),
                        )
                      : Container(
                          color: const Color(0xFF1A1A2E),
                          child: const Icon(Icons.play_circle_outline,
                              color: Colors.white24),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content.title ?? 'Untitled',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      content.creatorName ?? '',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      content.formattedViewCount,
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
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
    );
  }
}
