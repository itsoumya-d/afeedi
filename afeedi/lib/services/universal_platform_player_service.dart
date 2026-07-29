import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'dart:html' as html;
import 'dart:ui' as ui;
import '../models/content_model.dart';
import 'analytics_service.dart';
import 'youtube_player_service.dart';

// Conditional import for web
import '../src/stubs/ui_web.dart' if (dart.library.html) 'dart:ui_web' as ui_web;

class UniversalPlatformPlayerService {
  static UniversalPlatformPlayerService? _instance;
  static UniversalPlatformPlayerService get instance => _instance ??= UniversalPlatformPlayerService._();
  
  UniversalPlatformPlayerService._();
  
  // Cache for iframe HTML content
  final Map<String, String> _iframeCache = {};
  
  // Create platform-specific player with fallback to external app
  Future<PlatformPlayerResult> createPlayer({
    required Content content,
    required String containerId,
    bool autoplay = false,
    bool showControls = true,
  }) async {
    try {
      switch (content.platform) {
        case PlatformType.youtube:
          return await _createYouTubePlayer(
            content: content,
            containerId: containerId,
            autoplay: autoplay,
            showControls: showControls,
          );
        case PlatformType.instagram:
          return await _createInstagramPlayer(
            content: content,
            containerId: containerId,
            autoplay: autoplay,
            showControls: showControls,
          );
        case PlatformType.tiktok:
          return await _createTikTokPlayer(
            content: content,
            containerId: containerId,
            autoplay: autoplay,
            showControls: showControls,
          );
        case PlatformType.facebook:
          return await _createFacebookPlayer(
            content: content,
            containerId: containerId,
            autoplay: autoplay,
            showControls: showControls,
          );
      }
    } catch (error) {
      await AnalyticsService.instance.trackError(
        errorType: 'platform_player_creation_error',
        errorMessage: error.toString(),
        screen: 'video_player',
      );
      
      return PlatformPlayerResult(
        success: false,
        playerId: null,
        platform: content.platform,
        fallbackUrl: _getPlatformUrl(content),
        errorMessage: error.toString(),
      );
    }
  }
  
  Future<PlatformPlayerResult> _createYouTubePlayer({
    required Content content,
    required String containerId,
    required bool autoplay,
    required bool showControls,
  }) async {
    try {
      final youtubeResult = await YouTubePlayerService.instance.createPlayer(
        content: content,
        containerId: containerId,
        autoplay: autoplay,
        showControls: showControls,
      );
      
      return PlatformPlayerResult(
        success: youtubeResult.success,
        playerId: youtubeResult.playerId,
        platform: PlatformType.youtube,
        embedUrl: youtubeResult.embedUrl,
        externalUrl: youtubeResult.externalUrl,
        fallbackUrl: youtubeResult.fallbackUrl,
        errorMessage: youtubeResult.errorMessage,
      );
    } catch (error) {
      return PlatformPlayerResult(
        success: false,
        playerId: null,
        platform: PlatformType.youtube,
        fallbackUrl: 'https://www.youtube.com/watch?v=${content.platformContentId}',
        errorMessage: error.toString(),
      );
    }
  }
  
  Future<PlatformPlayerResult> _createInstagramPlayer({
    required Content content,
    required String containerId,
    required bool autoplay,
    required bool showControls,
  }) async {
    try {
      if (kIsWeb) {
        // Create Instagram embed iframe
        final embedUrl = 'https://www.instagram.com/p/${content.platformContentId}/embed/';
        
        // TODO: Implement proper iframe creation for web platform
        // Note: View factory registration is now handled by UniversalPlatformPlayer
        // to avoid conflicts with multiple registrations
        
        await AnalyticsService.instance.trackUserInteraction(
          action: 'instagram_player_created',
          screen: 'video_player',
          additionalData: {
            'content_id': content.id,
            'post_id': content.platformContentId,
            'embed_mode': 'iframe',
          },
        );
        
        return PlatformPlayerResult(
          success: true,
          playerId: containerId,
          platform: PlatformType.instagram,
          embedUrl: embedUrl,
        );
      }
      
      // Fallback to external Instagram
      return PlatformPlayerResult(
        success: false,
        playerId: null,
        platform: PlatformType.instagram,
        fallbackUrl: 'https://www.instagram.com/p/${content.platformContentId}/',
        errorMessage: 'Instagram embed not supported',
      );
    } catch (error) {
      return PlatformPlayerResult(
        success: false,
        playerId: null,
        platform: PlatformType.instagram,
        fallbackUrl: 'https://www.instagram.com/p/${content.platformContentId}/',
        errorMessage: error.toString(),
      );
    }
  }
  
  Future<PlatformPlayerResult> _createTikTokPlayer({
    required Content content,
    required String containerId,
    required bool autoplay,
    required bool showControls,
  }) async {
    try {
      if (kIsWeb) {
        // Enhanced TikTok embed using the latest player API
        final queryParams = <String, String>{
          if (!showControls) 'controls': '0',
          if (autoplay) 'autoplay': '1',
          'music_info': '1',
          'description': '1',
        };
        
        final queryString = queryParams.entries
            .map((e) => '${e.key}=${e.value}')
            .join('&');
        
        // Use the enhanced TikTok player v1 API for better control
        final embedUrl = 'https://www.tiktok.com/player/v1/${content.platformContentId}?$queryString';
        
        // Register iframe for web platform with postMessage support
        if (kIsWeb) {
          // Create iframe element with enhanced features
          final iframeHtml = '''
            <iframe 
              id="$containerId"
              src="$embedUrl"
              width="100%"
              height="100%"
              frameborder="0"
              allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
              allowfullscreen
              style="border-radius: 8px; box-shadow: 0 4px 12px rgba(0,0,0,0.15);"
            ></iframe>
            <script>
              // Enhanced postMessage communication with TikTok player
              window.addEventListener('message', function(event) {
                if (event.data && event.data['x-tiktok-player']) {
                  console.log('TikTok player event:', event.data);
                  // Handle player events (play, pause, ended, etc.)
                  if (event.data.type === 'video_play') {
                    window.parent.postMessage({type: 'tiktok_play', videoId: '${content.platformContentId}'}, '*');
                  } else if (event.data.type === 'video_pause') {
                    window.parent.postMessage({type: 'tiktok_pause', videoId: '${content.platformContentId}'}, '*');
                  } else if (event.data.type === 'video_ended') {
                    window.parent.postMessage({type: 'tiktok_ended', videoId: '${content.platformContentId}'}, '*');
                  }
                }
              });
              
              // Enhanced player control functions
              function seekTo(seconds) {
                const iframe = document.getElementById('$containerId');
                if (iframe && iframe.contentWindow) {
                  iframe.contentWindow.postMessage({
                    type: 'seekTo',
                    value: Number(seconds),
                    'x-tiktok-player': true
                  }, '*');
                }
              }
              
              function playVideo() {
                const iframe = document.getElementById('$containerId');
                if (iframe && iframe.contentWindow) {
                  iframe.contentWindow.postMessage({
                    type: 'play',
                    'x-tiktok-player': true
                  }, '*');
                }
              }
              
              function pauseVideo() {
                const iframe = document.getElementById('$containerId');
                if (iframe && iframe.contentWindow) {
                  iframe.contentWindow.postMessage({
                    type: 'pause',
                    'x-tiktok-player': true
                  }, '*');
                }
              }
              
              // Expose control functions globally
              window.tiktokPlayer_$containerId = {
                seekTo: seekTo,
                play: playVideo,
                pause: pauseVideo
              };
            </script>
          ''';
          
          // Store iframe HTML for platform view registration
          _iframeCache[containerId] = iframeHtml;
        }
        
        await AnalyticsService.instance.trackUserInteraction(
          action: 'tiktok_enhanced_player_created',
          screen: 'video_player',
          additionalData: {
            'content_id': content.id,
            'video_id': content.platformContentId,
            'embed_mode': 'enhanced_iframe',
            'autoplay': autoplay,
            'show_controls': showControls,
            'player_version': 'v1',
          },
        );
        
        return PlatformPlayerResult(
          success: true,
          playerId: containerId,
          platform: PlatformType.tiktok,
          embedUrl: embedUrl,
        );
      }
      
      // Enhanced mobile fallback with better URL construction
      final mobileUrl = content.videoUrl ?? 'https://www.tiktok.com/@user/video/${content.platformContentId}';
      
      return PlatformPlayerResult(
        success: false,
        playerId: null,
        platform: PlatformType.tiktok,
        fallbackUrl: mobileUrl,
        errorMessage: 'TikTok embed requires web platform - redirecting to TikTok app',
      );
    } catch (error) {
      await AnalyticsService.instance.trackError(
        errorType: 'tiktok_player_creation_error',
        errorMessage: error.toString(),
        screen: 'video_player',
        additionalData: {
          'content_id': content.id,
          'video_id': content.platformContentId,
        },
      );
      
      return PlatformPlayerResult(
        success: false,
        playerId: null,
        platform: PlatformType.tiktok,
        fallbackUrl: content.videoUrl ?? 'https://www.tiktok.com/@user/video/${content.platformContentId}',
        errorMessage: error.toString(),
      );
    }
  }
  
  Future<PlatformPlayerResult> _createFacebookPlayer({
    required Content content,
    required String containerId,
    required bool autoplay,
    required bool showControls,
  }) async {
    try {
      if (kIsWeb) {
        // Create Facebook embed iframe
        final videoUrl = 'https://www.facebook.com/video.php?v=${content.platformContentId}';
        final embedUrl = 'https://www.facebook.com/plugins/video.php?href=${Uri.encodeComponent(videoUrl)}&width=500&show_text=false&appId';
        
        // TODO: Implement proper iframe creation for web platform
        // Note: View factory registration is now handled by UniversalPlatformPlayer
        // to avoid conflicts with multiple registrations
        
        await AnalyticsService.instance.trackUserInteraction(
          action: 'facebook_player_created',
          screen: 'video_player',
          additionalData: {
            'content_id': content.id,
            'video_id': content.platformContentId,
            'embed_mode': 'iframe',
          },
        );
        
        return PlatformPlayerResult(
          success: true,
          playerId: containerId,
          platform: PlatformType.facebook,
          embedUrl: embedUrl,
        );
      }
      
      // Fallback to external Facebook
      return PlatformPlayerResult(
        success: false,
        playerId: null,
        platform: PlatformType.facebook,
        fallbackUrl: 'https://www.facebook.com/video.php?v=${content.platformContentId}',
        errorMessage: 'Facebook embed not supported',
      );
    } catch (error) {
      return PlatformPlayerResult(
        success: false,
        playerId: null,
        platform: PlatformType.facebook,
        fallbackUrl: 'https://www.facebook.com/video.php?v=${content.platformContentId}',
        errorMessage: error.toString(),
      );
    }
  }
  
  // Open content in external platform app/website
  Future<bool> openInPlatform(Content content) async {
    try {
      final platformUrl = _getPlatformUrl(content);
      final appUrl = _getPlatformAppUrl(content);
      
      bool launched = false;
      
      // Try platform app first if available
      if (appUrl != null) {
        try {
          if (await canLaunchUrl(Uri.parse(appUrl))) {
            launched = await launchUrl(
              Uri.parse(appUrl),
              mode: LaunchMode.externalApplication,
            );
          }
        } catch (e) {
          // Platform app not available, continue to browser fallback
        }
      }
      
      // Fallback to browser
      if (!launched) {
        launched = await launchUrl(
          Uri.parse(platformUrl),
          mode: LaunchMode.externalApplication,
        );
      }
      
      if (launched) {
        await AnalyticsService.instance.trackUserInteraction(
          action: '${content.platform.name}_external_launch',
          screen: 'video_player',
          additionalData: {
            'content_id': content.id,
            'platform': content.platform.name,
            'launch_mode': 'external_app',
          },
        );
      }
      
      return launched;
    } catch (error) {
      await AnalyticsService.instance.trackError(
        errorType: 'platform_external_open_error',
        errorMessage: error.toString(),
        screen: 'video_player',
      );
      return false;
    }
  }
  
  String _getPlatformUrl(Content content) {
    switch (content.platform) {
      case PlatformType.youtube:
        return 'https://www.youtube.com/watch?v=${content.platformContentId}';
      case PlatformType.instagram:
        return 'https://www.instagram.com/p/${content.platformContentId}/';
      case PlatformType.tiktok:
        return 'https://www.tiktok.com/@user/video/${content.platformContentId}';
      case PlatformType.facebook:
        return 'https://www.facebook.com/video.php?v=${content.platformContentId}';
    }
  }
  
  String? _getPlatformAppUrl(Content content) {
    switch (content.platform) {
      case PlatformType.youtube:
        return 'youtube://watch?v=${content.platformContentId}';
      case PlatformType.instagram:
        return 'instagram://media?id=${content.platformContentId}';
      case PlatformType.tiktok:
        return 'tiktok://video/${content.platformContentId}';
      case PlatformType.facebook:
        return 'fb://video/${content.platformContentId}';
    }
  }
  
  // Get platform-specific thumbnail URL
  String getPlatformThumbnailUrl(Content content, {PlatformThumbnailQuality quality = PlatformThumbnailQuality.high}) {
    if (content.thumbnailUrl != null) {
      return content.thumbnailUrl!;
    }
    
    switch (content.platform) {
      case PlatformType.youtube:
        return YouTubePlayerService.instance.getThumbnailUrl(
          content.platformContentId,
          quality: YouTubeThumbnailQuality.high,
        );
      case PlatformType.instagram:
        return 'https://www.instagram.com/p/${content.platformContentId}/media/?size=l';
      case PlatformType.tiktok:
        return 'https://www.tiktok.com/oembed?url=https://www.tiktok.com/@user/video/${content.platformContentId}';
      case PlatformType.facebook:
        return 'https://graph.facebook.com/${content.platformContentId}/picture?type=large';
    }
  }
  
  // Check if platform embed is supported
  bool isPlatformEmbedSupported(PlatformType platform) {
    if (!kIsWeb) return false; // Mobile uses external apps
    
    switch (platform) {
      case PlatformType.youtube:
        return YouTubePlayerService.instance.isEmbedSupported();
      case PlatformType.instagram:
      case PlatformType.tiktok:
      case PlatformType.facebook:
        return true; // Basic iframe support
    }
  }
  
  // Get platform-specific player configuration
  Map<String, dynamic> getPlatformConfig(PlatformType platform) {
    switch (platform) {
      case PlatformType.youtube:
        return {
          'embedDomain': 'youtube.com',
          'playerType': 'iframe',
          'supportedFormats': ['MP4', 'WebM'],
          'maxQuality': '1080p',
          'autoplay': true,
          'controls': true,
          'allowFullscreen': true,
        };
      case PlatformType.instagram:
        return {
          'embedDomain': 'instagram.com',
          'playerType': 'iframe',
          'supportedFormats': ['MP4'],
          'maxQuality': '720p',
          'autoplay': false,
          'controls': true,
          'allowFullscreen': false,
        };
      case PlatformType.tiktok:
        return {
          'embedDomain': 'tiktok.com',
          'playerType': 'iframe',
          'supportedFormats': ['MP4'],
          'maxQuality': '720p',
          'autoplay': true,
          'controls': false,
          'allowFullscreen': true,
        };
      case PlatformType.facebook:
        return {
          'embedDomain': 'facebook.com',
          'playerType': 'iframe',
          'supportedFormats': ['MP4'],
          'maxQuality': '1080p',
          'autoplay': false,
          'controls': true,
          'allowFullscreen': true,
        };
    }
  }
}

// Result class for platform player operations
class PlatformPlayerResult {
  final bool success;
  final String? playerId;
  final PlatformType platform;
  final String? embedUrl;
  final String? externalUrl;
  final String? fallbackUrl;
  final String? errorMessage;
  
  const PlatformPlayerResult({
    required this.success,
    this.playerId,
    required this.platform,
    this.embedUrl,
    this.externalUrl,
    this.fallbackUrl,
    this.errorMessage,
  });
  
  bool get isEmbedded => embedUrl != null;
  bool get isExternal => externalUrl != null;
  bool get hasFallback => fallbackUrl != null;
}

// Platform thumbnail quality options
enum PlatformThumbnailQuality {
  low,
  medium,
  high,
  maxres,
}