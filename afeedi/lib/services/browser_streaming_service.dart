import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../src/stubs/html.dart' if (dart.library.html) 'dart:html' as html;
import '../models/content_model.dart';
import '../models/platform_connection_model.dart';
import 'analytics_service.dart';
import 'auth_service.dart';

class BrowserStreamingService {
  static BrowserStreamingService? _instance;
  static BrowserStreamingService get instance => _instance ??= BrowserStreamingService._();
  
  BrowserStreamingService._();
  
  // Supported streaming protocols
  static const List<String> supportedProtocols = [
    'HLS', // HTTP Live Streaming
    'DASH', // Dynamic Adaptive Streaming over HTTP
    'MP4', // Progressive download
    'WebM', // WebM format
    'OGG', // Ogg format
  ];
  
  // Platform-specific streaming configurations
  static const Map<PlatformType, Map<String, dynamic>> platformConfigs = {
    PlatformType.youtube: {
      'embedDomain': 'youtube.com',
      'playerType': 'iframe',
      'supportedFormats': ['MP4', 'WebM'],
      'maxQuality': '1080p',
      'autoplay': true,
      'controls': true,
    },
    PlatformType.instagram: {
      'embedDomain': 'instagram.com',
      'playerType': 'iframe',
      'supportedFormats': ['MP4'],
      'maxQuality': '720p',
      'autoplay': false,
      'controls': true,
    },
    PlatformType.tiktok: {
      'embedDomain': 'tiktok.com',
      'playerType': 'iframe',
      'supportedFormats': ['MP4'],
      'maxQuality': '720p',
      'autoplay': true,
      'controls': false,
    },
    PlatformType.facebook: {
      'embedDomain': 'facebook.com',
      'playerType': 'iframe',
      'supportedFormats': ['MP4'],
      'maxQuality': '1080p',
      'autoplay': false,
      'controls': true,
    },
  };
  
  // Initialize streaming service
  Future<void> initialize() async {
    try {
      if (kIsWeb) {
        await _initializeWebStreaming();
      } else {
        await _initializeMobileStreaming();
      }
      
      await AnalyticsService.instance.trackUserInteraction(
        action: 'streaming_service_initialized',
        screen: 'streaming',
        additionalData: {
          'platform': kIsWeb ? 'web' : 'mobile',
          'supported_protocols': supportedProtocols,
        },
      );
    } catch (error) {
      await AnalyticsService.instance.trackError(
        errorType: 'streaming_initialization_error',
        errorMessage: error.toString(),
        screen: 'streaming',
      );
      rethrow;
    }
  }
  
  // Create streaming player for content
  Future<StreamingPlayer> createPlayer({
    required Content content,
    Map<String, dynamic>? playerOptions,
  }) async {
    try {
      final config = platformConfigs[content.platform] ?? {};
      
      final player = StreamingPlayer(
        content: content,
        config: config,
        options: playerOptions ?? {},
      );
      
      await player.initialize();
      
      await AnalyticsService.instance.trackUserInteraction(
        action: 'streaming_player_created',
        screen: 'streaming',
        additionalData: {
          'content_id': content.id,
          'platform': content.platform.name,
          'content_type': content.contentType.name,
        },
      );
      
      return player;
    } catch (error) {
      await AnalyticsService.instance.trackError(
        errorType: 'streaming_player_error',
        errorMessage: error.toString(),
        screen: 'streaming',
      );
      rethrow;
    }
  }
  
  // Get optimal streaming quality based on connection
  Future<String> getOptimalQuality() async {
    try {
      if (kIsWeb) {
        final connection = html.window.navigator.connection;
        if (connection != null) {
          final effectiveType = connection.effectiveType;
          switch (effectiveType) {
            case '4g':
              return '1080p';
            case '3g':
              return '720p';
            case '2g':
              return '480p';
            default:
              return '720p';
          }
        }
      }
      
      // Default quality for mobile or when connection info unavailable
      return '720p';
    } catch (error) {
      debugPrint('Error getting optimal quality: $error');
      return '720p';
    }
  }
  
  // Check browser compatibility
  bool isBrowserSupported() {
    if (!kIsWeb) return true; // Mobile apps are always supported
    
    try {
      final userAgent = html.window.navigator.userAgent.toLowerCase();
      
      // Check for modern browser features
      final hasVideoSupport = html.VideoElement().canPlayType('video/mp4') != '';
      final hasWebMSupport = html.VideoElement().canPlayType('video/webm') != '';
      final hasHLSSupport = _checkHLSSupport();
      
      // Check browser versions
      final isChrome = userAgent.contains('chrome') && !userAgent.contains('edge');
      final isFirefox = userAgent.contains('firefox');
      final isSafari = userAgent.contains('safari') && !userAgent.contains('chrome');
      final isEdge = userAgent.contains('edge');
      
      return hasVideoSupport && (isChrome || isFirefox || isSafari || isEdge);
    } catch (error) {
      debugPrint('Error checking browser support: $error');
      return false;
    }
  }
  
  // Get supported video formats for current browser
  List<String> getSupportedFormats() {
    if (!kIsWeb) {
      return ['MP4', 'WebM', 'HLS', 'DASH'];
    }
    
    final supportedFormats = <String>[];
    final video = html.VideoElement();
    
    if (video.canPlayType('video/mp4') != '') {
      supportedFormats.add('MP4');
    }
    if (video.canPlayType('video/webm') != '') {
      supportedFormats.add('WebM');
    }
    if (video.canPlayType('video/ogg') != '') {
      supportedFormats.add('OGG');
    }
    if (_checkHLSSupport()) {
      supportedFormats.add('HLS');
    }
    if (_checkDASHSupport()) {
      supportedFormats.add('DASH');
    }
    
    return supportedFormats;
  }
  
  // Create embed URL for platform content
  String createEmbedUrl(Content content, {Map<String, String>? parameters}) {
    final baseParams = {
      'autoplay': '0',
      'controls': '1',
      'modestbranding': '1',
      'rel': '0',
      'showinfo': '0',
    };
    
    if (parameters != null) {
      baseParams.addAll(parameters);
    }
    
    switch (content.platform) {
      case PlatformType.youtube:
        return _createYouTubeEmbedUrl(content.platformContentId, baseParams);
      case PlatformType.instagram:
        return _createInstagramEmbedUrl(content.platformContentId, baseParams);
      case PlatformType.tiktok:
        return _createTikTokEmbedUrl(content.platformContentId, baseParams);
      case PlatformType.facebook:
        return _createFacebookEmbedUrl(content.platformContentId, baseParams);
    }
  }
  
  // Handle streaming errors
  Future<void> handleStreamingError({
    required String errorType,
    required String errorMessage,
    String? contentId,
    PlatformType? platform,
  }) async {
    await AnalyticsService.instance.trackError(
      errorType: 'streaming_error',
      errorMessage: '$errorType: $errorMessage',
      screen: 'streaming',
      additionalData: {
        'content_id': contentId,
        'platform': platform?.name,
        'error_type': errorType,
      },
    );
    
    // Implement error recovery strategies
    switch (errorType) {
      case 'network_error':
        await _handleNetworkError();
        break;
      case 'format_error':
        await _handleFormatError();
        break;
      case 'permission_error':
        await _handlePermissionError();
        break;
      default:
        debugPrint('Unhandled streaming error: $errorType - $errorMessage');
    }
  }
  
  // Private helper methods
  
  Future<void> _initializeWebStreaming() async {
    // Initialize web-specific streaming components
    if (kIsWeb) {
      // Check for required APIs
      if (!_checkMediaSourceSupport()) {
        throw Exception('MediaSource API not supported');
      }
      
      // Initialize HLS.js if needed
      await _loadHLSLibrary();
      
      // Initialize DASH.js if needed
      await _loadDASHLibrary();
    }
  }
  
  Future<void> _initializeMobileStreaming() async {
    // Initialize mobile-specific streaming components
    // WebView configuration for embedded players
  }
  
  bool _checkHLSSupport() {
    if (!kIsWeb) return true;
    
    try {
      final video = html.VideoElement();
      return video.canPlayType('application/vnd.apple.mpegurl') != '' ||
             video.canPlayType('audio/mpegurl') != '';
    } catch (error) {
      return false;
    }
  }
  
  bool _checkDASHSupport() {
    if (!kIsWeb) return true;
    
    try {
      final video = html.VideoElement();
      return video.canPlayType('application/dash+xml') != '';
    } catch (error) {
      return false;
    }
  }
  
  bool _checkMediaSourceSupport() {
    if (!kIsWeb) return true;
    
    try {
      return html.window.navigator.userAgent.contains('MediaSource');
    } catch (error) {
      return false;
    }
  }
  
  Future<void> _loadHLSLibrary() async {
    // Load HLS.js library for browsers that don't natively support HLS
    if (kIsWeb && !_checkHLSSupport()) {
      // Implementation would load HLS.js from CDN
      debugPrint('Loading HLS.js library...');
    }
  }
  
  Future<void> _loadDASHLibrary() async {
    // Load DASH.js library for DASH streaming support
    if (kIsWeb) {
      // Implementation would load DASH.js from CDN
      debugPrint('Loading DASH.js library...');
    }
  }
  
  String _createYouTubeEmbedUrl(String videoId, Map<String, String> params) {
    final queryString = params.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    return 'https://www.youtube.com/embed/$videoId?$queryString';
  }
  
  String _createInstagramEmbedUrl(String postId, Map<String, String> params) {
    return 'https://www.instagram.com/p/$postId/embed/';
  }
  
  String _createTikTokEmbedUrl(String videoId, Map<String, String> params) {
    return 'https://www.tiktok.com/embed/v2/$videoId';
  }
  
  String _createFacebookEmbedUrl(String postId, Map<String, String> params) {
    return 'https://www.facebook.com/plugins/video.php?href=https://www.facebook.com/video.php?v=$postId';
  }
  
  Future<void> _handleNetworkError() async {
    // Implement network error recovery
    debugPrint('Handling network error - attempting reconnection...');
  }
  
  Future<void> _handleFormatError() async {
    // Implement format error recovery
    debugPrint('Handling format error - trying alternative format...');
  }
  
  Future<void> _handlePermissionError() async {
    // Implement permission error recovery
    debugPrint('Handling permission error - checking authentication...');
  }
}

// Streaming player class
class StreamingPlayer {
  final Content content;
  final Map<String, dynamic> config;
  final Map<String, dynamic> options;
  
  WebViewController? _webViewController;
  html.VideoElement? _videoElement;
  bool _isInitialized = false;
  bool _isPlaying = false;
  double _currentTime = 0.0;
  double _duration = 0.0;
  String _currentQuality = '720p';
  
  StreamingPlayer({
    required this.content,
    required this.config,
    required this.options,
  });
  
  // Initialize the player
  Future<void> initialize() async {
    try {
      if (kIsWeb) {
        await _initializeWebPlayer();
      } else {
        await _initializeMobilePlayer();
      }
      
      _isInitialized = true;
      
      await AnalyticsService.instance.trackUserInteraction(
        action: 'player_initialized',
        screen: 'streaming',
        additionalData: {
          'content_id': content.id,
          'platform': content.platform.name,
        },
      );
    } catch (error) {
      await AnalyticsService.instance.trackError(
        errorType: 'player_initialization_error',
        errorMessage: error.toString(),
        screen: 'streaming',
      );
      rethrow;
    }
  }
  
  // Play content
  Future<void> play() async {
    if (!_isInitialized) {
      throw Exception('Player not initialized');
    }
    
    try {
      if (kIsWeb && _videoElement != null) {
        await _videoElement!.play();
      }
      
      _isPlaying = true;
      
      await AnalyticsService.instance.trackUserInteraction(
        action: 'content_played',
        screen: 'streaming',
        additionalData: {
          'content_id': content.id,
          'platform': content.platform.name,
          'current_time': _currentTime,
        },
      );
    } catch (error) {
      await BrowserStreamingService.instance.handleStreamingError(
        errorType: 'playback_error',
        errorMessage: error.toString(),
        contentId: content.id,
        platform: content.platform,
      );
      rethrow;
    }
  }
  
  // Pause content
  Future<void> pause() async {
    if (!_isInitialized) return;
    
    try {
      if (kIsWeb && _videoElement != null) {
        _videoElement!.pause();
      }
      
      _isPlaying = false;
      
      await AnalyticsService.instance.trackUserInteraction(
        action: 'content_paused',
        screen: 'streaming',
        additionalData: {
          'content_id': content.id,
          'current_time': _currentTime,
        },
      );
    } catch (error) {
      debugPrint('Error pausing content: $error');
    }
  }
  
  // Seek to specific time
  Future<void> seekTo(double seconds) async {
    if (!_isInitialized) return;
    
    try {
      if (kIsWeb && _videoElement != null) {
        _videoElement!.currentTime = seconds;
      }
      
      _currentTime = seconds;
      
      await AnalyticsService.instance.trackUserInteraction(
        action: 'content_seeked',
        screen: 'streaming',
        additionalData: {
          'content_id': content.id,
          'seek_time': seconds,
        },
      );
    } catch (error) {
      debugPrint('Error seeking content: $error');
    }
  }
  
  // Change quality
  Future<void> setQuality(String quality) async {
    if (!_isInitialized) return;
    
    try {
      _currentQuality = quality;
      
      await AnalyticsService.instance.trackUserInteraction(
        action: 'quality_changed',
        screen: 'streaming',
        additionalData: {
          'content_id': content.id,
          'new_quality': quality,
        },
      );
    } catch (error) {
      debugPrint('Error changing quality: $error');
    }
  }
  
  // Dispose player resources
  Future<void> dispose() async {
    try {
      if (kIsWeb && _videoElement != null) {
        _videoElement!.pause();
        _videoElement!.src = '';
        _videoElement = null;
      }
      
      _webViewController = null;
      _isInitialized = false;
      _isPlaying = false;
      
      await AnalyticsService.instance.trackUserInteraction(
        action: 'player_disposed',
        screen: 'streaming',
        additionalData: {
          'content_id': content.id,
          'total_watch_time': _currentTime,
        },
      );
    } catch (error) {
      debugPrint('Error disposing player: $error');
    }
  }
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isPlaying => _isPlaying;
  double get currentTime => _currentTime;
  double get duration => _duration;
  String get currentQuality => _currentQuality;
  
  // Private methods
  
  Future<void> _initializeWebPlayer() async {
    if (content.embedUrl != null) {
      // Use iframe embed for web
      final embedUrl = BrowserStreamingService.instance.createEmbedUrl(content);
      debugPrint('Initializing web player with embed URL: $embedUrl');
    } else if (content.videoUrl != null) {
      // Use direct video element
      _videoElement = html.VideoElement()
        ..src = content.videoUrl!
        ..controls = config['controls'] ?? true
        ..autoplay = config['autoplay'] ?? false;
      
      // Set up event listeners
      _videoElement!.onLoadedMetadata.listen((_) {
        _duration = (_videoElement!.duration ?? 0.0).toDouble();
      });
      
      _videoElement!.onTimeUpdate.listen((_) {
        _currentTime = (_videoElement!.currentTime ?? 0.0).toDouble();
      });
    }
  }
  
  Future<void> _initializeMobilePlayer() async {
    // Initialize WebView for mobile platforms
    if (content.embedUrl != null) {
      final embedUrl = BrowserStreamingService.instance.createEmbedUrl(content);
      
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(Uri.parse(embedUrl));
    }
  }
}

// Streaming quality options
enum StreamingQuality {
  auto,
  p144,
  p240,
  p360,
  p480,
  p720,
  p1080,
  p1440,
  p2160,
}

// Streaming state
enum StreamingState {
  idle,
  loading,
  ready,
  playing,
  paused,
  buffering,
  ended,
  error,
}