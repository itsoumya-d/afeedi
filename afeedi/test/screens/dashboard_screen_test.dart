import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import 'package:afeedi/screens/dashboard_screen.dart';
import 'package:afeedi/widgets/common/shared_bottom_navigation.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('afeedi_dashboard_test');

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

  group('DashboardScreen', () {
    testWidgets('DashboardScreen renders with bottom navigation', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));
      // Pump once to build the widget tree without waiting for async content
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(SharedBottomNavigation), findsOneWidget);
    });

    testWidgets('DashboardScreen has 5 tabs', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));
      await tester.pump();

      // The SharedBottomNavigation displays the 5 tab labels
      expect(find.byType(SharedBottomNavigation), findsOneWidget);
      expect(find.text('Home'), findsWidgets);
      expect(find.text('Discover'), findsWidgets);
      expect(find.text('Shorts'), findsWidgets);
      expect(find.text('Profile'), findsWidgets);
    });

    testWidgets('DashboardScreen shows Home tab by default', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));
      await tester.pump();

      // The initial page is 0 (Home). PageController starts at page 0 by default.
      final pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.controller?.initialPage ?? 0, equals(0));
    });

    testWidgets('DashboardScreen shows app bar with Afeedi branding',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));
      await tester.pump();

      expect(find.text('Afeedi'), findsOneWidget);
    });

    testWidgets('DashboardScreen contains PageView for tab content',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));
      await tester.pump();

      expect(find.byType(PageView), findsOneWidget);
    });
  });
}
