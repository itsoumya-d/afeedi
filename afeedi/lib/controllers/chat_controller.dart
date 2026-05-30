import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../models/genre.dart';
import '../models/onboarding_step.dart';
import '../services/onboarding_service.dart';
import '../services/analytics_service.dart';
import '../services/navigation_service.dart';

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
  bool _showLanguagePicker = false;
  bool _showFinalButton = false;
  String? _selectedLanguage;
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
  bool get showLanguagePicker => _showLanguagePicker;
  String? get selectedLanguage => _selectedLanguage;
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

  Future<void> saveProgressDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('onboarding_draft_step', _currentStep);
    await prefs.setString('onboarding_draft_user_name', _userName);
    await prefs.setStringList('onboarding_draft_genres', _selectedGenres.map((g) => g.name).toList());
    await prefs.setString('onboarding_draft_saved_at', DateTime.now().toIso8601String());
  }

  Future<void> _resumeOrStartOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedAt = prefs.getString('onboarding_draft_saved_at');
      final draftStep = prefs.getInt('onboarding_draft_step');
      if (savedAt != null && draftStep != null && draftStep > 0) {
        final savedDate = DateTime.tryParse(savedAt);
        if (savedDate != null && DateTime.now().difference(savedDate).inDays < 7) {
          _currentStep = draftStep.clamp(0, _onboardingSteps.length - 1);
          _userName = prefs.getString('onboarding_draft_user_name') ?? '';
          final genreNames = prefs.getStringList('onboarding_draft_genres') ?? [];
          _selectedGenres = _allGenres.where((g) => genreNames.contains(g.name)).toList();
          Future.delayed(const Duration(milliseconds: 300), () {
            showBotMessage('Welcome back! Let\'s pick up where you left off. 👋');
            showStepOptions();
            notifyListeners();
          });
          return;
        }
      }
    } catch (_) {}
    startOnboarding();
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
    _showLanguagePicker = false;
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
    final currentStepData = _onboardingSteps[_currentStep];
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (currentStepData.isGenreSelection) {
        _showGenreSelection = true;
        _showTextInput = false;
      } else if (currentStepData.isPlatformSelection) {
        _showPlatformSelection = true;
        _showTextInput = false;
      } else if (currentStepData.isLanguageSelection) {
        _showLanguagePicker = true;
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
    
    switch (_currentStep) {
      case 0:
        _currentSuggestions = [
          'Hi there!',
          'Hello',
          'Let\'s get started',
          'I\'m ready'
        ];
        break;
      case 1:
        _currentSuggestions = [
          'My name is Alex',
          'Call me Sam',
          'I\'m Jordan'
        ];
        break;
      case 2:
        _currentSuggestions = [
          'I love comedy videos',
          'I enjoy educational content',
          'I like music and entertainment',
          'I prefer short funny clips'
        ];
        break;
      case 5:
        _currentSuggestions = [
          'Sounds great!',
          'I\'m excited to start',
          'Let\'s do this'
        ];
        break;
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
    _showLanguagePicker = false;
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
    final genreNames = _selectedGenres.map((g) => g.name).join(', ');
    addUserMessage('I\'m interested in: $genreNames');
    processUserInput('Selected ${_selectedGenres.length} genres');
  }

  Future<void> handleLanguageSelected(String name, String locale) async {
    _showLanguagePicker = false;
    _selectedLanguage = name;
    addUserMessage(name);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_locale', locale);
    await prefs.setString('onboarding_content_language', name);
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 800), () {
      _advanceStep();
    });
  }

  void _advanceStep() {
    _currentStep++;
    if (_currentStep < _onboardingSteps.length) {
      showBotMessage(_onboardingSteps[_currentStep].botMessage);
    } else {
      completeOnboarding();
    }
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
    if (_currentStep == 1 && input.isNotEmpty) {
      _userName = input;
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
    
    Future.delayed(const Duration(milliseconds: 500), () {
      _currentStep++;
      if (_currentStep < _onboardingSteps.length) {
        showBotMessage(_onboardingSteps[_currentStep].botMessage);
      } else {
        completeOnboarding();
      }
    });
  }

  void completeOnboarding() {
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
      },
    );

    _onboardingService.saveOnboardingData(
      userName: _userName,
      selectedGenres: _selectedGenres,
      platformConnections: _platformConnections,
      chatHistory: _messages,
    );

    final welcomeMessage = _onboardingService.generateWelcomeMessage(
      userName: _userName,
      selectedGenres: _selectedGenres,
      platformConnections: _platformConnections,
    );

    showBotMessage(welcomeMessage);
    
    _showFinalButton = true;
    notifyListeners();
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