import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'dart:math' as Math;

import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../services/onboarding_service.dart';
import '../services/analytics_service.dart';
import '../services/user_service.dart';
import '../models/user_preferences.dart';
import '../models/onboarding_step.dart';
import '../widgets/onboarding/interest_selection_grid.dart';
import '../widgets/onboarding/content_type_selection.dart';
import '../widgets/onboarding/platform_selection_widget.dart';
import '../widgets/onboarding/viewing_habits_widget.dart';
import '../widgets/onboarding/personalization_settings_widget.dart';

// Dark theme color constants used throughout the onboarding flow
const Color _kDarkBase = Color(0xFF1A0A3E);
const Color _kDarkDeep = Color(0xFF0A1628);
const Color _kDarkAccent = Color(0xFF2D1B69);
const Color _kDarkMid = Color(0xFF1A2F4A);
const Color _kCyan = Color(0xFF00E5FF);

class EnhancedOnboardingFlow extends StatefulWidget {
  final Function() onComplete;

  EnhancedOnboardingFlow({Key? key, required this.onComplete}) : super(key: key);

  @override
  State<EnhancedOnboardingFlow> createState() => _EnhancedOnboardingFlowState();
}

class _EnhancedOnboardingFlowState extends State<EnhancedOnboardingFlow>
    with SingleTickerProviderStateMixin {
  final OnboardingService _onboardingService = OnboardingService.instance;
  final AnalyticsService _analyticsService = AnalyticsService.instance;
  final UserService _userService = UserService.instance;

  late PageController _pageController;
  late ConfettiController _confettiController;
  late AnimationController _backgroundAnimationController;
  late Animation<Color?> _backgroundColorAnimation;

  int _currentStep = 0;
  bool _isLastStep = false;
  UserPreferences _userPreferences = UserPreferences();
  bool _isLoading = false;

  // Dark-themed background gradient colors for each step
  final List<List<Color>> _backgroundColors = [
    [const Color(0xFF1A0A3E), const Color(0xFF2D1B69)],
    [const Color(0xFF0D1B2A), const Color(0xFF1A2F4A)],
    [const Color(0xFF1A0A3E), const Color(0xFF3D1A6E)],
    [const Color(0xFF0A1628), const Color(0xFF1A2A4E)],
    [const Color(0xFF1A0A3E), const Color(0xFF2D1B69)],
    [const Color(0xFF0D1B2A), const Color(0xFF1A3A5C)],
    [const Color(0xFF1A0A3E), const Color(0xFF3D1A6E)],
    [const Color(0xFF0A1628), const Color(0xFF1A2A4E)],
    [const Color(0xFF1A0A3E), const Color(0xFF2D1B69)],
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _backgroundAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _backgroundColorAnimation = ColorTween(
      begin: _backgroundColors[0][0],
      end: _backgroundColors[0][0],
    ).animate(_backgroundAnimationController);

    _loadUserPreferences();
    _trackOnboardingStarted();
  }

  Future<void> _loadUserPreferences() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final preferences = await _onboardingService.getCurrentPreferences();
      if (preferences != null) {
        setState(() {
          _userPreferences = preferences;
        });
      }
    } catch (e) {
      debugPrint('Error loading preferences: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _trackOnboardingStarted() {
    _analyticsService.trackEvent(
      eventName: 'onboarding_started',
      eventType: 'onboarding',
      additionalData: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  void _updateBackgroundColor(int stepIndex) {
    final colorIndex = stepIndex % _backgroundColors.length;
    _backgroundColorAnimation = ColorTween(
      begin: _backgroundColorAnimation.value,
      end: _backgroundColors[colorIndex][0],
    ).animate(_backgroundAnimationController);
    _backgroundAnimationController.forward(from: 0.0);
  }

  void _nextStep() {
    if (_currentStep < OnboardingService.onboardingFlow.length - 1) {
      setState(() {
        _currentStep++;
        _isLastStep = _currentStep == OnboardingService.onboardingFlow.length - 1;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      _updateBackgroundColor(_currentStep);
      _trackStepCompleted(_currentStep - 1);
    } else {
      _completeOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _isLastStep = false;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      _updateBackgroundColor(_currentStep);
    }
  }

  void _trackStepCompleted(int stepIndex) {
    final stepKey = OnboardingService.onboardingFlow[stepIndex]['id'];
    _analyticsService.trackEvent(
      eventName: 'onboarding_step_completed',
      eventType: 'onboarding',
      additionalData: {
        'step_key': stepKey,
        'step_index': stepIndex,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> _completeOnboarding() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _onboardingService.savePreferences(_userPreferences);
      await _onboardingService.markOnboardingComplete();

      _analyticsService.trackEvent(
        eventName: 'onboarding_completed',
        eventType: 'onboarding',
        additionalData: {
          'timestamp': DateTime.now().toIso8601String(),
          'total_steps': OnboardingService.onboardingFlow.length,
        },
      );

      _confettiController.play();

      await Future.delayed(const Duration(seconds: 2));

      widget.onComplete();
    } catch (e) {
      debugPrint('Error completing onboarding: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving preferences: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateUserPreferences(String key, dynamic value) {
    setState(() {
      switch (key) {
        case 'personalInfo':
          _userPreferences = _userPreferences.copyWith(
            name: value['name'],
            age: value['age'],
          );
          break;
        case 'contentInterests':
          _userPreferences =
              _userPreferences.copyWith(contentInterests: List<String>.from(value));
          break;
        case 'contentTypes':
          _userPreferences =
              _userPreferences.copyWith(contentTypes: List<String>.from(value));
          break;
        case 'viewingHabits':
          _userPreferences = _userPreferences.copyWith(
            preferredViewingTimes: List<String>.from(value['preferredViewingTimes']),
            averageSessionDuration: value['averageSessionDuration'],
            contentLengthPreferences: Map<String, int>.from(value['contentLengthPreferences']),
          );
          break;
        case 'entertainmentPreferences':
          _userPreferences = _userPreferences.copyWith(
            entertainmentPreferences: {
              ...(_userPreferences.entertainmentPreferences),
              'genres': List<String>.from(value['genres']),
              'moods': List<String>.from(value['moods']),
            },
          );
          break;
        case 'platformPreferences':
          _userPreferences =
              _userPreferences.copyWith(platformPriorities: Map<String, double>.from(value));
          break;
        case 'personalizationSettings':
          _userPreferences = _userPreferences.copyWith(
            enableAIRecommendations: value['enableAIRecommendations'],
            diversityLevel: value['diversityLevel'],
            crossPlatformRecommendations: value['crossPlatformRecommendations'],
          );
          break;
        case 'calendarIntegration':
          _userPreferences = _userPreferences.copyWith(
            calendarIntegration: value['enabled'],
            smartScheduling: value['smartScheduling'],
          );
          break;
        case 'appCustomization':
          _userPreferences = _userPreferences.copyWith(
            theme: value['theme'],
            compactMode: value['compactMode'],
            feedLayout: value['feedLayout'],
          );
          break;
      }
    });

    _onboardingService.savePreferences(_userPreferences);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _confettiController.dispose();
    _backgroundAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _kDarkBase,
        body: const Center(
          child: CircularProgressIndicator(color: _kCyan),
        ),
      );
    }

    final totalSteps = OnboardingService.onboardingFlow.length;

    return Scaffold(
      backgroundColor: _kDarkBase,
      body: AnimatedBuilder(
        animation: _backgroundAnimationController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _backgroundColorAnimation.value ?? _backgroundColors[0][0],
                  _backgroundColors[_currentStep % _backgroundColors.length][1],
                ],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Stack(
            children: [
              // Confetti effect
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirection: -Math.pi / 2,
                  emissionFrequency: 0.05,
                  numberOfParticles: 20,
                  maxBlastForce: 100,
                  minBlastForce: 80,
                  gravity: 0.2,
                ),
              ),

              // Main content
              Column(
                children: [
                  // Progress bar at the top
                  _buildProgressHeader(totalSteps),

                  // Page content
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: totalSteps,
                      itemBuilder: (context, index) {
                        final step = OnboardingService.onboardingFlow[index];
                        final stepId = step['id'] as String;
                        final stepTitle = step['title'] as String;
                        final isCompletionStep = stepId == 'complete';

                        return SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24.0, vertical: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Step title
                                Text(
                                  stepTitle,
                                  style: AppTextStyles.heading2.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                                    .animate()
                                    .fadeIn(duration: 400.ms)
                                    .slideY(begin: 0.1, end: 0),

                                const SizedBox(height: 8),

                                // Step description
                                Text(
                                  _stepDescription(stepId),
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                )
                                    .animate()
                                    .fadeIn(duration: 400.ms, delay: 100.ms)
                                    .slideY(begin: 0.1, end: 0),

                                const SizedBox(height: 32),

                                // Step content
                                _buildStepContent(stepId),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Bottom navigation area
                  _buildBottomNavigation(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Thin progress bar header with back button and step counter.
  Widget _buildProgressHeader(int totalSteps) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8.0, 8.0, 16.0, 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _currentStep > 0 ? _previousStep : null,
                color: _currentStep > 0 ? Colors.white : Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_currentStep + 1) / totalSteps,
                    backgroundColor: Colors.white.withOpacity(0.15),
                    valueColor: const AlwaysStoppedAnimation<Color>(_kCyan),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_currentStep + 1}/$totalSteps',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Bottom navigation: primary CTA + optional skip link.
  Widget _buildBottomNavigation() {
    final totalSteps = OnboardingService.onboardingFlow.length;
    final currentStepId =
        OnboardingService.onboardingFlow[_currentStep]['id'] as String;
    final isCompletionStep = currentStepId == 'complete';
    // Show skip on all non-completion steps except step 0 (has guest button instead)
    final showSkip = !isCompletionStep && _currentStep > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary CTA button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kCyan,
                foregroundColor: const Color(0xFF1A0A3E),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isCompletionStep ? 'Start Exploring' : 'Continue',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5),
              ),
            ),
          ),

          // Skip option for optional steps (steps 1 through second-to-last)
          if (showSkip)
            TextButton(
              onPressed: _nextStep,
              child: Text(
                'Skip this step',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _stepDescription(String stepId) {
    switch (stepId) {
      case 'welcome':
        return 'Let\'s get started on your personalized content journey!';
      case 'genres':
        return 'Tell us what kind of content you love!';
      case 'platforms':
        return 'Link your accounts for better recommendations.';
      case 'profile':
        return 'Tell us a bit about yourself.';
      case 'complete':
        return 'Your personalized feed is ready.';
      default:
        return '';
    }
  }

  Widget _buildStepContent(String stepId) {
    switch (stepId) {
      case 'welcome':
        return _buildWelcomeStep();
      case 'genres':
        return InterestSelectionGrid(
          selectedInterests: _userPreferences.contentInterests,
          onInterestsChanged: (interests) =>
              _updateUserPreferences('contentInterests', interests),
        );
      case 'platforms':
        return PlatformSelectionWidget(
          platformPriorities: _userPreferences.platformPriorities,
          onPlatformPrioritiesChanged: (prefs) =>
              _updateUserPreferences('platformPreferences', prefs),
        );
      case 'profile':
        return _buildPersonalInfoStep();
      case 'complete':
        return _buildCompletionStep();
      default:
        return Center(
          child: Text(
            'Step content not implemented',
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Step builders
  // ---------------------------------------------------------------------------

  Widget _buildWelcomeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 12),
        Icon(
          Icons.play_circle_fill,
          size: 88,
          color: _kCyan,
        ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
        const SizedBox(height: 28),
        Text(
          'Welcome to Afeedi!',
          style: AppTextStyles.heading2.copyWith(
            fontSize: 28,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'We\'re excited to help you discover content that matters to you. Let\'s personalize your experience in a few simple steps.',
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 16,
            color: Colors.white.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Column(
            children: [
              _buildFeatureItem(
                icon: Icons.person_outline,
                title: 'Personalized Content',
                description: 'Discover videos tailored to your interests',
              ),
              Divider(color: Colors.white.withOpacity(0.12)),
              _buildFeatureItem(
                icon: Icons.calendar_today_outlined,
                title: 'Calendar Integration',
                description: 'Content recommendations based on your schedule',
              ),
              Divider(color: Colors.white.withOpacity(0.12)),
              _buildFeatureItem(
                icon: Icons.devices_outlined,
                title: 'Multi-Platform Experience',
                description: 'Seamlessly watch content from multiple platforms',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // "Skip for now" guest option
        TextButton(
          onPressed: widget.onComplete,
          child: Text(
            'Skip for now →',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _kCyan.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _kCyan),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    final nameController = TextEditingController(
      text: _userPreferences.personalInfo['name'] ?? '',
    );
    final ageController = TextEditingController(
      text: _userPreferences.personalInfo['age']?.toString() ?? '',
    );

    void updatePersonalInfo() {
      final personalInfo = Map<String, dynamic>.from(_userPreferences.personalInfo);
      personalInfo['name'] = nameController.text;
      final age = int.tryParse(ageController.text);
      if (age != null) {
        personalInfo['age'] = age;
      }
      _updateUserPreferences('personalInfo', personalInfo);
    }

    nameController.addListener(updatePersonalInfo);
    ageController.addListener(updatePersonalInfo);

    final inputDecoration = InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withOpacity(0.08),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kCyan, width: 1.5),
      ),
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Theme(
          data: Theme.of(context).copyWith(inputDecorationTheme: inputDecoration),
          child: Column(
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter your name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kCyan, width: 1.5),
                  ),
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.08),
                  prefixIcon: Icon(Icons.person_outline,
                      color: Colors.white.withOpacity(0.6)),
                ),
                textCapitalization: TextCapitalization.words,
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: 16),

              TextField(
                controller: ageController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Age',
                  hintText: 'Enter your age',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kCyan, width: 1.5),
                  ),
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.08),
                  prefixIcon: Icon(Icons.cake_outlined,
                      color: Colors.white.withOpacity(0.6)),
                ),
                keyboardType: TextInputType.number,
              ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.1, end: 0),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Privacy note
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kCyan.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kCyan.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              Icon(Icons.privacy_tip_outlined, color: _kCyan.withOpacity(0.8)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your information helps us personalize your experience. We respect your privacy and never share your data with third parties.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
      ],
    );
  }

  Widget _buildCompletionStep() {
    // Trigger confetti on build (first time the final step is shown)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_confettiController.state != ConfettiControllerState.playing) {
        _confettiController.play();
      }
    });

    final selectedInterests = _userPreferences.contentInterests;
    final selectedPlatforms = _userPreferences.platformPriorities.entries
        .where((e) => e.value > 0)
        .map((e) => e.key)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 12),
        // Large animated checkmark
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _kCyan.withOpacity(0.15),
            border: Border.all(color: _kCyan, width: 2),
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 60,
            color: _kCyan,
          ),
        )
            .animate()
            .scale(duration: 600.ms, curve: Curves.elasticOut)
            .fadeIn(duration: 400.ms),

        const SizedBox(height: 28),

        Text(
          'You\'re all set!',
          style: AppTextStyles.heading2.copyWith(
            fontSize: 30,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

        const SizedBox(height: 12),

        Text(
          'Your personalized feed is ready to explore.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white.withOpacity(0.8),
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(duration: 400.ms, delay: 300.ms),

        const SizedBox(height: 32),

        // Summary card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your preferences',
                style: TextStyle(
                  color: _kCyan,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),

              // Interests summary
              if (selectedInterests.isNotEmpty) ...[
                _buildSummaryRow(
                  icon: Icons.favorite_outline,
                  label: 'Interests',
                  value: selectedInterests.take(3).join(', ') +
                      (selectedInterests.length > 3
                          ? ' +${selectedInterests.length - 3} more'
                          : ''),
                ),
                const SizedBox(height: 12),
              ],

              // Platforms summary
              if (selectedPlatforms.isNotEmpty)
                _buildSummaryRow(
                  icon: Icons.devices_outlined,
                  label: 'Platforms',
                  value: selectedPlatforms.take(3).join(', ') +
                      (selectedPlatforms.length > 3
                          ? ' +${selectedPlatforms.length - 3} more'
                          : ''),
                ),

              if (selectedInterests.isEmpty && selectedPlatforms.isEmpty)
                Text(
                  'You can always update your preferences from your profile settings.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        ).animate().fadeIn(duration: 500.ms, delay: 400.ms).slideY(begin: 0.05, end: 0),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: _kCyan.withOpacity(0.8)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// End of file
