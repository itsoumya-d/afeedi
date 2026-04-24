import 'package:flutter_test/flutter_test.dart';
import 'package:afeedi/services/onboarding_service.dart';
import 'package:afeedi/core/storage/local_storage_service.dart';
import 'package:afeedi/models/user_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

void main() {
  late OnboardingService onboardingService;

  setUpAll(() async {
    // Setup Hive for testing
    final tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);
    SharedPreferences.setMockInitialValues({});
    await LocalStorageService.instance.initialize();
  });

  setUp(() async {
    onboardingService = OnboardingService.instance;
    onboardingService.resetOnboarding();
    await LocalStorageService.instance.clearAllData();
  });

  group('OnboardingService Persistence Tests', () {
    test('Initial state is correct', () async {
      expect(onboardingService.getProgress(), 0.0);
      final isCompleted = await onboardingService.isOnboardingCompleted();
      expect(isCompleted, false);
    });

    test('completeStep persists progress', () async {
      await onboardingService.completeStep(0, {'welcome': 'done'});

      expect(onboardingService.getProgress(), 0.2); // 1/5 steps

      // Use instance to verify persistence
      final newService = OnboardingService.instance;
      await newService.initialize();

      expect(newService.getProgress(), 0.2);
    });

    test('skipStep persists progress', () async {
      await onboardingService.skipStep(0);

      expect(onboardingService.getProgress(), 0.2);

      final newService = OnboardingService.instance;
      await newService.initialize();

      expect(newService.getProgress(), 0.2);
    });

    test('markOnboardingComplete persists completion state', () async {
      await onboardingService.markOnboardingComplete();

      expect(await onboardingService.isOnboardingCompleted(), true);

      final newService = OnboardingService.instance;
      await newService.initialize();
      expect(await newService.isOnboardingCompleted(), true);
    });

    test('savePreferences and getCurrentPreferences persist user choices', () async {
      final prefs = UserPreferences(
        name: 'Test User',
        contentInterests: ['Gaming', 'Music'],
        platformPriorities: {'youtube': 1.0, 'instagram': 0.0},
      );

      await onboardingService.savePreferences(prefs);

      final savedPrefs = await onboardingService.getCurrentPreferences();
      expect(savedPrefs?.name, 'Test User');
      expect(savedPrefs?.contentInterests, containsAll(['Gaming', 'Music']));
      expect(savedPrefs?.platformPriorities['youtube'], 1.0);

      final newService = OnboardingService.instance;
      await newService.initialize();
      final loadedPrefs = await newService.getCurrentPreferences();
      expect(loadedPrefs?.name, 'Test User');
    });
  });
}
