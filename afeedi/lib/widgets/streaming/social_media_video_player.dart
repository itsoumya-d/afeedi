import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/content_model.dart';
import '../../services/social_media_streaming_service.dart';
import '../../services/analytics_service.dart';
import '../../utils/logger.dart';
import 'platform_branding_widget.dart';

// Platform-specific imports - only for web
import '../../src/stubs/html.dart' if (dart.library.html) 'dart:html' as html;
import '../../src/stubs/ui_web.dart' if (dart.library.html) 'dart:ui_web' as ui_web;

/// Widget for playing social media videos from Instagram, TikTok, and Facebook
class SocialMediaVideoPlayer extends StatefulWidget {
  final Content content;
  final bool autoPlay;
  final bool showControls;
  final bool showBranding;
  final VoidCallback? onFullscreen;
  final Function(String)? onError;
  final int? maxWidth;
  final int? maxHeight;

  const SocialMediaVideoPlayer({
    super.key,
    required this.content,
    this.autoPlay = false,
    this.showControls = true,
    this.showBranding = true,
    this.onFullscreen,
    this.onError,
    this.maxWidth,
    this.maxHeight,
  });

  @override
  State<SocialMediaVideoPlayer> createState() => _SocialMediaVideoPlayerState();
}

class _SocialMediaVideoPlayerState extends State<SocialMediaVideoPlayer> {
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  SocialMediaEmbedResult? _embedResult;
  String? _webViewId;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
      });

      // Ensure social media streaming service is initialized
      await SocialMediaStreamingService.instance.initialize();

      // Get embed data for the content
      final embedResult = await SocialMediaStreamingService.instance.getEmbedData(
        url: widget.content.videoUrl ?? widget.content.embedUrl ?? '',
        platform: widget.content.platform,
        maxWidth: widget.maxWidth,
        maxHeight: widget.maxHeight,
      );

      if (embedResult.success) {
        if (kIsWeb) {
          _webViewId = 'social_media_embed_${widget.content.platform.name}_${widget.content.id}_${DateTime.now().millisecondsSinceEpoch}';

          ui_web.platformViewRegistry.registerViewFactory(_webViewId!, (int viewId) {
            final iframe = html.IFrameElement()
              ..style.border = 'none'
              ..style.width = '100%'
              ..style.height = '100%'
              ..allowFullscreen = true;

            if (embedResult.embedHtml != null && embedResult.embedHtml!.isNotEmpty) {
              iframe.srcdoc = embedResult.embedHtml;
            } else if (embedResult.embedUrl != null && embedResult.embedUrl!.isNotEmpty) {
              iframe.src = embedResult.embedUrl;
            } else {
              // Fallback if neither is available, try fallbackUrl or just empty
              iframe.src = embedResult.fallbackUrl ?? '';
            }

            return iframe;
          });
        }

        setState(() {
          _embedResult = embedResult;
          _isLoading = false;
        });

        // Track successful initialization
        await AnalyticsService.instance.trackUserInteraction(
          action: 'social_media_player_initialized',
          screen: 'video_player',
          additionalData: {
            'content_id': widget.content.id,
            'platform': widget.content.platform.name,
            'content_type': embedResult.type ?? 'unknown',
          },
        );
      } else {
        throw Exception(embedResult.errorMessage ?? 'Failed to load embed data');
      }
    } catch (error) {
      Logger.error('Failed to initialize social media player: $error');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = error.toString();
      });

      widget.onError?.call(error.toString());

      await AnalyticsService.instance.trackError(
        errorType: 'social_media_player_error',
        errorMessage: error.toString(),
        screen: 'video_player',
        additionalData: {
          'content_id': widget.content.id,
          'platform': widget.content.platform.name,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: _getAspectRatio(),
          child: Stack(
            children: [
              // Main content
              Positioned.fill(
                child: _buildPlayerContent(),
              ),
              
              // Platform branding overlay
              if (widget.showBranding && _embedResult != null)
                Positioned(
                  top: 8,
                  left: 8,
                  child: PlatformBrandingWidget(
                    platform: widget.content.platform,
                    size: 24,
                  ),
                ),
              
              // Fullscreen button
              if (widget.onFullscreen != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    onPressed: widget.onFullscreen,
                    icon: const Icon(
                      Icons.fullscreen,
                      color: Colors.white,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.7),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }
    
    if (_hasError) {
      return _buildErrorState();
    }
    
    if (_embedResult != null) {
      return _buildEmbedPlayer();
    }
    
    return _buildErrorState();
  }

  Widget _buildLoadingState() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              'Loading video...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load video',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _initializePlayer,
                  child: const Text('Retry'),
                ),
                const SizedBox(width: 16),
                if (_embedResult?.fallbackUrl != null)
                  ElevatedButton(
                    onPressed: () => _openInBrowser(_embedResult!.fallbackUrl!),
                    child: const Text('Open in Browser'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmbedPlayer() {
    if (kIsWeb) {
      return _buildWebEmbedPlayer();
    } else {
      return _buildMobileEmbedPlayer();
    }
  }

  Widget _buildWebEmbedPlayer() {
    if (_webViewId != null) {
      return HtmlElementView(viewType: _webViewId!);
    }
    // Fallback if view ID wasn't generated
    return _buildMobileEmbedPlayer();
  }

  Widget _buildMobileEmbedPlayer() {
    // For mobile, we'll use a WebView or fallback to opening in browser
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getPlatformIcon(),
              color: Colors.white,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Tap to view on ${widget.content.platform.name}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_embedResult?.title != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _embedResult!.title!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _openInBrowser(
                _embedResult?.fallbackUrl ?? widget.content.videoUrl ?? widget.content.embedUrl ?? '',
              ),
              child: const Text('Open Video'),
            ),
          ],
        ),
      ),
    );
  }

  double _getAspectRatio() {
    switch (widget.content.platform) {
      case PlatformType.instagram:
        return widget.content.contentType == ContentType.story ? 9 / 16 : 1.0;
      case PlatformType.tiktok:
        return 9 / 16; // TikTok is always vertical
      case PlatformType.facebook:
        return 16 / 9; // Facebook videos are typically horizontal
      default:
        return 16 / 9;
    }
  }

  IconData _getPlatformIcon() {
    switch (widget.content.platform) {
      case PlatformType.instagram:
        return Icons.camera_alt;
      case PlatformType.tiktok:
        return Icons.music_video;
      case PlatformType.facebook:
        return Icons.video_library;
      default:
        return Icons.play_circle_outline;
    }
  }

  void _openInBrowser(String url) {
    // For mobile platforms, use url_launcher
    // This would require adding url_launcher dependency
    print('Opening URL: $url');
    Logger.info('Would open URL in browser: $url');
  }

  @override
  void dispose() {
    super.dispose();
  }
}

/// Compact version of social media video player for grid views
class CompactSocialMediaVideoPlayer extends StatelessWidget {
  final Content content;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const CompactSocialMediaVideoPlayer({
    super.key,
    required this.content,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              // Thumbnail or placeholder
              Positioned.fill(
                child: content.thumbnailUrl != null
                    ? Image.network(
                        content.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholder();
                        },
                      )
                    : _buildPlaceholder(),
              ),
              
              // Play button overlay
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Center(
                    child: Icon(
                      Icons.play_circle_filled,
                      color: Colors.white,
                      size: width != null ? width! * 0.3 : 40,
                    ),
                  ),
                ),
              ),
              
              // Platform branding
              Positioned(
                top: 4,
                left: 4,
                child: PlatformBrandingWidget(
                  platform: content.platform,
                  size: 16,
                ),
              ),
              
              // Duration badge (if available)
              if (content.metadata['duration'] != null)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatDuration(Duration(seconds: content.metadata['duration'] ?? 0)),
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
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[900],
      child: Center(
        child: Icon(
          _getPlatformIcon(),
          color: Colors.white54,
          size: width != null ? width! * 0.4 : 48,
        ),
      ),
    );
  }

  IconData _getPlatformIcon() {
    switch (content.platform) {
      case PlatformType.instagram:
        return Icons.camera_alt;
      case PlatformType.tiktok:
        return Icons.music_video;
      case PlatformType.facebook:
        return Icons.video_library;
      default:
        return Icons.play_circle_outline;
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}