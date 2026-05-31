/// Edge-case tests for EnhancedOnboardingScreen.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:afeedi/screens/onboarding/enhanced_onboarding_screen.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('afeedi_onboarding_edge');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall call) async => tempDir.path,
        );

    Hive.init(tempDir.path);
    SharedPreferences.setMockInitialValues({});
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  /// Pumps the onboarding screen with the COPPA age-gate bypassed and drains
  /// the initial animation frames.
  Future<void> pumpOnboarding(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'coppa_age_verified': true});
    await tester.pumpWidget(
      const MaterialApp(home: EnhancedOnboardingScreen()),
    );
    // Drain post-frame callbacks (draft resume, age-gate check).
    await tester.pump(const Duration(milliseconds: 100));
    // Let entrance animations tick without pumpAndSettle (avoids infinite
    // animation loops from the confetti controller).
    await tester.pump(const Duration(milliseconds: 900));
  }

  group('EnhancedOnboardingScreen', () {
    testWidgets('renders without errors', (tester) async {
      await pumpOnboarding(tester);

      expect(find.byType(EnhancedOnboardingScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('name field has maxLength 50', (tester) async {
      // Use the draft-resume mechanism to jump directly to the profile step
      // (index 6) where the name TextFormField(maxLength: 50) lives.
      final now = DateTime.now().toIso8601String();
      SharedPreferences.setMockInitialValues({
        'coppa_age_verified': true,
        'enhanced_onboarding_draft_step': 6,
        'enhanced_onboarding_draft_saved_at': now,
      });

      await tester.runAsync(() async {
        await tester.pumpWidget(
          const MaterialApp(home: EnhancedOnboardingScreen()),
        );
        // Allow real async operations (SharedPreferences, post-frame callbacks)
        // to complete.
        await Future<void>.delayed(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 900));
      });

      // The profile step wraps a TextFormField(maxLength: 50) → TextField.
      bool foundMaxLength50 = false;
      for (final tf in tester.widgetList<TextField>(find.byType(TextField))) {
        if (tf.maxLength == 50) {
          foundMaxLength50 = true;
          break;
        }
      }

      expect(
        foundMaxLength50,
        isTrue,
        reason:
            'Expected a TextField with maxLength 50 on the profile step. '
            'Ensure EnhancedOnboardingScreen._buildPersonalInfoStep() '
            'sets maxLength: 50 on the name TextFormField.',
      );
    });

    testWidgets('shows first onboarding step content', (tester) async {
      await pumpOnboarding(tester);

      // First step is 'welcome' — title is 'Welcome to Afeedi'.
      expect(find.textContaining('Welcome'), findsWidgets);
      // Progress indicator label confirms step 1.
      expect(find.textContaining('Step 1'), findsOneWidget);
    });

    testWidgets('back button on first page shows leave dialog', (tester) async {
      await pumpOnboarding(tester);

      // Trigger the Android back gesture via the Navigator — PopScope intercepts
      // it on the first page and shows the leave-setup AlertDialog.
      final NavigatorState navigator = tester.state(find.byType(Navigator));
      navigator.maybePop();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Leave setup?'), findsOneWidget);
    });

    testWidgets('language validation shows snackbar when empty', (
      tester,
    ) async {
      // Use the draft-resume mechanism to start directly on the language step
      // (index 1) without going through the animated page transition.
      final now = DateTime.now().toIso8601String();
      SharedPreferences.setMockInitialValues({
        'coppa_age_verified': true,
        'enhanced_onboarding_draft_step': 1,
        'enhanced_onboarding_draft_saved_at': now,
      });
      await tester.pumpWidget(
        const MaterialApp(home: EnhancedOnboardingScreen()),
      );
      // Let post-frame callbacks fire (draft resume + age-gate).
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 900));

      // Now on the language step — tap Next without selecting a language.
      final nextBtn = find.widgetWithText(ElevatedButton, 'Next');
      expect(nextBtn, findsOneWidget);
      await tester.tap(nextBtn);
      // One frame for showSnackBar to schedule the widget.
      await tester.pump();
      // One more frame to start the SnackBar slide-in animation.
      await tester.pump(const Duration(milliseconds: 100));

      // The SnackBar widget must be present in the tree.
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
