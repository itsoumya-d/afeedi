import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/content_model.dart';
import '../services/content_service.dart';
import '../widgets/streaming/enhanced_youtube_player.dart';
import '../widgets/streaming/social_media_video_player.dart';

class PlayerScreen extends StatefulWidget {
  final Content content;

  const PlayerScreen({super.key, required this.content});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  bool _isLiked = false;
  bool _isSaved = false;
  late DateTime _watchStartTime;

  @override
  void initState() {
    super.initState();
    _watchStartTime = DateTime.now();
    _incrementVideoCount();
  }

  Future<void> _incrementVideoCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt('stat_videos_watched') ?? 0) + 1;
    await prefs.setInt('stat_videos_watched', count);
  }

  @override
  void dispose() {
    _saveWatchTime();
    super.dispose();
  }

  Future<void> _saveWatchTime() async {
    final elapsed = DateTime.now().difference(_watchStartTime).inSeconds;
    if (elapsed < 5) return; // ignore accidental opens
    final prefs = await SharedPreferences.getInstance();
    final minutes = prefs.getInt('stat_watch_minutes') ?? 0;
    await prefs.setInt('stat_watch_minutes', minutes + (elapsed ~/ 60));
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App bar row — 44dp minimum touch on back button via IconButton default
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            // Video player
            Expanded(
              child: widget.content.platform == PlatformType.youtube
                  ? EnhancedYouTubePlayer(content: widget.content, autoPlay: true)
                  : SocialMediaVideoPlayer(content: widget.content, autoPlay: true),
            ),
            // Info section
            Container(
              color: const Color(0xFF0D0B1E),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.content.title ?? 'Untitled',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.content.creatorName ?? 'Unknown Creator',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Like button
                      _ActionButton(
                        icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _isLiked ? Colors.red : Colors.white,
                        label: _formatCount(widget.content.likeCount),
                        onTap: () async {
                          await ContentService.instance.trackContentInteraction(
                            contentId: widget.content.id,
                            interactionType: InteractionType.like,
                          );
                          setState(() => _isLiked = !_isLiked);
                        },
                      ),
                      const SizedBox(width: 20),
                      // Save button
                      _ActionButton(
                        icon: _isSaved ? Icons.bookmark : Icons.bookmark_border,
                        color: _isSaved ? Colors.cyan : Colors.white,
                        label: _isSaved ? 'Saved' : 'Save',
                        onTap: () async {
                          await ContentService.instance.trackContentInteraction(
                            contentId: widget.content.id,
                            interactionType: InteractionType.save,
                          );
                          setState(() => _isSaved = !_isSaved);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
    return InkWell(
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
    );
  }
}
