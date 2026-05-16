import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// import 'dart:html' as html;
import '../models/content_model.dart';
import '../core/storage/local_storage_service.dart';
import '../services/analytics_service.dart';
import '../utils/logger.dart';

/// Service for handling social media video streaming from Instagram, TikTok, and Facebook
class SocialMediaStreamingService {
  static final SocialMediaStreamingService _instance = SocialMediaStreamingService._internal();
  static SocialMediaStreamingService get instance => _instance;
  SocialMediaStreamingService._internal();

  bool _isInitialized = false;
  Map<String, String> _accessTokens = {};
  
  // Platform-specific configurations
  static const Map<PlatformType, Map<String, dynamic>> _platformConfigs = {
    PlatformType.instagram: {
      'oembedEndpoint': 'https://graph.facebook.com/v23.0/instagram_oembed',
      'requiresAuth': true,
      'supportedFormats': ['photo', 'video', 'reel'],
      'maxWidth': 658,
      'maxHeight': 658,
    },
    PlatformType.tiktok: {
      'oembedEndpoint': 'https://www.tiktok.com/oembed',
      'requiresAuth': false,
      'supportedFormats': ['video'],
      'maxWidth': 605,
      'minWidth': 325,
    },
    PlatformType.facebook: {
      'oembedEndpoint': 'https://www.facebook.com/plugins/video.php',
      'requiresAuth': false,
      'supportedFormats': ['video', 'post'],
      'maxWidth': 500,
    },
  };

  /// Initialize the social media streaming service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      Logger.info('Initializing Social Media Streaming Service');
      
      // Load any stored access tokens
      await _loadStoredTokens();
      
      // Initialize platform-specific configurations
      await _initializePlatformConfigs();
      
      _isInitialized = true;
      Logger.info('Social Media Streaming Service initialized successfully');
      
      await AnalyticsService.instance.trackUserInteraction(
        action: 'social_media_streaming_initialized',
        screen: 'streaming',
        additionalData: {
          'platforms_configured': _platformConfigs.keys.map((p) => p.name).toList(),
        },
      );
    } catch (error) {
      Logger.error('Failed to initialize Social Media Streaming Service: $error');
      await AnalyticsService.instance.trackError(
        errorType: 'social_media_streaming_init_error',
        errorMessage: error.toString(),
        screen: 'streaming',
      );
      rethrow;
    }
  }

  /// Set access token for a specific platform (required for Instagram)
  void setAccessToken(PlatformType platform, String token) {
    _accessTokens[platform.name] = token;
    Logger.info('Access token set for ${platform.name}');
  }

  /// Get embed data for a social media URL
  Future<SocialMediaEmbedResult> getEmbedData({
    required String url,
    required PlatformType platform,
    int? maxWidth,
    int? maxHeight,
  }) async {
    if (!_isInitialized) {
      throw Exception('Social Media Streaming Service not initialized');
    }

    try {
      Logger.info('Getting embed data for $platform: $url');
      
      switch (platform) {
        case PlatformType.instagram:
          return await _getInstagramEmbed(url, maxWidth, maxHeight);
        case PlatformType.tiktok:
          return await _getTikTokEmbed(url, maxWidth, maxHeight);
        case PlatformType.facebook:
          return await _getFacebookEmbed(url, maxWidth, maxHeight);
        default:
          throw Exception('Unsupported platform: $platform');
      }
    } catch (error) {
      Logger.error('Failed to get embed data for $platform: $error');
      await AnalyticsService.instance.trackError(
        errorType: 'social_media_embed_error',
        errorMessage: error.toString(),
        screen: 'streaming',
        additionalData: {
          'platform': platform.name,
          'url': url,
        },
      );
      
      return SocialMediaEmbedResult(
        success: false,
        platform: platform,
        errorMessage: error.toString(),
        fallbackUrl: url,
      );
    }
  }

  /// Get Instagram embed using oEmbed API
  Future<SocialMediaEmbedResult> _getInstagramEmbed(
    String url,
    int? maxWidth,
    int? maxHeight,
  ) async {
    final config = _platformConfigs[PlatformType.instagram]!;
    
    if (config['requiresAuth'] && !_accessTokens.containsKey('instagram')) {
      throw Exception('Instagram access token required. Please set access token first.');
    }

    final queryParams = {
      'url': url,
      'access_token': _accessTokens['instagram'] ?? '',
      if (maxWidth != null) 'maxwidth': maxWidth.toString(),
      if (maxHeight != null) 'maxheight': maxHeight.toString(),
    };

    final uri = Uri.parse(config['oembedEndpoint']).replace(
      queryParameters: queryParams,
    );

    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      await AnalyticsService.instance.trackUserInteraction(
        action: 'instagram_embed_success',
        screen: 'streaming',
        additionalData: {
          'url': url,
          'type': data['type'],
          'author': data['author_name'],
        },
      );
      
      return SocialMediaEmbedResult(
        success: true,
        platform: PlatformType.instagram,
        embedHtml: data['html'],
        title: data['title'],
        authorName: data['author_name'],
        authorUrl: data['author_url'],
        providerName: data['provider_name'],
        providerUrl: data['provider_url'],
        width: data['width'],
        height: data['height'],
        thumbnailUrl: data['thumbnail_url'],
        thumbnailWidth: data['thumbnail_width'],
        thumbnailHeight: data['thumbnail_height'],
        type: data['type'],
        version: data['version'],
      );
    } else {
      throw Exception('Instagram oEmbed API error: ${response.statusCode} - ${response.body}');
    }
  }

  // Cache for embed results
  final Map<String, Map<String, dynamic>> _embedCache = {};

  /// Get TikTok embed using oEmbed API with enhanced error handling and caching
  Future<SocialMediaEmbedResult> _getTikTokEmbed(
    String url,
    int? maxWidth,
    int? maxHeight,
  ) async {
    try {
      // Check cache first
      final cacheKey = 'tiktok_embed_${url.hashCode}';
      if (_embedCache.containsKey(cacheKey)) {
        final cached = _embedCache[cacheKey]!;
        if (DateTime.now().difference(cached['timestamp']).inHours < 24) {
          return cached['result'] as SocialMediaEmbedResult;
        }
      }
      
      final config = _platformConfigs[PlatformType.tiktok]!;
      
      // Enhanced query parameters with better defaults
      final queryParams = {
        'url': url,
        'maxwidth': (maxWidth ?? 325).toString(),
        'maxheight': (maxHeight ?? 580).toString(),
        'omit_script': 'true',
      };

      final uri = Uri.parse(config['oembedEndpoint']).replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'Afeedi/1.0 (+https://afeedi.com)',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Enhanced embed HTML with better responsive design
        String embedHtml = data['html'] ?? '';
        
        // Add responsive wrapper and enhanced styling
        embedHtml = '''
          <div class="tiktok-embed-wrapper" style="
            position: relative;
            width: 100%;
            max-width: 325px;
            margin: 0 auto;
            background: #000;
            border-radius: 12px;
            overflow: hidden;
            box-shadow: 0 4px 12px rgba(0,0,0,0.15);
          ">
            $embedHtml
            <style>
              .tiktok-embed-wrapper iframe {
                width: 100% !important;
                height: 580px !important;
                border: none;
                border-radius: 12px;
              }
              .tiktok-embed-wrapper blockquote {
                margin: 0;
                padding: 0;
              }
            </style>
          </div>
        ''';
        
        final result = SocialMediaEmbedResult(
          success: true,
          platform: PlatformType.tiktok,
          embedHtml: embedHtml,
          title: data['title'] ?? 'TikTok Video',
          authorName: data['author_name'] ?? 'TikTok User',
          authorUrl: data['author_url'],
          providerName: data['provider_name'] ?? 'TikTok',
          providerUrl: data['provider_url'] ?? 'https://www.tiktok.com',
          width: data['width'] ?? 325,
          height: data['height'] ?? 580,
          thumbnailUrl: data['thumbnail_url'],
          thumbnailWidth: data['thumbnail_width'],
          thumbnailHeight: data['thumbnail_height'],
          type: data['type'] ?? 'video',
          version: data['version'] ?? '1.0',
        );
        
        // Cache the result
        _embedCache[cacheKey] = {
          'result': result,
          'timestamp': DateTime.now(),
        };
        
        await AnalyticsService.instance.trackUserInteraction(
          action: 'tiktok_embed_success',
          screen: 'streaming',
          additionalData: {
            'url': url,
            'type': data['type'],
            'author': data['author_name'],
            'title': data['title'],
            'has_thumbnail': data['thumbnail_url'] != null,
            'cached': false,
          },
        );
        
        return result;
      } else if (response.statusCode == 404) {
        throw Exception('TikTok video not found or private');
      } else if (response.statusCode == 429) {
        throw Exception('Rate limit exceeded. Please try again later.');
      } else {
        throw Exception('TikTok oEmbed API error: ${response.statusCode} - ${response.body}');
      }
    } catch (error) {
      Logger.error('Error getting TikTok embed: $error');
      
      // Provide fallback embed for better user experience
      return _createFallbackTikTokEmbed(url, error.toString());
    }
  }
  
  SocialMediaEmbedResult _createFallbackTikTokEmbed(String url, String error) {
    // Extract video ID from URL for fallback
    final videoId = _extractTikTokVideoId(url);
    
    final fallbackHtml = '''
      <div class="tiktok-fallback" style="
        width: 100%;
        max-width: 325px;
        height: 580px;
        background: linear-gradient(135deg, #ff0050, #00f2ea);
        border-radius: 12px;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        color: white;
        text-align: center;
        padding: 20px;
        box-sizing: border-box;
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      ">
        <div style="font-size: 48px; margin-bottom: 16px;">🎵</div>
        <h3 style="margin: 0 0 8px 0; font-size: 18px; font-weight: 600;">TikTok Video</h3>
        <p style="margin: 0 0 20px 0; font-size: 14px; opacity: 0.9;">Tap to view on TikTok</p>
        <a href="$url" target="_blank" rel="noopener noreferrer" style="
          background: rgba(255,255,255,0.2);
          color: white;
          text-decoration: none;
          padding: 12px 24px;
          border-radius: 25px;
          font-weight: 600;
          transition: all 0.3s ease;
          border: 2px solid rgba(255,255,255,0.3);
        " onmouseover="this.style.background='rgba(255,255,255,0.3)'" onmouseout="this.style.background='rgba(255,255,255,0.2)'">
          Open TikTok
        </a>
        <p style="margin: 20px 0 0 0; font-size: 12px; opacity: 0.7;">Video ID: $videoId</p>
      </div>
    ''';
    
    return SocialMediaEmbedResult(
      success: true, // Mark as success since we provide fallback
      platform: PlatformType.tiktok,
      embedHtml: fallbackHtml,
      fallbackUrl: url,
      errorMessage: error,
      title: 'TikTok Video',
      width: 325,
      height: 580,
      type: 'video',
      version: '1.0',
    );
  }
  
  String _extractTikTokVideoId(String url) {
    // Extract video ID from various TikTok URL formats
    final patterns = [
      RegExp(r'/video/(\d+)'),
      RegExp(r'/v/(\d+)'),
      RegExp(r'tiktok\.com/@[^/]+/video/(\d+)'),
      RegExp(r'vm\.tiktok\.com/([A-Za-z0-9]+)'),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null) {
        return match.group(1) ?? 'unknown';
      }
    }
    
    return url.split('/').last.split('?').first;
  }

  /// Get Facebook embed using plugins API
  Future<SocialMediaEmbedResult> _getFacebookEmbed(
    String url,
    int? maxWidth,
    int? maxHeight,
  ) async {
    // Facebook uses a different approach - we create the embed URL directly
    final embedUrl = 'https://www.facebook.com/plugins/video.php?href=${Uri.encodeComponent(url)}&width=${maxWidth ?? 500}&show_text=false';
    
    // Create basic embed HTML for Facebook
    final embedHtml = '''
<iframe src="$embedUrl" 
        width="${maxWidth ?? 500}" 
        height="${maxHeight ?? 280}" 
        style="border:none;overflow:hidden" 
        scrolling="no" 
        frameborder="0" 
        allowfullscreen="true" 
        allow="autoplay; clipboard-write; encrypted-media; picture-in-picture; web-share">
</iframe>
''';
    
    await AnalyticsService.instance.trackUserInteraction(
      action: 'facebook_embed_success',
      screen: 'streaming',
      additionalData: {
        'url': url,
        'embed_url': embedUrl,
      },
    );
    
    return SocialMediaEmbedResult(
      success: true,
      platform: PlatformType.facebook,
      embedHtml: embedHtml,
      embedUrl: embedUrl,
      width: maxWidth ?? 500,
      height: maxHeight ?? 280,
      type: 'video',
      version: '1.0',
      providerName: 'Facebook',
      providerUrl: 'https://www.facebook.com',
    );
  }

  // Web embed element creation disabled for now
  // TODO: Implement proper web embed support
  dynamic createWebEmbedElement(SocialMediaEmbedResult embedResult) {
    if (!kIsWeb || !embedResult.success) return null;
    
    Logger.info('Web embed creation not implemented yet for ${embedResult.platform}');
    return null;
  }

  /// Create Instagram web embed element (disabled)
  dynamic _createInstagramWebElement(SocialMediaEmbedResult embedResult) {
    Logger.info('Instagram web embed not implemented');
    return null;
  }

  /// Create TikTok web embed element (disabled)
  dynamic _createTikTokWebElement(SocialMediaEmbedResult embedResult) {
    Logger.info('TikTok web embed not implemented');
    return null;
  }

  /// Create Facebook web embed element (disabled)
  dynamic _createFacebookWebElement(SocialMediaEmbedResult embedResult) {
    Logger.info('Facebook web embed not implemented');
    return null;
  }

  /// Extract platform and content ID from social media URL
  SocialMediaUrlInfo? parseUrl(String url) {
    try {
      final uri = Uri.parse(url);
      
      // Instagram URL patterns
      if (uri.host.contains('instagram.com')) {
        final pathSegments = uri.pathSegments;
        if (pathSegments.length >= 2 && pathSegments[0] == 'p') {
          return SocialMediaUrlInfo(
            platform: PlatformType.instagram,
            contentId: pathSegments[1],
            contentType: 'post',
            originalUrl: url,
          );
        }
        if (pathSegments.length >= 2 && pathSegments[0] == 'reel') {
          return SocialMediaUrlInfo(
            platform: PlatformType.instagram,
            contentId: pathSegments[1],
            contentType: 'reel',
            originalUrl: url,
          );
        }
      }
      
      // TikTok URL patterns
      if (uri.host.contains('tiktok.com')) {
        final pathSegments = uri.pathSegments;
        if (pathSegments.length >= 3 && pathSegments[1] == 'video') {
          return SocialMediaUrlInfo(
            platform: PlatformType.tiktok,
            contentId: pathSegments[2],
            contentType: 'video',
            originalUrl: url,
          );
        }
      }
      
      // Facebook URL patterns
      if (uri.host.contains('facebook.com')) {
        if (url.contains('/video/') || url.contains('/videos/')) {
          // Extract video ID from various Facebook URL formats
          final videoIdMatch = RegExp(r'(?:video|videos)[/=]([0-9]+)').firstMatch(url);
          if (videoIdMatch != null) {
            return SocialMediaUrlInfo(
              platform: PlatformType.facebook,
              contentId: videoIdMatch.group(1)!,
              contentType: 'video',
              originalUrl: url,
            );
          }
        }
      }
      
      return null;
    } catch (error) {
      Logger.error('Failed to parse social media URL: $error');
      return null;
    }
  }

  /// Check if a URL is supported by this service
  bool isUrlSupported(String url) {
    final urlInfo = parseUrl(url);
    return urlInfo != null;
  }

  /// Get supported platforms
  List<PlatformType> getSupportedPlatforms() {
    return _platformConfigs.keys.toList();
  }

  /// Private helper methods
  
  Future<void> _loadStoredTokens() async {
    try {
      final instagramToken = await LocalStorageService.instance.getSecureData('oauth_access_token_instagram');
      if (instagramToken != null) {
        _accessTokens['instagram'] = instagramToken;
      }
      final tiktokToken = await LocalStorageService.instance.getSecureData('oauth_access_token_tiktok');
      if (tiktokToken != null) {
        _accessTokens['tiktok'] = tiktokToken;
      }
      final facebookToken = await LocalStorageService.instance.getSecureData('oauth_access_token_facebook');
      if (facebookToken != null) {
        _accessTokens['facebook'] = facebookToken;
      }
      final youtubeToken = await LocalStorageService.instance.getSecureData('oauth_access_token_youtube');
      if (youtubeToken != null) {
        _accessTokens['youtube'] = youtubeToken;
      }
    } catch (e) {
      Logger.error('Error loading stored tokens: $e');
    }
  }

  Future<void> _initializePlatformConfigs() async {
    // Initialize any platform-specific configurations
    Logger.info('Platform configurations initialized');
  }

  /// Dispose resources
  void dispose() {
    _accessTokens.clear();
    _isInitialized = false;
  }
}

/// Result class for social media embed operations
class SocialMediaEmbedResult {
  final bool success;
  final PlatformType platform;
  final String? embedHtml;
  final String? embedUrl;
  final String? title;
  final String? authorName;
  final String? authorUrl;
  final String? providerName;
  final String? providerUrl;
  final int? width;
  final int? height;
  final String? thumbnailUrl;
  final int? thumbnailWidth;
  final int? thumbnailHeight;
  final String? type;
  final String? version;
  final String? errorMessage;
  final String? fallbackUrl;

  const SocialMediaEmbedResult({
    required this.success,
    required this.platform,
    this.embedHtml,
    this.embedUrl,
    this.title,
    this.authorName,
    this.authorUrl,
    this.providerName,
    this.providerUrl,
    this.width,
    this.height,
    this.thumbnailUrl,
    this.thumbnailWidth,
    this.thumbnailHeight,
    this.type,
    this.version,
    this.errorMessage,
    this.fallbackUrl,
  });
}

/// Information extracted from social media URLs
class SocialMediaUrlInfo {
  final PlatformType platform;
  final String contentId;
  final String contentType;
  final String originalUrl;

  const SocialMediaUrlInfo({
    required this.platform,
    required this.contentId,
    required this.contentType,
    required this.originalUrl,
  });
}