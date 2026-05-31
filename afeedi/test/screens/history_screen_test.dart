import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import 'package:afeedi/screens/history_screen.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('afeedi_history_test');

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

  group('HistoryScreen', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HistoryScreen()));
      await tester.pump();

      expect(find.byType(HistoryScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows empty state when no history', (tester) async {
      // No watched_ids or watch_progress_ keys → empty state
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const MaterialApp(home: HistoryScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('No watch history yet.'), findsOneWidget);
    });

    testWidgets("shows correct title 'Watch History'", (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HistoryScreen()));
      await tester.pump();

      expect(find.text('Watch History'), findsOneWidget);
    });
  });
}
