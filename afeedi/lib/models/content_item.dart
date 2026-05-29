/// Represents a content item from various platforms that can be recommended to users
class ContentItem {
  /// Unique identifier for the content item
  final String id;
  
  /// Title of the content
  final String title;
  
  /// Optional description of the content
  final String? description;
  
  /// URL to the content (can be web URL or deep link)
  final String? url;
  
  /// Platform where the content is hosted (e.g., YouTube, Instagram, TikTok)
  final String platform;
  
  /// Type of content (e.g., video, article, image, podcast)
  final String contentType;
  
  /// Creator or author of the content
  final String? creator;
  
  /// URL to the thumbnail image
  final String? thumbnailUrl;
  
  /// Duration of the content in seconds (for time-based content like videos)
  final int durationSeconds;
  
  /// Publication or creation date
  final DateTime? publishedAt;
  
  /// Tags or categories associated with the content
  final List<String> tags;
  
  /// Category of the content
  final String category;
  
  /// Engagement metrics (views, likes, comments, etc.)
  final Map<String, dynamic>? engagementMetrics;
  
  /// Personalization score (how well it matches user preferences)
  final double personalizationScore;
  
  /// Novelty score (how new/unique the content is)
  final double noveltyScore;
  
  /// Relevance score (how relevant the content is to user interests)
  final double relevanceScore;
  
  /// Reason why this content was recommended to the user
  String recommendationReason;
  
  /// Contextual relevance (e.g., "morning content", "related to calendar event")
  final String? contextualRelevance;
  
  /// Whether the content has been viewed by the user
  final bool isViewed;
  
  /// Whether the content has been saved/bookmarked by the user
  final bool isSaved;
  
  /// Whether the content is new/fresh for the user
  final bool isNew;
  
  /// Additional platform-specific data
  final Map<String, dynamic>? platformData;

  ContentItem({
    required this.id,
    required this.title,
    this.description,
    this.url,
    required this.platform,
    required this.contentType,
    this.creator,
    this.thumbnailUrl,
    required this.durationSeconds,
    this.publishedAt,
    required this.tags,
    required this.category,
    this.engagementMetrics,
    this.personalizationScore = 0.0,
    this.noveltyScore = 0.0,
    this.relevanceScore = 0.0,
    this.recommendationReason = '',
    this.contextualRelevance,
    this.isViewed = false,
    this.isSaved = false,
    this.isNew = true,
    this.platformData,
  });

  /// Create a copy of this ContentItem with modified fields
  ContentItem copyWith({
    String? id,
    String? title,
    String? description,
    String? url,
    String? platform,
    String? contentType,
    String? creator,
    String? thumbnailUrl,
    int? durationSeconds,
    DateTime? publishedAt,
    List<String>? tags,
    String? category,
    Map<String, dynamic>? engagementMetrics,
    double? personalizationScore,
    double? noveltyScore,
    double? relevanceScore,
    String? recommendationReason,
    String? contextualRelevance,
    bool? isViewed,
    bool? isSaved,
    bool? isNew,
    Map<String, dynamic>? platformData,
  }) {
    return ContentItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      url: url ?? this.url,
      platform: platform ?? this.platform,
      contentType: contentType ?? this.contentType,
      creator: creator ?? this.creator,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      publishedAt: publishedAt ?? this.publishedAt,
      tags: tags ?? this.tags,
      category: category ?? this.category,
      engagementMetrics: engagementMetrics ?? this.engagementMetrics,
      personalizationScore: personalizationScore ?? this.personalizationScore,
      noveltyScore: noveltyScore ?? this.noveltyScore,
      relevanceScore: relevanceScore ?? this.relevanceScore,
      recommendationReason: recommendationReason ?? this.recommendationReason,
      contextualRelevance: contextualRelevance ?? this.contextualRelevance,
      isViewed: isViewed ?? this.isViewed,
      isSaved: isSaved ?? this.isSaved,
      isNew: isNew ?? this.isNew,
      platformData: platformData ?? this.platformData,
    );
  }

  /// Convert ContentItem to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'url': url,
      'platform': platform,
      'contentType': contentType,
      'creator': creator,
      'thumbnailUrl': thumbnailUrl,
      'durationSeconds': durationSeconds,
      'publishedAt': publishedAt?.toIso8601String(),
      'tags': tags,
      'engagementMetrics': engagementMetrics,
      'personalizationScore': personalizationScore,
      'recommendationReason': recommendationReason,
      'contextualRelevance': contextualRelevance,
      'isViewed': isViewed,
      'isSaved': isSaved,
      'isNew': isNew,
      'platformData': platformData,
    };
  }

  /// Create ContentItem from a Map
  factory ContentItem.fromMap(Map<String, dynamic> map) {
    return ContentItem(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      url: map['url'] as String?,
      platform: map['platform'] as String,
      contentType: map['contentType'] as String,
      creator: map['creator'] as String?,
      thumbnailUrl: map['thumbnailUrl'] as String?,
      durationSeconds: map['durationSeconds'] as int? ?? 0,
      publishedAt: map['publishedAt'] != null
          ? DateTime.parse(map['publishedAt'] as String)
          : null,
      tags: List<String>.from(map['tags'] ?? []),
      category: map['category'] as String? ?? 'Uncategorized',
      engagementMetrics: map['engagementMetrics'] as Map<String, dynamic>?,
      personalizationScore: (map['personalizationScore'] as num?)?.toDouble() ?? 0.0,
      noveltyScore: (map['noveltyScore'] as num?)?.toDouble() ?? 0.0,
      relevanceScore: (map['relevanceScore'] as num?)?.toDouble() ?? 0.0,
      recommendationReason: map['recommendationReason'] as String? ?? '',
      contextualRelevance: map['contextualRelevance'] as String?,
      isViewed: map['isViewed'] as bool? ?? false,
      isSaved: map['isSaved'] as bool? ?? false,
      isNew: map['isNew'] as bool? ?? true,
      platformData: map['platformData'] as Map<String, dynamic>?,
    );
  }
  
  /// Create ContentItem from a JSON map
  factory ContentItem.fromJson(Map<String, dynamic> json) {
    return ContentItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      url: json['url'] as String?,
      platform: json['platform'] as String,
      contentType: json['content_type'] as String? ?? 'video',
      creator: json['creator'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'] as String)
          : null,
      tags: List<String>.from(json['tags'] ?? []),
      category: json['category'] as String? ?? 'Uncategorized',
      engagementMetrics: json['engagement_metrics'] as Map<String, dynamic>?,
      personalizationScore: (json['personalization_score'] as num?)?.toDouble() ?? 0.0,
      noveltyScore: (json['novelty_score'] as num?)?.toDouble() ?? 0.0,
      relevanceScore: (json['relevance_score'] as num?)?.toDouble() ?? 0.0,
      recommendationReason: json['recommendation_reason'] as String? ?? '',
      contextualRelevance: json['contextual_relevance'] as String?,
      isViewed: json['is_viewed'] as bool? ?? false,
      isSaved: json['is_saved'] as bool? ?? false,
      isNew: json['is_new'] as bool? ?? true,
      platformData: json['platform_data'] as Map<String, dynamic>?,
    );
  }

  /// Check if this content is part of a series (based on tags or title patterns)
  bool get isPartOfSeries {
    return tags.any((tag) => tag.toLowerCase().contains('series')) ||
           tags.any((tag) => tag.toLowerCase().contains('episode')) ||
           title.toLowerCase().contains('episode') ||
           title.toLowerCase().contains('part');
  }
  
  /// Check if this content is niche (based on category and engagement metrics)
  bool get isNiche {
    final views = engagementMetrics?['views'] as num? ?? 0;
    final likes = engagementMetrics?['likes'] as num? ?? 0;
    
    // Consider content niche if it has low engagement or specific categories
    return views < 10000 || 
           likes < 100 ||
           category.toLowerCase().contains('niche') ||
           tags.any((tag) => ['specialized', 'advanced', 'expert', 'technical'].contains(tag.toLowerCase()));
  }
  
  /// Getter for popularity score based on engagement metrics
  double get popularityScore {
    if (engagementMetrics == null) return 0.0;
    
    final views = (engagementMetrics!['views'] as num?)?.toDouble() ?? 0.0;
    final likes = (engagementMetrics!['likes'] as num?)?.toDouble() ?? 0.0;
    final comments = (engagementMetrics!['comments'] as num?)?.toDouble() ?? 0.0;
    final shares = (engagementMetrics!['shares'] as num?)?.toDouble() ?? 0.0;
    
    // Calculate a normalized popularity score (0.0 to 1.0)
    // Using logarithmic scaling to handle large numbers
    double score = 0.0;
    
    if (views > 0) score += (views.clamp(0, 1000000) / 1000000) * 0.4;
    if (likes > 0) score += (likes.clamp(0, 100000) / 100000) * 0.3;
    if (comments > 0) score += (comments.clamp(0, 10000) / 10000) * 0.2;
    if (shares > 0) score += (shares.clamp(0, 10000) / 10000) * 0.1;
    
    return score.clamp(0.0, 1.0);
  }

  @override
  String toString() {
    return 'ContentItem(id: $id, title: $title, platform: $platform, contentType: $contentType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is ContentItem &&
      other.id == id &&
      other.title == title &&
      other.platform == platform &&
      other.contentType == contentType;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      title.hashCode ^
      platform.hashCode ^
      contentType.hashCode;
  }
}