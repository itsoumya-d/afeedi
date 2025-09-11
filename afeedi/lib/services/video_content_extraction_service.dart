import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/content_model.dart';
import 'analytics_service.dart';

class VideoContentExtractionService {
  static VideoContentExtractionService? _instance;
  static VideoContentExtractionService get instance => _instance ??= VideoContentExtractionService._();
  
  VideoContentExtractionService._();
  
  late final YoutubeExplode _youtubeExplode;
  
  // Initialize the service
  Future<void> initialize() async {
    try {
      _youtubeExplode = YoutubeExplode();
      
      await AnalyticsService.instance.trackUserInteraction(
        action: 'video_extraction_service_initialized',
        screen: 'video_extraction',
        additionalData: {
          'platform': kIsWeb ? 'web' : 'mobile',
        },
      );
    } catch (error) {
      await AnalyticsService.instance.trackError(
        errorType: 'video_extraction_initialization_error',
        errorMessage: error.toString(),
        screen: 'video_extraction',
      );
      rethrow;
    }
  }
  
  // Extract video metadata and stream URLs
  Future<ExtractedVideoContent> extractVideoContent(Content content) async {
    try {
      if (content.platform != PlatformType.youtube) {
        throw UnsupportedError('Only YouTube content extraction is currently supported');
      }
      
      final videoId = content.platformContentId;
      
      // Get video metadata
      final video = await _youtubeExplode.videos.get(videoId);
      
      // Get video streams
      final streamManifest = await _youtubeExplode.videos.streamsClient.getManifest(videoId);
      
      // Get audio-only streams
      final audioStreams = streamManifest.audioOnly
          .where((stream) => stream.codec.mimeType.contains('mp4'))
          .toList()
        ..sort((a, b) => b.bitrate.bitsPerSecond.compareTo(a.bitrate.bitsPerSecond));
      
      // Get video-only streams
      final videoStreams = streamManifest.videoOnly
          .where((stream) => stream.codec.mimeType.contains('mp4'))
          .toList()
        ..sort((a, b) => b.videoResolution.height.compareTo(a.videoResolution.height));
      
      // Get muxed streams (video + audio)
      final muxedStreams = streamManifest.muxed
          .where((stream) => stream.codec.mimeType.contains('mp4'))
          .toList()
        ..sort((a, b) => b.videoResolution.height.compareTo(a.videoResolution.height));
      
      // Get captions if available
      final captionManifest = await _youtubeExplode.videos.closedCaptions.getManifest(videoId);
      final captions = captionManifest.tracks
          .map((track) => ExtractedCaption(
                language: track.language.name,
                languageCode: track.language.code,
                url: track.url.toString(),
              ))
          .toList();
      
      final extractedContent = ExtractedVideoContent(
        videoId: videoId,
        title: video.title,
        description: video.description,
        duration: video.duration,
        thumbnailUrl: video.thumbnails.highResUrl,
        author: video.author,
        viewCount: video.engagement.viewCount,
        uploadDate: video.uploadDate,
        audioStreams: audioStreams.map((stream) => ExtractedAudioStream(
          url: stream.url.toString(),
          bitrate: stream.bitrate.bitsPerSecond,
          codec: stream.codec.toString(),
          size: stream.size.totalBytes,
        )).toList(),
        videoStreams: videoStreams.map((stream) => ExtractedVideoStream(
          url: stream.url.toString(),
          quality: stream.videoQuality.toString(),
          resolution: '${stream.videoResolution.width}x${stream.videoResolution.height}',
          fps: stream.framerate.framesPerSecond.toInt(),
          codec: stream.codec.toString(),
          size: stream.size.totalBytes,
        )).toList(),
        muxedStreams: muxedStreams.map((stream) => ExtractedMuxedStream(
          url: stream.url.toString(),
          quality: stream.videoQuality.toString(),
          resolution: '${stream.videoResolution.width}x${stream.videoResolution.height}',
          codec: stream.codec.toString(),
          size: stream.size.totalBytes,
        )).toList(),
        captions: captions,
      );
      
      await AnalyticsService.instance.trackUserInteraction(
        action: 'video_content_extracted',
        screen: 'video_extraction',
        additionalData: {
          'video_id': videoId,
          'content_id': content.id,
          'duration_seconds': video.duration?.inSeconds,
          'audio_streams_count': audioStreams.length,
          'video_streams_count': videoStreams.length,
          'muxed_streams_count': muxedStreams.length,
          'captions_count': captions.length,
        },
      );
      
      return extractedContent;
    } catch (error) {
      await AnalyticsService.instance.trackError(
        errorType: 'video_extraction_error',
        errorMessage: error.toString(),
        screen: 'video_extraction',
      );
      rethrow;
    }
  }
  
  // Get optimal stream based on quality preference and device capabilities
  ExtractedStream? getOptimalStream(ExtractedVideoContent content, {
    StreamQuality quality = StreamQuality.high,
    bool preferMuxed = true,
  }) {
    try {
      // Prefer muxed streams for simplicity (video + audio in one stream)
      if (preferMuxed && content.muxedStreams.isNotEmpty) {
        switch (quality) {
          case StreamQuality.low:
            return content.muxedStreams.last; // Lowest quality
          case StreamQuality.medium:
            final midIndex = content.muxedStreams.length ~/ 2;
            return content.muxedStreams[midIndex];
          case StreamQuality.high:
            return content.muxedStreams.first; // Highest quality
          case StreamQuality.auto:
            // Return medium quality for auto
            final midIndex = content.muxedStreams.length ~/ 2;
            return content.muxedStreams[midIndex];
        }
      }
      
      // Fallback to video-only streams
      if (content.videoStreams.isNotEmpty) {
        switch (quality) {
          case StreamQuality.low:
            return content.videoStreams.last;
          case StreamQuality.medium:
            final midIndex = content.videoStreams.length ~/ 2;
            return content.videoStreams[midIndex];
          case StreamQuality.high:
            return content.videoStreams.first;
          case StreamQuality.auto:
            final midIndex = content.videoStreams.length ~/ 2;
            return content.videoStreams[midIndex];
        }
      }
      
      return null;
    } catch (error) {
      debugPrint('Error getting optimal stream: $error');
      return null;
    }
  }
  
  // Get best audio stream
  ExtractedAudioStream? getBestAudioStream(ExtractedVideoContent content) {
    if (content.audioStreams.isEmpty) return null;
    return content.audioStreams.first; // Highest bitrate
  }
  
  // Dispose resources
  void dispose() {
    _youtubeExplode.close();
  }
}

// Data models for extracted content
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

enum StreamQuality {
  low,
  medium,
  high,
  auto,
}