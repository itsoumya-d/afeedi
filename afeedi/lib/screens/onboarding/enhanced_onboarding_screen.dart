import 'dart:math' show pi;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/user_preferences.dart';
import '../../services/onboarding_service.dart';
import '../../services/navigation_service.dart';
import '../../services/analytics_service.dart';
import '../../widgets/onboarding/interest_selection_grid.dart';
import '../../widgets/onboarding/language_selection.dart';
import '../../widgets/onboarding/platform_selection_widget.dart';
import '../../widgets/onboarding/content_type_selection.dart';
import '../../widgets/onboarding/personalization_settings_widget.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class EnhancedOnboardingScreen extends StatefulWidget {
  const EnhancedOnboardingScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedOnboardingScreen> createState() =>
      _EnhancedOnboardingScreenState();
}

class _EnhancedOnboardingScreenState extends State<EnhancedOnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();
  late ConfettiController _confettiController;
  late AnimationController _animationController;
  late AnimationController _slideController;

  // Static flow from OnboardingService
  final List<Map<String, dynamic>> _flow = OnboardingService.onboardingFlow;

  int _currentPageIndex = 0;
  bool _isLoading = false;
  bool _isLastStep = false;
  UserPreferences _userPreferences = const UserPreferences();

  // Controllers for text fields
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _loadExistingPreferences();
    _animationController.forward();

    AnalyticsService.instance.trackUserInteraction(
      action: 'screen_view',
      screen: 'enhanced_onboarding_screen',
    );

    // COPPA/GDPR Art. 8 age gate — show once per device, block under-13 users
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAgeGate());
  }

  Future<void> _checkAgeGate() async {
    final prefs = await SharedPreferences.getInstance();
    final verified = prefs.getBool('coppa_age_verified') ?? false;
    if (verified || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Age Verification',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'You must be 13 or older to use Afeedi. Are you 13 years of age or older?',
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D4FF),
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes, I am 13+'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirmed == true) {
      await prefs.setBool('coppa_age_verified', true);
    } else {
      // User is under 13 — block registration per COPPA §312.3
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Age Requirement',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          content: const Text(
            'Afeedi is not available to users under 13 years of age.',
            style: TextStyle(color: Colors.white70, height: 1.5),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D4FF),
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop(); // return to welcome
    }
  }

  Future<void> _loadExistingPreferences() async {
    final prefs = await OnboardingService.instance.getUserPreferences();
    if (prefs != null && mounted) {
      setState(() {
        _userPreferences = prefs;
        _nameController.text = prefs.name ?? '';
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _confettiController.dispose();
    _animationController.dispose();
    _slideController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPageIndex == _flow.length - 1) {
      _completeOnboarding();
      return;
    }

    // Validate genre step: require at least 3 selections
    final currentStepId = _flow[_currentPageIndex]['id'] as String?;
    if (currentStepId == 'genres' || currentStepId == 'content_interests') {
      if (_userPreferences.contentInterests.length < 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please select at least 3 genres to personalize your feed.',
            ),
          ),
        );
        return;
      }
    }

    _saveCurrentStepData();

    _slideController.forward().then((_) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      _slideController.reset();
    });

    AnalyticsService.instance.trackUserInteraction(
      action: 'onboarding_next_step',
      screen: 'enhanced_onboarding_screen',
      additionalData: {
        'step': _currentPageIndex,
        'step_id': _flow[_currentPageIndex]['id'],
      },
    );
  }

  void _previousPage() {
    if (_currentPageIndex == 0) return;

    _pageController.previousPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );

    AnalyticsService.instance.trackUserInteraction(
      action: 'onboarding_previous_step',
      screen: 'enhanced_onboarding_screen',
      additionalData: {'step': _currentPageIndex},
    );
  }

  Future<void> _completeOnboarding() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _saveCurrentStepData();

      await OnboardingService.instance.savePreferences(_userPreferences);
      await OnboardingService.instance.markOnboardingComplete();

      _confettiController.play();

      AnalyticsService.instance.trackUserInteraction(
        action: 'onboarding_completed',
        screen: 'enhanced_onboarding_screen',
        additionalData: {
          'total_steps': _flow.length,
          'interests_count': _userPreferences.contentInterests.length,
          'platforms_count': _userPreferences.platformPriorities.length,
        },
      );

      await Future.delayed(const Duration(milliseconds: 1200));

      if (mounted) {
        await _showTrialOffer();
      }

      if (mounted) {
        NavigationService.navigateToHome();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing onboarding: $e')),
        );
      }

      AnalyticsService.instance.trackError(
        errorType: 'onboarding_completion_error',
        errorMessage: e.toString(),
        screen: 'enhanced_onboarding_screen',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showTrialOffer() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyPremium = prefs.getBool('is_premium') ?? false;
    if (alreadyPremium || !mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Icon(
              Icons.workspace_premium,
              color: Color(0xFF00D4FF),
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Your feed is ready! 🎉',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Unlock the full Afeedi experience with a free 7-day trial of Pro.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _trialFeatureRow(Icons.bookmark_border, 'Unlimited saves'),
            _trialFeatureRow(Icons.block, 'No ads'),
            _trialFeatureRow(Icons.auto_awesome, 'Weekly AI Digest'),
            _trialFeatureRow(Icons.search, 'Cross-platform search filters'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D4FF),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.premium);
                  AnalyticsService.instance.trackUserInteraction(
                    action: 'onboarding_trial_cta_tapped',
                    screen: 'enhanced_onboarding_screen',
                  );
                },
                child: const Text(
                  'Start Free 7-Day Trial',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Maybe later',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _trialFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00D4FF), size: 18),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }

  void _saveCurrentStepData() {
    final stepId = _flow[_currentPageIndex]['id'] as String?;

    if (stepId == 'personal_info' || stepId == 'profile') {
      _userPreferences = _userPreferences.copyWith(
        name: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
      );
    }
  }

  void _updatePreferences(UserPreferences updatedPreferences) {
    setState(() {
      _userPreferences = updatedPreferences;
    });
  }

  void _skipOnboarding() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip Onboarding?'),
        content: const Text(
          'Skipping onboarding will limit personalized recommendations. '
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await OnboardingService.instance.markOnboardingComplete();

              AnalyticsService.instance.trackUserInteraction(
                action: 'onboarding_skipped',
                screen: 'enhanced_onboarding_screen',
                additionalData: {'step': _currentPageIndex},
              );

              if (mounted) {
                NavigationService.navigateToHome();
              }
            },
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryLight, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Progress indicator and skip button
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LinearProgressIndicator(
                              value: (_currentPageIndex + 1) / _flow.length,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.3,
                              ),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Step ${_currentPageIndex + 1} of ${_flow.length}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_currentPageIndex < _flow.length / 2)
                        TextButton(
                          onPressed: _skipOnboarding,
                          child: const Text(
                            'Skip',
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Page content
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() {
                        _currentPageIndex = index;
                        _isLastStep = index == _flow.length - 1;
                      });
                      HapticFeedback.lightImpact();
                    },
                    itemCount: _flow.length,
                    itemBuilder: (context, index) {
                      final step = _flow[index];

                      return SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(0.05, 0),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: _slideController,
                                curve: Curves.easeOut,
                              ),
                            ),
                        child: FadeTransition(
                          opacity: Tween<double>(begin: 0.8, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _animationController,
                              curve: Curves.easeOut,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: _buildStepContent(step, index),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Navigation buttons
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentPageIndex > 0)
                        IconButton(
                          onPressed: _previousPage,
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white70,
                            size: 28,
                          ),
                        )
                      else
                        const SizedBox(width: 48),

                      // Next/Finish button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          minimumSize: const Size(160, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              )
                            : Text(
                                _isLastStep ? 'Finish' : 'Next',
                                style: AppTextStyles.buttonMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Confetti effect for completion
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 5,
              minBlastForce: 1,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Colors.red,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(Map<String, dynamic> step, int index) {
    final title = step['title'] as String? ?? 'Step ${index + 1}';
    final type = step['type'] as String? ?? '';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.heading2.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 24),

          _buildStepSpecificContent(step, type),
        ],
      ),
    );
  }

  Widget _buildStepSpecificContent(Map<String, dynamic> step, String type) {
    final id = step['id'] as String? ?? type;

    switch (id) {
      case 'welcome':
        return _buildWelcomeStep();
      case 'language':
        return LanguageSelectionWidget(
          onLanguageSelected: (name, locale) {
            _updatePreferences(_userPreferences.copyWith(language: locale));
          },
          slideAnimation:
              Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: _slideController,
                  curve: Curves.easeOut,
                ),
              ),
          fadeAnimation: Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeOut,
            ),
          ),
        );
      case 'genres':
      case 'content_interests':
        return InterestSelectionGrid(
          selectedInterests: _userPreferences.contentInterests,
          onInterestsChanged: (interests) {
            _updatePreferences(
              _userPreferences.copyWith(contentInterests: interests),
            );
          },
        );
      case 'platforms':
      case 'platform_preferences':
        return PlatformSelectionWidget(
          platformPriorities: _userPreferences.platformPriorities,
          onPlatformPrioritiesChanged: (platformPriorities) {
            _updatePreferences(
              _userPreferences.copyWith(platformPriorities: platformPriorities),
            );
          },
        );
      case 'profile':
      case 'personal_info':
        return _buildPersonalInfoStep();
      case 'complete':
      case 'completion':
        return _buildCompletionStep();
      case 'content_types':
        return ContentTypeSelection(
          selectedContentTypes: _userPreferences.contentTypes,
          onContentTypesChanged: (contentTypes) {
            _updatePreferences(
              _userPreferences.copyWith(contentTypes: contentTypes),
            );
          },
        );
      case 'personalization':
      case 'personalization_settings':
        return PersonalizationSettingsWidget(
          personalizationSettings: _userPreferences.personalizationSettings,
          onPersonalizationSettingsChanged: (settings) {
            _updatePreferences(
              _userPreferences.copyWith(personalizationSettings: settings),
            );
          },
        );
      default:
        return Center(
          child: Text(
            'Setting up your experience...',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
          ),
        );
    }
  }

  Widget _buildWelcomeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(
          Icons.play_circle_fill_rounded,
          size: 100,
          color: Colors.white,
        ),

        const SizedBox(height: 24),

        Text(
          'Welcome to Afeedi!',
          style: AppTextStyles.heading2.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 16),

        Text(
          "We'll help you discover content that matters to you across multiple platforms.",
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 16,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 24),

        ..._buildFeatureItem(
          icon: Icons.recommend,
          title: 'Personalized Recommendations',
          description: 'Content tailored to your interests and preferences',
        ),

        ..._buildFeatureItem(
          icon: Icons.devices,
          title: 'Multi-Platform Support',
          description:
              'Access content from YouTube, TikTok, Instagram, and more',
        ),
      ],
    ).animate().fadeIn(duration: 600.ms, delay: 200.ms);
  }

  List<Widget> _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return [
      const SizedBox(height: 16),
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.subtitle.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  description,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildPersonalInfoStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Name',
              hintText: 'Enter your name',
              labelStyle: const TextStyle(color: Colors.white70),
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(
                Icons.person_outline,
                color: Colors.white70,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white54),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.error),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.error),
              ),
            ),
            textInputAction: TextInputAction.done,
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.privacy_tip_outlined,
                      size: 20,
                      color: Colors.white70,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Privacy Note',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Your information helps us personalize your experience. '
                  'We respect your privacy and will never share your personal data with third parties.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 200.ms);
  }

  Widget _buildCompletionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle_rounded, size: 100, color: Colors.white),

        const SizedBox(height: 24),

        Text(
          "You're all set!",
          style: AppTextStyles.heading2.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 16),

        Text(
          "Your personalized feed is ready. Let's start discovering amazing content!",
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 16,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ).animate().fadeIn(duration: 600.ms, delay: 200.ms);
  }
}
