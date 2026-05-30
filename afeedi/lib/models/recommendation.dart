/// A model representing a content recommendation with metadata
class Recommendation {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String platform;
  final String category;
  final int durationSeconds;
  final double relevanceScore;
  final String recommendationReason;
  final double contextualRelevance;
  final DateTime createdAt;

  Recommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.platform,
    required this.category,
    required this.durationSeconds,
    this.relevanceScore = 0.0,
    this.recommendationReason = '',
    this.contextualRelevance = 0.0,
    DateTime? createdAt,
  }) : this.createdAt = createdAt ?? DateTime.now();

  /// Create a copy of this Recommendation with the given fields replaced
  Recommendation copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? platform,
    String? category,
    int? durationSeconds,
    double? relevanceScore,
    String? recommendationReason,
    double? contextualRelevance,
    DateTime? createdAt,
  }) {
    return Recommendation(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      platform: platform ?? this.platform,
      category: category ?? this.category,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      relevanceScore: relevanceScore ?? this.relevanceScore,
      recommendationReason: recommendationReason ?? this.recommendationReason,
      contextualRelevance: contextualRelevance ?? this.contextualRelevance,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Convert Recommendation to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'platform': platform,
      'category': category,
      'durationSeconds': durationSeconds,
      'relevanceScore': relevanceScore,
      'recommendationReason': recommendationReason,
      'contextualRelevance': contextualRelevance,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create a Recommendation from a JSON map
  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      platform: json['platform'] as String,
      category: json['category'] as String,
      durationSeconds: json['durationSeconds'] as int,
      relevanceScore: (json['relevanceScore'] as num?)?.toDouble() ?? 0.0,
      recommendationReason: json['recommendationReason'] as String? ?? '',
      contextualRelevance:
          (json['contextualRelevance'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  /// Create a sample recommendation for testing
  factory Recommendation.sample({
    String? id,
    String? title,
    String? platform,
    String? category,
    int? durationSeconds,
    String? timeOfDay,
    int? count,
  }) {
    return Recommendation(
      id: id ?? 'rec_${DateTime.now().millisecondsSinceEpoch}',
      title: title ?? 'Sample Recommendation',
      description: 'This is a sample recommendation for testing purposes',
      imageUrl: 'https://example.com/sample.jpg',
      platform: platform ?? 'Netflix',
      category: category ?? 'Action',
      durationSeconds: durationSeconds ?? 3600,
      relevanceScore: 0.85,
      recommendationReason: 'Based on your preferences',
      contextualRelevance: 0.75,
    );
  }
}
