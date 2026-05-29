import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/content_model.dart';
import '../services/video_content_extraction_service.dart';
import '../services/analytics_service.dart';

class EnhancedVideoPlayerWidget extends StatefulWidget {
  final Content content;
  final bool contentOnlyMode;
  final StreamQuality quality;
  final VoidCallback? onError;
  final VoidCallback? onLoaded;
  
  const EnhancedVideoPlayerWidget({
    super.key,
    required this.content,
    this.contentOnlyMode = true,
    this.quality = StreamQuality.auto,
    this.onError,
    this.onLoaded,
  });
  
  @override
  State<EnhancedVideoPlayerWidget> createState() => _EnhancedVideoPlayerWidgetState();
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
      
      if (widget.contentOnlyMode && widget.content.platform == PlatformType.youtube) {
        // Extract video content for content-only mode
        await _extractVideoContent();
      } else {
        // Fallback to standard embed mode
        await _initializeWebView();
      }
      
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
  
  Future<void> _extractVideoContent() async {
    try {
      final extractedContent = await VideoContentExtractionService.instance
          .extractVideoContent(widget.content);
      
      setState(() {
        _isLoading = false;
      });
      
      // Initialize WebView with extracted stream
      await _initializeWebViewWithExtractedContent(extractedContent);
    } catch (error) {
      // Fallback to standard embed if extraction fails
      debugPrint('Video extraction failed, falling back to embed: $error');
      await _initializeWebView();
    }
  }
  
  Future<void> _initializeWebViewWithExtractedContent(ExtractedVideoContent content) async {
    final optimalStream = VideoContentExtractionService.instance
        .getOptimalStream(content, quality: widget.quality);
    
    if (optimalStream == null) {
      throw Exception('No suitable video stream found');
    }
    
    // Create HTML content with video player
    final htmlContent = _buildVideoPlayerHTML(
      streamUrl: optimalStream.url,
      title: content.title,
      thumbnailUrl: content.thumbnailUrl,
    );
    
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('Video player page started loading: $url');
          },
          onPageFinished: (String url) {
            debugPrint('Video player page finished loading: $url');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Video player error: ${error.description}');
            setState(() {
              _hasError = true;
              _errorMessage = error.description;
              _isLoading = false;
            });
          },
        ),
      )
      ..loadHtmlString(htmlContent);
  }
  
  Future<void> _initializeWebView() async {
    final embedUrl = _buildEmbedUrl();
    
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('Embed page started loading: $url');
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            debugPrint('Embed page finished loading: $url');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Embed error: ${error.description}');
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
        // Instagram embed URL (simplified)
        return 'https://www.instagram.com/p/${widget.content.platformContentId}/embed';
      case PlatformType.tiktok:
        // TikTok embed URL (simplified)
        return 'https://www.tiktok.com/embed/v2/${widget.content.platformContentId}';
      default:
        throw UnsupportedError('Platform ${widget.content.platform} not supported for embed');
    }
  }
  
  String _buildVideoPlayerHTML({
    required String streamUrl,
    required String title,
    required String thumbnailUrl,
  }) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$title</title>
    <style>
        body {
            margin: 0;
            padding: 0;
            background: #000;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        }
        .video-container {
            position: relative;
            width: 100%;
            height: 100vh;
            background: #000;
        }
        video {
            width: 100%;
            height: 100%;
            object-fit: contain;
        }
        .video-overlay {
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(0, 0, 0, 0.3);
            display: flex;
            justify-content: center;
            align-items: center;
            opacity: 0;
            transition: opacity 0.3s ease;
        }
        .video-container:hover .video-overlay {
            opacity: 1;
        }
        .play-button {
            width: 80px;
            height: 80px;
            background: rgba(255, 255, 255, 0.9);
            border-radius: 50%;
            display: flex;
            justify-content: center;
            align-items: center;
            cursor: pointer;
            transition: transform 0.2s ease;
        }
        .play-button:hover {
            transform: scale(1.1);
        }
        .play-icon {
            width: 0;
            height: 0;
            border-left: 25px solid #000;
            border-top: 15px solid transparent;
            border-bottom: 15px solid transparent;
            margin-left: 5px;
        }
        .loading {
            color: white;
            text-align: center;
            padding: 20px;
        }
        .error {
            color: #ff6b6b;
            text-align: center;
            padding: 20px;
        }
    </style>
</head>
<body>
    <div class="video-container">
        <video 
            id="videoPlayer"
            controls
            preload="metadata"
            poster="$thumbnailUrl"
            playsinline
            webkit-playsinline>
            <source src="$streamUrl" type="video/mp4">
            <div class="error">Your browser does not support the video tag.</div>
        </video>
        
        <div class="video-overlay" id="videoOverlay">
            <div class="play-button" onclick="togglePlay()">
                <div class="play-icon"></div>
            </div>
        </div>
    </div>
    
    <script>
        const video = document.getElementById('videoPlayer');
        const overlay = document.getElementById('videoOverlay');
        
        function togglePlay() {
            if (video.paused) {
                video.play();
            } else {
                video.pause();
            }
        }
        
        video.addEventListener('play', function() {
            overlay.style.display = 'none';
        });
        
        video.addEventListener('pause', function() {
            overlay.style.display = 'flex';
        });
        
        video.addEventListener('ended', function() {
            overlay.style.display = 'flex';
        });
        
        // Handle video loading errors
        video.addEventListener('error', function(e) {
            console.error('Video loading error:', e);
            document.body.innerHTML = '<div class="error">Failed to load video content</div>';
        });
        
        // Auto-hide overlay after video starts
        video.addEventListener('loadeddata', function() {
            setTimeout(() => {
                if (!video.paused) {
                    overlay.style.display = 'none';
                }
            }, 1000);
        });
    </script>
</body>
</html>
''';
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
              Icon(
                Icons.error_outline,
                color: Colors.red[400],
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load video',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
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
                'Loading video...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: WebViewWidget(controller: _webViewController),
      ),
    );
  }
  
  @override
  void dispose() {
    super.dispose();
  }
}