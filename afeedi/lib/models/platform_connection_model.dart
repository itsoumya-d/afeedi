import 'content_model.dart';

class PlatformConnection {
  final String id;
  final String userId;
  final PlatformType platform;
  final String platformUserId;
  final String? platformUsername;
  final String? accessToken;
  final String? refreshToken;
  final DateTime? tokenExpiresAt;
  final List<String> scopes;
  final bool isActive;
  final DateTime? lastSyncAt;
  final String? syncError;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PlatformConnection({
    required this.id,
    required this.userId,
    required this.platform,
    required this.platformUserId,
    this.platformUsername,
    this.accessToken,
    this.refreshToken,
    this.tokenExpiresAt,
    this.scopes = const [],
    this.isActive = true,
    this.lastSyncAt,
    this.syncError,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PlatformConnection.fromJson(Map<String, dynamic> json) {
    return PlatformConnection(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      platform: PlatformType.values.firstWhere(
        (e) => e.name == json['platform'],
        orElse: () => PlatformType.youtube,
      ),
      platformUserId: json['platform_user_id'] as String,
      platformUsername: json['platform_username'] as String?,
      accessToken: json['access_token'] as String?,
      refreshToken: json['refresh_token'] as String?,
      tokenExpiresAt: json['token_expires_at'] != null
          ? DateTime.parse(json['token_expires_at'] as String)
          : null,
      scopes: List<String>.from(json['scopes'] ?? []),
      isActive: json['is_active'] as bool? ?? true,
      lastSyncAt: json['last_sync_at'] != null
          ? DateTime.parse(json['last_sync_at'] as String)
          : null,
      syncError: json['sync_error'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'platform': platform.name,
      'platform_user_id': platformUserId,
      'platform_username': platformUsername,
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'token_expires_at': tokenExpiresAt?.toIso8601String(),
      'scopes': scopes,
      'is_active': isActive,
      'last_sync_at': lastSyncAt?.toIso8601String(),
      'sync_error': syncError,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  PlatformConnection copyWith({
    String? id,
    String? userId,
    PlatformType? platform,
    String? platformUserId,
    String? platformUsername,
    String? accessToken,
    String? refreshToken,
    DateTime? tokenExpiresAt,
    List<String>? scopes,
    bool? isActive,
    DateTime? lastSyncAt,
    String? syncError,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlatformConnection(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      platform: platform ?? this.platform,
      platformUserId: platformUserId ?? this.platformUserId,
      platformUsername: platformUsername ?? this.platformUsername,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      tokenExpiresAt: tokenExpiresAt ?? this.tokenExpiresAt,
      scopes: scopes ?? this.scopes,
      isActive: isActive ?? this.isActive,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      syncError: syncError ?? this.syncError,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isTokenExpired {
    if (tokenExpiresAt == null) return false;
    return tokenExpiresAt!.isBefore(DateTime.now());
  }

  bool get needsRefresh {
    if (tokenExpiresAt == null) return false;
    // Refresh if token expires within the next hour
    return tokenExpiresAt!.isBefore(
      DateTime.now().add(const Duration(hours: 1)),
    );
  }

  bool get hasError => syncError != null && syncError!.isNotEmpty;

  bool get isConnected => isActive && !isTokenExpired;

  String get platformDisplayName {
    switch (platform) {
      case PlatformType.youtube:
        return 'YouTube';
      case PlatformType.instagram:
        return 'Instagram';
      case PlatformType.tiktok:
        return 'TikTok';
      case PlatformType.facebook:
        return 'Facebook';
    }
  }

  String get connectionStatus {
    if (!isActive) return 'Disconnected';
    if (isTokenExpired) return 'Token Expired';
    if (hasError) return 'Error';
    return 'Connected';
  }

  Duration? get timeSinceLastSync {
    if (lastSyncAt == null) return null;
    return DateTime.now().difference(lastSyncAt!);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlatformConnection && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PlatformConnection(id: $id, platform: $platform, userId: $userId, isActive: $isActive)';
  }
}

class OAuthCredentials {
  final String accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;
  final List<String> scopes;
  final Map<String, dynamic> additionalData;

  const OAuthCredentials({
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
    this.scopes = const [],
    this.additionalData = const {},
  });

  factory OAuthCredentials.fromJson(Map<String, dynamic> json) {
    return OAuthCredentials(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String?,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      scopes: List<String>.from(json['scopes'] ?? []),
      additionalData: Map<String, dynamic>.from(json['additional_data'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_at': expiresAt?.toIso8601String(),
      'scopes': scopes,
      'additional_data': additionalData,
    };
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return expiresAt!.isBefore(DateTime.now());
  }

  bool get needsRefresh {
    if (expiresAt == null) return false;
    // Refresh if token expires within the next 10 minutes
    return expiresAt!.isBefore(DateTime.now().add(const Duration(minutes: 10)));
  }

  @override
  String toString() {
    return 'OAuthCredentials(hasToken: ${accessToken.isNotEmpty}, hasRefresh: ${refreshToken != null}, expiresAt: $expiresAt)';
  }
}

class PlatformUserInfo {
  final String platformUserId;
  final String? username;
  final String? displayName;
  final String? email;
  final String? avatarUrl;
  final String? profileUrl;
  final Map<String, dynamic> additionalInfo;

  const PlatformUserInfo({
    required this.platformUserId,
    this.username,
    this.displayName,
    this.email,
    this.avatarUrl,
    this.profileUrl,
    this.additionalInfo = const {},
  });

  factory PlatformUserInfo.fromJson(Map<String, dynamic> json) {
    return PlatformUserInfo(
      platformUserId: json['platform_user_id'] as String,
      username: json['username'] as String?,
      displayName: json['display_name'] as String?,
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      profileUrl: json['profile_url'] as String?,
      additionalInfo: Map<String, dynamic>.from(json['additional_info'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'platform_user_id': platformUserId,
      'username': username,
      'display_name': displayName,
      'email': email,
      'avatar_url': avatarUrl,
      'profile_url': profileUrl,
      'additional_info': additionalInfo,
    };
  }

  @override
  String toString() {
    return 'PlatformUserInfo(id: $platformUserId, username: $username, displayName: $displayName)';
  }
}

class SyncResult {
  final bool success;
  final String? error;
  final int? itemsProcessed;
  final int? itemsAdded;
  final int? itemsUpdated;
  final int? itemsSkipped;
  final DateTime syncedAt;
  final Duration syncDuration;

  const SyncResult({
    required this.success,
    this.error,
    this.itemsProcessed,
    this.itemsAdded,
    this.itemsUpdated,
    this.itemsSkipped,
    required this.syncedAt,
    required this.syncDuration,
  });

  factory SyncResult.success({
    int? itemsProcessed,
    int? itemsAdded,
    int? itemsUpdated,
    int? itemsSkipped,
    required DateTime syncedAt,
    required Duration syncDuration,
  }) {
    return SyncResult(
      success: true,
      itemsProcessed: itemsProcessed,
      itemsAdded: itemsAdded,
      itemsUpdated: itemsUpdated,
      itemsSkipped: itemsSkipped,
      syncedAt: syncedAt,
      syncDuration: syncDuration,
    );
  }

  factory SyncResult.failure({
    required String error,
    required DateTime syncedAt,
    required Duration syncDuration,
  }) {
    return SyncResult(
      success: false,
      error: error,
      syncedAt: syncedAt,
      syncDuration: syncDuration,
    );
  }

  factory SyncResult.fromJson(Map<String, dynamic> json) {
    return SyncResult(
      success: json['success'] as bool,
      error: json['error'] as String?,
      itemsProcessed: json['items_processed'] as int?,
      itemsAdded: json['items_added'] as int?,
      itemsUpdated: json['items_updated'] as int?,
      itemsSkipped: json['items_skipped'] as int?,
      syncedAt: DateTime.parse(json['synced_at'] as String),
      syncDuration: Duration(milliseconds: json['sync_duration_ms'] as int),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'error': error,
      'items_processed': itemsProcessed,
      'items_added': itemsAdded,
      'items_updated': itemsUpdated,
      'items_skipped': itemsSkipped,
      'synced_at': syncedAt.toIso8601String(),
      'sync_duration_ms': syncDuration.inMilliseconds,
    };
  }

  String get summary {
    if (!success) {
      return 'Sync failed: $error';
    }

    final parts = <String>[];
    if (itemsProcessed != null) parts.add('$itemsProcessed processed');
    if (itemsAdded != null && itemsAdded! > 0) parts.add('$itemsAdded added');
    if (itemsUpdated != null && itemsUpdated! > 0)
      parts.add('$itemsUpdated updated');
    if (itemsSkipped != null && itemsSkipped! > 0)
      parts.add('$itemsSkipped skipped');

    return 'Sync completed: ${parts.join(', ')}';
  }

  @override
  String toString() {
    return 'SyncResult(success: $success, ${success ? summary : error})';
  }
}
