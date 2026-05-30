import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/content_model.dart';
import '../services/content_service.dart';
import '../services/user_interaction_service.dart';
import '../widgets/streaming/enhanced_youtube_player.dart';
import '../widgets/streaming/social_media_video_player.dart';
import '../l10n/app_localizations.dart';

class PlayerScreen extends StatefulWidget {
  final Content content;

  const PlayerScreen({super.key, required this.content});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with WidgetsBindingObserver {
  bool _isLiked = false;
  bool _isSaved = false;
  bool _isFullscreen = false;
  bool _isDescriptionExpanded = false;
  bool _dataSaverMode = false;
  double _playbackSpeed = 1.0;
  late DateTime _watchStartTime;
  List<Content> _relatedContent = [];
  Timer? _progressTimer;

  static const List<double> _speedOptions = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _watchStartTime = DateTime.now();
    _incrementVideoCount();
    _loadRelatedContent();
    _loadSettings();
    _progressTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _saveWatchTime(),
    );
    setState(() {
      _isLiked = UserInteractionService.instance.isLiked(widget.content.id);
      _isSaved = UserInteractionService.instance.isSaved(widget.content.id);
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _dataSaverMode = prefs.getBool('setting_data_saver') ?? false;
      });
    }
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
    _progressTimer?.cancel();
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
    // Save watch timestamp so history can group by when the user actually watched
    await prefs.setString(
      'watch_ts_${widget.content.id}',
      DateTime.now().toIso8601String(),
    );

    // Update implicit genre weights when user watches >20% of content
    if (progress > 0.2 && widget.content.tags.isNotEmpty) {
      final weightsRaw = prefs.getString('genre_implicit_weights') ?? '';
      final weights = <String, int>{};
      for (final entry in weightsRaw.split(',')) {
        final parts = entry.split(':');
        if (parts.length == 2) weights[parts[0]] = int.tryParse(parts[1]) ?? 0;
      }
      // Weight increases proportionally to watch completion (0.2→1.0 mapped to 1→5 points)
      final points = ((progress - 0.2) / 0.8 * 4 + 1).round().clamp(1, 5);
      for (final tag in widget.content.tags) {
        if (tag.isNotEmpty) weights[tag] = (weights[tag] ?? 0) + points;
      }
      final newWeightsRaw = weights.entries
          .where((e) => e.key.isNotEmpty)
          .map((e) => '${e.key}:${e.value}')
          .join(',');
      await prefs.setString('genre_implicit_weights', newWeightsRaw);
    }
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  void _share() {
    final url = widget.content.videoUrl ?? widget.content.embedUrl;
    if (url != null && url.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: url));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Link copied to clipboard')));
    }
  }

  String _speedLabel(double speed) {
    if (speed == speed.truncateToDouble()) {
      return '${speed.toInt()}×';
    }
    return '$speed×';
  }

  void _showSpeedSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Playback Speed',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: _speedOptions.map((speed) {
                    final isSelected = _playbackSpeed == speed;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _playbackSpeed = speed);
                        Navigator.pop(ctx);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 72,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF00D4FF)
                              : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF00D4FF)
                                : Colors.white24,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _speedLabel(speed),
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
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
                  ? EnhancedYouTubePlayer(
                      content: widget.content,
                      autoPlay: !_dataSaverMode,
                    )
                  : SocialMediaVideoPlayer(
                      content: widget.content,
                      autoPlay: !_dataSaverMode,
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
                                Icon(
                                  Icons.visibility_outlined,
                                  color: Colors.white60,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_formatCount(widget.content.viewCount)} views',
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Text(
                                    widget.content.creatorName ?? '',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                      fontSize: 13,
                                    ),
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
                                    HapticFeedback.lightImpact();
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
                                    HapticFeedback.lightImpact();
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
                                const SizedBox(width: 20),
                                _SpeedButton(
                                  speed: _playbackSpeed,
                                  onTap: _showSpeedSelector,
                                ),
                              ],
                            ),

                            // Description
                            if (widget.content.description != null &&
                                widget.content.description!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              GestureDetector(
                                onTap: () => setState(
                                  () => _isDescriptionExpanded =
                                      !_isDescriptionExpanded,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.content.description!,
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 13,
                                        height: 1.5,
                                      ),
                                      maxLines: _isDescriptionExpanded
                                          ? null
                                          : 2,
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
                                        fontWeight: FontWeight.w500,
                                      ),
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
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            AppLocalizations.of(context)?.recommended ??
                                'Up Next',
                            style: const TextStyle(
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

// ─── Speed button ────────────────────────────────────────────────────────────
class _SpeedButton extends StatelessWidget {
  final double speed;
  final VoidCallback onTap;

  const _SpeedButton({required this.speed, required this.onTap});

  String get _label {
    if (speed == speed.truncateToDouble()) {
      return '${speed.toInt()}×';
    }
    return '$speed×';
  }

  @override
  Widget build(BuildContext context) {
    final bool isNonDefault = speed != 1.0;
    return Semantics(
      label: 'Playback speed: $_label',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.speed,
                color: isNonDefault ? const Color(0xFF00D4FF) : Colors.white,
                size: 22,
              ),
              const SizedBox(width: 6),
              Text(
                _label,
                style: TextStyle(
                  color: isNonDefault ? const Color(0xFF00D4FF) : Colors.white,
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
                            child: const Icon(
                              Icons.play_circle_outline,
                              color: Colors.white24,
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: const Color(0xFF1A1A2E),
                            child: const Icon(
                              Icons.play_circle_outline,
                              color: Colors.white24,
                            ),
                          ),
                        )
                      : Container(
                          color: const Color(0xFF1A1A2E),
                          child: const Icon(
                            Icons.play_circle_outline,
                            color: Colors.white24,
                          ),
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
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      content.formattedViewCount,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
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
