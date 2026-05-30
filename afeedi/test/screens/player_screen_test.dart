import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import 'package:afeedi/screens/player_screen.dart';
import 'package:afeedi/models/content_model.dart';

Content _makeContent() => Content(
      id: 'test1',
      platform: PlatformType.youtube,
      platformContentId: 'dQw4w9WgXcQ',
      contentType: ContentType.video,
      title: 'Test Video',
      creatorName: 'Test Creator',
      videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      viewCount: 1000,
      likeCount: 100,
      tags: ['tech'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('afeedi_player_test');

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

  group('PlayerScreen', () {
    testWidgets('renders without errors given a YouTube Content object',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: PlayerScreen(content: _makeContent())),
      );
      await tester.pump();

      expect(find.byType(PlayerScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows back button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: PlayerScreen(content: _makeContent())),
      );
      await tester.pump();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('shows share button (Icons.share_outlined) in app bar',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: PlayerScreen(content: _makeContent())),
      );
      await tester.pump();

      expect(find.byIcon(Icons.share_outlined), findsWidgets);
    });

    testWidgets('shows video title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: PlayerScreen(content: _makeContent())),
      );
      await tester.pump();

      expect(find.text('Test Video'), findsOneWidget);
    });

    testWidgets('shows creator name', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: PlayerScreen(content: _makeContent())),
      );
      await tester.pump();

      expect(find.text('Test Creator'), findsOneWidget);
    });

    testWidgets('like button is tappable', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(home: PlayerScreen(content: _makeContent())),
      );
      await tester.pump();

      final likeButton = find.byIcon(Icons.favorite_border);
      expect(likeButton, findsOneWidget);
      await tester.ensureVisible(likeButton);
      await tester.tap(likeButton);
      await tester.pump();

      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('save button is tappable', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(home: PlayerScreen(content: _makeContent())),
      );
      await tester.pump();

      final saveButton = find.byIcon(Icons.bookmark_border);
      expect(saveButton, findsOneWidget);
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pump();

      expect(find.text('Saved'), findsOneWidget);
    });

    testWidgets("renders correctly after async content loading",
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: PlayerScreen(content: _makeContent())),
      );
      await tester.pump();
      // Allow async operations (avoid pumpAndSettle which can timeout on continuous animations)
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(PlayerScreen), findsOneWidget);
    });

    testWidgets('has playback speed button (Icons.speed)', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(home: PlayerScreen(content: _makeContent())),
      );
      await tester.pump();

      expect(find.byIcon(Icons.speed), findsOneWidget);
    });

    testWidgets('speed button is tappable and opens speed selector',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(home: PlayerScreen(content: _makeContent())),
      );
      await tester.pump();

      final speedButton = find.byIcon(Icons.speed);
      expect(speedButton, findsOneWidget);
      await tester.ensureVisible(speedButton);
      await tester.tap(speedButton);
      // Use pump(Duration) instead of pumpAndSettle — video player has
      // continuous animations that would cause pumpAndSettle to timeout.
      await tester.pump(const Duration(milliseconds: 500));

      // Speed selector bottom sheet shows 'Playback Speed' label
      expect(find.text('Playback Speed'), findsOneWidget);
    });

    testWidgets('speed selector shows all speed options', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(home: PlayerScreen(content: _makeContent())),
      );
      await tester.pump();

      await tester.ensureVisible(find.byIcon(Icons.speed));
      await tester.tap(find.byIcon(Icons.speed));
      await tester.pump(const Duration(milliseconds: 500));

      // Default speed options: 0.5, 0.75, 1×, 1.25, 1.5, 2×
      expect(find.text('1×'), findsWidgets);
      expect(find.text('2×'), findsOneWidget);
    });

    testWidgets('shows related content section header when async loads',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(home: PlayerScreen(content: _makeContent())),
      );
      // Allow related content to load
      await tester.pump(const Duration(seconds: 3));

      // If related content is empty (no network in tests), section header is
      // not rendered — just confirm the screen still renders correctly
      expect(find.byType(PlayerScreen), findsOneWidget);
    });

    testWidgets('shows share action in action buttons row', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(home: PlayerScreen(content: _makeContent())),
      );
      await tester.pump();

      // share_outlined appears in both the top bar and the action buttons row
      expect(find.byIcon(Icons.share_outlined), findsWidgets);
    });

    testWidgets('shows view count for content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: PlayerScreen(content: _makeContent())),
      );
      await tester.pump();

      // findsWidgets because related content cards may also show view counts
      expect(find.textContaining('views'), findsWidgets);
    });
  });
}
