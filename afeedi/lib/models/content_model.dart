enum PlatformType {
  youtube,
  instagram,
  tiktok,
  facebook,
}

enum ContentType {
  video,
  short,
  reel,
  story,
  post,
}

enum InteractionType {
  view,
  like,
  save,
  share,
  schedule,
}

class Content {
  final String id;
  final PlatformType platform;
  final String platformContentId;
  final ContentType contentType;
  final String? title;
  final String? description;
  final String? thumbnailUrl;
  final String? videoUrl;
  final String? embedUrl;
  final int? durationSeconds;
  final int viewCount;
  final int likeCount;
  final String? creatorName;
  final String? creatorId;
  final String? creatorAvatarUrl;
  final List<String> tags;
  final List<String> categories;
  final String? language;
  final DateTime? publishedAt;
  final bool isActive;
  final String? contentRating;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Content({
    required this.id,
    required this.platform,
    required this.platformContentId,
    required this.contentType,
    this.title,
    this.description,
    this.thumbnailUrl,
    this.videoUrl,
    this.embedUrl,
    this.durationSeconds,
    this.viewCount = 0,
    this.likeCount = 0,
    this.creatorName,
    this.creatorId,
    this.creatorAvatarUrl,
    this.tags = const [],
    this.categories = const [],
    this.language,
    this.publishedAt,
    this.isActive = true,
    this.contentRating,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory Content.fromJson(Map<String, dynamic> json) {
    return Content(
      id: json['id'] as String,
      platform: PlatformType.values.firstWhere(
        (e) => e.name == json['platform'],
        orElse: () => PlatformType.youtube,
      ),
      platformContentId: json['platform_content_id'] as String,
      contentType: ContentType.values.firstWhere(
        (e) => e.name == json['content_type'],
        orElse: () => ContentType.video,
      ),
      title: json['title'] as String?,
      description: json['description'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      videoUrl: json['video_url'] as String?,
      embedUrl: json['embed_url'] as String?,
      durationSeconds: json['duration_seconds'] as int?,
      viewCount: json['view_count'] as int? ?? 0,
      likeCount: json['like_count'] as int? ?? 0,
      creatorName: json['creator_name'] as String?,
      creatorId: json['creator_id'] as String?,
      creatorAvatarUrl: json['creator_avatar_url'] as String?,
      tags: List<String>.from(json['tags'] ?? []),
      categories: List<String>.from(json['categories'] ?? []),
      language: json['language'] as String?,
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
      contentRating: json['content_rating'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'platform': platform.name,
      'platform_content_id': platformContentId,
      'content_type': contentType.name,
      'title': title,
      'description': description,
      'thumbnail_url': thumbnailUrl,
      'video_url': videoUrl,
      'embed_url': embedUrl,
      'duration_seconds': durationSeconds,
      'view_count': viewCount,
      'like_count': likeCount,
      'creator_name': creatorName,
      'creator_id': creatorId,
      'creator_avatar_url': creatorAvatarUrl,
      'tags': tags,
      'categories': categories,
      'language': language,
      'published_at': publishedAt?.toIso8601String(),
      'is_active': isActive,
      'content_rating': contentRating,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Content copyWith({
    String? id,
    PlatformType? platform,
    String? platformContentId,
    ContentType? contentType,
    String? title,
    String? description,
    String? thumbnailUrl,
    String? videoUrl,
    String? embedUrl,
    int? durationSeconds,
    int? viewCount,
    int? likeCount,
    String? creatorName,
    String? creatorId,
    String? creatorAvatarUrl,
    List<String>? tags,
    List<String>? categories,
    String? language,
    DateTime? publishedAt,
    bool? isActive,
    String? contentRating,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Content(
      id: id ?? this.id,
      platform: platform ?? this.platform,
      platformContentId: platformContentId ?? this.platformContentId,
      contentType: contentType ?? this.contentType,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      embedUrl: embedUrl ?? this.embedUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      creatorName: creatorName ?? this.creatorName,
      creatorId: creatorId ?? this.creatorId,
      creatorAvatarUrl: creatorAvatarUrl ?? this.creatorAvatarUrl,
      tags: tags ?? this.tags,
      categories: categories ?? this.categories,
      language: language ?? this.language,
      publishedAt: publishedAt ?? this.publishedAt,
      isActive: isActive ?? this.isActive,
      contentRating: contentRating ?? this.contentRating,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get formattedDuration {
    if (durationSeconds == null) return 'Unknown';
    final duration = Duration(seconds: durationSeconds!);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  String get formattedViewCount {
    if (viewCount >= 1000000) {
      return '${(viewCount / 1000000).toStringAsFixed(1)}M views';
    } else if (viewCount >= 1000) {
      return '${(viewCount / 1000).toStringAsFixed(1)}K views';
    } else {
      return '$viewCount views';
    }
  }

  String get formattedLikeCount {
    if (likeCount >= 1000000) {
      return '${(likeCount / 1000000).toStringAsFixed(1)}M';
    } else if (likeCount >= 1000) {
      return '${(likeCount / 1000).toStringAsFixed(1)}K';
    } else {
      return likeCount.toString();
    }
  }

  bool get isShortForm => contentType == ContentType.short || 
                         contentType == ContentType.reel ||
                         (durationSeconds != null && durationSeconds! <= 60);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Content && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Content(id: $id, platform: $platform, title: $title, creator: $creatorName)';
  }
}

class ContentInteraction {
  final String id;
  final String userId;
  final String contentId;
  final InteractionType interactionType;
  final Map<String, dynamic> interactionData;
  final DateTime createdAt;

  const ContentInteraction({
    required this.id,
    required this.userId,
    required this.contentId,
    required this.interactionType,
    this.interactionData = const {},
    required this.createdAt,
  });

  factory ContentInteraction.fromJson(Map<String, dynamic> json) {
    return ContentInteraction(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      contentId: json['content_id'] as String,
      interactionType: InteractionType.values.firstWhere(
        (e) => e.name == json['interaction_type'],
        orElse: () => InteractionType.view,
      ),
      interactionData: Map<String, dynamic>.from(json['interaction_data'] ?? {}),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'content_id': contentId,
      'interaction_type': interactionType.name,
      'interaction_data': interactionData,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ContentInteraction copyWith({
    String? id,
    String? userId,
    String? contentId,
    InteractionType? interactionType,
    Map<String, dynamic>? interactionData,
    DateTime? createdAt,
  }) {
    return ContentInteraction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      contentId: contentId ?? this.contentId,
      interactionType: interactionType ?? this.interactionType,
      interactionData: interactionData ?? this.interactionData,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContentInteraction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ContentInteraction(id: $id, type: $interactionType, userId: $userId, contentId: $contentId)';
  }
}

class Recommendation {
  final String id;
  final String userId;
  final String contentId;
  final double recommendationScore;
  final String? recommendationReason;
  final String? algorithmVersion;
  final bool isShown;
  final bool isClicked;
  final DateTime createdAt;
  final DateTime expiresAt;

  const Recommendation({
    required this.id,
    required this.userId,
    required this.contentId,
    required this.recommendationScore,
    this.recommendationReason,
    this.algorithmVersion,
    this.isShown = false,
    this.isClicked = false,
    required this.createdAt,
    required this.expiresAt,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      contentId: json['content_id'] as String,
      recommendationScore: (json['recommendation_score'] as num).toDouble(),
      recommendationReason: json['recommendation_reason'] as String?,
      algorithmVersion: json['algorithm_version'] as String?,
      isShown: json['is_shown'] as bool? ?? false,
      isClicked: json['is_clicked'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'content_id': contentId,
      'recommendation_score': recommendationScore,
      'recommendation_reason': recommendationReason,
      'algorithm_version': algorithmVersion,
      'is_shown': isShown,
      'is_clicked': isClicked,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    };
  }

  Recommendation copyWith({
    String? id,
    String? userId,
    String? contentId,
    double? recommendationScore,
    String? recommendationReason,
    String? algorithmVersion,
    bool? isShown,
    bool? isClicked,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return Recommendation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      contentId: contentId ?? this.contentId,
      recommendationScore: recommendationScore ?? this.recommendationScore,
      recommendationReason: recommendationReason ?? this.recommendationReason,
      algorithmVersion: algorithmVersion ?? this.algorithmVersion,
      isShown: isShown ?? this.isShown,
      isClicked: isClicked ?? this.isClicked,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  bool get isExpired => expiresAt.isBefore(DateTime.now());
  bool get isHighScore => recommendationScore >= 0.8;
  bool get isMediumScore => recommendationScore >= 0.5 && recommendationScore < 0.8;
  bool get isLowScore => recommendationScore < 0.5;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Recommendation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Recommendation(id: $id, userId: $userId, contentId: $contentId, score: $recommendationScore)';
  }
}

class ScheduledContent {
  final String id;
  final String userId;
  final String contentId;
  final DateTime scheduledFor;
  final String? notes;
  final bool isRecurring;
  final Map<String, dynamic>? recurrencePattern;
  final bool notificationSent;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ScheduledContent({
    required this.id,
    required this.userId,
    required this.contentId,
    required this.scheduledFor,
    this.notes,
    this.isRecurring = false,
    this.recurrencePattern,
    this.notificationSent = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ScheduledContent.fromJson(Map<String, dynamic> json) {
    return ScheduledContent(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      contentId: json['content_id'] as String,
      scheduledFor: DateTime.parse(json['scheduled_for'] as String),
      notes: json['notes'] as String?,
      isRecurring: json['is_recurring'] as bool? ?? false,
      recurrencePattern: json['recurrence_pattern'] != null
          ? Map<String, dynamic>.from(json['recurrence_pattern'])
          : null,
      notificationSent: json['notification_sent'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'content_id': contentId,
      'scheduled_for': scheduledFor.toIso8601String(),
      'notes': notes,
      'is_recurring': isRecurring,
      'recurrence_pattern': recurrencePattern,
      'notification_sent': notificationSent,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ScheduledContent copyWith({
    String? id,
    String? userId,
    String? contentId,
    DateTime? scheduledFor,
    String? notes,
    bool? isRecurring,
    Map<String, dynamic>? recurrencePattern,
    bool? notificationSent,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ScheduledContent(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      contentId: contentId ?? this.contentId,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      notes: notes ?? this.notes,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      notificationSent: notificationSent ?? this.notificationSent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}