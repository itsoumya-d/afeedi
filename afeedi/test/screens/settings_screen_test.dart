import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import 'package:afeedi/screens/settings_screen.dart';
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
    tempDir = await Directory.systemTemp.createTemp('afeedi_settings_test');

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

  group('SettingsScreen', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(_buildApp(const SettingsScreen()));
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('has dark mode toggle', (tester) async {
      await tester.pumpWidget(_buildApp(const SettingsScreen()));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Dark Mode'), findsOneWidget);
      expect(find.byType(SwitchListTile), findsWidgets);
    });

    testWidgets('has Privacy Policy tile', (tester) async {
      tester.view.physicalSize = const Size(800, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildApp(const SettingsScreen()));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Privacy Policy'), findsOneWidget);
    });

    testWidgets('has Terms of Service tile', (tester) async {
      tester.view.physicalSize = const Size(800, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildApp(const SettingsScreen()));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Terms of Service'), findsOneWidget);
    });

    testWidgets('has account section', (tester) async {
      tester.view.physicalSize = const Size(800, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildApp(const SettingsScreen()));
      await tester.pump(const Duration(seconds: 1));

      // _sectionHeader renders title.toUpperCase()
      expect(find.text('ACCOUNT'), findsOneWidget);
    });
  });
}
