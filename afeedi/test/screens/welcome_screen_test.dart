import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import 'package:afeedi/screens/welcome_screen.dart';
import 'package:afeedi/l10n/app_localizations.dart';

Widget _buildApp(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

/// Pump the widget tree and drain all pending timers from the
/// WelcomeScreen animation controllers (fade=1500ms, slide=1200ms,
/// plus a 300ms Future.delayed).
Future<void> _pumpWelcome(WidgetTester tester) async {
  await tester.pumpWidget(_buildApp(const WelcomeScreen()));
  // Advance past the 300ms Future.delayed and then the animation durations
  await tester.pump(const Duration(milliseconds: 300));  // fires the delayed
  await tester.pump(const Duration(milliseconds: 1500)); // fade animation
  await tester.pump(const Duration(milliseconds: 100));  // slide animation tail
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('afeedi_welcome_test');

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

  group('WelcomeScreen', () {
    testWidgets('renders without errors', (tester) async {
      await _pumpWelcome(tester);

      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows app name Afeedi', (tester) async {
      await _pumpWelcome(tester);

      expect(find.text('Afeedi'), findsOneWidget);
    });

    testWidgets('has Get Started button', (tester) async {
      await _pumpWelcome(tester);

      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets('has Continue with Google button', (tester) async {
      await _pumpWelcome(tester);

      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets('has Continue with Apple button', (tester) async {
      await _pumpWelcome(tester);

      expect(find.text('Continue with Apple'), findsOneWidget);
    });

    testWidgets('has Skip button', (tester) async {
      await _pumpWelcome(tester);

      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('has play_arrow icon in logo badge', (tester) async {
      await _pumpWelcome(tester);

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('has Google icon on sign-in button', (tester) async {
      await _pumpWelcome(tester);

      expect(find.byIcon(Icons.g_mobiledata), findsOneWidget);
    });

    testWidgets('has Apple icon on sign-in button', (tester) async {
      await _pumpWelcome(tester);

      expect(find.byIcon(Icons.apple), findsOneWidget);
    });

    testWidgets('has Already have an account sign-in link', (tester) async {
      await _pumpWelcome(tester);

      expect(find.text('Already have an account? Sign in'), findsOneWidget);
    });

    testWidgets('Get Started button is semantically labeled', (tester) async {
      await _pumpWelcome(tester);

      // Accessibility: Semantics wraps the Get Started button
      expect(find.bySemanticsLabel('Get started with Afeedi'), findsOneWidget);
    });

    testWidgets('Sign in button is semantically labeled', (tester) async {
      await _pumpWelcome(tester);

      expect(find.bySemanticsLabel('Sign in to Afeedi'), findsOneWidget);
    });

    testWidgets('shows tagline text', (tester) async {
      await _pumpWelcome(tester);

      expect(
        find.text('All your favorite videos. One premium experience.'),
        findsOneWidget,
      );
    });

    testWidgets('shows OutlinedButton widgets for OAuth sign-in',
        (tester) async {
      await _pumpWelcome(tester);

      // Google and Apple both use OutlinedButton.icon
      expect(find.byType(OutlinedButton), findsWidgets);
    });

    testWidgets('renders correctly after all animations complete',
        (tester) async {
      await _pumpWelcome(tester);

      expect(find.byType(WelcomeScreen), findsOneWidget);
    });
  });
}
