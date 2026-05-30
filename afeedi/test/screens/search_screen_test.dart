import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import 'package:afeedi/screens/search_screen.dart';
import 'package:afeedi/l10n/app_localizations.dart';

Widget _buildApp(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('afeedi_search_test');

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

  group('SearchScreen', () {
    testWidgets('SearchScreen renders correctly', (tester) async {
      await tester.pumpWidget(_buildApp(const SearchScreen()));
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('SearchScreen shows trending topics', (tester) async {
      await tester.pumpWidget(_buildApp(const SearchScreen()));
      await tester.pump();

      // The discover section (shown when no query) shows "Popular Topics" heading
      expect(find.text('Popular Topics'), findsOneWidget);
    });

    testWidgets('SearchScreen shows search field', (tester) async {
      await tester.pumpWidget(_buildApp(const SearchScreen()));
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('SearchScreen returns empty for empty query', (tester) async {
      await tester.pumpWidget(_buildApp(const SearchScreen()));
      await tester.pump();

      // Enter a query then clear it to simulate an empty search
      await tester.enterText(find.byType(TextField), 'flutter');
      await tester.pump();

      await tester.enterText(find.byType(TextField), '');
      await tester.pump();

      // When query is empty, no results are shown and discover view appears
      expect(find.text('Popular Topics'), findsOneWidget);
    });

    testWidgets('SearchScreen shows discover content by platform', (tester) async {
      await tester.pumpWidget(_buildApp(const SearchScreen()));
      await tester.pump();

      expect(find.text('Browse by Platform'), findsOneWidget);
    });

    testWidgets('SearchScreen shows recent searches', (tester) async {
      await tester.pumpWidget(_buildApp(const SearchScreen()));
      await tester.pump();

      expect(find.text('Recent Searches'), findsOneWidget);
    });

    testWidgets('SearchScreen shows empty state (discover) before any search',
        (tester) async {
      await tester.pumpWidget(_buildApp(const SearchScreen()));
      await tester.pump();

      // Before any query is entered, the discover view is shown (not results)
      expect(find.text('Popular Topics'), findsOneWidget);
      expect(find.text('Browse by Platform'), findsOneWidget);
    });

    testWidgets('SearchScreen has search TextField', (tester) async {
      await tester.pumpWidget(_buildApp(const SearchScreen()));
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('SearchScreen has platform filter chips after search',
        (tester) async {
      await tester.pumpWidget(_buildApp(const SearchScreen()));
      await tester.pump();

      // Enter a query to trigger results view with platform filter row
      await tester.enterText(find.byType(TextField), 'flutter');
      await tester.pump();

      // Platform filters are shown once a search query is active
      expect(find.text('YouTube'), findsWidgets);
      expect(find.text('TikTok'), findsWidgets);
    });

    testWidgets('SearchScreen sanitizes very long queries gracefully',
        (tester) async {
      await tester.pumpWidget(_buildApp(const SearchScreen()));
      await tester.pump();

      // A query longer than 200 characters should not crash the app
      final longQuery = 'a' * 300;
      await tester.enterText(find.byType(TextField), longQuery);
      await tester.pump();

      // Screen still renders after very long input
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('SearchScreen sanitizes HTML/script injection in query',
        (tester) async {
      await tester.pumpWidget(_buildApp(const SearchScreen()));
      await tester.pump();

      // HTML tags should be stripped without causing errors
      await tester.enterText(
          find.byType(TextField), '<script>alert(1)</script>flutter');
      await tester.pump();

      // Screen still renders after HTML-injected input
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('SearchScreen returns to discover view when query is cleared',
        (tester) async {
      await tester.pumpWidget(_buildApp(const SearchScreen()));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'flutter');
      await tester.pump();

      await tester.enterText(find.byType(TextField), '');
      await tester.pump();

      // After clearing, discover view returns
      expect(find.text('Popular Topics'), findsOneWidget);
    });

    testWidgets('SearchScreen shows search icon in search bar', (tester) async {
      await tester.pumpWidget(_buildApp(const SearchScreen()));
      await tester.pump();

      expect(find.byIcon(Icons.search), findsOneWidget);
    });
  });
}
