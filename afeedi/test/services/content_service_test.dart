import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import 'package:afeedi/services/content_service.dart';
import 'package:afeedi/models/content_model.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('afeedi_content_test');

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

  group('ContentService', () {
    test('getFeedContent returns non-empty list', () async {
      final content = await ContentService.instance.getFeedContent();
      expect(content, isNotEmpty);
    });

    test('getFeedContent respects limit parameter', () async {
      final content = await ContentService.instance.getFeedContent(limit: 3);
      expect(content.length, lessThanOrEqualTo(3));
    });

    test('getFeedContent returns valid Content objects', () async {
      final content = await ContentService.instance.getFeedContent(limit: 5);
      for (final item in content) {
        expect(item.id, isNotEmpty);
        expect(item.platform, isA<PlatformType>());
        expect(item.contentType, isA<ContentType>());
        expect(item.platformContentId, isNotEmpty);
      }
    });

    test('getFeedContent includes short-form content', () async {
      final allContent = await ContentService.instance.getFeedContent(limit: 100);
      final shorts = allContent.where((c) =>
          c.contentType == ContentType.short ||
          c.contentType == ContentType.reel).toList();
      expect(shorts, isNotEmpty, reason: 'Feed should include short-form content for ShortsTab');
    });

    test('getFeedContent includes YouTube content with valid video IDs', () async {
      final content = await ContentService.instance.getFeedContent(limit: 100);
      final youtube = content.where((c) => c.platform == PlatformType.youtube).toList();
      expect(youtube, isNotEmpty);
      for (final item in youtube) {
        expect(item.platformContentId, isNotEmpty);
        expect(item.platformContentId.length, greaterThan(5));
      }
    });

    test('getTrendingVideos returns sorted by engagement', () async {
      final trending = await ContentService.instance.getTrendingVideos(limit: 5);
      expect(trending, isNotEmpty);
      expect(trending.length, lessThanOrEqualTo(5));

      // Verify they are in descending order of engagement
      for (int i = 0; i < trending.length - 1; i++) {
        final currentScore = trending[i].viewCount + trending[i].likeCount;
        final nextScore = trending[i + 1].viewCount + trending[i + 1].likeCount;
        expect(currentScore, greaterThanOrEqualTo(nextScore));
      }
    });

    test('searchVideos finds content by title', () async {
      final results = await ContentService.instance.searchVideos('Flutter');
      expect(results, isNotEmpty,
          reason: 'Should find Flutter-related content');
      for (final item in results) {
        final matchesTitle = item.title?.toLowerCase().contains('flutter') ?? false;
        final matchesTags = item.tags.any((t) => t.toLowerCase().contains('flutter'));
        final matchesDesc = item.description?.toLowerCase().contains('flutter') ?? false;
        expect(matchesTitle || matchesTags || matchesDesc, isTrue);
      }
    });

    test('searchVideos returns empty for empty query', () async {
      final results = await ContentService.instance.searchVideos('');
      expect(results, isEmpty);
    });

    test('getVideoById returns correct video', () async {
      final allContent = await ContentService.instance.getFeedContent(limit: 100);
      final firstId = allContent.first.id;
      final found = await ContentService.instance.getVideoById(firstId);
      expect(found, isNotNull);
      expect(found!.id, equals(firstId));
    });

    test('getVideoById returns null for non-existent ID', () async {
      final found = await ContentService.instance.getVideoById('non_existent_id_xyz');
      expect(found, isNull);
    });

    test('getVideos filters by platform', () async {
      final ytContent = await ContentService.instance.getVideos(
        platform: PlatformType.youtube,
        limit: 20,
      );
      for (final item in ytContent) {
        expect(item.platform, equals(PlatformType.youtube));
      }
    });

    test('getRecommendedVideos returns different content', () async {
      final allContent = await ContentService.instance.getFeedContent(limit: 100);
      final firstId = allContent.first.id;
      final recommended = await ContentService.instance.getRecommendedVideos(firstId, limit: 5);
      // Recommended should not include the source video
      for (final item in recommended) {
        expect(item.id, isNot(equals(firstId)));
      }
    });

    test('loadMoreContent returns content for pagination', () async {
      final page1 = await ContentService.instance.loadMoreContent(0, limit: 5);
      final page2 = await ContentService.instance.loadMoreContent(5, limit: 5);
      expect(page1, isNotEmpty);
      expect(page2, isNotEmpty);
      // Page IDs should be different
      final page1Ids = page1.map((c) => c.id).toSet();
      final page2Ids = page2.map((c) => c.id).toSet();
      expect(page1Ids.intersection(page2Ids), isEmpty);
    });

    test('YouTube content has valid thumbnail URLs', () async {
      final content = await ContentService.instance.getFeedContent(limit: 100);
      final youtube = content.where((c) =>
          c.platform == PlatformType.youtube && c.thumbnailUrl != null).toList();
      expect(youtube, isNotEmpty);
      for (final item in youtube) {
        expect(item.thumbnailUrl, startsWith('https://img.youtube.com/vi/'));
        expect(item.thumbnailUrl, contains(item.platformContentId));
      }
    });
  });
}
