import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import 'package:afeedi/screens/referral_screen.dart';

Widget _buildApp(Widget child) => MaterialApp(home: child);

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('afeedi_referral_test');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall call) async => tempDir.path,
        );

    Hive.init(tempDir.path);
    SharedPreferences.setMockInitialValues({
      'user_id': 'testuser123',
      'referral_invites_sent': 2,
      'referral_friends_joined': 1,
    });
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('ReferralScreen renders a Scaffold without throwing', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(const ReferralScreen()));
    await tester.pumpAndSettle();
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('ReferralScreen shows "Invite Friends" app bar title', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(const ReferralScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Invite Friends'), findsOneWidget);
  });

  testWidgets('ReferralScreen shows referral code with AF- prefix', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(const ReferralScreen()));
    await tester.pumpAndSettle();
    // Code format is AF-XXXXXX
    expect(find.textContaining('AF-'), findsOneWidget);
  });

  testWidgets('ReferralScreen shows "Your referral code" label', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(const ReferralScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Your referral code'), findsOneWidget);
  });

  testWidgets('ReferralScreen shows Share Invite button', (tester) async {
    await tester.pumpWidget(_buildApp(const ReferralScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Share Invite'), findsOneWidget);
  });

  testWidgets('ReferralScreen shows Invites Sent stat', (tester) async {
    await tester.pumpWidget(_buildApp(const ReferralScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Invites Sent'), findsOneWidget);
  });

  testWidgets('ReferralScreen shows Friends Joined stat', (tester) async {
    await tester.pumpWidget(_buildApp(const ReferralScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Friends Joined'), findsOneWidget);
  });

  testWidgets('ReferralScreen shows Pro Days Earned stat', (tester) async {
    await tester.pumpWidget(_buildApp(const ReferralScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Pro Days Earned'), findsOneWidget);
  });

  testWidgets('ReferralScreen shows How the reward works section', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(const ReferralScreen()));
    await tester.pumpAndSettle();
    expect(find.text('How the reward works'), findsOneWidget);
  });

  testWidgets('ReferralScreen shows Terms section', (tester) async {
    await tester.pumpWidget(_buildApp(const ReferralScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Terms'), findsOneWidget);
  });

  testWidgets('ReferralScreen copy icon has Semantics label', (tester) async {
    await tester.pumpWidget(_buildApp(const ReferralScreen()));
    await tester.pumpAndSettle();
    // The copy button should have a Semantics label
    expect(find.bySemanticsLabel('Copy referral code'), findsOneWidget);
  });

  testWidgets('ReferralScreen shows Give 7 Days Pro headline', (tester) async {
    await tester.pumpWidget(_buildApp(const ReferralScreen()));
    await tester.pumpAndSettle();
    expect(find.textContaining('7 Days Pro'), findsWidgets);
  });
}
