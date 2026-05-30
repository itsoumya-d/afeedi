import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import 'package:afeedi/screens/welcome_screen.dart';
import 'package:afeedi/screens/login_screen.dart';
import 'package:afeedi/screens/create_account_screen.dart';
import 'package:afeedi/screens/search_screen.dart';
import 'package:afeedi/screens/settings_screen.dart';
import 'package:afeedi/screens/profile_screen.dart';
import 'package:afeedi/screens/notifications_screen.dart';
import 'package:afeedi/services/navigation_service.dart';
import 'package:afeedi/l10n/app_localizations.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('afeedi_nav_test');

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

  group('App Routes', () {
    testWidgets('welcome screen renders (${AppRoutes.welcome})', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));
      // Advance past the 300ms Future.delayed in WelcomeScreen.initState
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('login screen renders (${AppRoutes.login})', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      // Advance past the 300ms Future.delayed used to start slide animation
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('create account screen renders (${AppRoutes.createAccount})',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const MaterialApp(home: CreateAccountScreen()));
      // Advance past the 300ms Future.delayed used to start slide animation
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('search screen renders (${AppRoutes.search})', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SearchScreen(),
      ));
      await tester.pump();
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('settings screen renders (${AppRoutes.settings})',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SettingsScreen(),
      ));
      await tester.pump();
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('profile screen renders (${AppRoutes.profile})', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
      await tester.pump();
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('notifications screen renders (${AppRoutes.notifications})',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const NotificationsScreen(),
      ));
      await tester.pump();
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('AppRoutes constants', () {
    test('route constants have expected values', () {
      expect(AppRoutes.welcome, equals('/'));
      expect(AppRoutes.login, equals('/login'));
      expect(AppRoutes.createAccount, equals('/create-account'));
      expect(AppRoutes.dashboard, equals('/dashboard'));
      expect(AppRoutes.search, equals('/search'));
      expect(AppRoutes.settings, equals('/settings'));
      expect(AppRoutes.profile, equals('/profile'));
      expect(AppRoutes.notifications, equals('/notifications'));
    });

    test('routes map contains all required routes', () {
      final routes = AppRoutes.routes;
      expect(routes.containsKey(AppRoutes.welcome), isTrue);
      expect(routes.containsKey(AppRoutes.login), isTrue);
      expect(routes.containsKey(AppRoutes.createAccount), isTrue);
      expect(routes.containsKey(AppRoutes.dashboard), isTrue);
      expect(routes.containsKey(AppRoutes.search), isTrue);
      expect(routes.containsKey(AppRoutes.settings), isTrue);
      expect(routes.containsKey(AppRoutes.profile), isTrue);
      expect(routes.containsKey(AppRoutes.notifications), isTrue);
    });
  });
}
