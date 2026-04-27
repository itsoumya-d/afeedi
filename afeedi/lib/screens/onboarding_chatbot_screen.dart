import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/navigation_service.dart';
import '../services/analytics_service.dart';
import '../services/onboarding_service.dart';
import '../models/chat_message.dart';
import '../models/genre.dart';
import '../models/onboarding_step.dart';
import '../widgets/onboarding/chat_message_widget.dart';
import '../widgets/onboarding/typing_indicator.dart';
import '../widgets/onboarding/quick_reply_chips.dart';
import '../widgets/onboarding/genre_selection.dart';
import '../widgets/onboarding/platform_connection.dart';
import '../widgets/onboarding/text_input_widget.dart';
import '../widgets/chat/chat_controller.dart';
import '../widgets/chat/chat_interface.dart';
import '../utils/debouncer.dart';

class OnboardingChatbotScreen extends StatefulWidget {
  const OnboardingChatbotScreen({super.key});

  @override
  State<OnboardingChatbotScreen> createState() =>
      _OnboardingChatbotScreenState();
}

class _OnboardingChatbotScreenState extends State<OnboardingChatbotScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final OnboardingService _onboardingService = OnboardingService();
  late ChatController _chatController;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _typingController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _typingAnimation;

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
  final Debouncer _searchDebouncer = Debouncer(milliseconds: 300);
  List<String> _currentSuggestions = [];

  late List<OnboardingStep> _onboardingSteps;
  late List<Genre> _allGenres;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _initializeAnalytics();
    _initializeAnimations();
    _initializeChatController();
    _preloadResources();
    _startOnboarding();
  }

  void _initializeChatController() {
    _chatController = ChatController(
      onboardingSteps: _onboardingSteps,
      allGenres: _allGenres,
      platformConnections: _platformConnections,
      onStepCompleted: _handleStepCompleted,
      onOnboardingCompleted: _handleOnboardingCompleted,
    );
  }

  void _initializeData() {
    _onboardingSteps = _onboardingService.getOnboardingSteps();
    _allGenres = _onboardingService.getAllGenres();
    _filteredGenres = _allGenres;
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

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _typingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
    _typingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _typingController, curve: Curves.easeInOut),
    );
  }

  Future<void> _preloadResources() async {
    try {
      await Future.wait([
        precacheImage(
          const AssetImage('assets/images/afeedi_logo.png'),
          context,
        ),
        precacheImage(
          const AssetImage('assets/images/onboarding_bg.jpg'),
          context,
        ),
      ]);
    } catch (e) {
      debugPrint('Error preloading resources: $e');
    }
  }

  @override
  void dispose() {
    _searchDebouncer.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    _typingController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _chatController.dispose();
    super.dispose();
  }

  void _startOnboarding() {
    Future.delayed(const Duration(milliseconds: 500), () {
      _chatController.startOnboarding();
    });
  }

  void _handleStepCompleted(
    int stepNumber,
    String stepName,
    Map<String, dynamic> data,
  ) {
    AnalyticsService.instance.trackOnboardingEvent(
      eventName: AnalyticsEvents.onboardingStepCompleted,
      stepNumber: stepNumber,
      stepName: stepName,
      additionalData: data,
    );
  }

  void _handleOnboardingCompleted(Map<String, dynamic> data) {
    AnalyticsService.instance.trackOnboardingEvent(
      eventName: AnalyticsEvents.onboardingCompleted,
      stepNumber: data['total_steps'] ?? 0,
      stepName: 'completed',
      additionalData: data,
    );

    // Save onboarding data
    _onboardingService.saveOnboardingData(
      userName: data['user_name'] ?? '',
      selectedGenres: data['selected_genres'] ?? [],
      platformConnections: data['platform_connections'] ?? {},
      chatHistory: data['chat_history'] ?? [],
    );

    // Navigate to dashboard
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      }
    });
  }

  void _showBotMessage(String message) {
    setState(() {
      _showTyping = true;
      _showQuickReplies = false;
      _showTextInput = false;
      _showGenreSelection = false;
      _showPlatformSelection = false;
    });

    _typingController.repeat();
    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _typingController.stop();
        setState(() {
          _showTyping = false;
          _messages.add(
            ChatMessage(text: message, isBot: true, timestamp: DateTime.now()),
          );
        });
        _fadeController.forward();
        _showStepOptions();
        _scrollToBottom();
      }
    });
  }

  void _showStepOptions() {
    final currentStep = _onboardingSteps[_currentStep];

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          if (currentStep.showGenreSelection) {
            _showGenreSelection = true;
            _showTextInput = false; // Hide text input during genre selection
          } else if (currentStep.showPlatformSelection) {
            _showPlatformSelection = true;
            _showTextInput = false; // Hide text input during platform selection
          } else {
            _quickReplies = currentStep.quickReplies;
            _showQuickReplies = currentStep.quickReplies.isNotEmpty;
            _showTextInput = true; // Always show text input for regular steps
            _updateSuggestions(); // Update suggestions for the current step
          }
        });
        _slideController.forward();
        _scrollToBottom();
      }
    });
  }

  void _handleQuickReply(String reply) {
    _addUserMessage(reply);
    _processUserInput(reply);
  }

  void _handleTextInput() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      _textController.clear();
      _addUserMessage(text);
      _processUserInput(text);
      _updateSuggestions();
    }
  }

  void _handleSuggestionTap(String suggestion) {
    _textController.text = suggestion;
    _handleTextInput();
  }

  void _updateSuggestions() {
    if (_currentStep >= _onboardingSteps.length) return;

    final currentStep = _onboardingSteps[_currentStep];

    setState(() {
      switch (_currentStep) {
        case 0: // Welcome step
          _currentSuggestions = [
            'Hi there!',
            'Hello',
            'Let\'s get started',
            'I\'m ready',
          ];
          break;
        case 1: // Name step
          _currentSuggestions = [
            'My name is Alex',
            'Call me Sam',
            'I\'m Jordan',
          ];
          break;
        case 2: // Preferences step
          _currentSuggestions = [
            'I love comedy videos',
            'I enjoy educational content',
            'I like music and entertainment',
            'I prefer short funny clips',
          ];
          break;
        case 5: // Final step
          _currentSuggestions = [
            'Sounds great!',
            'I\'m excited to start',
            'Let\'s do this',
          ];
          break;
        default:
          _currentSuggestions = [];
      }
    });
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(
        ChatMessage(text: text, isBot: false, timestamp: DateTime.now()),
      );
      _showQuickReplies = false;
      _showTextInput = false;
      _showGenreSelection = false;
      _showPlatformSelection = false;
    });
    _scrollToBottom();
  }

  void _handleGenreToggle(Genre genre) {
    setState(() {
      if (_selectedGenres.contains(genre)) {
        _selectedGenres.remove(genre);
      } else {
        _selectedGenres.add(genre);
      }
    });
  }

  void _handleGenreSearchChanged(String query) {
    _searchDebouncer.run(() {
      // BOLT OPTIMIZATION: Debounce search input to reduce unnecessary filtering and re-renders
      // Expected impact: Smoother typing experience and reduced CPU usage during search.
      setState(() {
        _filteredGenres = _onboardingService.filterGenres(_allGenres, query);
      });
    });
  }

  void _handleGenreContinue() {
    final genreNames = _selectedGenres.map((g) => g.name).join(', ');
    _addUserMessage('I\'m interested in: $genreNames');
    _processUserInput('Selected ${_selectedGenres.length} genres');
  }

  void _handlePlatformConnect(String platform) {
    setState(() {
      _platformConnections[platform] =
          !(_platformConnections[platform] ?? false);
    });
  }

  void _handlePlatformSkip() {
    _addUserMessage('I\'ll connect platforms later');
    _processUserInput('Skipped platform connections');
  }

  void _handlePlatformContinue() {
    final connectedPlatforms = _platformConnections.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    final message = connectedPlatforms.isNotEmpty
        ? 'Connected: ${connectedPlatforms.join(', ')}'
        : 'I\'ll connect platforms later';

    _addUserMessage(message);
    _processUserInput('Platform selection completed');
  }

  void _processUserInput(String input) {
    // Store user name if this is the name step
    if (_currentStep == 1 && input.isNotEmpty) {
      _userName = input;
    }

    // Track step completion
    AnalyticsService.instance.trackOnboardingEvent(
      eventName: AnalyticsEvents.onboardingStepCompleted,
      stepNumber: _currentStep,
      stepName: _currentStep < _onboardingSteps.length
          ? 'step_${_currentStep + 1}'
          : 'final_step',
      additionalData: {
        'user_input': input.length > 50
            ? '${input.substring(0, 50)}...'
            : input,
        'input_length': input.length,
      },
    );

    _fadeController.reset();
    _slideController.reset();

    Future.delayed(const Duration(milliseconds: 500), () {
      _currentStep++;
      if (_currentStep < _onboardingSteps.length) {
        _showBotMessage(_onboardingSteps[_currentStep].botMessage);
      } else {
        _completeOnboarding();
      }
    });
  }

  void _completeOnboarding() {
    // Track onboarding completion
    AnalyticsService.instance.trackOnboardingEvent(
      eventName: AnalyticsEvents.onboardingCompleted,
      stepNumber: _currentStep,
      stepName: 'completed',
      additionalData: {
        'total_steps': _onboardingSteps.length,
        'connected_platforms': _platformConnections.values
            .where((v) => v)
            .length,
        'selected_genres': _selectedGenres.length,
        'completion_time': DateTime.now().toIso8601String(),
        'user_name': _userName,
      },
    );

    // Save onboarding data
    _onboardingService.saveOnboardingData(
      userName: _userName,
      selectedGenres: _selectedGenres,
      platformConnections: _platformConnections,
      chatHistory: _messages,
    );

    // Show completion message
    final welcomeMessage = _onboardingService.generateWelcomeMessage(
      userName: _userName,
      selectedGenres: _selectedGenres,
      platformConnections: _platformConnections,
    );

    _showBotMessage(welcomeMessage);

    setState(() {
      _showFinalButton = true;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: ChatInterface(
                  controller: _chatController,
                  scrollController: _scrollController,
                  fadeAnimation: _fadeAnimation,
                  slideAnimation: _slideAnimation,
                  typingAnimation: _typingAnimation,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
          const Expanded(
            child: Text(
              'Welcome to Afeedi',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildFinalButton() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D4FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Start Exploring! 🚀',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}
