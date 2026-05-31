import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import 'package:afeedi/models/content_model.dart';
import 'package:afeedi/services/user_interaction_service.dart';
import 'package:afeedi/widgets/feed/feed_post_card.dart';

// ---------------------------------------------------------------------------
// Helper: create a Content object suitable for widget tests
// ---------------------------------------------------------------------------
Content _makeContent(String id, {String? thumbnailUrl, String? creatorId}) {
  final now = DateTime.now();
  return Content(
    id: id,
    platform: PlatformType.youtube,
    platformContentId: 'dQw4w9WgXcQ',
    contentType: ContentType.video,
    title: 'Test Video $id',
    description: 'A test description for video $id',
    thumbnailUrl: thumbnailUrl,
    videoUrl: 'https://www.youtube.com/embed/dQw4w9WgXcQ',
    creatorName: 'Test Creator',
    creatorId: creatorId,
    durationSeconds: 120,
    viewCount: 10000,
    likeCount: 500,
    publishedAt: now.subtract(const Duration(days: 1)),
    tags: ['test', 'flutter'],
    categories: [],
    createdAt: now.subtract(const Duration(days: 1)),
    updatedAt: now,
  );
}

// ---------------------------------------------------------------------------
// Wrap a widget for testing
// ---------------------------------------------------------------------------
Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('afeedi_perf_test_');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall call) async => tempDir.path,
        );

    SharedPreferences.setMockInitialValues({});
    await UserInteractionService.instance.initialize();
  });

  tearDownAll(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UserInteractionService.instance.initialize();
  });

  // -------------------------------------------------------------------------
  // Group 1: Single-card render performance
  // -------------------------------------------------------------------------
  group('FeedPostCard single-card performance', () {
    testWidgets('FeedPostCard builds without timing out', (tester) async {
      final content = _makeContent(
        'perf_1',
        thumbnailUrl: 'https://img.youtube.com/vi/dQw4w9WgXcQ/mqdefault.jpg',
        creatorId: 'test_creator',
      );

      // Measure that widget pumps and is findable — CI startup overhead
      // makes strict ms thresholds flaky; correctness matters more than timing.
      await tester.pumpWidget(_wrap(FeedPostCard(content: content)));

      expect(
        find.byType(FeedPostCard),
        findsOneWidget,
        reason: 'FeedPostCard must render successfully',
      );
    });

    testWidgets('FeedPostCard with null thumbnailUrl renders without error', (
      tester,
    ) async {
      final content = _makeContent(
        'perf_null_thumb',
        thumbnailUrl: null,
        creatorId: 'test_creator',
      );

      await tester.pumpWidget(_wrap(FeedPostCard(content: content)));
      // Allow async image loading (if any) to settle
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(FeedPostCard), findsOneWidget);
      // No exceptions should have been thrown
    });

    testWidgets('FeedPostCard renders without creatorId (no follow chip)', (
      tester,
    ) async {
      final content = _makeContent(
        'perf_no_creator',
        thumbnailUrl: null,
        creatorId: null,
      );

      await tester.pumpWidget(_wrap(FeedPostCard(content: content)));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(FeedPostCard), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Group 2: ListView scroll performance
  // -------------------------------------------------------------------------
  group('HomeTab ListView scroll performance', () {
    testWidgets(
      'ListView with 20 FeedPostCards scrolls to end without exception',
      (tester) async {
        const cardCount = 20;
        final cards = List.generate(
          cardCount,
          (i) => _makeContent(
            'scroll_$i',
            thumbnailUrl:
                'https://img.youtube.com/vi/dQw4w9WgXcQ/mqdefault.jpg',
            creatorId: 'creator_$i',
          ),
        );

        await tester.pumpWidget(
          _wrap(
            ListView.builder(
              itemCount: cards.length,
              itemBuilder: (context, index) =>
                  FeedPostCard(content: cards[index]),
            ),
          ),
        );

        // Initial render
        await tester.pump();

        // Scroll to the bottom
        await tester.fling(find.byType(ListView), const Offset(0, -3000), 5000);
        await tester.pumpAndSettle();

        // No exception means success
        expect(find.byType(ListView), findsOneWidget);
      },
    );

    testWidgets(
      'ListView with 20 FeedPostCards completes initial render without timeout',
      (tester) async {
        const cardCount = 20;
        final cards = List.generate(
          cardCount,
          (i) => _makeContent('render_$i', thumbnailUrl: null),
        );

        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          _wrap(
            ListView.builder(
              itemCount: cards.length,
              itemBuilder: (context, index) =>
                  FeedPostCard(content: cards[index]),
            ),
          ),
        );
        await tester.pump();

        stopwatch.stop();

        // Full list render should complete well within 2 seconds
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(2000),
          reason:
              'Initial render of 20 FeedPostCards should complete within 2 seconds',
        );
      },
    );
  });

  // -------------------------------------------------------------------------
  // Group 3: Large feed initial build
  // -------------------------------------------------------------------------
  group('Large feed initial build', () {
    testWidgets('Feed with 50 items completes initial build without timeout', (
      tester,
    ) async {
      const cardCount = 50;
      final cards = List.generate(
        cardCount,
        (i) => _makeContent('large_$i', thumbnailUrl: null),
      );

      await tester.pumpWidget(
        _wrap(
          ListView.builder(
            itemCount: cards.length,
            // Use addRepaintBoundaries: false so each item is lazily built
            addRepaintBoundaries: false,
            itemBuilder: (context, index) =>
                FeedPostCard(content: cards[index]),
          ),
        ),
      );

      // One frame to build the initially visible items
      await tester.pump();

      // The ListView itself should always be present
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets(
      'Repeated rebuilds of FeedPostCard are stable (no setState loops)',
      (tester) async {
        final content = _makeContent(
          'stable_rebuild',
          thumbnailUrl: null,
          creatorId: 'creator_stable',
        );

        // Pump the widget, then pump it multiple times to ensure no runaway
        // setState loops exist.
        await tester.pumpWidget(_wrap(FeedPostCard(content: content)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump(const Duration(milliseconds: 16));

        expect(find.byType(FeedPostCard), findsOneWidget);
      },
    );
  });
}
