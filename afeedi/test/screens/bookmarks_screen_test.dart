import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import 'package:afeedi/screens/bookmarks_screen.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('afeedi_bookmarks_test');

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

  group('BookmarksScreen', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: BookmarksScreen()));
      await tester.pump();

      expect(find.byType(BookmarksScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows empty state when no bookmarks', (tester) async {
      // No saved_ keys in prefs → empty state
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const MaterialApp(home: BookmarksScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('No saved videos yet.'), findsOneWidget);
    });

    testWidgets("has correct app bar title 'Bookmarks'", (tester) async {
      await tester.pumpWidget(const MaterialApp(home: BookmarksScreen()));
      await tester.pump();

      expect(find.text('Bookmarks'), findsOneWidget);
    });

    testWidgets('sort popup menu button exists', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: BookmarksScreen()));
      await tester.pump();

      // The AppBar has a PopupMenuButton identified by its filter_list icon
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });
  });
}
