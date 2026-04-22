import 'package:flutter_test/flutter_test.dart';
import 'package:afeedi/services/onboarding_service.dart';

void main() {
  group('OnboardingService - getOnboardingSteps', () {
    late OnboardingService onboardingService;

    setUp(() {
      onboardingService = OnboardingService();
    });

    test('should return exactly 5 onboarding steps', () {
      final steps = onboardingService.getOnboardingSteps();
      expect(steps.length, 5);
    });

    test('should return steps in the correct order', () {
      final steps = onboardingService.getOnboardingSteps();

      expect(steps[0].key, 'welcome');
      expect(steps[1].key, 'content_interests');
      expect(steps[2].key, 'platform_preferences');
      expect(steps[3].key, 'personal_info');
      expect(steps[4].key, 'completion');
    });

    test('welcome step should have correct configuration', () {
      final steps = onboardingService.getOnboardingSteps();
      final welcomeStep = steps[0];

      expect(welcomeStep.key, 'welcome');
      expect(welcomeStep.allowTextInput, isTrue);
      expect(welcomeStep.quickReplies.length, 3);
      expect(welcomeStep.isGenreSelection, isFalse);
      expect(welcomeStep.isPlatformSelection, isFalse);
    });

    test('genre selection step should have correct configuration', () {
      final steps = onboardingService.getOnboardingSteps();
      final genreStep = steps[1];

      expect(genreStep.key, 'content_interests');
      expect(genreStep.allowTextInput, isFalse);
      expect(genreStep.quickReplies, isEmpty);
      expect(genreStep.isGenreSelection, isTrue);
      expect(genreStep.allowMultiSelect, isTrue);
    });

    test('platform selection step should have correct configuration', () {
      final steps = onboardingService.getOnboardingSteps();
      final platformStep = steps[2];

      expect(platformStep.key, 'platform_preferences');
      expect(platformStep.allowTextInput, isFalse);
      expect(platformStep.quickReplies, isEmpty);
      expect(platformStep.isPlatformSelection, isTrue);
      expect(platformStep.showSkipOption, isTrue);
    });

    test('personal info step should have correct configuration', () {
      final steps = onboardingService.getOnboardingSteps();
      final personalInfoStep = steps[3];

      expect(personalInfoStep.key, 'personal_info');
      expect(personalInfoStep.allowTextInput, isTrue);
      expect(personalInfoStep.quickReplies.length, 3);
      expect(personalInfoStep.isGenreSelection, isFalse);
      expect(personalInfoStep.isPlatformSelection, isFalse);
    });

    test('completion step should have correct configuration', () {
      final steps = onboardingService.getOnboardingSteps();
      final completionStep = steps[4];

      expect(completionStep.key, 'completion');
      expect(completionStep.allowTextInput, isFalse);
      expect(completionStep.quickReplies.length, 2);
      expect(completionStep.isGenreSelection, isFalse);
      expect(completionStep.isPlatformSelection, isFalse);
    });
  });
}
