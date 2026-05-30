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

      // The discover section (shown when no query) shows "Trending Topics" heading
      expect(find.text('Trending Topics'), findsOneWidget);
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
      expect(find.text('Trending Topics'), findsOneWidget);
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
  });
}
