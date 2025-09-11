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

class EnhancedOnboardingFlow extends StatefulWidget {
  final Function() onComplete;

  EnhancedOnboardingFlow({Key? key, required this.onComplete}) : super(key: key);

  @override
  State<EnhancedOnboardingFlow> createState() => _EnhancedOnboardingFlowState();
}

class _EnhancedOnboardingFlowState extends State<EnhancedOnboardingFlow> with SingleTickerProviderStateMixin {
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
  
  // Background gradient colors for different steps
  final List<List<Color>> _backgroundColors = [
    [Colors.blue.shade100, Colors.blue.shade50],
    [Colors.purple.shade100, Colors.purple.shade50],
    [Colors.amber.shade100, Colors.amber.shade50],
    [Colors.green.shade100, Colors.green.shade50],
    [Colors.orange.shade100, Colors.orange.shade50],
    [Colors.teal.shade100, Colors.teal.shade50],
    [Colors.indigo.shade100, Colors.indigo.shade50],
    [Colors.pink.shade100, Colors.pink.shade50],
    [Colors.cyan.shade100, Colors.cyan.shade50],
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
      // Load existing preferences if available
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
    _analyticsService.trackEvent(eventName: 'onboarding_started', eventType: 'onboarding', additionalData: {
      'timestamp': DateTime.now().toIso8601String(),
    });
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
    _analyticsService.trackEvent(eventName: 'onboarding_step_completed', eventType: 'onboarding', additionalData: {
      'step_key': stepKey,
      'step_index': stepIndex,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _completeOnboarding() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Save final preferences
      await _onboardingService.savePreferences(_userPreferences);
      await _onboardingService.markOnboardingComplete();
      
      // Track completion
      _analyticsService.trackEvent(eventName: 'onboarding_completed', eventType: 'onboarding', additionalData: {
        'timestamp': DateTime.now().toIso8601String(),
        'total_steps': OnboardingService.onboardingFlow.length,
      });
      
      // Celebrate completion
      _confettiController.play();
      
      // Wait for confetti animation before proceeding
      await Future.delayed(const Duration(seconds: 2));
      
      // Notify parent that onboarding is complete
      widget.onComplete();
    } catch (e) {
      debugPrint('Error completing onboarding: $e');
      // Show error message
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
          _userPreferences = _userPreferences.copyWith(contentInterests: List<String>.from(value));
          break;
        case 'contentTypes':
          _userPreferences = _userPreferences.copyWith(contentTypes: List<String>.from(value));
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
          _userPreferences = _userPreferences.copyWith(platformPriorities: Map<String, double>.from(value));
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

    // Save preferences after each update
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
      return const Center(child: CircularProgressIndicator());
    }
    
    return Scaffold(
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
                  // Progress indicator and step counter
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: _currentStep > 0 ? _previousStep : null,
                          color: _currentStep > 0 ? Colors.black87 : Colors.grey.withOpacity(0.5),
                        ),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: (_currentStep + 1) / OnboardingService.onboardingFlow.length,
                            backgroundColor: Colors.grey.withOpacity(0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '${_currentStep + 1}/${OnboardingService.onboardingFlow.length}',
                          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  
                  // Page content
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: OnboardingService.onboardingFlow.length,
                      itemBuilder: (context, index) {
                        final step = OnboardingService.onboardingFlow[index];
                        return SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Step title
                                Text(
                                  step.stepTitle ?? 'Step ${index + 1}',
                                  style: AppTextStyles.heading2,
                                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                                
                                const SizedBox(height: 8),
                                
                                // Step description
                                Text(
                                  step.stepDescription ?? step.botMessage,
                                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.black87),
                                ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.1, end: 0),
                                
                                const SizedBox(height: 32),
                                
                                // Step content
                                _buildStepContent(step),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Navigation buttons
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _nextStep,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _isLastStep ? 'Complete' : 'Continue',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent(OnboardingStep step) {
    switch (step.key) {
      case 'welcome':
        return _buildWelcomeStep();
      case 'personal_info':
        return _buildPersonalInfoStep();
      case 'content_interests':
        return InterestSelectionGrid(
          selectedInterests: _userPreferences.contentInterests ?? [],
          onInterestsChanged: (interests) => _updateUserPreferences('contentInterests', interests),
        );
      case 'content_types':
        return ContentTypeSelection(
          selectedContentTypes: _userPreferences.contentTypes ?? [],
          onContentTypesChanged: (types) => _updateUserPreferences('contentTypes', types),
        );
      case 'entertainment_preferences':
        return _buildEntertainmentPreferencesStep();
      case 'viewing_habits':
        return ViewingHabitsWidget(
          viewingHabits: _userPreferences.viewingHabits ?? {},
          onViewingHabitsChanged: (habits) => _updateUserPreferences('viewingHabits', habits),
        );
      case 'platform_preferences':
        return PlatformSelectionWidget(
          platformPriorities: _userPreferences.platformPriorities ?? {},
          onPlatformPrioritiesChanged: (prefs) => _updateUserPreferences('platformPreferences', prefs),
        );
      case 'personalization_settings':
        return PersonalizationSettingsWidget(
          personalizationSettings: _userPreferences.personalizationSettings ?? {},
          onPersonalizationSettingsChanged: (settings) => 
              _updateUserPreferences('personalizationSettings', settings),
        );
      case 'calendar_integration':
        return _buildCalendarIntegrationStep();
      case 'welcome':
        return _buildWelcomeStep();
      default:
        return const Center(child: Text('Step content not implemented'));
    }
  }

  Widget _buildWelcomeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Icon(
          Icons.celebration,
          size: 80,
          color: AppColors.primary,
        ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
        const SizedBox(height: 32),
        Text(
          'Welcome to Afeedi!',
          style: AppTextStyles.heading2.copyWith(fontSize: 28),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'We\'re excited to help you discover content that matters to you. Let\'s personalize your experience in a few simple steps.',
          style: AppTextStyles.bodyMedium.copyWith(fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildFeatureItem(
                icon: Icons.person_outline,
                title: 'Personalized Content',
                description: 'Discover videos tailored to your interests',
              ),
              const Divider(),
              _buildFeatureItem(
                icon: Icons.calendar_today_outlined,
                title: 'Calendar Integration',
                description: 'Content recommendations based on your schedule',
              ),
              const Divider(),
              _buildFeatureItem(
                icon: Icons.devices_outlined,
                title: 'Multi-Platform Experience',
                description: 'Seamlessly watch content from multiple platforms',
              ),
            ],
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
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    // Initialize controllers with existing values
    final nameController = TextEditingController(
      text: _userPreferences.personalInfo?['name'] ?? '',
    );
    final ageController = TextEditingController(
      text: _userPreferences.personalInfo?['age']?.toString() ?? '',
    );
    
    // Update preferences when text changes
    void updatePersonalInfo() {
      final personalInfo = _userPreferences.personalInfo ?? {};
      personalInfo['name'] = nameController.text;
      
      final age = int.tryParse(ageController.text);
      if (age != null) {
        personalInfo['age'] = age;
      }
      
      _updateUserPreferences('personalInfo', personalInfo);
    }
    
    nameController.addListener(updatePersonalInfo);
    ageController.addListener(updatePersonalInfo);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name field
        TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Name',
            hintText: 'Enter your name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.person_outline),
            filled: true,
            fillColor: Colors.white.withOpacity(0.9),
          ),
          textCapitalization: TextCapitalization.words,
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
        
        const SizedBox(height: 16),
        
        // Age field
        TextField(
          controller: ageController,
          decoration: InputDecoration(
            labelText: 'Age',
            hintText: 'Enter your age',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.cake_outlined),
            filled: true,
            fillColor: Colors.white.withOpacity(0.9),
          ),
          keyboardType: TextInputType.number,
        ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.1, end: 0),
        
        const SizedBox(height: 24),
        
        // Privacy note
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.privacy_tip_outlined, color: Colors.blue[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your information helps us personalize your experience. We respect your privacy and never share your data with third parties.',
                  style: TextStyle(fontSize: 14, color: Colors.blue[800]),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
      ],
    );
  }

  Widget _buildEntertainmentPreferencesStep() {
    final entertainmentPrefs = _userPreferences.entertainmentPreferences ?? {};
    
    // Content mood preferences
    final List<Map<String, dynamic>> moodOptions = [
      {'value': 'uplifting', 'label': 'Uplifting', 'icon': Icons.sentiment_very_satisfied_outlined},
      {'value': 'relaxing', 'label': 'Relaxing', 'icon': Icons.spa_outlined},
      {'value': 'exciting', 'label': 'Exciting', 'icon': Icons.flash_on_outlined},
      {'value': 'informative', 'label': 'Informative', 'icon': Icons.lightbulb_outline},
      {'value': 'challenging', 'label': 'Challenging', 'icon': Icons.psychology_outlined},
      {'value': 'funny', 'label': 'Funny', 'icon': Icons.emoji_emotions_outlined},
    ];
    
    // Initialize selected moods
    List<String> selectedMoods = List.from(entertainmentPrefs['contentMoods'] ?? []);
    
    void updateMoods(List<String> moods) {
      selectedMoods = moods;
      final updatedPrefs = Map<String, dynamic>.from(entertainmentPrefs);
      updatedPrefs['contentMoods'] = moods;
      _updateUserPreferences('entertainmentPreferences', updatedPrefs);
    }
    
    void toggleMood(String mood) {
      final updatedMoods = List<String>.from(selectedMoods);
      if (updatedMoods.contains(mood)) {
        updatedMoods.remove(mood);
      } else {
        updatedMoods.add(mood);
      }
      updateMoods(updatedMoods);
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What content moods do you prefer?',
          style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        
        // Mood selection grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: moodOptions.length,
          itemBuilder: (context, index) {
            final mood = moodOptions[index];
            final isSelected = selectedMoods.contains(mood['value']);
            
            return InkWell(
              onTap: () => toggleMood(mood['value']),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.secondary.withOpacity(0.1) : Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.secondary : Colors.grey.withOpacity(0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      mood['icon'],
                      color: isSelected ? AppColors.secondary : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      mood['label'],
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColors.secondary : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 300.ms, delay: (50 * index).ms).slideY(begin: 0.05, end: 0);
          },
        ),
        
        const SizedBox(height: 24),
        
        // Content length preference
        Text(
          'Preferred content length',
          style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        
        // Content length slider
        StatefulBuilder(
          builder: (context, setState) {
            // Content length options
            const Map<String, String> lengthLabels = {
              'short': 'Short',
              'medium': 'Medium',
              'long': 'Long',
              'any': 'Any Length',
            };
            
            final currentLength = entertainmentPrefs['contentLength'] ?? 'any';
            
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: lengthLabels.entries.map((entry) {
                    final isSelected = currentLength == entry.key;
                    return InkWell(
                      onTap: () {
                        final updatedPrefs = Map<String, dynamic>.from(entertainmentPrefs);
                        updatedPrefs['contentLength'] = entry.key;
                        _updateUserPreferences('entertainmentPreferences', updatedPrefs);
                        setState(() {});
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.secondary.withOpacity(0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: isSelected 
                              ? Border.all(color: AppColors.secondary, width: 2)
                              : null,
                        ),
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppColors.secondary : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 24),
                
                // Explanation of content length
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Content Length Guide:',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800]),
                      ),
                      const SizedBox(height: 8),
                      _buildLengthGuideItem('Short', '< 5 minutes'),
                      _buildLengthGuideItem('Medium', '5-15 minutes'),
                      _buildLengthGuideItem('Long', '> 15 minutes'),
                      _buildLengthGuideItem('Any Length', 'No preference'),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildLengthGuideItem(String label, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(description),
        ],
      ),
    );
  }

  Widget _buildCalendarIntegrationStep() {
    final calendarIntegration = _userPreferences.calendarIntegration ?? {};
    final isEnabled = calendarIntegration['enabled'] ?? false;
    
    void toggleCalendarIntegration(bool value) {
      final updatedSettings = Map<String, dynamic>.from(calendarIntegration);
      updatedSettings['enabled'] = value;
      _updateUserPreferences('calendarIntegration', updatedSettings);
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Calendar integration toggle
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.calendar_month_outlined,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Calendar Integration',
                          style: AppTextStyles.subtitle.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Get content recommendations based on your schedule',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: isEnabled,
                    onChanged: toggleCalendarIntegration,
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
              
              if (isEnabled) ...[  
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                
                // Calendar integration options
                _buildCalendarOption(
                  title: 'Recommend content for free time',
                  subtitle: 'Find videos that fit your schedule gaps',
                  value: calendarIntegration['recommendForFreeTime'] ?? true,
                  onChanged: (value) {
                    final updatedSettings = Map<String, dynamic>.from(calendarIntegration);
                    updatedSettings['recommendForFreeTime'] = value;
                    _updateUserPreferences('calendarIntegration', updatedSettings);
                  },
                ),
                
                _buildCalendarOption(
                  title: 'Event-related content',
                  subtitle: 'Suggest videos related to upcoming events',
                  value: calendarIntegration['eventRelatedContent'] ?? true,
                  onChanged: (value) {
                    final updatedSettings = Map<String, dynamic>.from(calendarIntegration);
                    updatedSettings['eventRelatedContent'] = value;
                    _updateUserPreferences('calendarIntegration', updatedSettings);
                  },
                ),
                
                _buildCalendarOption(
                  title: 'Smart notifications',
                  subtitle: 'Get notified about relevant content before events',
                  value: calendarIntegration['smartNotifications'] ?? false,
                  onChanged: (value) {
                    final updatedSettings = Map<String, dynamic>.from(calendarIntegration);
                    updatedSettings['smartNotifications'] = value;
                    _updateUserPreferences('calendarIntegration', updatedSettings);
                  },
                ),
              ],
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Privacy information
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.privacy_tip_outlined, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Text(
                    'Privacy Information',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Calendar integration is completely optional. When enabled, we only access event titles and times to provide contextual recommendations. Your calendar data never leaves your device and is not stored on our servers.',
                style: TextStyle(color: Colors.blue[800]),
              ),
              const SizedBox(height: 12),
              Text(
                'You can disable this feature at any time in your profile settings.',
                style: TextStyle(color: Colors.blue[800], fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarOption({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

// End of file