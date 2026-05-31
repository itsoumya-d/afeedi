import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
// import 'dart:html' as html;
import 'dart:math';
import '../../models/content_model.dart';
import '../../services/universal_platform_player_service.dart';
// import '../../services/video_content_extraction_service.dart';
import '../../services/analytics_service.dart';
import 'social_media_video_player.dart';
import 'youtube_player_widget.dart';
// import '../enhanced_video_player_widget.dart';

// Conditional imports for web
import '../../src/stubs/ui_web.dart'
    if (dart.library.html) 'dart:ui_web'
    as ui_web;
import '../../src/stubs/html.dart' if (dart.library.html) 'dart:html' as html;

// Global registry to track registered view factories
final Set<String> _registeredViewFactories = <String>{};

class UniversalPlatformPlayer extends StatefulWidget {
  final Content content;
  final bool autoPlay;
  final bool showControls;
  final double? aspectRatio;
  final VoidCallback? onPlayerReady;
  final Function(String)? onError;
  final bool allowFullscreen;

  const UniversalPlatformPlayer({
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
  State<UniversalPlatformPlayer> createState() =>
      _UniversalPlatformPlayerState();
}

class _UniversalPlatformPlayerState extends State<UniversalPlatformPlayer> {
  bool _isLoading = true;
  bool _hasError = false;
  PlatformPlayerResult? _playerResult;
  String? _containerId;
  bool _showFallbackOptions = false;
  bool _useYouTubePlayer = false;
  // bool _useEnhancedPlayer = false;
  // VideoContentExtractionService? _extractionService;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void dispose() {
    _cleanupPlayer();
    // _extractionService?.dispose();
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Generate unique container ID for web
      if (kIsWeb) {
        _containerId =
            'iframe_${widget.content.platform.name}_${widget.content.id.replaceAll('-', '_')}_${Random().nextInt(999999)}';
      }

      // Wait for widget to be built before creating player
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _createPlayer();
      });
    } catch (error) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      widget.onError?.call(error.toString());
    }
  }

  Future<void> _createPlayer() async {
    try {
      // Try enhanced video extraction for YouTube content first
      if (widget.content.platform == PlatformType.youtube) {
        // await _tryEnhancedVideoExtraction();
        // Temporarily disabled - fallback to iframe
        if (kIsWeb && _containerId != null) {
          await _createWebIframe();
        } else {
          setState(() {
            _useYouTubePlayer = true;
            _isLoading = false;
          });
          widget.onPlayerReady?.call();
        }
      } else if (_isSocialMediaPlatform(widget.content.platform)) {
        // Instagram/TikTok/Facebook require OAuth tokens for embedding.
        // Show thumbnail + "Watch on Platform" UI instead.
        setState(() {
          _isLoading = false;
          _hasError = false;
          _showFallbackOptions = false;
          _playerResult = null;
        });
        widget.onPlayerReady?.call();
      } else if (kIsWeb && _containerId != null) {
        await _createWebIframe();
      } else {
        // For mobile, use external app launch
        setState(() {
          _playerResult = PlatformPlayerResult(
            success: false,
            playerId: null,
            platform: widget.content.platform,
            fallbackUrl: _getPlatformUrl(),
            errorMessage: 'Mobile playback requires external app',
          );
          _isLoading = false;
          _showFallbackOptions = true;
        });
      }
    } catch (error) {
      setState(() {
        _hasError = true;
        _isLoading = false;
        _showFallbackOptions = true;
      });
      widget.onError?.call(error.toString());
    }
  }

  // Future<void> _tryEnhancedVideoExtraction() async {
  //   try {
  //     _extractionService = VideoContentExtractionService();
  //     await _extractionService!.initialize();
  //
  //     // Try to extract video content
  //     final extractedContent = await _extractionService!.extractVideoContent(
  //       widget.content.videoUrl ?? widget.content.embedUrl ?? '',
  //     );
  //
  //     if (extractedContent != null && extractedContent.streams.isNotEmpty) {
  //       setState(() {
  //         _useEnhancedPlayer = true;
  //         _isLoading = false;
  //         _hasError = false;
  //       });
  //
  //       widget.onPlayerReady?.call();
  //
  //       // Track successful enhanced extraction
  //       await AnalyticsService.instance.trackUserInteraction(
  //         action: 'enhanced_video_extraction_success',
  //         screen: 'video_player',
  //         additionalData: {
  //           'content_id': widget.content.id,
  //           'platform': widget.content.platform.name,
  //           'streams_count': extractedContent.streams.length,
  //         },
  //       );
  //       return;
  //     }
  //   } catch (error) {
  //     // Log extraction failure but continue with fallback
  //     await AnalyticsService.instance.trackError(
  //       errorType: 'enhanced_extraction_failed',
  //       errorMessage: error.toString(),
  //       screen: 'video_player',
  //       additionalData: {
  //         'content_id': widget.content.id,
  //         'platform': widget.content.platform.name,
  //       },
  //     );
  //   }
  //
  //   // Fallback to standard iframe/external player
  //   if (kIsWeb && _containerId != null) {
  //     await _createWebIframe();
  //   } else {
  //     setState(() {
  //       _playerResult = PlatformPlayerResult(
  //         success: false,
  //         playerId: null,
  //         platform: widget.content.platform,
  //         fallbackUrl: _getPlatformUrl(),
  //         errorMessage: 'Enhanced extraction failed, use external app',
  //       );
  //       _isLoading = false;
  //       _showFallbackOptions = true;
  //     });
  //   }
  // }

  Future<void> _createWebIframe() async {
    if (!kIsWeb || _containerId == null) return;

    try {
      final embedUrl = _getEmbedUrl();

      // Create iframe element for web platform
      final iframe = html.IFrameElement()
        ..src = embedUrl
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allowFullscreen = true
        ..setAttribute(
          'allow',
          'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share',
        );

      // Register the view factory only if not already registered
      if (!_registeredViewFactories.contains(_containerId!)) {
        try {
          ui_web.platformViewRegistry.registerViewFactory(
            _containerId!,
            (int viewId) => iframe,
          );
          _registeredViewFactories.add(_containerId!);
        } catch (e) {
          // If registration fails, try with a different container ID
          _containerId =
              'iframe_${widget.content.platform.name}_${widget.content.id.replaceAll('-', '_')}_${Random().nextInt(999999)}_retry';
          ui_web.platformViewRegistry.registerViewFactory(
            _containerId!,
            (int viewId) => iframe,
          );
          _registeredViewFactories.add(_containerId!);
        }
      }

      setState(() {
        _playerResult = PlatformPlayerResult(
          success: true,
          playerId: _containerId,
          platform: widget.content.platform,
          embedUrl: embedUrl,
        );
        _isLoading = false;
        _hasError = false;
      });

      widget.onPlayerReady?.call();

      // Track successful player creation
      await AnalyticsService.instance.trackUserInteraction(
        action: '${widget.content.platform.name}_player_created',
        screen: 'video_player',
        additionalData: {
          'content_id': widget.content.id,
          'platform': widget.content.platform.name,
          'embed_mode': 'iframe',
        },
      );
    } catch (error) {
      setState(() {
        _hasError = true;
        _isLoading = false;
        _showFallbackOptions = true;
      });
      widget.onError?.call(error.toString());
    }
  }

  bool _isSocialMediaPlatform(PlatformType platform) {
    return platform == PlatformType.instagram ||
        platform == PlatformType.tiktok ||
        platform == PlatformType.facebook;
  }

  String _getEmbedUrl() {
    switch (widget.content.platform) {
      case PlatformType.youtube:
        final params = {
          'autoplay': widget.autoPlay ? '1' : '0',
          'controls': widget.showControls ? '1' : '0',

          'rel': '0',
          'showinfo': '0',
          'iv_load_policy': '3',
          'enablejsapi': '1',
        };
        final queryString = params.entries
            .map((e) => '${e.key}=${e.value}')
            .join('&');
        return 'https://www.youtube.com/embed/${widget.content.platformContentId}?$queryString';
      case PlatformType.instagram:
        return 'https://www.instagram.com/p/${widget.content.platformContentId}/embed/';
      case PlatformType.tiktok:
        return 'https://www.tiktok.com/embed/v2/${widget.content.platformContentId}';
      case PlatformType.facebook:
        final videoUrl =
            'https://www.facebook.com/video.php?v=${widget.content.platformContentId}';
        return 'https://www.facebook.com/plugins/video.php?href=${Uri.encodeComponent(videoUrl)}&width=500&show_text=false';
    }
  }

  String _getPlatformUrl() {
    switch (widget.content.platform) {
      case PlatformType.youtube:
        return 'https://www.youtube.com/watch?v=${widget.content.platformContentId}';
      case PlatformType.instagram:
        return 'https://www.instagram.com/p/${widget.content.platformContentId}/';
      case PlatformType.tiktok:
        return 'https://www.tiktok.com/@user/video/${widget.content.platformContentId}';
      case PlatformType.facebook:
        return 'https://www.facebook.com/video.php?v=${widget.content.platformContentId}';
    }
  }

  void _cleanupPlayer() {
    if (kIsWeb && _containerId != null) {
      // TODO: Implement proper DOM cleanup for web platform
      // final container = html.document.getElementById(_containerId!);
      // container?.children.clear();
      // Note: We don't remove from _registeredViewFactories as the factory
      // can be reused by other instances
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

    // Temporarily disable enhanced player for debugging
    // if (_useEnhancedPlayer && widget.content.platform == PlatformType.youtube) {
    //   return _buildEnhancedPlayer();
    // }

    // Use social media video player for social media platforms
    if (_isSocialMediaPlatform(widget.content.platform) &&
        _playerResult?.success == true) {
      return _buildSocialMediaPlayer();
    }

    if (kIsWeb && _containerId != null && _playerResult?.isEmbedded == true) {
      return _buildWebPlayer();
    }

    if (_useYouTubePlayer && widget.content.platform == PlatformType.youtube) {
      return YouTubePlayerWidget(
        content: widget.content,
        autoPlay: widget.autoPlay,
        showControls: widget.showControls,
        onReady: widget.onPlayerReady,
        onError: widget.onError,
      );
    }

    return _buildMobilePlayer();
  }

  // Widget _buildEnhancedPlayer() {
  //   return EnhancedVideoPlayerWidget(
  //     content: widget.content,
  //     autoPlay: widget.autoPlay,
  //     showControls: widget.showControls,
  //     extractionService: _extractionService!,
  //     onError: (error) {
  //       setState(() {
  //         _hasError = true;
  //         _errorMessage = error;
  //         _useEnhancedPlayer = false;
  //         _showFallbackOptions = true;
  //       });
  //       widget.onError?.call(error);
  //     },
  //     onFallback: () {
  //       setState(() {
  //         _useEnhancedPlayer = false;
  //         _showFallbackOptions = true;
  //       });
  //     },
  //   );
  // }

  Widget _buildSocialMediaPlayer() {
    return SocialMediaVideoPlayer(
      content: widget.content,
      autoPlay: widget.autoPlay,
      showControls: widget.showControls,
      showBranding: true,
      onFullscreen: widget.allowFullscreen
          ? () {
              // Handle fullscreen for social media player
              _handleFullscreen();
            }
          : null,
      onError: (error) {
        setState(() {
          _hasError = true;
          _showFallbackOptions = true;
        });
        widget.onError?.call(error);
      },
    );
  }

  void _handleFullscreen() {
    // Implement fullscreen logic for social media players
    // This could involve navigating to a fullscreen view or using native fullscreen APIs
  }

  Widget _buildLoadingState() {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // Thumbnail background
          _buildThumbnailBackground(),

          // Loading overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getPlatformColor(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading ${_getPlatformName()} Player...',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
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
          _buildThumbnailBackground(),

          // Error overlay with options
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.8),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getPlatformIcon(),
                    color: _getPlatformColor(),
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.content.title ?? '${_getPlatformName()} Content',
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
                    'Tap to watch on ${_getPlatformName()}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
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
        // Primary action - Open in platform
        ElevatedButton.icon(
          onPressed: _openInPlatform,
          icon: const Icon(Icons.open_in_new, color: Colors.white),
          label: Text(
            'Watch on ${_getPlatformName()}',
            style: const TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _getPlatformColor(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),

        const SizedBox(height: 12),

        // Secondary action - Retry embed
        TextButton.icon(
          onPressed: _retryPlayer,
          icon: Icon(Icons.refresh, color: Colors.white.withValues(alpha: 0.8)),
          label: Text(
            'Try Again',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
          ),
        ),
      ],
    );
  }

  Widget _buildWebPlayer() {
    return Stack(
      children: [
        // Container for platform iframe
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
              onPressed: _openInPlatform,
              icon: const Icon(Icons.open_in_new, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.7),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMobilePlayer() {
    return GestureDetector(
      onTap: _openInPlatform,
      child: Stack(
        children: [
          // Thumbnail
          _buildThumbnailBackground(),

          // Play button overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: Icon(
                  Icons.play_circle_filled,
                  color: _getPlatformColor(),
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
                  color: Colors.black.withValues(alpha: 0.8),
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

          // Platform logo
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getPlatformColor(),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getPlatformName(),
                style: const TextStyle(
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

  Widget _buildThumbnailBackground() {
    final thumbnailUrl = UniversalPlatformPlayerService.instance
        .getPlatformThumbnailUrl(widget.content);

    return Positioned.fill(
      child: Image.network(
        thumbnailUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildThumbnailPlaceholder();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildThumbnailPlaceholder();
        },
      ),
    );
  }

  Widget _buildThumbnailPlaceholder() {
    return Container(
      color: Colors.grey[900],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getPlatformIcon(), color: _getPlatformColor(), size: 48),
            const SizedBox(height: 8),
            Text(
              _getPlatformName(),
              style: const TextStyle(
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

  Future<void> _openInPlatform() async {
    final success = await UniversalPlatformPlayerService.instance
        .openInPlatform(widget.content);

    if (!success) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to open ${_getPlatformName()}. Please try again.',
            ),
            backgroundColor: _getPlatformColor(),
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

  // Helper methods for platform-specific styling
  Color _getPlatformColor() {
    switch (widget.content.platform) {
      case PlatformType.youtube:
        return const Color(0xFFFF0000);
      case PlatformType.instagram:
        return const Color(0xFFE4405F);
      case PlatformType.tiktok:
        return const Color(0xFF000000);
      case PlatformType.facebook:
        return const Color(0xFF1877F2);
    }
  }

  IconData _getPlatformIcon() {
    switch (widget.content.platform) {
      case PlatformType.youtube:
        return Icons.play_circle;
      case PlatformType.instagram:
        return Icons.camera_alt;
      case PlatformType.tiktok:
        return Icons.music_video;
      case PlatformType.facebook:
        return Icons.facebook;
    }
  }

  String _getPlatformName() {
    switch (widget.content.platform) {
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
}
