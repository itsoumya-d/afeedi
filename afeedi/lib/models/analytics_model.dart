enum EventType { onboarding, oauth, userInteraction, performance, error }

class AnalyticsEvent {
  final String id;
  final String? userId;
  final String? sessionId;
  final EventType eventType;
  final String eventName;
  final Map<String, dynamic> eventData;
  final String? platform;
  final String? screenName;
  final String? userAgent;
  final String? ipAddress;
  final DateTime createdAt;

  const AnalyticsEvent({
    required this.id,
    this.userId,
    this.sessionId,
    required this.eventType,
    required this.eventName,
    this.eventData = const {},
    this.platform,
    this.screenName,
    this.userAgent,
    this.ipAddress,
    required this.createdAt,
  });

  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) {
    return AnalyticsEvent(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      sessionId: json['session_id'] as String?,
      eventType: EventType.values.firstWhere(
        (e) => e.name == json['event_type'],
        orElse: () => EventType.userInteraction,
      ),
      eventName: json['event_name'] as String,
      eventData: Map<String, dynamic>.from(json['event_data'] ?? {}),
      platform: json['platform'] as String?,
      screenName: json['screen_name'] as String?,
      userAgent: json['user_agent'] as String?,
      ipAddress: json['ip_address'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'session_id': sessionId,
      'event_type': eventType.name,
      'event_name': eventName,
      'event_data': eventData,
      'platform': platform,
      'screen_name': screenName,
      'user_agent': userAgent,
      'ip_address': ipAddress,
      'created_at': createdAt.toIso8601String(),
    };
  }

  AnalyticsEvent copyWith({
    String? id,
    String? userId,
    String? sessionId,
    EventType? eventType,
    String? eventName,
    Map<String, dynamic>? eventData,
    String? platform,
    String? screenName,
    String? userAgent,
    String? ipAddress,
    DateTime? createdAt,
  }) {
    return AnalyticsEvent(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
      eventType: eventType ?? this.eventType,
      eventName: eventName ?? this.eventName,
      eventData: eventData ?? this.eventData,
      platform: platform ?? this.platform,
      screenName: screenName ?? this.screenName,
      userAgent: userAgent ?? this.userAgent,
      ipAddress: ipAddress ?? this.ipAddress,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnalyticsEvent && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'AnalyticsEvent(id: $id, type: $eventType, name: $eventName, userId: $userId)';
  }
}

class UserSession {
  final String id;
  final String? userId;
  final String sessionToken;
  final Map<String, dynamic> deviceInfo;
  final String? ipAddress;
  final String? userAgent;
  final bool isActive;
  final DateTime expiresAt;
  final DateTime createdAt;
  final DateTime lastActivityAt;

  const UserSession({
    required this.id,
    this.userId,
    required this.sessionToken,
    this.deviceInfo = const {},
    this.ipAddress,
    this.userAgent,
    this.isActive = true,
    required this.expiresAt,
    required this.createdAt,
    required this.lastActivityAt,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      sessionToken: json['session_token'] as String,
      deviceInfo: Map<String, dynamic>.from(json['device_info'] ?? {}),
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      lastActivityAt: DateTime.parse(json['last_activity_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'session_token': sessionToken,
      'device_info': deviceInfo,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'is_active': isActive,
      'expires_at': expiresAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'last_activity_at': lastActivityAt.toIso8601String(),
    };
  }

  UserSession copyWith({
    String? id,
    String? userId,
    String? sessionToken,
    Map<String, dynamic>? deviceInfo,
    String? ipAddress,
    String? userAgent,
    bool? isActive,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? lastActivityAt,
  }) {
    return UserSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sessionToken: sessionToken ?? this.sessionToken,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      isActive: isActive ?? this.isActive,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
    );
  }

  bool get isExpired => expiresAt.isBefore(DateTime.now());
  bool get isValid => isActive && !isExpired;

  Duration get sessionDuration => lastActivityAt.difference(createdAt);
  Duration get timeSinceLastActivity =>
      DateTime.now().difference(lastActivityAt);

  String? get deviceType => deviceInfo['type'] as String?;
  String? get deviceModel => deviceInfo['model'] as String?;
  String? get operatingSystem => deviceInfo['os'] as String?;
  String? get appVersion => deviceInfo['app_version'] as String?;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserSession && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UserSession(id: $id, userId: $userId, isActive: $isActive, expiresAt: $expiresAt)';
  }
}

class PerformanceMetric {
  final String id;
  final String? userId;
  final String? sessionId;
  final String metricName;
  final double value;
  final String? unit;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const PerformanceMetric({
    required this.id,
    this.userId,
    this.sessionId,
    required this.metricName,
    required this.value,
    this.unit,
    this.metadata = const {},
    required this.createdAt,
  });

  factory PerformanceMetric.fromJson(Map<String, dynamic> json) {
    return PerformanceMetric(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      sessionId: json['session_id'] as String?,
      metricName: json['metric_name'] as String,
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'session_id': sessionId,
      'metric_name': metricName,
      'value': value,
      'unit': unit,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get formattedValue {
    if (unit == null) return value.toStringAsFixed(2);
    return '${value.toStringAsFixed(2)} $unit';
  }

  @override
  String toString() {
    return 'PerformanceMetric(name: $metricName, value: $formattedValue)';
  }
}

class AnalyticsReport {
  final String id;
  final String reportType;
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, dynamic> data;
  final Map<String, dynamic> summary;
  final DateTime generatedAt;

  const AnalyticsReport({
    required this.id,
    required this.reportType,
    required this.startDate,
    required this.endDate,
    required this.data,
    required this.summary,
    required this.generatedAt,
  });

  factory AnalyticsReport.fromJson(Map<String, dynamic> json) {
    return AnalyticsReport(
      id: json['id'] as String,
      reportType: json['report_type'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      summary: Map<String, dynamic>.from(json['summary'] ?? {}),
      generatedAt: DateTime.parse(json['generated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'report_type': reportType,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'data': data,
      'summary': summary,
      'generated_at': generatedAt.toIso8601String(),
    };
  }

  Duration get reportPeriod => endDate.difference(startDate);

  int? get totalEvents => summary['total_events'] as int?;
  int? get uniqueUsers => summary['unique_users'] as int?;
  double? get averageSessionDuration =>
      summary['average_session_duration'] as double?;
  Map<String, int>? get eventBreakdown => summary['event_breakdown'] != null
      ? Map<String, int>.from(summary['event_breakdown'])
      : null;

  @override
  String toString() {
    return 'AnalyticsReport(type: $reportType, period: ${startDate.toIso8601String()} to ${endDate.toIso8601String()})';
  }
}

class UserBehaviorInsight {
  final String userId;
  final Map<String, int> screenViews;
  final Map<String, int> actionCounts;
  final List<String> preferredContentTypes;
  final List<String> mostUsedFeatures;
  final double engagementScore;
  final Duration averageSessionDuration;
  final DateTime lastActiveAt;
  final Map<String, dynamic> additionalMetrics;

  const UserBehaviorInsight({
    required this.userId,
    this.screenViews = const {},
    this.actionCounts = const {},
    this.preferredContentTypes = const [],
    this.mostUsedFeatures = const [],
    this.engagementScore = 0.0,
    this.averageSessionDuration = Duration.zero,
    required this.lastActiveAt,
    this.additionalMetrics = const {},
  });

  factory UserBehaviorInsight.fromJson(Map<String, dynamic> json) {
    return UserBehaviorInsight(
      userId: json['user_id'] as String,
      screenViews: Map<String, int>.from(json['screen_views'] ?? {}),
      actionCounts: Map<String, int>.from(json['action_counts'] ?? {}),
      preferredContentTypes: List<String>.from(
        json['preferred_content_types'] ?? [],
      ),
      mostUsedFeatures: List<String>.from(json['most_used_features'] ?? []),
      engagementScore: (json['engagement_score'] as num?)?.toDouble() ?? 0.0,
      averageSessionDuration: Duration(
        milliseconds: json['average_session_duration_ms'] as int? ?? 0,
      ),
      lastActiveAt: DateTime.parse(json['last_active_at'] as String),
      additionalMetrics: Map<String, dynamic>.from(
        json['additional_metrics'] ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'screen_views': screenViews,
      'action_counts': actionCounts,
      'preferred_content_types': preferredContentTypes,
      'most_used_features': mostUsedFeatures,
      'engagement_score': engagementScore,
      'average_session_duration_ms': averageSessionDuration.inMilliseconds,
      'last_active_at': lastActiveAt.toIso8601String(),
      'additional_metrics': additionalMetrics,
    };
  }

  String get engagementLevel {
    if (engagementScore >= 0.8) return 'High';
    if (engagementScore >= 0.5) return 'Medium';
    if (engagementScore >= 0.2) return 'Low';
    return 'Very Low';
  }

  String? get mostViewedScreen {
    if (screenViews.isEmpty) return null;
    return screenViews.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  String? get mostUsedAction {
    if (actionCounts.isEmpty) return null;
    return actionCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  int get totalActions =>
      actionCounts.values.fold(0, (sum, count) => sum + count);
  int get totalScreenViews =>
      screenViews.values.fold(0, (sum, count) => sum + count);

  @override
  String toString() {
    return 'UserBehaviorInsight(userId: $userId, engagement: $engagementLevel, totalActions: $totalActions)';
  }
}
