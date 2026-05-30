import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/content_model.dart';

/// HTTP client connecting the Flutter app to the local Afeedi Content API.
///
/// Local dev: run `python3 backend/content_server.py` (defaults to :8888).
/// Falls back gracefully when the server is unreachable so the app always works.
class ApiContentService {
  static final ApiContentService _instance = ApiContentService._internal();
  factory ApiContentService() => _instance;
  ApiContentService._internal();

  static ApiContentService get instance => _instance;

  // Local dev base URL — override via environment variable AFEEDI_API_URL
  static String get _baseUrl {
    const envUrl = String.fromEnvironment('AFEEDI_API_URL', defaultValue: '');
    if (envUrl.isNotEmpty) return envUrl.trimRight();
    // Default: loopback for mobile emulator / local dev
    return kIsWeb ? 'http://localhost:8888' : 'http://10.0.2.2:8888';
  }

  static const _timeout = Duration(seconds: 10);
  bool _serverAvailable = false;

  // -------------------------------------------------------------------------
  // Health check — called once at startup to discover if local API is reachable
  // -------------------------------------------------------------------------
  Future<bool> checkHealth() async {
    try {
      final resp = await http
          .get(Uri.parse('$_baseUrl/api/v1/health'))
          .timeout(_timeout);
      _serverAvailable = resp.statusCode == 200;
      if (_serverAvailable) {
        debugPrint('ApiContentService: local API reachable at $_baseUrl');
      }
    } catch (_) {
      _serverAvailable = false;
      debugPrint('ApiContentService: local API unreachable — using fallback');
    }
    return _serverAvailable;
  }

  bool get isAvailable => _serverAvailable;

  // -------------------------------------------------------------------------
  // Feed
  // -------------------------------------------------------------------------
  Future<List<Content>> getFeed({
    int page = 1,
    int limit = 10,
    String? platform,
  }) async {
    if (!_serverAvailable) return [];
    final query = {
      'page': '$page',
      'limit': '$limit',
      if (platform != null) 'platform': platform,
    };
    return _fetchList('/api/v1/content/feed', query);
  }

  // -------------------------------------------------------------------------
  // Trending
  // -------------------------------------------------------------------------
  Future<List<Content>> getTrending({int limit = 10}) async {
    if (!_serverAvailable) return [];
    return _fetchList('/api/v1/content/trending', {'limit': '$limit'});
  }

  // -------------------------------------------------------------------------
  // Search
  // -------------------------------------------------------------------------
  Future<List<Content>> search(String query, {int limit = 10}) async {
    if (!_serverAvailable || query.isEmpty) return [];
    return _fetchList('/api/v1/content/search', {
      'q': query,
      'limit': '$limit',
    });
  }

  // -------------------------------------------------------------------------
  // Single item
  // -------------------------------------------------------------------------
  Future<Content?> getById(String id) async {
    if (!_serverAvailable) return null;
    try {
      final resp = await http
          .get(Uri.parse('$_baseUrl/api/v1/content/$id'))
          .timeout(_timeout);
      if (resp.statusCode == 200) {
        return Content.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('ApiContentService.getById error: $e');
    }
    return null;
  }

  // -------------------------------------------------------------------------
  // Internal helper
  // -------------------------------------------------------------------------
  Future<List<Content>> _fetchList(
    String path,
    Map<String, String> params,
  ) async {
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: params);
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        final resp = await http.get(uri).timeout(_timeout);
        if (resp.statusCode == 200) {
          final json = jsonDecode(resp.body) as Map<String, dynamic>;
          final rawItems = json['items'] as List<dynamic>? ?? [];
          return rawItems
              .map((j) => Content.fromJson(j as Map<String, dynamic>))
              .toList();
        }
        // Non-200: don't retry
        debugPrint('ApiContentService $path → ${resp.statusCode}');
        return [];
      } catch (e) {
        if (attempt < 2) {
          await Future.delayed(Duration(seconds: (attempt + 1) * 2));
        } else {
          debugPrint('ApiContentService $path failed after 3 attempts: $e');
          _serverAvailable = false; // mark unreachable for this session
        }
      }
    }
    return [];
  }
}
