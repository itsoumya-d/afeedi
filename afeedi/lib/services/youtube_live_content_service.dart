import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/content_model.dart';

/// Provides YouTube content using seed data only.
/// youtube_explode_dart was removed — scraping YouTube violates YouTube ToS §4.F
/// and Google Play Developer Policy. Use YouTube Data API v3 for live content.
class YouTubeLiveContentService {
  static final YouTubeLiveContentService _instance = YouTubeLiveContentService._internal();
  factory YouTubeLiveContentService() => _instance;
  YouTubeLiveContentService._internal();

  static YouTubeLiveContentService get instance => _instance;

  List<Content> _cachedContent = [];
  bool _initialized = false;

  /// Returns cached content. This is now a no-op stub — ContentService
  /// provides all content via its seed data + optional API backend.
  Future<List<Content>> getContent({bool forceRefresh = false}) async {
    if (!_initialized || forceRefresh) {
      _cachedContent = [];
      _initialized = true;
      if (kDebugMode) {
        debugPrint('YouTubeLiveContentService: using ContentService seed data');
      }
    }
    return _cachedContent;
  }

  /// Search stub — returns empty list. Use ContentService.searchVideos() instead.
  Future<List<Content>> searchLive(String query, {int limit = 15}) async {
    if (kDebugMode) {
      debugPrint('YouTubeLiveContentService.searchLive: delegating to ContentService');
    }
    return [];
  }
}
