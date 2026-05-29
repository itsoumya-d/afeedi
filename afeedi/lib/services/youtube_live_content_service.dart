import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/content_model.dart';

/// Fetches real YouTube video data using youtube_explode_dart (no API key needed).
/// Results are cached in SharedPreferences with a 30-minute TTL.
class YouTubeLiveContentService {
  static final YouTubeLiveContentService _instance = YouTubeLiveContentService._internal();
  factory YouTubeLiveContentService() => _instance;
  YouTubeLiveContentService._internal();

  static YouTubeLiveContentService get instance => _instance;

  static const _cacheKey = 'yt_live_content_v3';
  static const _cacheTimestampKey = 'yt_live_content_ts_v3';
  static const _cacheTtlMinutes = 30;

  // Topic queries that generate diverse, high-quality content
  static const _searchTopics = [
    'flutter dart mobile development tutorial',
    'machine learning artificial intelligence explained',
    'science nature universe documentary',
    'cooking recipes healthy food',
    'travel adventure vlog destinations',
    'fitness workout exercise home',
    'technology news innovation 2024',
    'music performance artist live',
  ];

  List<Content> _cachedContent = [];
  bool _initialized = false;

  /// Returns cached content if fresh, otherwise fetches new content.
  Future<List<Content>> getContent({bool forceRefresh = false}) async {
    if (!_initialized || forceRefresh) {
      await _loadOrFetch(forceRefresh: forceRefresh);
    }
    return _cachedContent;
  }

  /// Searches YouTube in real time for [query]. Returns up to [limit] results.
  Future<List<Content>> searchLive(String query, {int limit = 15}) async {
    final yt = YoutubeExplode();
    try {
      final videos = await yt.search.getVideos(query);
      final results = <Content>[];
      for (final v in videos.take(limit)) {
        final c = _videoToContent(v, tags: [query.split(' ').first]);
        if (c != null) results.add(c);
      }
      return results;
    } catch (e) {
      debugPrint('YouTubeLiveContentService search error: $e');
      return [];
    } finally {
      yt.close();
    }
  }

  Future<void> _loadOrFetch({bool forceRefresh = false}) async {
    // Try loading from cache first
    if (!forceRefresh && await _loadFromCache()) {
      _initialized = true;
      return;
    }
    // Fetch fresh data from YouTube
    await _fetchAndCache();
    _initialized = true;
  }

  Future<bool> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ts = prefs.getInt(_cacheTimestampKey) ?? 0;
      final age = DateTime.now().millisecondsSinceEpoch - ts;
      if (age > _cacheTtlMinutes * 60 * 1000) return false;

      final raw = prefs.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return false;

      final list = jsonDecode(raw) as List;
      _cachedContent = list
          .map((j) => Content.fromJson(j as Map<String, dynamic>))
          .toList();
      debugPrint('YouTubeLiveContentService: loaded ${_cachedContent.length} items from cache');
      return _cachedContent.isNotEmpty;
    } catch (e) {
      debugPrint('YouTubeLiveContentService cache load error: $e');
      return false;
    }
  }

  Future<void> _fetchAndCache() async {
    final yt = YoutubeExplode();
    final fetched = <Content>[];
    final seenIds = <String>{};

    try {
      for (final topic in _searchTopics) {
        // Retry each topic up to 2 times with exponential backoff
        for (int attempt = 0; attempt < 2; attempt++) {
          try {
            final videos = await yt.search.getVideos(topic);
            int added = 0;
            for (final v in videos) {
              if (added >= 8) break;
              if (seenIds.contains(v.id.value)) continue;
              final tags = topic.split(' ').take(3).toList();
              final c = _videoToContent(v, tags: tags);
              if (c != null) {
                fetched.add(c);
                seenIds.add(v.id.value);
                added++;
              }
            }
            break; // success — skip retry
          } catch (e) {
            if (attempt == 0) {
              await Future.delayed(const Duration(seconds: 2));
            } else {
              debugPrint('YouTubeLiveContentService topic "$topic" failed: $e');
            }
          }
        }
      }
    } finally {
      yt.close();
    }

    if (fetched.isNotEmpty) {
      _cachedContent = fetched;
      await _saveToCache(fetched);
      debugPrint('YouTubeLiveContentService: fetched ${fetched.length} live items');
    } else {
      debugPrint('YouTubeLiveContentService: fetch returned empty, keeping existing cache');
    }
  }

  Future<void> _saveToCache(List<Content> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(items.map((c) => c.toJson()).toList());
      await prefs.setString(_cacheKey, json);
      await prefs.setInt(
          _cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('YouTubeLiveContentService cache save error: $e');
    }
  }

  Content? _videoToContent(Video video, {List<String> tags = const []}) {
    try {
      final id = video.id.value;
      final durationSecs = video.duration?.inSeconds;
      // Classify by duration: <3 min → short, otherwise → video
      final contentType =
          durationSecs != null && durationSecs <= 180 ? ContentType.short : ContentType.video;

      // Prefer the highest-resolution thumbnail available
      final thumb = video.thumbnails.maxResUrl.isNotEmpty
          ? video.thumbnails.maxResUrl
          : 'https://img.youtube.com/vi/$id/mqdefault.jpg';

      return Content(
        id: 'live_$id',
        platform: PlatformType.youtube,
        platformContentId: id,
        contentType: contentType,
        title: video.title.isNotEmpty ? video.title : null,
        description: video.description.isNotEmpty ? video.description : null,
        thumbnailUrl: thumb,
        videoUrl: 'https://www.youtube.com/watch?v=$id',
        embedUrl: 'https://www.youtube.com/embed/$id',
        durationSeconds: durationSecs,
        viewCount: 0,
        likeCount: 0,
        creatorName: video.author,
        creatorId: video.channelId.value,
        tags: tags,
        publishedAt: video.uploadDate,
        createdAt: video.uploadDate ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('YouTubeLiveContentService _videoToContent error: $e');
      return null;
    }
  }
}
