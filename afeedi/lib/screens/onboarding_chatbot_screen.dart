import 'package:flutter/material.dart';
import '../services/navigation_service.dart';
import '../services/analytics_service.dart';
import '../services/onboarding_service.dart';
import '../models/onboarding_step.dart';
import '../models/genre.dart';
import '../widgets/chat/chat_controller.dart';
import '../widgets/chat/chat_interface.dart';

class OnboardingChatbotScreen extends StatefulWidget {
  const OnboardingChatbotScreen({super.key});

  @override
  State<OnboardingChatbotScreen> createState() => _OnboardingChatbotScreenState();
}

class _OnboardingChatbotScreenState extends State<OnboardingChatbotScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final OnboardingService _onboardingService = OnboardingService();
  late ChatController _chatController;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _typingController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _typingAnimation;

  final Map<String, bool> _platformConnections = {
    'YouTube': false,
    'Instagram': false,
    'TikTok': false,
    'Facebook': false,
    'Twitter': false,
  };

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
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _typingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _typingController, curve: Curves.easeInOut),
    );
  }

  Future<void> _preloadResources() async {
    try {
      await Future.wait([
        precacheImage(const AssetImage('assets/images/afeedi_logo.png'), context),
        precacheImage(const AssetImage('assets/images/onboarding_bg.jpg'), context),
      ]);
    } catch (e) {
      debugPrint('Error preloading resources: $e');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _typingController.dispose();
    _scrollController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  void _startOnboarding() {
    Future.delayed(const Duration(milliseconds: 500), () {
      _chatController.startOnboarding();
    });
  }

  void _handleStepCompleted(int stepNumber, String stepName, Map<String, dynamic> data) {
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

    // Convert genre name strings to Genre objects for saveOnboardingData
    final genreNames = (data['selected_genres'] as List<dynamic>? ?? []);
    final selectedGenres = genreNames
        .map((name) => Genre(name: name.toString(), emoji: '', category: '', keywords: []))
        .toList();

    final platforms = Map<String, bool>.from(
      (data['platform_connections'] as Map?)?.map((k, v) => MapEntry(k.toString(), v == true)) ?? {},
    );

    _onboardingService.saveOnboardingData(
      userName: (data['user_name'] ?? '').toString(),
      selectedGenres: selectedGenres,
      platformConnections: platforms,
      chatHistory: [],
    );
    _onboardingService.markOnboardingComplete();

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
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
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
            ],
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
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
