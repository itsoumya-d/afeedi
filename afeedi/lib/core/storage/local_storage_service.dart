import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';
import '../../models/content_model.dart';
import '../../models/platform_connection_model.dart';

/// Local storage service to replace Supabase functionality
class LocalStorageService {
  static const String _userBox = 'users';
  static const String _contentBox = 'content';
  static const String _scheduledContentBox = 'scheduled_content';
  static const String _userPreferencesBox = 'user_preferences';
  static const String _platformConnectionsBox = 'platform_connections';
  static const String _recommendationsBox = 'recommendations';
  static const String _analyticsBox = 'analytics';
  static const String _contentInteractionsBox = 'content_interactions';
  static const String _contentCacheBox = 'content_cache';

  static LocalStorageService? _instance;
  static LocalStorageService get instance => _instance ??= LocalStorageService._();
  
  LocalStorageService._();

  late Box<Map> _userBoxInstance;
  late Box<Map> _contentBoxInstance;
  late Box<Map> _scheduledContentBoxInstance;
  late Box<Map> _userPreferencesBoxInstance;
  late Box<Map> _platformConnectionsBoxInstance;
  late Box<Map> _recommendationsBoxInstance;
  late Box<Map> _analyticsBoxInstance;
  late Box<Map> _contentInteractionsBoxInstance;
  late Box<Map> _contentCacheBoxInstance;
  late SharedPreferences _prefs;

  /// Initialize local storage
  Future<void> initialize() async {
    await Hive.initFlutter();
    _prefs = await SharedPreferences.getInstance();
    
    // Open all boxes concurrently
    final boxes = await Future.wait([
      Hive.openBox<Map>(_userBox),
      Hive.openBox<Map>(_contentBox),
      Hive.openBox<Map>(_scheduledContentBox),
      Hive.openBox<Map>(_userPreferencesBox),
      Hive.openBox<Map>(_platformConnectionsBox),
      Hive.openBox<Map>(_recommendationsBox),
      Hive.openBox<Map>(_analyticsBox),
      Hive.openBox<Map>(_contentInteractionsBox),
      Hive.openBox<Map>(_contentCacheBox),
    ]);

    _userBoxInstance = boxes[0];
    _contentBoxInstance = boxes[1];
    _scheduledContentBoxInstance = boxes[2];
    _userPreferencesBoxInstance = boxes[3];
    _platformConnectionsBoxInstance = boxes[4];
    _recommendationsBoxInstance = boxes[5];
    _analyticsBoxInstance = boxes[6];
    _contentInteractionsBoxInstance = boxes[7];
    _contentCacheBoxInstance = boxes[8];
  }

  /// User Management
  Future<void> saveUser(User user) async {
    await _userBoxInstance.put(user.id, user.toJson());
  }

  Future<User?> getUser(String userId) async {
    final userData = _userBoxInstance.get(userId);
    if (userData != null) {
      return User.fromJson(Map<String, dynamic>.from(userData));
    }
    return null;
  }

  Future<void> deleteUser(String userId) async {
    await _userBoxInstance.delete(userId);
  }

  Future<List<User>> getAllUsers() async {
    final users = <User>[];
    for (final userData in _userBoxInstance.values) {
      users.add(User.fromJson(Map<String, dynamic>.from(userData)));
    }
    return users;
  }

  /// User Preferences
  Future<void> saveUserPreferences(UserPreferences preferences) async {
    await _userPreferencesBoxInstance.put(preferences.userId, preferences.toJson());
  }

  Future<UserPreferences?> getUserPreferences(String userId) async {
    final prefsData = _userPreferencesBoxInstance.get(userId);
    if (prefsData != null) {
      return UserPreferences.fromJson(Map<String, dynamic>.from(prefsData));
    }
    return null;
  }

  /// Content Management
  Future<void> saveContent(Content content) async {
    await _contentBoxInstance.put(content.id, content.toJson());
  }

  Future<Content?> getContent(String contentId) async {
    final contentData = _contentBoxInstance.get(contentId);
    if (contentData != null) {
      return Content.fromJson(Map<String, dynamic>.from(contentData));
    }
    return null;
  }

  Future<List<Content>> getAllContent() async {
    final contentList = <Content>[];
    for (final contentData in _contentBoxInstance.values) {
      contentList.add(Content.fromJson(Map<String, dynamic>.from(contentData)));
    }
    return contentList;
  }

  Future<List<Content>> getContentByPlatform(String platform) async {
    final contentList = <Content>[];
    for (final contentData in _contentBoxInstance.values) {
      final content = Content.fromJson(Map<String, dynamic>.from(contentData));
      if (content.platform == platform) {
        contentList.add(content);
      }
    }
    return contentList;
  }

  /// Scheduled Content
  Future<void> saveScheduledContent(Map<String, dynamic> scheduledContent) async {
    await _scheduledContentBoxInstance.put(scheduledContent['id'], scheduledContent);
  }

  Future<Map<String, dynamic>?> getScheduledContent(String scheduledContentId) async {
    final scheduledData = _scheduledContentBoxInstance.get(scheduledContentId);
    if (scheduledData != null) {
      return Map<String, dynamic>.from(scheduledData);
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getScheduledContentForUser(String userId) async {
    final scheduledList = <Map<String, dynamic>>[];
    for (final scheduledData in _scheduledContentBoxInstance.values) {
      final scheduled = Map<String, dynamic>.from(scheduledData);
      if (scheduled['user_id'] == userId) {
        scheduledList.add(scheduled);
      }
    }
    return scheduledList;
  }

  Future<void> deleteScheduledContent(String scheduledContentId) async {
    await _scheduledContentBoxInstance.delete(scheduledContentId);
  }

  /// Platform Connections
  Future<void> savePlatformConnection(PlatformConnection connection) async {
    await _platformConnectionsBoxInstance.put('${connection.userId}_${connection.platform}', connection.toJson());
  }

  Future<List<PlatformConnection>> getPlatformConnections(String userId) async {
    final connections = <PlatformConnection>[];
    for (final connectionData in _platformConnectionsBoxInstance.values) {
      final connection = PlatformConnection.fromJson(Map<String, dynamic>.from(connectionData));
      if (connection.userId == userId) {
        connections.add(connection);
      }
    }
    return connections;
  }

  Future<void> deletePlatformConnection(String userId, String platform) async {
    await _platformConnectionsBoxInstance.delete('${userId}_$platform');
  }

  /// Recommendations
  Future<void> saveRecommendation(Map<String, dynamic> recommendation) async {
    final id = recommendation['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    await _recommendationsBoxInstance.put(id, recommendation);
  }

  Future<List<Map<String, dynamic>>> getRecommendations(String userId) async {
    final recommendations = <Map<String, dynamic>>[];
    for (final recommendationData in _recommendationsBoxInstance.values) {
      final recommendation = Map<String, dynamic>.from(recommendationData);
      if (recommendation['user_id'] == userId) {
        recommendations.add(recommendation);
      }
    }
    return recommendations;
  }

  /// Content Interactions
  Future<void> saveContentInteraction(Map<String, dynamic> interaction) async {
    final id = interaction['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    await _contentInteractionsBoxInstance.put(id, interaction);
  }

  Future<List<Map<String, dynamic>>> getContentInteractions(String userId) async {
    final interactions = <Map<String, dynamic>>[];
    for (final interactionData in _contentInteractionsBoxInstance.values) {
      final interaction = Map<String, dynamic>.from(interactionData);
      if (interaction['user_id'] == userId) {
        interactions.add(interaction);
      }
    }
    return interactions;
  }

  /// Analytics Events
  Future<void> saveAnalyticsEvent(Map<String, dynamic> event) async {
    final id = event['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    await _analyticsBoxInstance.put(id, event);
  }

  Future<List<Map<String, dynamic>>> getAnalyticsEvents(String userId) async {
    final events = <Map<String, dynamic>>[];
    for (final eventData in _analyticsBoxInstance.values) {
      final event = Map<String, dynamic>.from(eventData);
      if (event['user_id'] == userId) {
        events.add(event);
      }
    }
    return events;
  }

  /// Content Cache
  Future<void> saveCachedContent(String key, Map<String, dynamic> content) async {
    await _contentCacheBoxInstance.put(key, content);
  }

  Future<Map<String, dynamic>?> getCachedContent(String key) async {
    final cachedData = _contentCacheBoxInstance.get(key);
    if (cachedData != null) {
      return Map<String, dynamic>.from(cachedData);
    }
    return null;
  }

  Future<void> clearCachedContent() async {
    await _contentCacheBoxInstance.clear();
  }

  /// Authentication State
  Future<void> saveAuthState(String userId, String? sessionToken) async {
    await _prefs.setString('current_user_id', userId);
    if (sessionToken != null) {
      await _prefs.setString('session_token', sessionToken);
    }
  }

  Future<String?> getCurrentUserId() async {
    return _prefs.getString('current_user_id');
  }

  Future<String?> getSessionToken() async {
    return _prefs.getString('session_token');
  }

  Future<void> clearAuthState() async {
    await _prefs.remove('current_user_id');
    await _prefs.remove('session_token');
  }

  /// Utility Methods
  Future<void> clearAllData() async {
    await Future.wait([
      _userBoxInstance.clear(),
      _contentBoxInstance.clear(),
      _scheduledContentBoxInstance.clear(),
      _userPreferencesBoxInstance.clear(),
      _platformConnectionsBoxInstance.clear(),
      _recommendationsBoxInstance.clear(),
      _analyticsBoxInstance.clear(),
      _contentInteractionsBoxInstance.clear(),
      _contentCacheBoxInstance.clear(),
      _prefs.clear(),
    ]);
  }

  /// Export data for backup
  Future<Map<String, dynamic>> exportAllData() async {
    return {
      'users': _userBoxInstance.toMap(),
      'content': _contentBoxInstance.toMap(),
      'scheduled_content': _scheduledContentBoxInstance.toMap(),
      'user_preferences': _userPreferencesBoxInstance.toMap(),
      'platform_connections': _platformConnectionsBoxInstance.toMap(),
      'recommendations': _recommendationsBoxInstance.toMap(),
      'analytics': _analyticsBoxInstance.toMap(),
      'content_interactions': _contentInteractionsBoxInstance.toMap(),
      'content_cache': _contentCacheBoxInstance.toMap(),
    };
  }

  /// Import data from backup
  Future<void> importData(Map<String, dynamic> data) async {
    if (data['users'] != null) {
      await _userBoxInstance.clear();
      await _userBoxInstance.putAll(Map<String, Map>.from(data['users']));
    }
    if (data['content'] != null) {
      await _contentBoxInstance.clear();
      await _contentBoxInstance.putAll(Map<String, Map>.from(data['content']));
    }
    if (data['scheduled_content'] != null) {
      await _scheduledContentBoxInstance.clear();
      await _scheduledContentBoxInstance.putAll(Map<String, Map>.from(data['scheduled_content']));
    }
    if (data['user_preferences'] != null) {
      await _userPreferencesBoxInstance.clear();
      await _userPreferencesBoxInstance.putAll(Map<String, Map>.from(data['user_preferences']));
    }
    if (data['platform_connections'] != null) {
      await _platformConnectionsBoxInstance.clear();
      await _platformConnectionsBoxInstance.putAll(Map<String, Map>.from(data['platform_connections']));
    }
    if (data['recommendations'] != null) {
      await _recommendationsBoxInstance.clear();
      await _recommendationsBoxInstance.putAll(Map<String, Map>.from(data['recommendations']));
    }
    if (data['analytics'] != null) {
      await _analyticsBoxInstance.clear();
      await _analyticsBoxInstance.putAll(Map<String, Map>.from(data['analytics']));
    }
    if (data['content_interactions'] != null) {
      await _contentInteractionsBoxInstance.clear();
      await _contentInteractionsBoxInstance.putAll(Map<String, Map>.from(data['content_interactions']));
    }
    if (data['content_cache'] != null) {
      await _contentCacheBoxInstance.clear();
      await _contentCacheBoxInstance.putAll(Map<String, Map>.from(data['content_cache']));
    }
  }
}

/// Response wrapper for consistency with previous Supabase implementation
class LocalStorageResponse<T> {
  final T? data;
  final String? error;
  final bool success;

  LocalStorageResponse.success(this.data) : error = null, success = true;
  LocalStorageResponse.error(this.error) : data = null, success = false;
}