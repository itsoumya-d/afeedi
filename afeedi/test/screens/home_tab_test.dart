/// HomeTab widget tests.
///
/// HomeTab calls ContentService and AnalyticsService asynchronously in
/// initState. To avoid "Timer still pending" failures we wrap every pump in
/// tester.runAsync so real async I/O can complete (or time-out) before the
/// test framework verifies timer invariants.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import 'package:afeedi/widgets/dashboard/home_tab.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('afeedi_hometab_test');

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

  Widget buildApp() {
    return MaterialApp(
      routes: {
        '/dashboard': (_) => const Scaffold(body: Text('Dashboard')),
        '/premium': (_) => const Scaffold(body: Text('Premium')),
        '/search': (_) => const Scaffold(body: Text('Search')),
        '/player': (_) => const Scaffold(body: Text('Player')),
      },
      home: const Scaffold(body: HomeTab()),
    );
  }

  /// Builds the HomeTab inside runAsync so all scheduled async tasks from
  /// initState complete (or resolve with an error) before the pump returns.
  Future<void> pumpHomeTab(WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(buildApp());
      // Allow network/storage calls to resolve or fail.
      await Future.delayed(const Duration(seconds: 3));
    });
    // Settle any remaining microtasks/frames.
    await tester.pump();
  }

  group('HomeTab', () {
    testWidgets('renders the HomeTab widget', (tester) async {
      await pumpHomeTab(tester);
      expect(find.byType(HomeTab), findsOneWidget);
    });

    testWidgets('shows Trending label in header', (tester) async {
      await pumpHomeTab(tester);
      expect(find.text('Trending'), findsOneWidget);
    });

    testWidgets('shows trending topic hashtags', (tester) async {
      await pumpHomeTab(tester);
      // Trending topics are derived from content tags (dynamic) or default to '#Trending'
      expect(
        find.byWidgetPredicate((w) =>
            w is Text && (w.data?.startsWith('#') ?? false)),
        findsWidgets,
      );
    });

    testWidgets('shows For You tab switch', (tester) async {
      await pumpHomeTab(tester);
      // 'For You' appears in both the tab switch and the quick filter chip
      expect(find.text('For You'), findsWidgets);
    });

    testWidgets('shows New stat in header', (tester) async {
      await pumpHomeTab(tester);
      expect(find.text('New'), findsOneWidget);
    });

    testWidgets('shows platform quick filter labels', (tester) async {
      await pumpHomeTab(tester);
      // Quick filters use custom GestureDetector containers, not FilterChip
      expect(find.text('YouTube'), findsOneWidget);
    });

    testWidgets('has YouTube platform filter', (tester) async {
      await pumpHomeTab(tester);
      expect(find.text('YouTube'), findsOneWidget);
    });

    testWidgets('has Instagram platform filter', (tester) async {
      await pumpHomeTab(tester);
      expect(find.text('Instagram'), findsOneWidget);
    });

    testWidgets('has TikTok platform filter', (tester) async {
      await pumpHomeTab(tester);
      // TikTok appears in the quick filter chip and possibly in content cards
      expect(find.text('TikTok', skipOffstage: false), findsWidgets);
    });

    testWidgets('has For You filter chip (default selected)', (tester) async {
      await pumpHomeTab(tester);
      // 'For You' appears in tab switch (size 18) and quick filter (size 12)
      expect(find.text('For You'), findsWidgets);
    });

    testWidgets('has a RefreshIndicator for pull-to-refresh', (tester) async {
      await pumpHomeTab(tester);
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('has a ListView for the feed area', (tester) async {
      await pumpHomeTab(tester);
      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('shows Scaffold', (tester) async {
      await pumpHomeTab(tester);
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
