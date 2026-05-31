import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:afeedi/main.dart' as app;
import 'package:afeedi/services/local_auth_service.dart';
import 'package:afeedi/services/onboarding_service.dart';

/// End-to-end integration tests for the Afeedi app.
///
/// These run the real app (not a mock) against widget interactions.
/// Run on device/emulator: flutter test integration_test/
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // E2E 1 — App launches and shows welcome screen
  // ---------------------------------------------------------------------------
  testWidgets('App launches and renders welcome screen for unauthenticated user',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    await app.appMain();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    final hasWelcome = find.textContaining('Afeedi', findRichText: true);
    expect(hasWelcome, findsWidgets,
        reason: 'Welcome screen must display Afeedi branding');
  });

  // ---------------------------------------------------------------------------
  // E2E 2 — Dashboard loads for authenticated user
  // ---------------------------------------------------------------------------
  testWidgets('Dashboard renders correctly for logged-in user', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await LocalAuthService.instance.initialize();
    await LocalAuthService.instance.signUp(
      email: 'e2e@afeedi.test',
      password: 'password123',
      fullName: 'E2E Tester',
    );
    await OnboardingService.instance.initialize();
    await OnboardingService.instance.markOnboardingComplete();

    await app.appMain();
    await tester.pumpAndSettle(const Duration(seconds: 4));

    expect(find.byType(BottomNavigationBar), findsOneWidget,
        reason: 'Dashboard must show bottom navigation');
  });

  // ---------------------------------------------------------------------------
  // E2E 3 — Feed displays Card widgets for authenticated user
  // ---------------------------------------------------------------------------
  testWidgets('Feed displays content cards for authenticated user',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await LocalAuthService.instance.initialize();
    await LocalAuthService.instance.signUp(
      email: 'feed@afeedi.test',
      password: 'password123',
      fullName: 'Feed Tester',
    );
    await OnboardingService.instance.initialize();
    await OnboardingService.instance.markOnboardingComplete();

    await app.appMain();
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.byType(Card), findsWidgets,
        reason: 'Feed should display at least one content card');
  });

  // ---------------------------------------------------------------------------
  // E2E 4 — App always shows a Scaffold
  // ---------------------------------------------------------------------------
  testWidgets('App always renders a Scaffold (no blank screen)',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    await app.appMain();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.byType(Scaffold), findsWidgets,
        reason: 'App must always render at least one Scaffold');
  });

  // ---------------------------------------------------------------------------
  // E2E 5 — MaterialApp is present
  // ---------------------------------------------------------------------------
  testWidgets('MaterialApp is present in widget tree', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await app.appMain();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
