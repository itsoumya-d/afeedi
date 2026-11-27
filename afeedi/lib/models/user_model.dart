enum UserRole {
  guest,
  registered,
  premium,
  admin,
}

class User {
  final String id;
  final String email;
  final String? name;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;
  final DateTime? subscriptionExpiresAt;
  final DateTime? termsAcceptedAt;
  final DateTime? privacyPolicyAcceptedAt;

  const User({
    required this.id,
    required this.email,
    this.name,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
    this.subscriptionExpiresAt,
    this.termsAcceptedAt,
    this.privacyPolicyAcceptedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.registered,
      ),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastLoginAt: json['last_login_at'] != null 
          ? DateTime.parse(json['last_login_at'] as String) 
          : null,
      subscriptionExpiresAt: json['subscription_expires_at'] != null 
          ? DateTime.parse(json['subscription_expires_at'] as String) 
          : null,
      termsAcceptedAt: json['terms_accepted_at'] != null 
          ? DateTime.parse(json['terms_accepted_at'] as String) 
          : null,
      privacyPolicyAcceptedAt: json['privacy_policy_accepted_at'] != null 
          ? DateTime.parse(json['privacy_policy_accepted_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role.name,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'subscription_expires_at': subscriptionExpiresAt?.toIso8601String(),
      'terms_accepted_at': termsAcceptedAt?.toIso8601String(),
      'privacy_policy_accepted_at': privacyPolicyAcceptedAt?.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? email,
    UserRole? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    DateTime? subscriptionExpiresAt,
    DateTime? termsAcceptedAt,
    DateTime? privacyPolicyAcceptedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      subscriptionExpiresAt: subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      termsAcceptedAt: termsAcceptedAt ?? this.termsAcceptedAt,
      privacyPolicyAcceptedAt: privacyPolicyAcceptedAt ?? this.privacyPolicyAcceptedAt,
    );
  }

  bool get isPremium => role == UserRole.premium;
  bool get isAdmin => role == UserRole.admin;
  bool get hasAcceptedTerms => termsAcceptedAt != null;
  bool get hasAcceptedPrivacyPolicy => privacyPolicyAcceptedAt != null;
  bool get isSubscriptionActive => 
      subscriptionExpiresAt != null && 
      subscriptionExpiresAt!.isAfter(DateTime.now());

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'User(id: $id, email: $email, role: $role, isActive: $isActive)';
  }
}

class UserProfile {
  final String id;
  final String userId;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;
  final DateTime? dateOfBirth;
  final String timezone;
  final String language;
  final String? country;
  final bool onboardingCompleted;
  final int onboardingStep;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.userId,
    this.displayName,
    this.avatarUrl,
    this.bio,
    this.dateOfBirth,
    this.timezone = 'UTC',
    this.language = 'en',
    this.country,
    this.onboardingCompleted = false,
    this.onboardingStep = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      dateOfBirth: json['date_of_birth'] != null 
          ? DateTime.parse(json['date_of_birth'] as String) 
          : null,
      timezone: json['timezone'] as String? ?? 'UTC',
      language: json['language'] as String? ?? 'en',
      country: json['country'] as String?,
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      onboardingStep: json['onboarding_step'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'timezone': timezone,
      'language': language,
      'country': country,
      'onboarding_completed': onboardingCompleted,
      'onboarding_step': onboardingStep,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? userId,
    String? displayName,
    String? avatarUrl,
    String? bio,
    DateTime? dateOfBirth,
    String? timezone,
    String? language,
    String? country,
    bool? onboardingCompleted,
    int? onboardingStep,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      timezone: timezone ?? this.timezone,
      language: language ?? this.language,
      country: country ?? this.country,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      onboardingStep: onboardingStep ?? this.onboardingStep,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month || 
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UserProfile(id: $id, userId: $userId, displayName: $displayName)';
  }
}

class NotificationSettings {
  final bool push;
  final bool email;
  final bool inApp;
  final bool contentRecommendations;
  final bool scheduledContent;
  final bool platformUpdates;
  final bool marketingEmails;

  const NotificationSettings({
    this.push = true,
    this.email = false,
    this.inApp = true,
    this.contentRecommendations = true,
    this.scheduledContent = true,
    this.platformUpdates = false,
    this.marketingEmails = false,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      push: json['push'] as bool? ?? true,
      email: json['email'] as bool? ?? false,
      inApp: json['in_app'] as bool? ?? true,
      contentRecommendations: json['content_recommendations'] as bool? ?? true,
      scheduledContent: json['scheduled_content'] as bool? ?? true,
      platformUpdates: json['platform_updates'] as bool? ?? false,
      marketingEmails: json['marketing_emails'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'push': push,
      'email': email,
      'in_app': inApp,
      'content_recommendations': contentRecommendations,
      'scheduled_content': scheduledContent,
      'platform_updates': platformUpdates,
      'marketing_emails': marketingEmails,
    };
  }

  NotificationSettings copyWith({
    bool? push,
    bool? email,
    bool? inApp,
    bool? contentRecommendations,
    bool? scheduledContent,
    bool? platformUpdates,
    bool? marketingEmails,
  }) {
    return NotificationSettings(
      push: push ?? this.push,
      email: email ?? this.email,
      inApp: inApp ?? this.inApp,
      contentRecommendations: contentRecommendations ?? this.contentRecommendations,
      scheduledContent: scheduledContent ?? this.scheduledContent,
      platformUpdates: platformUpdates ?? this.platformUpdates,
      marketingEmails: marketingEmails ?? this.marketingEmails,
    );
  }
}

class PrivacySettings {
  final bool profilePublic;
  final bool analyticsEnabled;
  final bool dataCollection;
  final bool personalizedAds;
  final bool shareUsageData;
  final bool allowCookies;

  const PrivacySettings({
    this.profilePublic = false,
    this.analyticsEnabled = true,
    this.dataCollection = true,
    this.personalizedAds = false,
    this.shareUsageData = false,
    this.allowCookies = true,
  });

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      profilePublic: json['profile_public'] as bool? ?? false,
      analyticsEnabled: json['analytics_enabled'] as bool? ?? true,
      dataCollection: json['data_collection'] as bool? ?? true,
      personalizedAds: json['personalized_ads'] as bool? ?? false,
      shareUsageData: json['share_usage_data'] as bool? ?? false,
      allowCookies: json['allow_cookies'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profile_public': profilePublic,
      'analytics_enabled': analyticsEnabled,
      'data_collection': dataCollection,
      'personalized_ads': personalizedAds,
      'share_usage_data': shareUsageData,
      'allow_cookies': allowCookies,
    };
  }

  PrivacySettings copyWith({
    bool? profilePublic,
    bool? analyticsEnabled,
    bool? dataCollection,
    bool? personalizedAds,
    bool? shareUsageData,
    bool? allowCookies,
  }) {
    return PrivacySettings(
      profilePublic: profilePublic ?? this.profilePublic,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
      dataCollection: dataCollection ?? this.dataCollection,
      personalizedAds: personalizedAds ?? this.personalizedAds,
      shareUsageData: shareUsageData ?? this.shareUsageData,
      allowCookies: allowCookies ?? this.allowCookies,
    );
  }
}

class UserPreferences {
  final String id;
  final String userId;
  final List<String> contentCategories;
  final Map<String, int> platformPriorities;
  final NotificationSettings notificationSettings;
  final PrivacySettings privacySettings;
  final bool aiRecommendationsEnabled;
  final bool matureContentEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserPreferences({
    required this.id,
    required this.userId,
    this.contentCategories = const [],
    this.platformPriorities = const {
      'youtube': 1,
      'instagram': 2,
      'tiktok': 3,
      'facebook': 4,
    },
    this.notificationSettings = const NotificationSettings(),
    this.privacySettings = const PrivacySettings(),
    this.aiRecommendationsEnabled = true,
    this.matureContentEnabled = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      contentCategories: List<String>.from(json['content_categories'] ?? []),
      platformPriorities: Map<String, int>.from(json['platform_priorities'] ?? {
        'youtube': 1,
        'instagram': 2,
        'tiktok': 3,
        'facebook': 4,
      }),
      notificationSettings: NotificationSettings.fromJson(
        json['notification_settings'] ?? {},
      ),
      privacySettings: PrivacySettings.fromJson(
        json['privacy_settings'] ?? {},
      ),
      aiRecommendationsEnabled: json['ai_recommendations_enabled'] as bool? ?? true,
      matureContentEnabled: json['mature_content_enabled'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'content_categories': contentCategories,
      'platform_priorities': platformPriorities,
      'notification_settings': notificationSettings.toJson(),
      'privacy_settings': privacySettings.toJson(),
      'ai_recommendations_enabled': aiRecommendationsEnabled,
      'mature_content_enabled': matureContentEnabled,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserPreferences copyWith({
    String? id,
    String? userId,
    List<String>? contentCategories,
    Map<String, int>? platformPriorities,
    NotificationSettings? notificationSettings,
    PrivacySettings? privacySettings,
    bool? aiRecommendationsEnabled,
    bool? matureContentEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserPreferences(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      contentCategories: contentCategories ?? this.contentCategories,
      platformPriorities: platformPriorities ?? this.platformPriorities,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      privacySettings: privacySettings ?? this.privacySettings,
      aiRecommendationsEnabled: aiRecommendationsEnabled ?? this.aiRecommendationsEnabled,
      matureContentEnabled: matureContentEnabled ?? this.matureContentEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserPreferences && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UserPreferences(id: $id, userId: $userId, categories: ${contentCategories.length})';
  }
}