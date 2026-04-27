import 'package:flutter/material.dart';
import '../../models/onboarding_step.dart';
import '../../models/genre.dart';
import '../../models/chat_message.dart';
import '../../services/analytics_service.dart';
import '../../services/smart_suggestions_service.dart';
import '../../utils/constants.dart';
import '../../utils/debouncer.dart';

class ChatController extends ChangeNotifier {
  final List<OnboardingStep> onboardingSteps;
  final List<Genre> allGenres;
  final Map<String, bool> platformConnections;
  final Function(int, String, Map<String, dynamic>)? onStepCompleted;
  final Function(Map<String, dynamic>)? onOnboardingCompleted;

  ChatController({
    required this.onboardingSteps,
    required this.allGenres,
    required this.platformConnections,
    this.onStepCompleted,
    this.onOnboardingCompleted,
  });

  // State variables
  List<ChatMessage> _messages = [];
  List<String> _quickReplies = [];
  List<String> _currentSuggestions = [];
  List<Genre> _filteredGenres = [];
  Set<String> _selectedGenres = {};
  int _currentStep = 0;
  bool _showTyping = false;
  bool _showQuickReplies = false;
  bool _showTextInput = false;
  bool _showGenreSelection = false;
  bool _showPlatformSelection = false;
  bool _showFinalButton = false;
  String _userName = '';
  final Debouncer _searchDebouncer = Debouncer(milliseconds: 300);

  // Getters
  List<ChatMessage> get messages => _messages;
  List<String> get quickReplies => _quickReplies;
  List<String> get currentSuggestions => _currentSuggestions;
  List<Genre> get filteredGenres => _filteredGenres;
  Set<String> get selectedGenres => _selectedGenres;
  int get currentStep => _currentStep;
  bool get showTyping => _showTyping;
  bool get showQuickReplies => _showQuickReplies;
  bool get showTextInput => _showTextInput;
  bool get showGenreSelection => _showGenreSelection;
  bool get showPlatformSelection => _showPlatformSelection;
  bool get showFinalButton => _showFinalButton;
  String get userName => _userName;

  void initializeAnalytics() {
    AnalyticsService.instance.trackOnboardingEvent(
      eventName: AnalyticsEvents.onboardingStarted,
      stepNumber: 0,
      stepName: 'welcome',
      additionalData: {
        'timestamp': DateTime.now().toIso8601String(),
        'total_steps': onboardingSteps.length,
      },
    );
  }

  void startOnboarding() {
    _showBotMessage(onboardingSteps[0].botMessage);
  }

  void _showBotMessage(String message) {
    _showTyping = true;
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 1500), () {
      _showTyping = false;
      _messages.add(
        ChatMessage(text: message, isBot: true, timestamp: DateTime.now()),
      );
      notifyListeners();

      // Show appropriate UI based on current step
      _showStepUI();
    });
  }

  void _showStepUI() {
    if (_currentStep < onboardingSteps.length) {
      final step = onboardingSteps[_currentStep];

      Future.delayed(const Duration(milliseconds: 500), () {
        if (step.quickReplies.isNotEmpty) {
          _quickReplies = step.quickReplies;
          _showQuickReplies = true;
        } else {
          _showTextInput = true;
        }
        notifyListeners();
      });
    }
  }

  void handleQuickReply(String reply) {
    _addUserMessage(reply);
    _showQuickReplies = false;
    _processUserInput(reply);
  }

  void handleTextInput(String input) {
    if (input.trim().isEmpty) return;

    _addUserMessage(input);
    _showTextInput = false;
    _processUserInput(input);
  }

  void _addUserMessage(String text) {
    _messages.add(
      ChatMessage(text: text, isBot: false, timestamp: DateTime.now()),
    );
    notifyListeners();
  }

  void _processUserInput(String input) {
    final step = onboardingSteps[_currentStep];

    // Track step completion
    onStepCompleted?.call(_currentStep + 1, 'step_${_currentStep + 1}', {
      'user_input': input,
      'step_type': 'onboarding_step',
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Handle specific step logic based on current step
    if (_currentStep == 0) {
      _userName = input;
    } else if (step.isGenreSelection) {
      _showGenreSelection = true;
      _filteredGenres = allGenres;
      notifyListeners();
      return;
    } else if (step.isPlatformSelection) {
      _showPlatformSelection = true;
      notifyListeners();
      return;
    } else if (_currentStep == onboardingSteps.length - 1) {
      _completeOnboarding();
      return;
    }

    _moveToNextStep();
  }

  void handleGenreToggle(String genreId) {
    if (_selectedGenres.contains(genreId)) {
      _selectedGenres.remove(genreId);
    } else {
      _selectedGenres.add(genreId);
    }
    notifyListeners();
  }

  void handleGenreSearchChanged(String query) {
    _searchDebouncer.run(() {
      // BOLT OPTIMIZATION: Debounce search input to reduce unnecessary filtering and re-renders
      // Expected impact: Smoother typing experience and reduced CPU usage during search.
      if (query.isEmpty) {
        _filteredGenres = allGenres;
      } else {
        _filteredGenres = allGenres
            .where(
              (genre) => genre.name.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
      notifyListeners();
    });
  }

  void handleGenreContinue() {
    _showGenreSelection = false;
    _addUserMessage('Selected ${_selectedGenres.length} genres');
    _moveToNextStep();
  }

  void handlePlatformConnect(String platform) {
    platformConnections[platform] = true;
    notifyListeners();
  }

  void handlePlatformSkip() {
    _showPlatformSelection = false;
    _addUserMessage('Skipped platform connections');
    _moveToNextStep();
  }

  void handlePlatformContinue() {
    _showPlatformSelection = false;
    final connectedCount = platformConnections.values
        .where((connected) => connected)
        .length;
    _addUserMessage('Connected $connectedCount platforms');
    _moveToNextStep();
  }

  void _moveToNextStep() {
    _currentStep++;

    if (_currentStep < onboardingSteps.length) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        _showBotMessage(onboardingSteps[_currentStep].botMessage);
      });
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() {
    _showFinalButton = true;
    notifyListeners();

    final completionData = {
      'user_name': _userName,
      'selected_genres': _selectedGenres.toList(),
      'platform_connections': platformConnections,
      'chat_history': _messages
          .map(
            (m) => {
              'text': m.text,
              'is_user': !m.isBot,
              'timestamp': m.timestamp.toIso8601String(),
            },
          )
          .toList(),
      'total_steps': onboardingSteps.length,
      'completion_time': DateTime.now().toIso8601String(),
    };

    onOnboardingCompleted?.call(completionData);
  }

  void updateSuggestions(List<String> suggestions) {
    _currentSuggestions = suggestions;
    notifyListeners();
  }

  @override
  void dispose() {
    _searchDebouncer.cancel();
    super.dispose();
  }
}
