// COMPLIANCE NOTE: youtube_explode_dart has been removed because it bypasses
// the official YouTube API to extract direct stream URLs, violating YouTube's
// Terms of Service (Section 5.1.H). This causes App Store and Play Store
// rejection. Use the official YouTube IFrame Player API for embedded playback
// and the YouTube Data API v3 (with a valid API key) for metadata.
//
// For mobile: launch videos via url_launcher to the YouTube app/browser.
// For web: use the YouTube IFrame embed API.

import 'package:flutter/foundation.dart';
import '../models/content_model.dart';
import 'analytics_service.dart';

class VideoContentExtractionService {
  static VideoContentExtractionService? _instance;
  static VideoContentExtractionService get instance =>
      _instance ??= VideoContentExtractionService._();

  VideoContentExtractionService._();

  Future<void> initialize() async {
    await AnalyticsService.instance.trackUserInteraction(
      action: 'video_extraction_service_initialized',
      screen: 'video_extraction',
      additionalData: {'platform': kIsWeb ? 'web' : 'mobile'},
    );
  }

  // Stream extraction has been removed to comply with YouTube ToS and
  // App Store / Play Store policies. Videos are opened in the YouTube
  // app or browser via url_launcher instead.
  Future<ExtractedVideoContent> extractVideoContent(Content content) async {
    throw UnsupportedError(
      'Direct stream extraction is not supported. '
      'Use YouTubePlayerService to open videos in the YouTube app.',
    );
  }

  void dispose() {}
}

// Minimal stubs kept for backward compatibility with any remaining imports.
class ExtractedVideoContent {
  final String videoId;
  final String title;
  final String description;
  final Duration? duration;
  final String thumbnailUrl;
  final String author;
  final int viewCount;
  final DateTime? uploadDate;
  final List<ExtractedAudioStream> audioStreams;
  final List<ExtractedVideoStream> videoStreams;
  final List<ExtractedMuxedStream> muxedStreams;
  final List<ExtractedCaption> captions;

  const ExtractedVideoContent({
    required this.videoId,
    required this.title,
    required this.description,
    this.duration,
    required this.thumbnailUrl,
    required this.author,
    required this.viewCount,
    this.uploadDate,
    required this.audioStreams,
    required this.videoStreams,
    required this.muxedStreams,
    required this.captions,
  });
}

abstract class ExtractedStream {
  final String url;
  final String codec;
  final int size;
  const ExtractedStream({required this.url, required this.codec, required this.size});
}

class ExtractedAudioStream extends ExtractedStream {
  final int bitrate;
  const ExtractedAudioStream({
    required super.url,
    required this.bitrate,
    required super.codec,
    required super.size,
  });
}

class ExtractedVideoStream extends ExtractedStream {
  final String quality;
  final String resolution;
  final int fps;
  const ExtractedVideoStream({
    required super.url,
    required this.quality,
    required this.resolution,
    required this.fps,
    required super.codec,
    required super.size,
  });
}

class ExtractedMuxedStream extends ExtractedStream {
  final String quality;
  final String resolution;
  const ExtractedMuxedStream({
    required super.url,
    required this.quality,
    required this.resolution,
    required super.codec,
    required super.size,
  });
}

class ExtractedCaption {
  final String language;
  final String languageCode;
  final String url;
  const ExtractedCaption({
    required this.language,
    required this.languageCode,
    required this.url,
  });
}

enum StreamQuality { low, medium, high, auto }
