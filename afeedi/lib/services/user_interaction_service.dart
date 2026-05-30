import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists likes, saves, follows in SharedPreferences.
/// Key schema:
///   `liked_<contentId>`        -> bool
///   `saved_<contentId>`        -> bool
///   `followed_<creatorId>`     -> bool
///   `interaction_counts`       -> JSON map of contentId -> {likeCount, saveCount, shareCount}
class UserInteractionService {
  UserInteractionService._();

  static final UserInteractionService _instance = UserInteractionService._();
  static UserInteractionService get instance => _instance;

  SharedPreferences? _prefs;

  // In-memory caches for fast reads
  final Map<String, bool> _likeCache = {};
  final Map<String, bool> _saveCache = {};
  final Map<String, bool> _followCache = {};
  Map<String, Map<String, int>> _countsCache = {};
  final Set<String> _notInterestedCache = {};

  // Change notification stream
  final StreamController<void> _changeController =
      StreamController<void>.broadcast();
  Stream<void> get onChanged => _changeController.stream;

  // -------------------------------------------------------------------------
  // Initialization
  // -------------------------------------------------------------------------

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadCaches();
  }

  void _loadCaches() {
    final prefs = _prefs;
    if (prefs == null) return;

    // Clear in-memory caches before reloading so stale values don't persist
    _likeCache.clear();
    _saveCache.clear();
    _followCache.clear();
    _countsCache.clear();
    _notInterestedCache.clear();

    // Load liked / saved / followed / not-interested from all stored keys
    for (final key in prefs.getKeys()) {
      if (key.startsWith('liked_')) {
        _likeCache[key.substring(6)] = prefs.getBool(key) ?? false;
      } else if (key.startsWith('saved_')) {
        _saveCache[key.substring(6)] = prefs.getBool(key) ?? false;
      } else if (key.startsWith('followed_')) {
        _followCache[key.substring(9)] = prefs.getBool(key) ?? false;
      } else if (key.startsWith('notinterested_')) {
        if (prefs.getBool(key) == true) {
          _notInterestedCache.add(key.substring(14));
        }
      }
    }

    // Load counts map
    final countsJson = prefs.getString('interaction_counts');
    if (countsJson != null) {
      try {
        final decoded = jsonDecode(countsJson) as Map<String, dynamic>;
        _countsCache = decoded.map((id, v) {
          final counts = v as Map<String, dynamic>;
          return MapEntry(id, {
            'likeCount': (counts['likeCount'] as int?) ?? 0,
            'saveCount': (counts['saveCount'] as int?) ?? 0,
            'shareCount': (counts['shareCount'] as int?) ?? 0,
          });
        });
      } catch (_) {
        _countsCache = {};
      }
    }
  }

  Future<void> _persistCounts() async {
    final encoded = jsonEncode(_countsCache);
    await _prefs?.setString('interaction_counts', encoded);
  }

  void _notify() {
    if (!_changeController.isClosed) {
      _changeController.add(null);
    }
  }

  // -------------------------------------------------------------------------
  // Read helpers
  // -------------------------------------------------------------------------

  bool isLiked(String contentId) => _likeCache[contentId] ?? false;

  bool isSaved(String contentId) => _saveCache[contentId] ?? false;

  bool isNotInterested(String contentId) => _notInterestedCache.contains(contentId);

  List<String> getNotInterestedIds() => _notInterestedCache.toList();

  Future<void> markNotInterested(String contentId) async {
    _notInterestedCache.add(contentId);
    await _prefs?.setBool('notinterested_$contentId', true);
    _notify();
  }

  /// Returns true when the free save limit (20 items) has been reached.
  bool hasReachedSaveLimit({int limit = 20}) {
    return _saveCache.values.where((v) => v).length >= limit;
  }

  bool isFollowed(String creatorId) => _followCache[creatorId] ?? false;

  int getLikeCount(String contentId, {int baseCount = 0}) {
    final delta = (_countsCache[contentId]?['likeCount'] ?? 0);
    return baseCount + delta;
  }

  List<String> getSavedContentIds() =>
      _saveCache.entries.where((e) => e.value).map((e) => e.key).toList();

  List<String> getLikedContentIds() =>
      _likeCache.entries.where((e) => e.value).map((e) => e.key).toList();

  List<String> getFollowedCreatorIds() =>
      _followCache.entries.where((e) => e.value).map((e) => e.key).toList();

  // -------------------------------------------------------------------------
  // Toggle / track helpers
  // -------------------------------------------------------------------------

  Future<bool> toggleLike(String contentId, {int baseCount = 0}) async {
    final current = isLiked(contentId);
    final next = !current;
    _likeCache[contentId] = next;
    await _prefs?.setBool('liked_$contentId', next);

    // Adjust local delta so displayed count tracks the toggle
    final counts = _countsCache.putIfAbsent(contentId, () => {
      'likeCount': 0,
      'saveCount': 0,
      'shareCount': 0,
    });
    counts['likeCount'] = (counts['likeCount'] ?? 0) + (next ? 1 : -1);
    await _persistCounts();

    _notify();
    return next;
  }

  Future<bool> toggleSave(String contentId) async {
    final current = isSaved(contentId);
    final next = !current;
    _saveCache[contentId] = next;
    await _prefs?.setBool('saved_$contentId', next);

    final counts = _countsCache.putIfAbsent(contentId, () => {
      'likeCount': 0,
      'saveCount': 0,
      'shareCount': 0,
    });
    counts['saveCount'] = (counts['saveCount'] ?? 0) + (next ? 1 : -1);
    await _persistCounts();

    _notify();
    return next;
  }

  Future<bool> toggleFollow(String creatorId) async {
    final current = isFollowed(creatorId);
    final next = !current;
    _followCache[creatorId] = next;
    await _prefs?.setBool('followed_$creatorId', next);

    _notify();
    return next;
  }

  Future<void> trackShare(String contentId) async {
    final counts = _countsCache.putIfAbsent(contentId, () => {
      'likeCount': 0,
      'saveCount': 0,
      'shareCount': 0,
    });
    counts['shareCount'] = (counts['shareCount'] ?? 0) + 1;
    await _persistCounts();

    _notify();
  }

  // -------------------------------------------------------------------------
  // Disposal
  // -------------------------------------------------------------------------

  void dispose() {
    _changeController.close();
  }
}
