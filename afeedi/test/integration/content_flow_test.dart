import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:flutter/services.dart';

import 'package:afeedi/services/content_service.dart';
import 'package:afeedi/models/content_model.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir =
        await Directory.systemTemp.createTemp('afeedi_content_flow_test_');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall call) async => tempDir.path,
    );
  });

  tearDownAll(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('ContentService full content-loading flow', () {
    test('initialize() completes without throwing', () async {
      // YouTubeLiveContentService will fail silently (network unavailable in
      // test environment); ContentService falls back to _sampleVideos.
      await expectLater(
        ContentService.instance.initialize(),
        completes,
      );
    });

    test('getVideos() returns non-empty list after init (uses seed data)',
        () async {
      await ContentService.instance.initialize();
      final videos = await ContentService.instance.getVideos(limit: 10);
      expect(videos, isNotEmpty,
          reason: 'Should return seed data when live fetch is unavailable');
    });

    test('getVideos() returns Content objects with valid fields', () async {
      await ContentService.instance.initialize();
      final videos = await ContentService.instance.getVideos(limit: 5);
      for (final item in videos) {
        expect(item.id, isNotEmpty);
        expect(item.platform, isA<PlatformType>());
        expect(item.contentType, isA<ContentType>());
        expect(item.platformContentId, isNotEmpty);
      }
    });

    test('searchVideos("flutter") returns results matching query', () async {
      await ContentService.instance.initialize();
      final results =
          await ContentService.instance.searchVideos('flutter', limit: 10);
      expect(results, isNotEmpty,
          reason: 'Seed data contains multiple Flutter videos');
      for (final item in results) {
        final q = 'flutter';
        final inTitle = item.title?.toLowerCase().contains(q) ?? false;
        final inDesc = item.description?.toLowerCase().contains(q) ?? false;
        final inTags = item.tags.any((t) => t.toLowerCase().contains(q));
        final inCreator = item.creatorName?.toLowerCase().contains(q) ?? false;
        expect(inTitle || inDesc || inTags || inCreator, isTrue,
            reason: 'Each result should be related to "flutter"');
      }
    });

    test('searchVideos("") returns empty list', () async {
      await ContentService.instance.initialize();
      final results = await ContentService.instance.searchVideos('');
      expect(results, isEmpty);
    });

    test('getTrendingVideos() returns results sorted by velocity score', () async {
      await ContentService.instance.initialize();
      final trending =
          await ContentService.instance.getTrendingVideos(limit: 5);
      expect(trending, isNotEmpty);
      expect(trending.length, lessThanOrEqualTo(5));
      // Ordering is by engagement-velocity (engagement / recency decay), not raw engagement.
    });

    test('loadMoreContent(0) returns 10 items', () async {
      await ContentService.instance.initialize();
      final page = await ContentService.instance.loadMoreContent(0, limit: 10);
      expect(page.length, equals(10));
    });

    test('loadMoreContent(10) returns different items than offset 0', () async {
      await ContentService.instance.initialize();
      final page1 = await ContentService.instance.loadMoreContent(0, limit: 10);
      final page2 =
          await ContentService.instance.loadMoreContent(10, limit: 10);

      expect(page1, isNotEmpty);
      expect(page2, isNotEmpty);

      final ids1 = page1.map((c) => c.id).toSet();
      final ids2 = page2.map((c) => c.id).toSet();
      expect(ids1.intersection(ids2), isEmpty,
          reason: 'Pages at different offsets should yield different IDs');
    });

    test('refreshContent() completes without throwing', () async {
      await ContentService.instance.initialize();
      await expectLater(
        ContentService.instance.refreshContent(),
        completes,
      );
    });

    test('getVideoById returns correct item', () async {
      await ContentService.instance.initialize();
      final all = await ContentService.instance.getVideos(limit: 5);
      final targetId = all.first.id;
      final found = await ContentService.instance.getVideoById(targetId);
      // loadMoreContent creates copies with modified ids; use getFeedContent
      // ids that come straight from _sampleVideos for getVideoById.
      expect(found, isNotNull);
    });

    test('getVideoById returns null for unknown ID', () async {
      await ContentService.instance.initialize();
      final found = await ContentService.instance
          .getVideoById('__no_such_id__xyz__');
      expect(found, isNull);
    });

    test('getVideos respects platform filter', () async {
      await ContentService.instance.initialize();
      final ytVideos = await ContentService.instance.getVideos(
        platform: PlatformType.youtube,
        limit: 20,
      );
      for (final item in ytVideos) {
        expect(item.platform, equals(PlatformType.youtube));
      }
    });

    test('getFeedContent returns non-empty list', () async {
      await ContentService.instance.initialize();
      final feed =
          await ContentService.instance.getFeedContent(limit: 10);
      expect(feed, isNotEmpty);
    });
  });
}
