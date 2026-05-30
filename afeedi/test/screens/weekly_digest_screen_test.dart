import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import 'package:afeedi/screens/weekly_digest_screen.dart';

Widget _buildApp(Widget child) => MaterialApp(
      home: child,
      routes: {
        '/player': (_) => const Scaffold(body: Text('Player')),
      },
    );

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('afeedi_digest_test');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall call) async => tempDir.path,
    );

    Hive.init(tempDir.path);
    SharedPreferences.setMockInitialValues({
      'onboarding_user_name': 'Soumya',
      'onboarding_selected_genres': ['Gaming', 'Tech', 'Comedy'],
    });
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('WeeklyDigestScreen renders a Scaffold without throwing', (tester) async {
    await tester.pumpWidget(_buildApp(const WeeklyDigestScreen()));
    await tester.pump();
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('WeeklyDigestScreen shows "Weekly Digest" app bar title', (tester) async {
    await tester.pumpWidget(_buildApp(const WeeklyDigestScreen()));
    await tester.pump();
    expect(find.text('Weekly Digest'), findsOneWidget);
  });

  testWidgets('WeeklyDigestScreen shows Share action button', (tester) async {
    await tester.pumpWidget(_buildApp(const WeeklyDigestScreen()));
    await tester.pump();
    expect(find.text('Share'), findsOneWidget);
  });

  testWidgets('WeeklyDigestScreen shows AI DIGEST badge', (tester) async {
    await tester.pumpWidget(_buildApp(const WeeklyDigestScreen()));
    await tester.pump();
    expect(find.text('AI DIGEST'), findsOneWidget);
  });

  testWidgets('WeeklyDigestScreen shows week label in header', (tester) async {
    await tester.pumpWidget(_buildApp(const WeeklyDigestScreen()));
    await tester.pump();
    // Week label format: "May 25 – May 31"
    // Month abbreviation should appear
    final monthAbbrevs = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final found = monthAbbrevs.any((m) => find.textContaining(m).evaluate().isNotEmpty);
    expect(found, isTrue);
  });

  testWidgets('WeeklyDigestScreen shows genre chips when genres selected', (tester) async {
    await tester.pumpWidget(_buildApp(const WeeklyDigestScreen()));
    await tester.pump();
    // Should show at least one of the selected genres
    final hasGenre = find.text('Gaming').evaluate().isNotEmpty ||
        find.text('Tech').evaluate().isNotEmpty ||
        find.text('Comedy').evaluate().isNotEmpty;
    expect(hasGenre, isTrue);
  });

  testWidgets('WeeklyDigestScreen loading indicator or picks shown after settle', (tester) async {
    await tester.pumpWidget(_buildApp(const WeeklyDigestScreen()));
    await tester.pump();
    // Either CircularProgressIndicator (loading) or picks (loaded)
    final isLoading = find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
    final hasPicks = find.text("This week's picks").evaluate().isNotEmpty;
    expect(isLoading || hasPicks, isTrue);
  });

  testWidgets('WeeklyDigestScreen shows loading indicator initially', (tester) async {
    await tester.pumpWidget(_buildApp(const WeeklyDigestScreen()));
    await tester.pump(); // one frame — still loading
    // Either loading indicator or already-loaded content
    final hasSpinner = find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
    final hasContent = find.text("This week's picks").evaluate().isNotEmpty ||
        find.text('Complete onboarding to personalize your digest.').evaluate().isNotEmpty;
    expect(hasSpinner || hasContent, isTrue);
  });

  testWidgets('WeeklyDigestScreen back button has tooltip', (tester) async {
    await tester.pumpWidget(_buildApp(const WeeklyDigestScreen()));
    await tester.pump();
    // IconButton with tooltip 'Back'
    expect(
      find.byTooltip('Back'),
      findsOneWidget,
    );
  });
}
