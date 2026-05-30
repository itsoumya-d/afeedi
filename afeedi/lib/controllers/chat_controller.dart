import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../models/genre.dart';
import '../models/onboarding_step.dart';
import '../services/onboarding_service.dart';
import '../services/analytics_service.dart';
import '../services/notification_service.dart';

class ChatController extends ChangeNotifier {
  final OnboardingService _onboardingService = OnboardingService();
  final ScrollController scrollController = ScrollController();
  final TextEditingController textController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  final FocusNode textFocusNode = FocusNode();
  final FocusNode searchFocusNode = FocusNode();

  List<ChatMessage> _messages = [];
  List<String> _quickReplies = [];
  List<Genre> _selectedGenres = [];
  List<Genre> _filteredGenres = [];
  Map<String, bool> _platformConnections = {
    'YouTube': false,
    'Instagram': false,
    'TikTok': false,
    'Facebook': false,
    'Twitter': false,
  };
  
  int _currentStep = 0;
  bool _showTyping = false;
  bool _showQuickReplies = false;
  bool _showTextInput = false;
  bool _showGenreSelection = false;
  bool _showPlatformSelection = false;
  bool _showFinalButton = false;
  String _userName = '';
  List<String> _currentSuggestions = [];

  late List<OnboardingStep> _onboardingSteps;
  late List<Genre> _allGenres;

  // Getters
  List<ChatMessage> get messages => _messages;
  List<String> get quickReplies => _quickReplies;
  List<Genre> get selectedGenres => _selectedGenres;
  List<Genre> get filteredGenres => _filteredGenres;
  Map<String, bool> get platformConnections => _platformConnections;
  int get currentStep => _currentStep;
  bool get showTyping => _showTyping;
  bool get showQuickReplies => _showQuickReplies;
  bool get showTextInput => _showTextInput;
  bool get showGenreSelection => _showGenreSelection;
  bool get showPlatformSelection => _showPlatformSelection;
  bool get showFinalButton => _showFinalButton;
  String get userName => _userName;
  List<String> get currentSuggestions => _currentSuggestions;
  List<OnboardingStep> get onboardingSteps => _onboardingSteps;
  List<Genre> get allGenres => _allGenres;

  void initialize() {
    _onboardingSteps = _onboardingService.getOnboardingSteps();
    _allGenres = _onboardingService.getAllGenres();
    _filteredGenres = _allGenres;

    _initializeAnalytics();
    _resumeOrStartOnboarding();
  }

  Future<void> _resumeOrStartOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftStep = prefs.getInt('onboarding_draft_step') ?? 0;
      final draftName = prefs.getString('onboarding_draft_user_name') ?? '';
      final draftGenreNames = prefs.getStringList('onboarding_draft_genres') ?? [];
      final savedAt = prefs.getString('onboarding_draft_saved_at');

      bool shouldResume = false;
      if (draftStep > 0 && savedAt != null) {
        final savedDate = DateTime.tryParse(savedAt);
        if (savedDate != null && DateTime.now().difference(savedDate).inDays < 7) {
          shouldResume = true;
        }
      }

      if (shouldResume) {
        _currentStep = draftStep;
        _userName = draftName;
        if (draftGenreNames.isNotEmpty) {
          _selectedGenres = _allGenres
              .where((g) => draftGenreNames.contains(g.name))
              .toList();
        }
        Future.delayed(const Duration(milliseconds: 500), () {
          _messages.add(ChatMessage(
            text: 'Welcome back! Let\'s continue setting up your feed 👋',
            isBot: true,
            timestamp: DateTime.now(),
          ));
          notifyListeners();
          Future.delayed(const Duration(milliseconds: 600), () {
            if (_currentStep < _onboardingSteps.length) {
              showBotMessage(_onboardingSteps[_currentStep].botMessage);
            }
          });
        });
      } else {
        startOnboarding();
      }
    } catch (_) {
      startOnboarding();
    }
  }

  void _initializeAnalytics() {
    AnalyticsService.instance.trackOnboardingEvent(
      eventName: AnalyticsEvents.onboardingStarted,
      stepNumber: 0,
      stepName: 'welcome',
      additionalData: {
        'timestamp': DateTime.now().toIso8601String(),
        'total_steps': _onboardingSteps.length,
      },
    );
  }

  void startOnboarding() {
    Future.delayed(const Duration(milliseconds: 500), () {
      showBotMessage(_onboardingSteps[0].botMessage);
    });
  }

  void showBotMessage(String message) {
    _showTyping = true;
    _showQuickReplies = false;
    _showTextInput = false;
    _showGenreSelection = false;
    _showPlatformSelection = false;
    notifyListeners();

    scrollToBottom();

    Future.delayed(const Duration(milliseconds: 1500), () {
      _showTyping = false;
      _messages.add(ChatMessage(
        text: message,
        isBot: true,
        timestamp: DateTime.now(),
      ));
      notifyListeners();
      showStepOptions();
      scrollToBottom();
    });
  }

  void showStepOptions() {
    if (_currentStep >= _onboardingSteps.length) return;
    final currentStepData = _onboardingSteps[_currentStep];
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (currentStepData.isGenreSelection) {
        _showGenreSelection = true;
        _showTextInput = false;
      } else if (currentStepData.isPlatformSelection) {
        _showPlatformSelection = true;
        _showTextInput = false;
      } else {
        _quickReplies = currentStepData.quickReplies;
        _showQuickReplies = currentStepData.quickReplies.isNotEmpty;
        _showTextInput = true;
        updateSuggestions();
      }
      notifyListeners();
      scrollToBottom();
    });
  }

  void handleQuickReply(String reply) {
    addUserMessage(reply);
    processUserInput(reply);
  }

  void handleTextInput() {
    final text = textController.text.trim();
    if (text.isNotEmpty) {
      textController.clear();
      addUserMessage(text);
      processUserInput(text);
      updateSuggestions();
    }
  }

  void handleSuggestionTap(String suggestion) {
    textController.text = suggestion;
    handleTextInput();
  }

  void updateSuggestions() {
    if (_currentStep >= _onboardingSteps.length) return;
    final key = _onboardingSteps[_currentStep].key;
    switch (key) {
      case 'welcome':
        _currentSuggestions = ['Hi there!', 'Hello!', 'Let\'s go!', 'I\'m ready'];
      case 'viewing_frequency':
        _currentSuggestions = ['Watch daily', 'A few times a week', 'Mostly weekends', 'All the time!'];
      case 'content_goals':
        _currentSuggestions = ['Entertainment & fun', 'Learning new things', 'Stay on trends', 'Just to relax'];
      case 'content_language':
        _currentSuggestions = ['English', 'Hindi', 'Spanish', 'Mix of languages'];
      case 'personal_info':
        _currentSuggestions = ['Alex', 'Sam', 'Jordan', 'Casey'];
      case 'completion':
        _currentSuggestions = ['So excited!', 'Let\'s do this', 'Can\'t wait!'];
      default:
        _currentSuggestions = [];
    }
    notifyListeners();
  }

  void addUserMessage(String text) {
    _messages.add(ChatMessage(
      text: text,
      isBot: false,
      timestamp: DateTime.now(),
    ));
    _showQuickReplies = false;
    _showTextInput = false;
    _showGenreSelection = false;
    _showPlatformSelection = false;
    notifyListeners();
    scrollToBottom();
  }

  void handleGenreToggle(Genre genre) {
    if (_selectedGenres.contains(genre)) {
      _selectedGenres.remove(genre);
    } else {
      _selectedGenres.add(genre);
    }
    notifyListeners();
  }

  void handleGenreSearchChanged(String query) {
    _filteredGenres = _onboardingService.filterGenres(_allGenres, query);
    notifyListeners();
  }

  void handleGenreContinue() {
    if (_selectedGenres.length < 3) {
      showBotMessage('Please pick at least 3 genres so I can build your perfect feed! You\'ve selected ${_selectedGenres.length} so far.');
      return;
    }
    final genreNames = _selectedGenres.map((g) => g.name).join(', ');
    addUserMessage('I\'m interested in: $genreNames');
    processUserInput('Selected ${_selectedGenres.length} genres');
  }

  void handlePlatformConnect(String platform) {
    _platformConnections[platform] = !(_platformConnections[platform] ?? false);
    notifyListeners();
  }

  void handlePlatformSkip() {
    addUserMessage('I\'ll connect platforms later');
    processUserInput('Skipped platform connections');
  }

  void handlePlatformContinue() {
    final connectedPlatforms = _platformConnections.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
    
    final message = connectedPlatforms.isNotEmpty
        ? 'Connected: ${connectedPlatforms.join(', ')}'
        : 'I\'ll connect platforms later';
    
    addUserMessage(message);
    processUserInput('Platform selection completed');
  }

  void processUserInput(String input) {
    if (_currentStep < _onboardingSteps.length &&
        _onboardingSteps[_currentStep].key == 'content_language') {
      // Map common language names to locale codes
      final lowerInput = input.toLowerCase();
      String? localeCode;
      if (lowerInput.contains('hindi') || lowerInput.contains('हिंदी')) {
        localeCode = 'hi';
      } else if (lowerInput.contains('spanish') || lowerInput.contains('español')) {
        localeCode = 'es';
      } else if (lowerInput.contains('french') || lowerInput.contains('français')) {
        localeCode = 'fr';
      } else if (lowerInput.contains('german') || lowerInput.contains('deutsch')) {
        localeCode = 'de';
      } else if (lowerInput.contains('arabic') || lowerInput.contains('عربى')) {
        localeCode = 'ar';
      } else if (lowerInput.contains('portuguese') || lowerInput.contains('português')) {
        localeCode = 'pt';
      } else if (lowerInput.contains('japanese') || lowerInput.contains('日本語')) {
        localeCode = 'ja';
      } else if (lowerInput.contains('korean') || lowerInput.contains('한국어')) {
        localeCode = 'ko';
      } else if (lowerInput.contains('chinese') || lowerInput.contains('中文')) {
        localeCode = 'zh';
      } else if (lowerInput.contains('indonesian') || lowerInput.contains('bahasa')) {
        localeCode = 'id';
      } else if (lowerInput.contains('russian') || lowerInput.contains('русский')) {
        localeCode = 'ru';
      } else {
        localeCode = 'en';
      }
      // Save locale preference and switch app language
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('app_locale', localeCode!);
        prefs.setString('onboarding_content_language', input);
      });
    }

    if (_currentStep < _onboardingSteps.length &&
        _onboardingSteps[_currentStep].key == 'personal_info' &&
        input.isNotEmpty &&
        input != 'Skip for now') {
      _userName = input;
    }

    // Save responses for all collected steps
    switch (_currentStep < _onboardingSteps.length
        ? _onboardingSteps[_currentStep].key
        : '') {
      case 'viewing_frequency':
        SharedPreferences.getInstance().then((prefs) {
          prefs.setString('user_viewing_frequency', input);
        });
      case 'content_duration':
        SharedPreferences.getInstance().then((prefs) {
          prefs.setString('user_content_duration', input);
        });
      case 'content_goals':
        SharedPreferences.getInstance().then((prefs) {
          prefs.setString('user_content_goals', input);
        });
      case 'creator_style':
        SharedPreferences.getInstance().then((prefs) {
          prefs.setString('user_creator_style', input);
        });
      case 'viewing_time':
        SharedPreferences.getInstance().then((prefs) {
          prefs.setString('user_viewing_time', input);
          // Also save as a scheduled notification time hint
          final hour = _parseViewingTimeToHour(input);
          if (hour != null) prefs.setInt('preferred_notification_hour', hour);
        });
      case 'notifications':
        SharedPreferences.getInstance().then((prefs) {
          prefs.setString('user_notification_preference', input);
        });
    }

    AnalyticsService.instance.trackOnboardingEvent(
      eventName: AnalyticsEvents.onboardingStepCompleted,
      stepNumber: _currentStep,
      stepName: _currentStep < _onboardingSteps.length ? 'step_${_currentStep + 1}' : 'final_step',
      additionalData: {
        'user_input': input.length > 50 ? '${input.substring(0, 50)}...' : input,
        'input_length': input.length,
      },
    );
    
    Future.delayed(const Duration(milliseconds: 500), () async {
      _currentStep++;
      if (_currentStep < _onboardingSteps.length) {
        showBotMessage(_onboardingSteps[_currentStep].botMessage);
      } else {
        await completeOnboarding();
      }
    });
  }

  Future<void> saveProgressDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('onboarding_draft_step', _currentStep);
      await prefs.setString('onboarding_draft_user_name', _userName);
      await prefs.setStringList(
        'onboarding_draft_genres',
        _selectedGenres.map((g) => g.name).toList(),
      );
      await prefs.setString(
        'onboarding_draft_saved_at',
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      debugPrint('saveProgressDraft error: $e');
    }
  }

  Future<void> completeOnboarding() async {
    final _completionPrefs = await SharedPreferences.getInstance();
    AnalyticsService.instance.trackOnboardingEvent(
      eventName: AnalyticsEvents.onboardingCompleted,
      stepNumber: _currentStep,
      stepName: 'completed',
      additionalData: {
        'total_steps': _onboardingSteps.length,
        'connected_platforms': _platformConnections.values.where((v) => v).length,
        'selected_genres': _selectedGenres.length,
        'completion_time': DateTime.now().toIso8601String(),
        'user_name': _userName,
        'viewing_frequency': _completionPrefs.getString('user_viewing_frequency') ?? '',
        'content_goals': _completionPrefs.getString('user_content_goals') ?? '',
        'viewing_time': _completionPrefs.getString('user_viewing_time') ?? '',
      },
    );

    try {
      await _onboardingService.saveOnboardingData(
        userName: _userName,
        selectedGenres: _selectedGenres,
        platformConnections: _platformConnections,
        chatHistory: _messages,
      );
    } catch (e) {
      debugPrint('Onboarding save error: $e');
      // Don't block user - continue with partial data
    }

    // Schedule personalized notifications based on selected genres
    NotificationService.instance
        .schedulePersonalizedNotifications()
        .catchError((e) => debugPrint('Notification schedule error: $e'));

    final welcomeMessage = _onboardingService.generateWelcomeMessage(
      userName: _userName,
      selectedGenres: _selectedGenres,
      platformConnections: _platformConnections,
    );

    showBotMessage(welcomeMessage);
    
    _showFinalButton = true;
    notifyListeners();
  }

  int? _parseViewingTimeToHour(String input) {
    final lower = input.toLowerCase();
    if (lower.contains('morning') || lower.contains('☀️')) return 8;
    if (lower.contains('afternoon') || lower.contains('🌤️')) return 14;
    if (lower.contains('evening') || lower.contains('🌆')) return 19;
    if (lower.contains('night') || lower.contains('🌙')) return 22;
    return null;
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    textController.dispose();
    searchController.dispose();
    textFocusNode.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }
}

// Analytics Events Constants
class AnalyticsEvents {
  static const String onboardingStarted = 'onboarding_started';
  static const String onboardingStepCompleted = 'onboarding_step_completed';
  static const String onboardingCompleted = 'onboarding_completed';
}