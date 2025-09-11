import '../models/onboarding_step.dart';
import '../models/genre.dart';
import '../models/chat_message.dart';
import '../models/user_preferences.dart';

class OnboardingService {
  static final OnboardingService _instance = OnboardingService._internal();
  factory OnboardingService() => _instance;
  OnboardingService._internal();
  
  static OnboardingService get instance => _instance;

  // Static onboarding flow data
  static final List<Map<String, dynamic>> onboardingFlow = [
    {
      'id': 'welcome',
      'title': 'Welcome',
      'type': 'welcome',
    },
    {
      'id': 'genres',
      'title': 'Choose Genres',
      'type': 'genre_selection',
    },
    {
      'id': 'platforms',
      'title': 'Connect Platforms',
      'type': 'platform_selection',
    },
    {
      'id': 'profile',
      'title': 'Your Profile',
      'type': 'profile_setup',
    },
    {
      'id': 'complete',
      'title': 'All Set!',
      'type': 'completion',
    },
  ];

  // Onboarding steps configuration
  List<OnboardingStep> getOnboardingSteps() {
    return [
      OnboardingStep(
        botMessage: "Hey there! 👋 Welcome to Afeedi! I'm here to help you discover amazing content that matches your vibe. Ready to get started?",
        quickReplies: ["Let's do this! 🚀", "Tell me more 🤔", "I'm ready! ✨"],
        allowTextInput: true,
        inputPlaceholder: "Type your response or pick a quick reply...",
        key: 'welcome',
        stepTitle: 'Welcome to Afeedi',
        stepDescription: 'Let\'s get started on your personalized content journey!',
      ),
      OnboardingStep(
        botMessage: "Awesome! First, let's talk about what you love. What kind of content gets you excited? Pick as many as you like! 🎯",
        quickReplies: [],
        allowTextInput: false,
        isGenreSelection: true,
        allowMultiSelect: true,
        key: 'content_interests',
        stepTitle: 'Your Interests',
        stepDescription: 'Tell us what kind of content you love!',
      ),
      OnboardingStep(
        botMessage: "Perfect choices! 🎉 Now, let's connect your social accounts so I can find content that matches your vibe. Don't worry, we only read - never post!",
        quickReplies: [],
        allowTextInput: false,
        isPlatformSelection: true,
        showSkipOption: true,
        key: 'platform_preferences',
        stepTitle: 'Connect Platforms',
        stepDescription: 'Link your accounts for better recommendations',
      ),
      OnboardingStep(
        botMessage: "Amazing! 🌟 Tell me a bit about yourself - what's your name, and what kind of mood are you in for content today?",
        quickReplies: ["I'm feeling adventurous! 🌍", "Something chill and relaxing 😌", "Surprise me! 🎲"],
        allowTextInput: true,
        key: 'personal_info',
        stepTitle: 'Personal Information',
        stepDescription: 'Tell us a bit about yourself',
      ),
      OnboardingStep(
        botMessage: "Perfect! 🎊 You're all set! I've curated a personalized feed just for you. Ready to dive into some amazing content?",
        quickReplies: ["Let's go! 🚀", "Show me my feed! 📱"],
        allowTextInput: false,
        key: 'completion',
        stepTitle: 'All Set!',
        stepDescription: 'Your personalized feed is ready',
      ),
    ];
  }

  // Genre data
  List<Genre> getAllGenres() {
    return [
      Genre(name: 'Gaming', emoji: '🎮', category: 'Entertainment', keywords: ['gaming', 'esports', 'gameplay', 'streaming']),
      Genre(name: 'Music', emoji: '🎵', category: 'Entertainment', keywords: ['music', 'songs', 'artists', 'concerts']),
      Genre(name: 'Comedy', emoji: '😂', category: 'Entertainment', keywords: ['funny', 'humor', 'jokes', 'memes']),
      Genre(name: 'Food', emoji: '🍕', category: 'Lifestyle', keywords: ['cooking', 'recipes', 'restaurants', 'food']),
      Genre(name: 'Travel', emoji: '✈️', category: 'Lifestyle', keywords: ['travel', 'destinations', 'adventure', 'culture']),
      Genre(name: 'Fashion', emoji: '👗', category: 'Lifestyle', keywords: ['fashion', 'style', 'outfits', 'trends']),
      Genre(name: 'Fitness', emoji: '💪', category: 'Health', keywords: ['workout', 'fitness', 'health', 'exercise']),
      Genre(name: 'Technology', emoji: '📱', category: 'Education', keywords: ['tech', 'gadgets', 'innovation', 'science']),
      Genre(name: 'Art', emoji: '🎨', category: 'Creative', keywords: ['art', 'drawing', 'painting', 'creative']),
      Genre(name: 'Sports', emoji: '⚽', category: 'Entertainment', keywords: ['sports', 'football', 'basketball', 'soccer']),
      Genre(name: 'Movies', emoji: '🎬', category: 'Entertainment', keywords: ['movies', 'films', 'cinema', 'reviews']),
      Genre(name: 'Books', emoji: '📚', category: 'Education', keywords: ['books', 'reading', 'literature', 'authors']),
      Genre(name: 'Photography', emoji: '📸', category: 'Creative', keywords: ['photography', 'photos', 'camera', 'visual']),
      Genre(name: 'Dance', emoji: '💃', category: 'Entertainment', keywords: ['dance', 'choreography', 'movement', 'rhythm']),
      Genre(name: 'Nature', emoji: '🌿', category: 'Lifestyle', keywords: ['nature', 'outdoors', 'wildlife', 'environment']),
      Genre(name: 'Cars', emoji: '🚗', category: 'Lifestyle', keywords: ['cars', 'automotive', 'vehicles', 'racing']),
      Genre(name: 'Pets', emoji: '🐕', category: 'Lifestyle', keywords: ['pets', 'animals', 'dogs', 'cats']),
      Genre(name: 'DIY', emoji: '🔨', category: 'Creative', keywords: ['diy', 'crafts', 'handmade', 'projects']),
      Genre(name: 'Beauty', emoji: '💄', category: 'Lifestyle', keywords: ['beauty', 'makeup', 'skincare', 'cosmetics']),
      Genre(name: 'Education', emoji: '🎓', category: 'Education', keywords: ['learning', 'education', 'tutorials', 'knowledge']),
    ];
  }

  // Filter genres based on search query
  List<Genre> filterGenres(List<Genre> genres, String query) {
    if (query.isEmpty) return genres;
    
    final lowercaseQuery = query.toLowerCase();
    return genres.where((genre) {
      return genre.name.toLowerCase().contains(lowercaseQuery) ||
             genre.category.toLowerCase().contains(lowercaseQuery) ||
             genre.keywords.any((keyword) => keyword.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  // Generate contextual suggestions based on user input
  List<String> generateSuggestions(String input, List<Genre> selectedGenres) {
    final suggestions = <String>[];
    final lowercaseInput = input.toLowerCase();

    // Base suggestions
    if (lowercaseInput.contains('name') || lowercaseInput.contains('call')) {
      suggestions.addAll(['Alex', 'Sam', 'Jordan', 'Casey']);
    }
    
    if (lowercaseInput.contains('mood') || lowercaseInput.contains('feeling')) {
      suggestions.addAll([
        'Excited for new discoveries! 🌟',
        'Looking for something chill 😌',
        'Ready for an adventure! 🚀',
        'Surprise me with something unique! 🎲'
      ]);
    }

    // Genre-based suggestions
    for (final genre in selectedGenres) {
      switch (genre.name.toLowerCase()) {
        case 'gaming':
          suggestions.addAll(['I love competitive games', 'Indie games are my favorite', 'RPGs all the way!']);
          break;
        case 'music':
          suggestions.addAll(['I\'m into indie music', 'Pop music gets me going', 'Classical music relaxes me']);
          break;
        case 'food':
          suggestions.addAll(['I love trying new cuisines', 'Cooking is my passion', 'Street food adventures!']);
          break;
        case 'travel':
          suggestions.addAll(['Beach destinations are perfect', 'Mountain adventures call to me', 'City exploration excites me']);
          break;
      }
    }

    // Remove duplicates and limit to 4 suggestions
    return suggestions.toSet().take(4).toList();
  }

  // Validate onboarding completion
  bool isOnboardingComplete({
    required List<Genre> selectedGenres,
    required Map<String, bool> platformConnections,
    required String userName,
  }) {
    return selectedGenres.isNotEmpty && userName.trim().isNotEmpty;
  }

  // Generate personalized welcome message
  String generateWelcomeMessage({
    required String userName,
    required List<Genre> selectedGenres,
    required Map<String, bool> platformConnections,
  }) {
    final connectedPlatforms = platformConnections.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    final genreNames = selectedGenres.map((g) => g.name).join(', ');
    
    String message = "Welcome to Afeedi, $userName! 🎉\n\n";
    message += "I've curated content based on your interests: $genreNames.\n\n";
    
    if (connectedPlatforms.isNotEmpty) {
      message += "Connected platforms: ${connectedPlatforms.join(', ')}.\n\n";
    }
    
    message += "Your personalized feed is ready! Let's discover amazing content together! 🚀";
    
    return message;
  }

  // Save onboarding data (placeholder for actual implementation)
  Future<void> saveOnboardingData({
    required String userName,
    required List<Genre> selectedGenres,
    required Map<String, bool> platformConnections,
    required List<ChatMessage> chatHistory,
  }) async {
    // TODO: Implement actual data persistence
    // This could save to local storage, database, or API
    print('Saving onboarding data for $userName');
    print('Selected genres: ${selectedGenres.map((g) => g.name).join(', ')}');
    print('Platform connections: $platformConnections');
    print('Chat history: ${chatHistory.length} messages');
  }

  // Load saved onboarding data (placeholder for actual implementation)
  Future<Map<String, dynamic>?> loadOnboardingData() async {
    // TODO: Implement actual data loading
    // This could load from local storage, database, or API
    return null;
  }

  // Check if onboarding is completed
  Future<bool> isOnboardingCompleted() async {
    // TODO: Implement actual onboarding completion check
    // For now, return false to indicate onboarding is not completed
    final data = await loadOnboardingData();
    return data != null && data['completed'] == true;
  }

  // Get current user preferences
  Future<UserPreferences?> getCurrentPreferences() async {
    // TODO: Implement actual preferences loading
    // For now, return default preferences
    final data = await loadOnboardingData();
    if (data == null) return null;
    
    final preferences = data['preferences'] as Map<String, dynamic>?;
    if (preferences == null) return null;
    
    return UserPreferences(
      contentInterests: List<String>.from(preferences['selectedGenres'] ?? []),
      platformPriorities: Map<String, double>.from(preferences['platformConnections']?.map((k, v) => MapEntry(k, v == true ? 1.0 : 0.0)) ?? {}),
      name: preferences['userName'] ?? '',
    );
  }

  // Get user preferences (alias for getCurrentPreferences)
  Future<UserPreferences?> getUserPreferences() async {
    return getCurrentPreferences();
  }

  // Mark onboarding as complete
  Future<void> markOnboardingComplete() async {
    // TODO: Implement actual completion marking
    // For now, just save a completion flag
    final data = await loadOnboardingData() ?? {};
    data['completed'] = true;
    data['completedAt'] = DateTime.now().toIso8601String();
    await saveOnboardingData(
      userName: data['preferences']?['userName'] ?? '',
      selectedGenres: [],
      platformConnections: {},
      chatHistory: [],
    );
  }

  // Save user preferences
  Future<void> savePreferences(UserPreferences preferences) async {
    final data = await loadOnboardingData() ?? {};
    data['preferences'] = {
      'selectedGenres': preferences.contentInterests,
      'platformConnections': preferences.platformPriorities.map((k, v) => MapEntry(k, v > 0)),
      'userName': preferences.name ?? '',
    };
    // Save the updated data
    await saveOnboardingData(
      userName: preferences.name ?? '',
      selectedGenres: [],
      platformConnections: preferences.platformPriorities.map((k, v) => MapEntry(k, v > 0)),
      chatHistory: [],
    );
  }

  // Current step tracking
  int _currentStepIndex = 0;
  final List<bool> _completedSteps = [];

  // Get next onboarding step
  Map<String, dynamic>? getNextStep() {
    final steps = getOnboardingSteps();
    if (_currentStepIndex >= steps.length) return null;
    
    return {
      'id': _currentStepIndex,
      'title': 'Step ${_currentStepIndex + 1}',
      'step': steps[_currentStepIndex],
      'required': _currentStepIndex < 2, // First two steps are required
    };
  }

  // Complete a step
  Future<void> completeStep(int stepId, Map<String, dynamic> data) async {
    if (stepId >= 0 && stepId < getOnboardingSteps().length) {
      // Ensure the completed steps list is large enough
      while (_completedSteps.length <= stepId) {
        _completedSteps.add(false);
      }
      _completedSteps[stepId] = true;
      _currentStepIndex = stepId + 1;
      
      // TODO: Save step data
      print('Completed step $stepId with data: $data');
    }
  }

  // Skip a step
  Future<void> skipStep(int stepId) async {
    if (stepId >= 0 && stepId < getOnboardingSteps().length) {
      _currentStepIndex = stepId + 1;
      print('Skipped step $stepId');
    }
  }

  // Get onboarding progress
  double getProgress() {
    final totalSteps = getOnboardingSteps().length;
    if (totalSteps == 0) return 1.0;
    return _currentStepIndex / totalSteps;
  }

  // Reset onboarding
  void resetOnboarding() {
    _currentStepIndex = 0;
    _completedSteps.clear();
  }
}