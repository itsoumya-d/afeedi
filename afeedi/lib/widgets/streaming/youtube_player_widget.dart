import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../models/content_model.dart';
import '../../services/analytics_service.dart';

class YouTubePlayerWidget extends StatefulWidget {
  final Content content;
  final bool autoPlay;
  final bool showControls;
  final VoidCallback? onReady;
  final Function(String)? onError;

  const YouTubePlayerWidget({
    super.key,
    required this.content,
    this.autoPlay = false,
    this.showControls = true,
    this.onReady,
    this.onError,
  });

  @override
  State<YouTubePlayerWidget> createState() => _YouTubePlayerWidgetState();
}

class _YouTubePlayerWidgetState extends State<YouTubePlayerWidget> {
  late YoutubePlayerController _controller;
  bool _isReady = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    final videoId = widget.content.platformContentId;

    _controller = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: widget.autoPlay,
      params: YoutubePlayerParams(
        showControls: widget.showControls,
        showFullscreenButton: true,
        enableJavaScript: true,
        playsInline: true,
      ),
    );

    _controller.listen((event) {
      if (!mounted) return;
      if (event.playerState == PlayerState.playing && !_isReady) {
        setState(() => _isReady = true);
        widget.onReady?.call();
        AnalyticsService.instance.trackUserInteraction(
          action: 'youtube_player_ready',
          screen: 'video_player',
          additionalData: {
            'content_id': widget.content.id,
            'video_id': videoId,
          },
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorFallback();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: YoutubePlayerControllerProvider(
          controller: _controller,
          child: YoutubePlayer(controller: _controller),
        ),
      ),
    );
  }

  Widget _buildErrorFallback() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white54, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Could not load video',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _initController();
                });
              },
              icon: const Icon(Icons.refresh, color: Color(0xFF00D4FF)),
              label: const Text(
                'Retry',
                style: TextStyle(color: Color(0xFF00D4FF)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
