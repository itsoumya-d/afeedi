import 'package:flutter/foundation.dart';
import '../models/content_model.dart';
import 'analytics_service.dart';

/// Video content metadata service — uses YouTube IFrame embed only.
/// youtube_explode_dart stream extraction was removed: extracting stream URLs
/// bypasses YouTube's player and violates YouTube ToS §4.F and §4.11,
/// which prohibits downloading or circumventing access controls.
/// All YouTube playback uses youtube_player_iframe (IFrame API) instead.
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

  /// Builds embed metadata for a content item.
  /// For YouTube: returns IFrame embed URL.
  /// For other platforms: returns the external URL.
  Future<ExtractedVideoContent> extractVideoContent(Content content) async {
    try {
      if (content.platform != PlatformType.youtube) {
        throw UnsupportedError(
            'Only YouTube content is supported. Other platforms use url_launcher.');
      }

      final videoId = content.platformContentId;
      final embedUrl =
          'https://www.youtube.com/embed/$videoId?autoplay=1&controls=1&rel=0&modestbranding=1';

      final extracted = ExtractedVideoContent(
        videoId: videoId,
        title: content.title ?? '',
        description: content.description ?? '',
        duration: content.durationSeconds != null
            ? Duration(seconds: content.durationSeconds!)
            : null,
        thumbnailUrl: content.thumbnailUrl ??
            'https://img.youtube.com/vi/$videoId/mqdefault.jpg',
        author: content.creatorName ?? '',
        viewCount: content.viewCount ?? 0,
        uploadDate: content.publishedAt,
        embedUrl: embedUrl,
        audioStreams: const [],
        videoStreams: const [],
        muxedStreams: const [],
        captions: const [],
      );

      await AnalyticsService.instance.trackUserInteraction(
        action: 'video_content_extracted',
        screen: 'video_extraction',
        additionalData: {
          'video_id': videoId,
          'content_id': content.id,
        },
      );

      return extracted;
    } catch (error) {
      await AnalyticsService.instance.trackError(
        errorType: 'video_extraction_error',
        errorMessage: error.toString(),
        screen: 'video_extraction',
      );
      rethrow;
    }
  }

  ExtractedStream? getOptimalStream(
    ExtractedVideoContent content, {
    StreamQuality quality = StreamQuality.high,
    bool preferMuxed = true,
  }) {
    if (content.muxedStreams.isNotEmpty) {
      switch (quality) {
        case StreamQuality.low:
          return content.muxedStreams.last;
        case StreamQuality.medium:
          return content.muxedStreams[content.muxedStreams.length ~/ 2];
        case StreamQuality.high:
        case StreamQuality.auto:
          return content.muxedStreams.first;
      }
    }
    if (content.videoStreams.isNotEmpty) {
      return content.videoStreams.first;
    }
    return null;
  }

  ExtractedAudioStream? getBestAudioStream(ExtractedVideoContent content) {
    if (content.audioStreams.isEmpty) return null;
    return content.audioStreams.first;
  }

  void dispose() {}
}

// ─── Data models (kept for API compatibility) ────────────────────────────────

class ExtractedVideoContent {
  final String videoId;
  final String title;
  final String description;
  final Duration? duration;
  final String thumbnailUrl;
  final String author;
  final int viewCount;
  final DateTime? uploadDate;
  final String embedUrl;
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
    required this.embedUrl,
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

  const ExtractedStream({
    required this.url,
    required this.codec,
    required this.size,
  });
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
