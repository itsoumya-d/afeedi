import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../src/stubs/html.dart' if (dart.library.html) 'dart:html' as html;
import 'dart:math';
import '../../models/content_model.dart';
import '../../services/youtube_player_service.dart';
import '../../services/analytics_service.dart';
import '../../core/theme/app_theme.dart';

class EnhancedYouTubePlayer extends StatefulWidget {
  final Content content;
  final bool autoPlay;
  final bool showControls;
  final double? aspectRatio;
  final VoidCallback? onPlayerReady;
  final Function(String)? onError;
  final bool allowFullscreen;

  const EnhancedYouTubePlayer({
    super.key,
    required this.content,
    this.autoPlay = false,
    this.showControls = true,
    this.aspectRatio,
    this.onPlayerReady,
    this.onError,
    this.allowFullscreen = true,
  });

  @override
  State<EnhancedYouTubePlayer> createState() => _EnhancedYouTubePlayerState();
}

class _EnhancedYouTubePlayerState extends State<EnhancedYouTubePlayer> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  YouTubePlayerResult? _playerResult;
  String? _containerId;
  bool _showFallbackOptions = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void dispose() {
    _cleanupPlayer();
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    if (widget.content.platform != PlatformType.youtube) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Content is not from YouTube';
        _isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Generate unique container ID for web
      if (kIsWeb) {
        _containerId = 'youtube-player-${Random().nextInt(999999)}';
      }

      // Wait for widget to be built before creating player
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _createPlayer();
      });
    } catch (error) {
      setState(() {
        _hasError = true;
        _errorMessage = error.toString();
        _isLoading = false;
      });
      widget.onError?.call(error.toString());
    }
  }

  Future<void> _createPlayer() async {
    try {
      final result = await YouTubePlayerService.instance.createPlayer(
        content: widget.content,
        containerId: _containerId ?? 'youtube-player-fallback',
        autoplay: widget.autoPlay,
        showControls: widget.showControls,
      );

      setState(() {
        _playerResult = result;
        _isLoading = false;
        _hasError = !result.success;
        _errorMessage = result.errorMessage ?? '';
        _showFallbackOptions = !result.success;
      });

      if (result.success) {
        widget.onPlayerReady?.call();
      } else {
        widget.onError?.call(result.errorMessage ?? 'Unknown error');
      }
    } catch (error) {
      setState(() {
        _hasError = true;
        _errorMessage = error.toString();
        _isLoading = false;
        _showFallbackOptions = true;
      });
      widget.onError?.call(error.toString());
    }
  }

  void _cleanupPlayer() {
    if (kIsWeb && _containerId != null) {
      final container = html.document.getElementById(_containerId!);
      container?.children.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final aspectRatio = widget.aspectRatio ?? 16 / 9;

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _buildPlayerContent(),
        ),
      ),
    );
  }

  Widget _buildPlayerContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_hasError || _showFallbackOptions) {
      return _buildErrorState();
    }

    if (kIsWeb && _containerId != null) {
      return _buildWebPlayer();
    }

    return _buildMobilePlayer();
  }

  Widget _buildLoadingState() {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // Thumbnail background
          if (widget.content.thumbnailUrl != null)
            Positioned.fill(
              child: Image.network(
                widget.content.thumbnailUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildThumbnailPlaceholder();
                },
              ),
            )
          else
            _buildThumbnailPlaceholder(),

          // Loading overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading YouTube Player...',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // Thumbnail background
          if (widget.content.thumbnailUrl != null)
            Positioned.fill(
              child: Image.network(
                widget.content.thumbnailUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildThumbnailPlaceholder();
                },
              ),
            )
          else
            _buildThumbnailPlaceholder(),

          // Error overlay with options
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.8),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.play_circle_outline,
                    color: Colors.red,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.content.title ?? 'YouTube Video',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to watch on YouTube',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Primary action - Open in YouTube
        ElevatedButton.icon(
          onPressed: _openInYouTube,
          icon: const Icon(Icons.open_in_new, color: Colors.white),
          label: const Text(
            'Watch on YouTube',
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),

        const SizedBox(height: 12),

        // Secondary action - Retry embed
        TextButton.icon(
          onPressed: _retryPlayer,
          icon: Icon(Icons.refresh, color: Colors.white.withOpacity(0.8)),
          label: Text(
            'Try Again',
            style: TextStyle(color: Colors.white.withOpacity(0.8)),
          ),
        ),
      ],
    );
  }

  Widget _buildWebPlayer() {
    return Stack(
      children: [
        // Container for YouTube iframe
        Positioned.fill(
          child: HtmlElementView(
            viewType: _containerId!,
            onPlatformViewCreated: (id) {
              // Platform view created
            },
          ),
        ),

        // Fallback overlay if needed
        if (_showFallbackOptions)
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              onPressed: _openInYouTube,
              icon: const Icon(Icons.open_in_new, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withOpacity(0.7),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMobilePlayer() {
    return GestureDetector(
      onTap: _openInYouTube,
      child: Stack(
        children: [
          // Thumbnail
          if (widget.content.thumbnailUrl != null)
            Positioned.fill(
              child: Image.network(
                widget.content.thumbnailUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildThumbnailPlaceholder();
                },
              ),
            )
          else
            _buildThumbnailPlaceholder(),

          // Play button overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Icon(
                  Icons.play_circle_filled,
                  color: Colors.red,
                  size: 64,
                ),
              ),
            ),
          ),

          // Duration badge
          if (widget.content.durationSeconds != null)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.content.formattedDuration,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          // YouTube logo
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'YouTube',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailPlaceholder() {
    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_outline, color: Colors.red, size: 48),
            SizedBox(height: 8),
            Text(
              'YouTube',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openInYouTube() async {
    final success = await YouTubePlayerService.instance.openInYouTube(
      widget.content,
    );

    if (!success) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open YouTube. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _retryPlayer() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _showFallbackOptions = false;
    });

    await _createPlayer();
  }
}
