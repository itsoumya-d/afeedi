import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/content_model.dart';
import '../services/analytics_service.dart';

/// YouTube-ToS-compliant video player widget.
/// Uses the official IFrame embed (webview_flutter) — never extracts stream URLs.
class EnhancedVideoPlayerWidget extends StatefulWidget {
  final Content content;
  final bool contentOnlyMode;
  final VoidCallback? onError;
  final VoidCallback? onLoaded;

  const EnhancedVideoPlayerWidget({
    super.key,
    required this.content,
    this.contentOnlyMode = true,
    this.onError,
    this.onLoaded,
  });

  @override
  State<EnhancedVideoPlayerWidget> createState() =>
      _EnhancedVideoPlayerWidgetState();
}

class _EnhancedVideoPlayerWidgetState extends State<EnhancedVideoPlayerWidget> {
  late WebViewController _webViewController;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

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
      await _initializeWebView();
      widget.onLoaded?.call();
    } catch (error) {
      setState(() {
        _hasError = true;
        _errorMessage = error.toString();
        _isLoading = false;
      });
      widget.onError?.call();
      await AnalyticsService.instance.trackError(
        errorType: 'enhanced_video_player_error',
        errorMessage: error.toString(),
        screen: 'video_player',
      );
    }
  }

  Future<void> _initializeWebView() async {
    final embedUrl = _buildEmbedUrl();

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _hasError = true;
              _errorMessage = error.description;
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(embedUrl));
  }

  String _buildEmbedUrl() {
    switch (widget.content.platform) {
      case PlatformType.youtube:
        final videoId = widget.content.platformContentId;
        return 'https://www.youtube.com/embed/$videoId?autoplay=1&controls=1&modestbranding=1&rel=0';
      case PlatformType.instagram:
        return 'https://www.instagram.com/p/${widget.content.platformContentId}/embed';
      case PlatformType.tiktok:
        return 'https://www.tiktok.com/embed/v2/${widget.content.platformContentId}';
      default:
        throw UnsupportedError(
          'Platform ${widget.content.platform} not supported for embed',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red[400], size: 48),
              const SizedBox(height: 16),
              Text(
                'Failed to load video',
                style: TextStyle(color: Colors.grey[300], fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializePlayer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading video…',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: WebViewWidget(controller: _webViewController),
      ),
    );
  }
}
