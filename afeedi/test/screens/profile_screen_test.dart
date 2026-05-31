/// Profile screen tests.
///
/// ProfileScreen uses Image.network() with hardcoded picsum.photos URLs which
/// fail in a CI/headless test environment. We isolate the network error by
/// wrapping each pump in `tester.runAsync` and swallowing the HTTP exception
/// inside the image stream completer so the widget-tree assertions still work.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import 'package:afeedi/screens/profile_screen.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('afeedi_profile_test');

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

  /// Pumps the ProfileScreen, routing the image-load exception to a no-op
  /// handler so tests can still inspect text and icon widgets.
  Future<void> pumpProfile(WidgetTester tester) async {
    // Swap in a handler that eats any network image errors from picsum.
    final prev = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exception.toString().contains('NetworkImageLoadException') ||
          details.exception.toString().contains('HTTP request failed') ||
          details.exception.toString().contains('picsum')) {
        return; // suppress network image noise in headless tests
      }
      prev?.call(details);
    };

    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));

    // We deliberately skip pumpAndSettle because the network image never
    // resolves; just advance one microtask queue flush so the widget tree is
    // laid out.
    await tester.pump(const Duration(milliseconds: 50));

    FlutterError.onError = prev;
  }

  group('ProfileScreen', () {
    testWidgets('renders a Scaffold without throwing', (tester) async {
      await pumpProfile(tester);
      expect(find.byType(Scaffold), findsOneWidget);
    }, skip: false);

    testWidgets('shows default user name', (tester) async {
      await pumpProfile(tester);
      // Default name when no user is logged in
      expect(find.text('You'), findsOneWidget);
    });

    testWidgets('shows Videos Watched stat label', (tester) async {
      await pumpProfile(tester);
      // Stat label rendered as 'Videos\nWatched' (multiline)
      expect(find.textContaining('Videos'), findsWidgets);
    });

    testWidgets('shows Watch Time stat label', (tester) async {
      await pumpProfile(tester);
      // Stat label rendered as 'Watch\nTime' (multiline)
      expect(find.textContaining('Time'), findsWidgets);
    });

    testWidgets('shows Streak stat label', (tester) async {
      await pumpProfile(tester);
      expect(find.text('Streak'), findsOneWidget);
    });

    testWidgets('has four tabs: Liked, Saved, History, Achievements', (
      tester,
    ) async {
      await pumpProfile(tester);
      expect(find.text('Liked'), findsOneWidget);
      // 'Saved' appears in both the stat row and the tab label
      expect(find.text('Saved'), findsWidgets);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Achievements'), findsOneWidget);
    });

    testWidgets('has edit profile icon', (tester) async {
      await pumpProfile(tester);
      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('Achievements tab is present and tappable', (tester) async {
      await pumpProfile(tester);
      final achievementsTab = find.text('Achievements');
      expect(achievementsTab, findsOneWidget);
      // The tab is tappable without throwing
      await tester.tap(achievementsTab);
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets('tapping edit opens a dialog', (tester) async {
      await pumpProfile(tester);
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });
}
