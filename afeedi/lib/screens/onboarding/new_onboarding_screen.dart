import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/onboarding_service.dart';
import '../../models/user_preferences.dart';
import '../../services/navigation_service.dart';
import '../../services/analytics_service.dart';
import 'widgets/onboarding_step_widget.dart';
import 'widgets/progress_indicator_widget.dart';
import 'widgets/step_navigation_widget.dart';

class NewOnboardingScreen extends StatefulWidget {
  const NewOnboardingScreen({super.key});

  @override
  State<NewOnboardingScreen> createState() => _NewOnboardingScreenState();
}

class _NewOnboardingScreenState extends State<NewOnboardingScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  Map<String, dynamic>? _currentStep;
  Map<String, dynamic> _stepData = {};
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeOnboarding();
  }
  
  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }
  
  Future<void> _initializeOnboarding() async {
    setState(() => _isLoading = true);
    
    try {
      await OnboardingService.instance.initialize();
      
      // Check if onboarding is already completed
      final isCompleted = await OnboardingService().isOnboardingCompleted();
      if (isCompleted && mounted) {
        NavigationService.pushReplacementNamed('/dashboard');
        return;
      }
      
      // Get the next step
      _currentStep = OnboardingService().getNextStep();
      
      if (_currentStep == null && mounted) {
        // All steps completed, navigate to home
        NavigationService.navigateToHome();
        return;
      }
      
      _fadeController.forward();
      _slideController.forward();
      
    } catch (e) {
      setState(() => _errorMessage = 'Failed to initialize onboarding: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _nextStep() async {
    if (_currentStep == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Validate step data
      if (_currentStep!['required'] == true && _stepData.isEmpty) {
        setState(() => _errorMessage = 'Please complete this step before continuing');
        return;
      }
      
      // Complete current step
      await OnboardingService().completeStep(
        _currentStep!['id'],
        _stepData,
      );
      
      // Animate out
      await _slideController.reverse();
      
      // Get next step
      _currentStep = OnboardingService().getNextStep();
      _stepData.clear();
      
      if (_currentStep == null) {
        // Onboarding completed
        if (mounted) {
          NavigationService.pushReplacementNamed('/dashboard');
        }
        return;
      }
      
      // Animate in new step
      await _slideController.forward();
      
      // Haptic feedback
      HapticFeedback.lightImpact();
      
    } catch (e) {
      setState(() => _errorMessage = 'Failed to proceed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _previousStep() async {
    // For now, we'll just go back in the step flow
    // In a more complex implementation, we could track step history
    HapticFeedback.lightImpact();
  }
  
  Future<void> _skipStep() async {
    if (_currentStep == null || _currentStep!['required'] == true) return;
    
    setState(() => _isLoading = true);
    
    try {
      await OnboardingService().skipStep(_currentStep!['id']);
      await _nextStep();
    } catch (e) {
      setState(() => _errorMessage = 'Failed to skip step: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  void _updateStepData(Map<String, dynamic> data) {
    setState(() {
      _stepData = {..._stepData, ...data};
      _errorMessage = null;
    });
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState()
            : _errorMessage != null
                ? _buildErrorState()
                : _buildOnboardingContent(),
      ),
    );
  }
  
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Setting up your experience...',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => setState(() => _errorMessage = null),
                  child: const Text('Retry'),
                ),
                const SizedBox(width: 16),
                FilledButton(
                  onPressed: () => NavigationService.pushReplacementNamed('/dashboard'),
                  child: const Text('Skip Onboarding'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOnboardingContent() {
    if (_currentStep == null) {
      return const Center(
        child: Text('No onboarding steps available'),
      );
    }
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Progress indicator
          ProgressIndicatorWidget(
            progress: OnboardingService().getProgress(),
            currentStep: _currentStep!['title'] ?? '',
            totalSteps: OnboardingService.onboardingFlow.length,
          ),
          
          // Main content
          Expanded(
            child: SlideTransition(
              position: _slideAnimation,
              child: OnboardingStepWidget(
                step: _currentStep!,
                data: _stepData,
                onDataChanged: _updateStepData,
              ),
            ),
          ),
          
          // Navigation buttons
          StepNavigationWidget(
            canGoBack: OnboardingService.instance.completedSteps.isNotEmpty,
            showSkip: _currentStep!['required'] != true,
            isLoading: _isLoading,
            onNext: _nextStep,
            onBack: _previousStep,
            onSkip: _skipStep,
          ),
        ],
      ),
    );
  }
}

// Extension for easier step type checking
extension StepTypeExtension on Map<String, dynamic> {
  String get stepType => this['type'] ?? 'form';
  bool get isRequired => this['required'] == true;
  List<String> get fields => List<String>.from(this['fields'] ?? []);
  List<dynamic> get options => this['options'] ?? [];
}