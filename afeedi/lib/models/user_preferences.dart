class UserPreferences {
  // Personal Information
  final Map<String, dynamic> personalInfo;
  final String? name;
  final int? age;
  final String? language;
  final String? timezone;
  
  // Content Preferences
  final List<String> contentInterests;
  final List<String> contentTypes;
  final Map<String, double> platformPreferences;
  final List<String> preferredCreators;
  final Map<String, bool> contentFilters;
  final String? contentDiscoveryStyle; // trending, niche, balanced
  
  // Viewing Habits
  final Map<String, dynamic> viewingHabits;
  final List<String> preferredViewingTimes; // morning, afternoon, evening, night
  final String? averageSessionDuration; // short, medium, long
  final Map<String, int> contentLengthPreferences; // short: 1-5min, medium: 5-20min, long: 20+min
  final Map<String, double> timeOfDayContentPreferences; // morning: educational, evening: entertainment
  final Map<String, int> weekdayPreferences; // weekday vs weekend preferences
  
  // Platform-Specific Preferences
  final Map<String, double> platformPriorities; // ranked platforms
  final Map<String, Map<String, dynamic>> platformSpecificSettings; // settings per platform
  
  // Content Consumption Patterns
  final Map<String, double> genreAffinityScores; // scores for different genres
  final Map<String, double> topicEngagementRates; // engagement rates for topics
  final Map<String, int> contentCompletionRates; // completion rates by content type
  final Map<String, String> contentMoodPreferences; // mood preferences for different times
  
  // Entertainment Preferences
  final Map<String, dynamic> entertainmentPreferences;
  
  // Personalization Settings
  final Map<String, dynamic> personalizationSettings;
  final bool? enableAIRecommendations;
  final double? diversityLevel; // 0.0 to 1.0
  final bool? crossPlatformRecommendations;
  
  // Calendar Integration
  final Map<String, dynamic> calendarIntegration;
  final bool? calendarIntegrationEnabled;
  final Map<String, String> timeBasedPreferences;
  final bool? smartScheduling;
  
  // App Customization
  final Map<String, dynamic> appCustomization;
  final String? theme;
  final String? feedLayout;
  final bool? compactMode;
  
  // Privacy & Safety
  final bool dataCollection;
  final bool personalizedAds;
  final List<String> blockedPlatforms;
  final bool parentalControls;
  final int maxDailyWatchTime; // in minutes, 0 = unlimited
  
  // Accessibility
  final bool subtitles;
  final bool audioDescriptions;
  final double playbackSpeed;
  final bool reducedMotion;
  final double fontSize;

  const UserPreferences({
    this.personalInfo = const {},
    this.name,
    this.age,
    this.language,
    this.timezone,
    this.contentInterests = const [],
    this.contentTypes = const [],
    this.platformPreferences = const {},
    this.preferredCreators = const [],
    this.contentFilters = const {},
    this.contentDiscoveryStyle,
    this.viewingHabits = const {},
    this.preferredViewingTimes = const [],
    this.averageSessionDuration,
    this.contentLengthPreferences = const {},
    this.timeOfDayContentPreferences = const {},
    this.weekdayPreferences = const {},
    this.platformPriorities = const {},
    this.platformSpecificSettings = const {},
    this.genreAffinityScores = const {},
    this.topicEngagementRates = const {},
    this.contentCompletionRates = const {},
    this.contentMoodPreferences = const {},
    this.entertainmentPreferences = const {},
    this.personalizationSettings = const {},
    this.enableAIRecommendations,
    this.diversityLevel,
    this.crossPlatformRecommendations,
    this.calendarIntegration = const {'enabled': false, 'recommendForFreeTime': true, 'eventRelatedContent': true, 'smartNotifications': false},
    this.calendarIntegrationEnabled,
    this.timeBasedPreferences = const {},
    this.smartScheduling,
    this.appCustomization = const {},
    this.theme,
    this.feedLayout,
    this.compactMode,
    this.dataCollection = true,
    this.personalizedAds = false,
    this.blockedPlatforms = const [],
    this.parentalControls = false,
    this.maxDailyWatchTime = 0,
    this.subtitles = false,
    this.audioDescriptions = false,
    this.playbackSpeed = 1.0,
    this.reducedMotion = false,
    this.fontSize = 1.0,
  });

  UserPreferences copyWith({
    Map<String, dynamic>? personalInfo,
    String? name,
    int? age,
    String? language,
    String? timezone,
    List<String>? contentInterests,
    List<String>? contentTypes,
    Map<String, double>? platformPreferences,
    List<String>? preferredCreators,
    Map<String, bool>? contentFilters,
    String? contentDiscoveryStyle,
    Map<String, dynamic>? viewingHabits,
    List<String>? preferredViewingTimes,
    String? averageSessionDuration,
    Map<String, int>? contentLengthPreferences,
    Map<String, double>? timeOfDayContentPreferences,
    Map<String, int>? weekdayPreferences,
    Map<String, double>? platformPriorities,
    Map<String, Map<String, dynamic>>? platformSpecificSettings,
    Map<String, double>? genreAffinityScores,
    Map<String, double>? topicEngagementRates,
    Map<String, int>? contentCompletionRates,
    Map<String, String>? contentMoodPreferences,
    Map<String, dynamic>? entertainmentPreferences,
    Map<String, dynamic>? personalizationSettings,
    bool? enableAIRecommendations,
    double? diversityLevel,
    bool? crossPlatformRecommendations,
    Map<String, dynamic>? calendarIntegration,
    bool? calendarIntegrationEnabled,
    Map<String, String>? timeBasedPreferences,
    bool? smartScheduling,
    Map<String, dynamic>? appCustomization,
    String? theme,
    String? feedLayout,
    bool? compactMode,
    bool? dataCollection,
    bool? personalizedAds,
    List<String>? blockedPlatforms,
    bool? parentalControls,
    int? maxDailyWatchTime,
    bool? subtitles,
    bool? audioDescriptions,
    double? playbackSpeed,
    bool? reducedMotion,
    double? fontSize,
  }) {
    return UserPreferences(
      personalInfo: personalInfo ?? this.personalInfo,
      name: name ?? this.name,
      age: age ?? this.age,
      language: language ?? this.language,
      timezone: timezone ?? this.timezone,
      contentInterests: contentInterests ?? this.contentInterests,
      contentTypes: contentTypes ?? this.contentTypes,
      platformPreferences: platformPreferences ?? this.platformPreferences,
      preferredCreators: preferredCreators ?? this.preferredCreators,
      contentFilters: contentFilters ?? this.contentFilters,
      contentDiscoveryStyle: contentDiscoveryStyle ?? this.contentDiscoveryStyle,
      viewingHabits: viewingHabits ?? this.viewingHabits,
      preferredViewingTimes: preferredViewingTimes ?? this.preferredViewingTimes,
      averageSessionDuration: averageSessionDuration ?? this.averageSessionDuration,
      contentLengthPreferences: contentLengthPreferences ?? this.contentLengthPreferences,
      timeOfDayContentPreferences: timeOfDayContentPreferences ?? this.timeOfDayContentPreferences,
      weekdayPreferences: weekdayPreferences ?? this.weekdayPreferences,
      platformPriorities: platformPriorities ?? this.platformPriorities,
      platformSpecificSettings: platformSpecificSettings ?? this.platformSpecificSettings,
      genreAffinityScores: genreAffinityScores ?? this.genreAffinityScores,
      topicEngagementRates: topicEngagementRates ?? this.topicEngagementRates,
      contentCompletionRates: contentCompletionRates ?? this.contentCompletionRates,
      contentMoodPreferences: contentMoodPreferences ?? this.contentMoodPreferences,
      entertainmentPreferences: entertainmentPreferences ?? this.entertainmentPreferences,
      personalizationSettings: personalizationSettings ?? this.personalizationSettings,
      enableAIRecommendations: enableAIRecommendations ?? this.enableAIRecommendations,
      diversityLevel: diversityLevel ?? this.diversityLevel,
      crossPlatformRecommendations: crossPlatformRecommendations ?? this.crossPlatformRecommendations,
      calendarIntegration: calendarIntegration ?? this.calendarIntegration,
      calendarIntegrationEnabled: calendarIntegrationEnabled ?? this.calendarIntegrationEnabled,
      timeBasedPreferences: timeBasedPreferences ?? this.timeBasedPreferences,
      smartScheduling: smartScheduling ?? this.smartScheduling,
      appCustomization: appCustomization ?? this.appCustomization,
      theme: theme ?? this.theme,
      feedLayout: feedLayout ?? this.feedLayout,
      compactMode: compactMode ?? this.compactMode,
      dataCollection: dataCollection ?? this.dataCollection,
      personalizedAds: personalizedAds ?? this.personalizedAds,
      blockedPlatforms: blockedPlatforms ?? this.blockedPlatforms,
      parentalControls: parentalControls ?? this.parentalControls,
      maxDailyWatchTime: maxDailyWatchTime ?? this.maxDailyWatchTime,
      subtitles: subtitles ?? this.subtitles,
      audioDescriptions: audioDescriptions ?? this.audioDescriptions,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      fontSize: fontSize ?? this.fontSize,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'personalInfo': personalInfo,
      'name': name,
      'age': age,
      'language': language,
      'timezone': timezone,
      'contentInterests': contentInterests,
      'contentTypes': contentTypes,
      'platformPreferences': platformPreferences,
      'preferredCreators': preferredCreators,
      'contentFilters': contentFilters,
      'contentDiscoveryStyle': contentDiscoveryStyle,
      'viewingHabits': viewingHabits,
      'preferredViewingTimes': preferredViewingTimes,
      'averageSessionDuration': averageSessionDuration,
      'contentLengthPreferences': contentLengthPreferences,
      'timeOfDayContentPreferences': timeOfDayContentPreferences,
      'weekdayPreferences': weekdayPreferences,
      'platformPriorities': platformPriorities,
      'platformSpecificSettings': platformSpecificSettings,
      'genreAffinityScores': genreAffinityScores,
      'topicEngagementRates': topicEngagementRates,
      'contentCompletionRates': contentCompletionRates,
      'contentMoodPreferences': contentMoodPreferences,
      'entertainmentPreferences': entertainmentPreferences,
      'personalizationSettings': personalizationSettings,
      'enableAIRecommendations': enableAIRecommendations,
      'diversityLevel': diversityLevel,
      'crossPlatformRecommendations': crossPlatformRecommendations,
      'calendarIntegration': calendarIntegration,
      'calendarIntegrationEnabled': calendarIntegrationEnabled,
      'timeBasedPreferences': timeBasedPreferences,
      'smartScheduling': smartScheduling,
      'appCustomization': appCustomization,
      'theme': theme,
      'feedLayout': feedLayout,
      'compactMode': compactMode,
      'dataCollection': dataCollection,
      'personalizedAds': personalizedAds,
      'blockedPlatforms': blockedPlatforms,
      'parentalControls': parentalControls,
      'maxDailyWatchTime': maxDailyWatchTime,
      'subtitles': subtitles,
      'audioDescriptions': audioDescriptions,
      'playbackSpeed': playbackSpeed,
      'reducedMotion': reducedMotion,
      'fontSize': fontSize,
    };
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      personalInfo: Map<String, dynamic>.from(json['personalInfo'] ?? {}),
      name: json['name'],
      age: json['age'],
      language: json['language'],
      timezone: json['timezone'],
      contentInterests: List<String>.from(json['contentInterests'] ?? []),
      contentTypes: List<String>.from(json['contentTypes'] ?? []),
      platformPreferences: Map<String, double>.from(json['platformPreferences'] ?? {}),
      preferredCreators: List<String>.from(json['preferredCreators'] ?? []),
      contentFilters: Map<String, bool>.from(json['contentFilters'] ?? {}),
      contentDiscoveryStyle: json['contentDiscoveryStyle'],
      viewingHabits: Map<String, dynamic>.from(json['viewingHabits'] ?? {}),
      preferredViewingTimes: List<String>.from(json['preferredViewingTimes'] ?? []),
      averageSessionDuration: json['averageSessionDuration'],
      contentLengthPreferences: json['contentLengthPreferences'] != null 
        ? Map<String, int>.from(json['contentLengthPreferences']) 
        : const {},
      timeOfDayContentPreferences: json['timeOfDayContentPreferences'] != null 
        ? Map<String, double>.from(json['timeOfDayContentPreferences']) 
        : const {},
      weekdayPreferences: json['weekdayPreferences'] != null 
        ? Map<String, int>.from(json['weekdayPreferences']) 
        : const {},
      platformPriorities: json['platformPriorities'] != null 
        ? Map<String, double>.from(json['platformPriorities']) 
        : const {},
      platformSpecificSettings: json['platformSpecificSettings'] != null 
        ? Map<String, Map<String, dynamic>>.from(
            json['platformSpecificSettings'].map((key, value) => 
              MapEntry(key, Map<String, dynamic>.from(value))
            )
          ) 
        : const {},
      genreAffinityScores: json['genreAffinityScores'] != null 
        ? Map<String, double>.from(json['genreAffinityScores']) 
        : const {},
      topicEngagementRates: json['topicEngagementRates'] != null 
        ? Map<String, double>.from(json['topicEngagementRates']) 
        : const {},
      contentCompletionRates: json['contentCompletionRates'] != null 
        ? Map<String, int>.from(json['contentCompletionRates']) 
        : const {},
      contentMoodPreferences: json['contentMoodPreferences'] != null 
        ? Map<String, String>.from(json['contentMoodPreferences']) 
        : const {},
      entertainmentPreferences: Map<String, dynamic>.from(json['entertainmentPreferences'] ?? {}),
      personalizationSettings: Map<String, dynamic>.from(json['personalizationSettings'] ?? {}),
      enableAIRecommendations: json['enableAIRecommendations'],
      diversityLevel: json['diversityLevel']?.toDouble(),
      crossPlatformRecommendations: json['crossPlatformRecommendations'],
      calendarIntegration: Map<String, dynamic>.from(json['calendarIntegration'] ?? {}),
      calendarIntegrationEnabled: json['calendarIntegrationEnabled'],
      timeBasedPreferences: json['timeBasedPreferences'] != null 
        ? Map<String, String>.from(json['timeBasedPreferences']) 
        : const {},
      smartScheduling: json['smartScheduling'],
      appCustomization: Map<String, dynamic>.from(json['appCustomization'] ?? {}),
      theme: json['theme'],
      feedLayout: json['feedLayout'],
      compactMode: json['compactMode'],
      dataCollection: json['dataCollection'] ?? false,
      personalizedAds: json['personalizedAds'] ?? false,
      blockedPlatforms: List<String>.from(json['blockedPlatforms'] ?? []),
      parentalControls: json['parentalControls'] ?? false,
      maxDailyWatchTime: json['maxDailyWatchTime'] ?? 0,
      subtitles: json['subtitles'] ?? false,
      audioDescriptions: json['audioDescriptions'] ?? false,
      playbackSpeed: json['playbackSpeed']?.toDouble() ?? 1.0,
      reducedMotion: json['reducedMotion'] ?? false,
      fontSize: json['fontSize']?.toDouble() ?? 1.0,
    );
  }
}

// Onboarding step data structure
class OnboardingStepData {
  final String stepId;
  final String title;
  final String description;
  final Map<String, dynamic> data;
  final bool isCompleted;
  final DateTime? completedAt;
  
  const OnboardingStepData({
    required this.stepId,
    required this.title,
    required this.description,
    required this.data,
    this.isCompleted = false,
    this.completedAt,
  });
  
  OnboardingStepData copyWith({
    String? stepId,
    String? title,
    String? description,
    Map<String, dynamic>? data,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return OnboardingStepData(
      stepId: stepId ?? this.stepId,
      title: title ?? this.title,
      description: description ?? this.description,
      data: data ?? this.data,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}