import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'dart:html' as html;
import '../models/content_model.dart';
import 'analytics_service.dart';

// Conditional import for web
import '../src/stubs/ui_web.dart' if (dart.library.html) 'dart:ui_web' as ui_web;

class YouTubePlayerService {
  static YouTubePlayerService? _instance;
  static YouTubePlayerService get instance => _instance ??= YouTubePlayerService._();
  
  YouTubePlayerService._();
  
  // Create YouTube player with fallback to external app
  Future<YouTubePlayerResult> createPlayer({
    required Content content,
    required String containerId,
    bool autoplay = false,
    bool showControls = true,
  }) async {
    try {
      if (content.platform != PlatformType.youtube) {
        throw Exception('Content is not from YouTube platform');
      }
      
      final videoId = content.platformContentId;
      
      if (kIsWeb) {
        return await _createWebPlayer(
          videoId: videoId,
          containerId: containerId,
          autoplay: autoplay,
          showControls: showControls,
          content: content,
        );
      } else {
        return await _createMobilePlayer(
          videoId: videoId,
          content: content,
        );
      }
    } catch (error) {
      await AnalyticsService.instance.trackError(
        errorType: 'youtube_player_creation_error',
        errorMessage: error.toString(),
        screen: 'video_player',
      );
      
      // Fallback to external YouTube
      return YouTubePlayerResult(
        success: false,
        playerId: null,
        fallbackUrl: 'https://www.youtube.com/watch?v=${content.platformContentId}',
        errorMessage: error.toString(),
      );
    }
  }
  
  Future<YouTubePlayerResult> _createWebPlayer({
    required String videoId,
    required String containerId,
    required bool autoplay,
    required bool showControls,
    required Content content,
  }) async {
    try {
      final embedUrl = _buildEmbedUrl(
        videoId: videoId,
        autoplay: autoplay,
        showControls: showControls,
      );

      // Create iframe element for YouTube embed
      // TODO: Implement proper iframe creation for web platform
      
      // Note: View factory registration is now handled by UniversalPlatformPlayer
      // to avoid conflicts with multiple registrations
      
      // Track successful player creation
      await AnalyticsService.instance.trackUserInteraction(
        action: 'youtube_player_created',
        screen: 'video_player',
        additionalData: {
          'video_id': videoId,
          'content_id': content.id,
          'autoplay': autoplay,
          'embed_mode': 'iframe',
        },
      );
      
      return YouTubePlayerResult(
        success: true,
        playerId: containerId,
        embedUrl: embedUrl,
      );
    } catch (error) {
      return YouTubePlayerResult(
        success: false,
        playerId: null,
        fallbackUrl: 'https://www.youtube.com/watch?v=$videoId',
        errorMessage: error.toString(),
      );
    }
  }
  
  Future<YouTubePlayerResult> _createMobilePlayer({
    required String videoId,
    required Content content,
  }) async {
    try {
      // For mobile, we'll use URL launcher to open YouTube app or browser
      final youtubeUrl = 'https://www.youtube.com/watch?v=$videoId';
      final youtubeAppUrl = 'youtube://watch?v=$videoId';
      
      // Try YouTube app first, fallback to browser
      bool launched = false;
      
      try {
        if (await canLaunchUrl(Uri.parse(youtubeAppUrl))) {
          launched = await launchUrl(
            Uri.parse(youtubeAppUrl),
            mode: LaunchMode.externalApplication,
          );
        }
      } catch (e) {
        // YouTube app not available, continue to browser fallback
      }
      
      if (!launched) {
        launched = await launchUrl(
          Uri.parse(youtubeUrl),
          mode: LaunchMode.externalApplication,
        );
      }
      
      if (launched) {
        await AnalyticsService.instance.trackUserInteraction(
          action: 'youtube_external_launch',
          screen: 'video_player',
          additionalData: {
            'video_id': videoId,
            'content_id': content.id,
            'launch_mode': 'external_app',
          },
        );
        
        return YouTubePlayerResult(
          success: true,
          playerId: 'external',
          externalUrl: youtubeUrl,
        );
      } else {
        throw Exception('Failed to launch YouTube');
      }
    } catch (error) {
      return YouTubePlayerResult(
        success: false,
        playerId: null,
        fallbackUrl: 'https://www.youtube.com/watch?v=$videoId',
        errorMessage: error.toString(),
      );
    }
  }
  
  String _buildEmbedUrl({
    required String videoId,
    bool autoplay = false,
    bool showControls = true,
    Map<String, String>? additionalParams,
  }) {
    final params = {
      'autoplay': autoplay ? '1' : '0',
      'controls': showControls ? '1' : '0',
      'modestbranding': '1',
      'rel': '0',
      'showinfo': '0',
      'iv_load_policy': '3',
      'enablejsapi': '1',
      'origin': 'https://localhost',
      ...?additionalParams,
    };
    
    final queryString = params.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    
    return 'https://www.youtube.com/embed/$videoId?$queryString';
  }
  
  // Open YouTube video externally
  Future<bool> openInYouTube(Content content) async {
    try {
      if (content.platform != PlatformType.youtube) {
        return false;
      }
      
      final videoId = content.platformContentId;
      final youtubeUrl = 'https://www.youtube.com/watch?v=$videoId';
      
      final launched = await launchUrl(
        Uri.parse(youtubeUrl),
        mode: LaunchMode.externalApplication,
      );
      
      if (launched) {
        await AnalyticsService.instance.trackUserInteraction(
          action: 'youtube_external_open',
          screen: 'video_player',
          additionalData: {
            'video_id': videoId,
            'content_id': content.id,
          },
        );
      }
      
      return launched;
    } catch (error) {
      await AnalyticsService.instance.trackError(
        errorType: 'youtube_external_open_error',
        errorMessage: error.toString(),
        screen: 'video_player',
      );
      return false;
    }
  }
  
  // Check if YouTube embed is supported
  bool isEmbedSupported() {
    if (kIsWeb) {
      // Assume iframe support on web
      return true;
    }
    return true; // Mobile always supports external launch
  }
  
  // Get video thumbnail URL
  String getThumbnailUrl(String videoId, {YouTubeThumbnailQuality quality = YouTubeThumbnailQuality.high}) {
    switch (quality) {
      case YouTubeThumbnailQuality.default_:
        return 'https://img.youtube.com/vi/$videoId/default.jpg';
      case YouTubeThumbnailQuality.medium:
        return 'https://img.youtube.com/vi/$videoId/mqdefault.jpg';
      case YouTubeThumbnailQuality.high:
        return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
      case YouTubeThumbnailQuality.standard:
        return 'https://img.youtube.com/vi/$videoId/sddefault.jpg';
      case YouTubeThumbnailQuality.maxres:
        return 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
    }
  }
}

// Result class for YouTube player operations
class YouTubePlayerResult {
  final bool success;
  final String? playerId;
  final String? embedUrl;
  final String? externalUrl;
  final String? fallbackUrl;
  final String? errorMessage;
  
  const YouTubePlayerResult({
    required this.success,
    this.playerId,
    this.embedUrl,
    this.externalUrl,
    this.fallbackUrl,
    this.errorMessage,
  });
  
  bool get isEmbedded => embedUrl != null;
  bool get isExternal => externalUrl != null;
  bool get hasFallback => fallbackUrl != null;
}

// YouTube thumbnail quality options
enum YouTubeThumbnailQuality {
  default_,
  medium,
  high,
  standard,
  maxres,
}