import '../models/chat_message.dart';
import '../models/genre.dart';

class SmartSuggestionsService {
  static const Map<int, List<String>> _stepBasedSuggestions = {
    0: [
      // Welcome step
      'Hi there!',
      'Hello',
      'Let\'s get started',
      'I\'m ready',
      'Good to meet you',
      'Excited to begin',
    ],
    1: [
      // Name step
      'My name is Alex',
      'Call me Sam',
      'I\'m Jordan',
      'You can call me Chris',
      'My friends call me Taylor',
      'I go by Morgan',
    ],
    2: [
      // Preferences step
      'I love comedy videos',
      'I enjoy educational content',
      'I like music and entertainment',
      'I prefer short funny clips',
      'I\'m into tech reviews',
      'I enjoy cooking shows',
      'I like travel vlogs',
      'I\'m interested in fitness content',
    ],
    3: [
      // Genre selection follow-up
      'That sounds perfect',
      'I\'d like to explore more',
      'Can you recommend similar content?',
      'What else do you suggest?',
    ],
    4: [
      // Platform connection
      'I\'d like to connect my accounts',
      'Let me link my social media',
      'I\'ll connect these later',
      'Skip for now',
    ],
    5: [
      // Final step
      'Sounds great!',
      'I\'m excited to start',
      'Let\'s do this',
      'Perfect, let\'s begin',
      'Can\'t wait to explore',
    ],
  };

  static const Map<String, List<String>> _contextualSuggestions = {
    'greeting': ['Hello!', 'Hi there!', 'Good to meet you', 'Nice to see you'],
    'name': ['My name is', 'Call me', 'I\'m', 'You can call me'],
    'preferences': [
      'I love',
      'I enjoy',
      'I\'m interested in',
      'I prefer',
      'I like watching',
    ],
    'positive': [
      'That sounds great!',
      'Perfect!',
      'Awesome!',
      'I love it!',
      'Exactly what I wanted',
    ],
    'question': [
      'Can you tell me more?',
      'What do you recommend?',
      'How does this work?',
      'What\'s next?',
    ],
  };

  static const List<String> _popularGenreSuggestions = [
    'I love comedy and humor',
    'Educational content is my favorite',
    'Music and entertainment videos',
    'Gaming and tech reviews',
    'Cooking and food content',
    'Travel and adventure vlogs',
    'Fitness and health tips',
    'DIY and crafting tutorials',
  ];

  /// Get suggestions based on the current onboarding step
  static List<String> getSuggestionsForStep(int step) {
    return _stepBasedSuggestions[step] ?? [];
  }

  /// Get contextual suggestions based on conversation history
  static List<String> getContextualSuggestions({
    required int currentStep,
    required List<ChatMessage> chatHistory,
    String? currentInput,
  }) {
    final suggestions = <String>[];

    // Add step-based suggestions
    suggestions.addAll(getSuggestionsForStep(currentStep));

    // Add context-aware suggestions based on chat history
    if (chatHistory.isNotEmpty) {
      final lastBotMessage = chatHistory.where((msg) => msg.isBot).lastOrNull;

      if (lastBotMessage != null) {
        suggestions.addAll(_getResponseSuggestions(lastBotMessage.text));
      }
    }

    // Add input-based suggestions
    if (currentInput != null && currentInput.isNotEmpty) {
      suggestions.addAll(_getInputBasedSuggestions(currentInput));
    }

    // Remove duplicates and limit to 6 suggestions
    return suggestions.toSet().take(6).toList();
  }

  /// Get smart suggestions based on user's selected genres
  static List<String> getGenreBasedSuggestions(List<Genre> selectedGenres) {
    if (selectedGenres.isEmpty) {
      return _popularGenreSuggestions;
    }

    final suggestions = <String>[];

    for (final genre in selectedGenres) {
      switch (genre.name.toLowerCase()) {
        case 'comedy':
          suggestions.addAll([
            'I love stand-up comedy',
            'Funny skits and pranks',
            'Comedy movie reviews',
          ]);
          break;
        case 'education':
          suggestions.addAll([
            'Science and technology',
            'History documentaries',
            'Language learning content',
          ]);
          break;
        case 'music':
          suggestions.addAll([
            'Music videos and concerts',
            'Artist interviews',
            'Music production tutorials',
          ]);
          break;
        case 'gaming':
          suggestions.addAll([
            'Game reviews and walkthroughs',
            'Esports tournaments',
            'Gaming news and updates',
          ]);
          break;
        default:
          suggestions.add('More ${genre.name.toLowerCase()} content');
      }
    }

    return suggestions.take(6).toList();
  }

  /// Get suggestions that help users express their preferences
  static List<String> getPreferenceSuggestions() {
    return [
      'I prefer short videos (under 5 minutes)',
      'I like longer, in-depth content',
      'I enjoy interactive content',
      'I prefer educational material',
      'I like entertaining and funny content',
      'I\'m interested in trending topics',
    ];
  }

  /// Get suggestions for platform connection step
  static List<String> getPlatformSuggestions(Map<String, bool> connections) {
    final connectedCount = connections.values.where((v) => v).length;

    if (connectedCount == 0) {
      return [
        'Let me connect my YouTube account',
        'I\'d like to link Instagram',
        'Connect my TikTok profile',
        'I\'ll set this up later',
      ];
    } else {
      return [
        'That\'s all for now',
        'Let me add one more platform',
        'Perfect, let\'s continue',
        'I\'m ready to proceed',
      ];
    }
  }

  static List<String> _getResponseSuggestions(String botMessage) {
    final message = botMessage.toLowerCase();

    if (message.contains('name') || message.contains('call')) {
      return _contextualSuggestions['name'] ?? [];
    } else if (message.contains('prefer') ||
        message.contains('like') ||
        message.contains('interest')) {
      return _contextualSuggestions['preferences'] ?? [];
    } else if (message.contains('question') || message.contains('help')) {
      return _contextualSuggestions['question'] ?? [];
    } else if (message.contains('great') ||
        message.contains('perfect') ||
        message.contains('awesome')) {
      return _contextualSuggestions['positive'] ?? [];
    }

    return [];
  }

  static List<String> _getInputBasedSuggestions(String input) {
    final inputLower = input.toLowerCase();
    final suggestions = <String>[];

    if (inputLower.contains('i like') || inputLower.contains('i love')) {
      suggestions.addAll([
        '${input} and similar content',
        '${input} especially on weekends',
        '${input} when I have free time',
      ]);
    } else if (inputLower.contains('my name')) {
      suggestions.addAll([
        'Nice to meet you!',
        'That\'s a great name',
        'Pleasure to meet you',
      ]);
    }

    return suggestions;
  }

  /// Generate dynamic suggestions based on time of day
  static List<String> getTimeBasedSuggestions() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return [
        'Good morning!',
        'Ready to start the day',
        'Let\'s begin this morning',
      ];
    } else if (hour < 17) {
      return ['Good afternoon!', 'Perfect timing', 'Let\'s continue'];
    } else {
      return ['Good evening!', 'Great time to explore', 'Let\'s get started'];
    }
  }

  /// Combine multiple suggestion sources intelligently
  static List<String> getCombinedSuggestions({
    required int currentStep,
    required List<ChatMessage> chatHistory,
    List<Genre>? selectedGenres,
    Map<String, bool>? platformConnections,
    String? currentInput,
  }) {
    final allSuggestions = <String>[];

    // Primary suggestions based on step
    allSuggestions.addAll(getSuggestionsForStep(currentStep));

    // Contextual suggestions
    allSuggestions.addAll(
      getContextualSuggestions(
        currentStep: currentStep,
        chatHistory: chatHistory,
        currentInput: currentInput,
      ),
    );

    // Genre-based suggestions if applicable
    if (selectedGenres != null && selectedGenres.isNotEmpty) {
      allSuggestions.addAll(getGenreBasedSuggestions(selectedGenres));
    }

    // Platform suggestions if applicable
    if (platformConnections != null) {
      allSuggestions.addAll(getPlatformSuggestions(platformConnections));
    }

    // Time-based suggestions
    allSuggestions.addAll(getTimeBasedSuggestions());

    // Remove duplicates, prioritize by relevance, and limit
    return _prioritizeAndLimit(allSuggestions, currentStep);
  }

  static List<String> _prioritizeAndLimit(List<String> suggestions, int step) {
    final uniqueSuggestions = suggestions.toSet().toList();

    // Prioritize step-specific suggestions
    final stepSuggestions = getSuggestionsForStep(step);
    final prioritized = <String>[];

    // Add step-specific suggestions first
    for (final suggestion in stepSuggestions) {
      if (uniqueSuggestions.contains(suggestion)) {
        prioritized.add(suggestion);
      }
    }

    // Add remaining suggestions
    for (final suggestion in uniqueSuggestions) {
      if (!prioritized.contains(suggestion) && prioritized.length < 6) {
        prioritized.add(suggestion);
      }
    }

    return prioritized.take(6).toList();
  }
}

extension on Iterable<ChatMessage> {
  ChatMessage? get lastOrNull {
    return isEmpty ? null : last;
  }
}
