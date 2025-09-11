import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/user_preferences.dart';
import '../../services/onboarding_service.dart';
import '../../services/navigation_service.dart';
import '../../services/analytics_service.dart';
import '../../services/auth_service.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/onboarding/interest_selection_grid.dart';
import '../../widgets/onboarding/platform_selection_widget.dart';
import '../../widgets/onboarding/content_type_selection.dart';
import '../../widgets/onboarding/viewing_habits_selector.dart';
import '../../widgets/onboarding/calendar_integration_widget.dart';
import '../../widgets/onboarding/personalization_settings_widget.dart';
import '../../widgets/common/gradient_button.dart';
import '../../widgets/common/animated_background.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class EnhancedOnboardingScreen extends StatefulWidget {
  const EnhancedOnboardingScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedOnboardingScreen> createState() => _EnhancedOnboardingScreenState();
}

class _EnhancedOnboardingScreenState extends State<EnhancedOnboardingScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final OnboardingService _onboardingService = OnboardingService.instance;
  final _formKey = GlobalKey<FormState>();
  late ConfettiController _confettiController;
  late AnimationController _animationController;
  late AnimationController _slideController;
  
  int _currentPageIndex = 0;
  bool _isLoading = false;
  bool _isLastStep = false;
  UserPreferences _userPreferences = UserPreferences();
  final List<FocusNode> _focusNodes = [];
  
  // Controllers for text fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _initializeOnboarding();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    // Initialize focus nodes for text fields
    for (int i = 0; i < 5; i++) {
      _focusNodes.add(FocusNode());
    }
    
    // Load any existing preferences
    _loadExistingPreferences();
    
    // Track screen view
    AnalyticsService.instance.trackScreenView('enhanced_onboarding_screen');
  }
  
  Future<void> _initializeOnboarding() async {
    // Check if user has partially completed onboarding
    final currentStep = await _onboardingService.getCurrentStep();
    if (currentStep > 0) {
      setState(() {
        _currentPageIndex = currentStep;
      });
      _pageController.jumpToPage(currentStep);
    }
    
    _animationController.forward();
  }
  
  Future<void> _loadExistingPreferences() async {
    final prefs = await _onboardingService.getUserPreferences();
    if (prefs != null) {
      setState(() {
        _userPreferences = prefs;
        _nameController.text = prefs.name ?? '';
        _ageController.text = prefs.age?.toString() ?? '';
        _locationController.text = prefs.location ?? '';
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
    _ageController.dispose();
    _locationController.dispose();
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _nextPage() {
    if (_currentPageIndex == _onboardingService.onboardingFlow.length - 1) {
      _completeOnboarding();
      return;
    }
    
    // Save current step data
    _saveCurrentStepData();
    
    // Animate to next page
    _slideController.forward().then((_) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      _slideController.reset();
    });
    
    // Track progress
    AnalyticsService.instance.trackUserInteraction(
      action: 'onboarding_next_step',
      screen: 'enhanced_onboarding_screen',
      additionalData: {
        'step': _currentPageIndex,
        'step_name': _onboardingService.onboardingFlow[_currentPageIndex].title,
      },
    );
  }

  void _previousPage() {
    if (_currentPageIndex == 0) return;
    
    _pageController.previousPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    
    // Track interaction
    AnalyticsService.instance.trackUserInteraction(
      action: 'onboarding_previous_step',
      screen: 'enhanced_onboarding_screen',
      additionalData: {
        'step': _currentPageIndex,
      },
    );
  }

  Future<void> _completeOnboarding() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Save final step data
      _saveCurrentStepData();
      
      // Save all preferences
      await _onboardingService.saveUserPreferences(_userPreferences);
      await _onboardingService.markOnboardingComplete();
      
      // Play confetti animation
      _confettiController.play();
      
      // Track completion
      AnalyticsService.instance.trackUserInteraction(
        action: 'onboarding_completed',
        screen: 'enhanced_onboarding_screen',
        additionalData: {
          'total_steps': _onboardingService.onboardingFlow.length,
          'interests_count': _userPreferences.interests.length,
          'platforms_count': _userPreferences.platformPriorities.length,
        },
      );
      
      // Delay navigation to allow confetti to play
      await Future.delayed(const Duration(seconds: 2));
      
      // Navigate to home screen
      if (mounted) {
        NavigationService.instance.navigateToHome(context);
      }
    } catch (e) {
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing onboarding: $e')),
        );
      }
      
      // Track error
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

  void _saveCurrentStepData() {
    final currentStep = _onboardingService.onboardingFlow[_currentPageIndex];
    
    switch (currentStep.id) {
      case 'personal_info':
        _userPreferences = _userPreferences.copyWith(
          name: _nameController.text,
          age: int.tryParse(_ageController.text),
          location: _locationController.text,
        );
        break;
      
      // Other steps are handled by their respective widgets
      // which update _userPreferences directly
      
      default:
        // No specific handling needed
        break;
    }
    
    // Save current step progress
    _onboardingService.saveCurrentStep(_currentPageIndex);
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
          'Are you sure you want to continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _onboardingService.markOnboardingComplete();
              
              // Track skip action
              AnalyticsService.instance.trackUserInteraction(
                action: 'onboarding_skipped',
                screen: 'enhanced_onboarding_screen',
                additionalData: {
                  'step': _currentPageIndex,
                },
              );
              
              if (mounted) {
                NavigationService.instance.navigateToHome(context);
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          AnimatedBackground(
            color1: isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary,
            color2: isDarkMode ? AppColors.darkAccent : AppColors.lightAccent,
          ),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Progress indicator and skip button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Progress indicator
                      Expanded(
                        child: LinearProgressIndicator(
                          value: (_currentPageIndex + 1) / _onboardingService.onboardingFlow.length,
                          backgroundColor: Colors.grey.withOpacity(0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDarkMode ? AppColors.darkAccent : AppColors.lightAccent,
                          ),
                        ),
                      ),
                      
                      // Skip button (only show in first half of onboarding)
                      if (_currentPageIndex < _onboardingService.onboardingFlow.length / 2)
                        TextButton(
                          onPressed: _skipOnboarding,
                          child: Text(
                            'Skip',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white70 : Colors.black54,
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
                        _isLastStep = index == _onboardingService.onboardingFlow.length - 1;
                      });
                      HapticFeedback.lightImpact();
                    },
                    itemCount: _onboardingService.onboardingFlow.length,
                    itemBuilder: (context, index) {
                      final step = _onboardingService.onboardingFlow[index];
                      
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.05, 0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _slideController,
                          curve: Curves.easeOut,
                        )),
                        child: FadeTransition(
                          opacity: Tween<double>(
                            begin: 0.8,
                            end: 1.0,
                          ).animate(CurvedAnimation(
                            parent: _animationController,
                            curve: Curves.easeOut,
                          )),
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button
                      if (_currentPageIndex > 0)
                        IconButton(
                          onPressed: _previousPage,
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                            size: 28,
                          ),
                        )
                      else
                        const SizedBox(width: 48),
                      
                      // Next/Finish button
                      GradientButton(
                        onPressed: _nextPage,
                        width: 160,
                        height: 50,
                        gradient: LinearGradient(
                          colors: [
                            isDarkMode ? AppColors.darkAccent : AppColors.lightAccent,
                            isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary,
                          ],
                        ),
                        child: _isLoading
                            ? const LoadingIndicator(size: 24, color: Colors.white)
                            : Text(
                                _isLastStep ? 'Finish' : 'Next',
                                style: AppTextStyles.buttonText.copyWith(
                                  color: Colors.white,
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

  Widget _buildStepContent(OnboardingStep step, int index) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step title
          Text(
            step.title,
            style: AppTextStyles.heading2.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
          
          const SizedBox(height: 8),
          
          // Step description
          Text(
            step.description,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ).animate().fadeIn(duration: 500.ms, delay: 100.ms).slideY(begin: 0.1, end: 0),
          
          const SizedBox(height: 24),
          
          // Step content
          _buildStepSpecificContent(step),
        ],
      ),
    );
  }

  Widget _buildStepSpecificContent(OnboardingStep step) {
    switch (step.id) {
      case 'welcome':
        return _buildWelcomeStep();
      case 'personal_info':
        return _buildPersonalInfoStep();
      case 'content_interests':
        return InterestSelectionGrid(
          selectedInterests: _userPreferences.interests,
          onInterestsChanged: (interests) {
            _updatePreferences(_userPreferences.copyWith(interests: interests));
          },
        );
      case 'content_types':
        return ContentTypeSelection(
          selectedContentTypes: _userPreferences.contentTypes,
          onContentTypesChanged: (contentTypes) {
            _updatePreferences(_userPreferences.copyWith(contentTypes: contentTypes));
          },
        );
      case 'entertainment_preferences':
        return _buildEntertainmentPreferencesStep();
      case 'viewing_habits':
        return ViewingHabitsSelector(
          preferences: _userPreferences,
          onPreferencesChanged: _updatePreferences,
        );
      case 'platform_preferences':
        return PlatformSelectionWidget(
          platformPriorities: _userPreferences.platformPriorities,
          onPlatformPrioritiesChanged: (platformPriorities) {
            _updatePreferences(_userPreferences.copyWith(
              platformPriorities: platformPriorities,
            ));
          },
        );
      case 'personalization_settings':
        return PersonalizationSettingsWidget(
          preferences: _userPreferences,
          onPreferencesChanged: _updatePreferences,
        );
      case 'calendar_integration':
        return CalendarIntegrationWidget(
          preferences: _userPreferences,
          onPreferencesChanged: _updatePreferences,
        );
      default:
        return const Center(
          child: Text('Step content not implemented'),
        );
    }
  }

  Widget _buildWelcomeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Welcome animation
        Lottie.asset(
          'assets/animations/welcome_animation.json',
          height: 200,
          width: 200,
          fit: BoxFit.contain,
        ),
        
        const SizedBox(height: 24),
        
        // Welcome message
        Text(
          'Welcome to Afeedi!',
          style: AppTextStyles.heading2.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 16),
        
        Text(
          'We'll help you discover content that matters to you across multiple platforms.',
          style: AppTextStyles.bodyMedium.copyWith(fontSize: 16),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 24),
        
        // Features list
        ..._buildFeatureItem(
          icon: Icons.recommend,
          title: 'Personalized Recommendations',
          description: 'Content tailored to your interests and preferences',
        ),
        
        ..._buildFeatureItem(
          icon: Icons.calendar_today,
          title: 'Calendar Integration',
          description: 'Content recommendations based on your schedule',
        ),
        
        ..._buildFeatureItem(
          icon: Icons.devices,
          title: 'Multi-Platform Support',
          description: 'Access content from YouTube, TikTok, Instagram, and more',
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
              color: AppColors.lightAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.lightAccent),
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
                  ),
                ),
                Text(
                  description,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 14,
                    color: Colors.grey[600],
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
          // Name field
          CustomTextField(
            controller: _nameController,
            focusNode: _focusNodes[0],
            label: 'Name',
            hint: 'Enter your name',
            prefixIcon: Icons.person_outline,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _focusNodes[1].requestFocus(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Age field
          CustomTextField(
            controller: _ageController,
            focusNode: _focusNodes[1],
            label: 'Age',
            hint: 'Enter your age',
            prefixIcon: Icons.cake_outlined,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _focusNodes[2].requestFocus(),
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final age = int.tryParse(value);
                if (age == null || age < 13 || age > 120) {
                  return 'Please enter a valid age (13-120)';
                }
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Location field
          CustomTextField(
            controller: _locationController,
            focusNode: _focusNodes[2],
            label: 'Location',
            hint: 'Enter your location (optional)',
            prefixIcon: Icons.location_on_outlined,
            textInputAction: TextInputAction.done,
          ),
          
          const SizedBox(height: 24),
          
          // Privacy note
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.privacy_tip_outlined, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Privacy Note',
                      style: AppTextStyles.subtitle.copyWith(
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
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 200.ms);
  }

  Widget _buildEntertainmentPreferencesStep() {
    final entertainmentPreferences = _userPreferences.entertainmentPreferences;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Content length preferences
        Text(
          'Content Length Preferences',
          style: AppTextStyles.subtitle.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'How long do you prefer your content to be?',
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Content length sliders
        _buildPreferenceSlider(
          label: 'Short (< 1 min)',
          value: _userPreferences.contentLengthPreferences['short'] ?? 50,
          onChanged: (value) {
            final updated = Map<String, double>.from(_userPreferences.contentLengthPreferences);
            updated['short'] = value;
            _updatePreferences(_userPreferences.copyWith(
              contentLengthPreferences: updated,
            ));
          },
        ),
        
        _buildPreferenceSlider(
          label: 'Medium (1-10 min)',
          value: _userPreferences.contentLengthPreferences['medium'] ?? 50,
          onChanged: (value) {
            final updated = Map<String, double>.from(_userPreferences.contentLengthPreferences);
            updated['medium'] = value;
            _updatePreferences(_userPreferences.copyWith(
              contentLengthPreferences: updated,
            ));
          },
        ),
        
        _buildPreferenceSlider(
          label: 'Long (> 10 min)',
          value: _userPreferences.contentLengthPreferences['long'] ?? 50,
          onChanged: (value) {
            final updated = Map<String, double>.from(_userPreferences.contentLengthPreferences);
            updated['long'] = value;
            _updatePreferences(_userPreferences.copyWith(
              contentLengthPreferences: updated,
            ));
          },
        ),
        
        const SizedBox(height: 24),
        
        // Entertainment categories
        Text(
          'Entertainment Categories',
          style: AppTextStyles.subtitle.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Select your favorite entertainment categories',
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Entertainment category chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildCategoryChip('Comedy', entertainmentPreferences),
            _buildCategoryChip('Drama', entertainmentPreferences),
            _buildCategoryChip('Action', entertainmentPreferences),
            _buildCategoryChip('Documentary', entertainmentPreferences),
            _buildCategoryChip('Music', entertainmentPreferences),
            _buildCategoryChip('Gaming', entertainmentPreferences),
            _buildCategoryChip('Sports', entertainmentPreferences),
            _buildCategoryChip('News', entertainmentPreferences),
            _buildCategoryChip('Science', entertainmentPreferences),
            _buildCategoryChip('Technology', entertainmentPreferences),
            _buildCategoryChip('Cooking', entertainmentPreferences),
            _buildCategoryChip('Travel', entertainmentPreferences),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 600.ms, delay: 200.ms);
  }

  Widget _buildPreferenceSlider({
    required String label,
    required double value,
    required Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${value.toInt()}%',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.lightAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: 0,
          max: 100,
          divisions: 10,
          activeColor: AppColors.lightAccent,
          inactiveColor: Colors.grey.withOpacity(0.3),
          onChanged: (newValue) {
            onChanged(newValue);
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildCategoryChip(String category, List<String> selectedCategories) {
    final isSelected = selectedCategories.contains(category);
    
    return FilterChip(
      label: Text(category),
      selected: isSelected,
      checkmarkColor: Colors.white,
      selectedColor: AppColors.lightAccent,
      backgroundColor: Colors.grey.withOpacity(0.1),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (selected) {
        final updated = List<String>.from(selectedCategories);
        if (selected) {
          updated.add(category);
        } else {
          updated.remove(category);
        }
        _updatePreferences(_userPreferences.copyWith(
          entertainmentPreferences: updated,
        ));
      },
    );
  }
}

// Helper extension for math constants
extension MathConstants on num {
  static const double pi = 3.1415926535897932;
}