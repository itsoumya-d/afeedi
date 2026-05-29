// Tests for error states and edge cases
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import 'package:afeedi/services/content_service.dart';
import 'package:afeedi/services/user_interaction_service.dart';
import 'package:afeedi/services/analytics_service.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('afeedi_error_state_test');

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

  group('ContentService error states', () {
    test('getVideoById returns null for non-existent ID', () async {
      final result = await ContentService.instance.getVideoById('non_existent_id_xyz_999');
      expect(result, isNull);
    });

    test('searchVideos returns empty list for empty query', () async {
      final results = await ContentService.instance.searchVideos('');
      expect(results, isEmpty);
    });

    test('getRecommendedVideos returns content excluding source', () async {
      // Get a real ID first
      final feed = await ContentService.instance.getFeedContent(limit: 5);
      expect(feed, isNotEmpty);
      final sourceId = feed.first.id;

      final recommended = await ContentService.instance.getRecommendedVideos(
        sourceId,
        limit: 5,
      );
      for (final item in recommended) {
        expect(item.id, isNot(equals(sourceId)),
            reason: 'Recommended videos should not include the source video');
      }
    });

    test('loadMoreContent handles offset beyond dataset size', () async {
      // Use a very large offset — should return empty or handle gracefully
      final result = await ContentService.instance.loadMoreContent(99999, limit: 5);
      // Should not throw; result may be empty or wrap around
      expect(result, isA<List>());
    });
  });

  group('UserInteractionService edge cases', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await UserInteractionService.instance.initialize();
    });

    test('toggleLike multiple times returns consistent state', () async {
      const id = 'edge_case_content_1';
      // First toggle: liked
      final first = await UserInteractionService.instance.toggleLike(id);
      expect(first, isTrue);
      expect(UserInteractionService.instance.isLiked(id), isTrue);

      // Second toggle: unliked
      final second = await UserInteractionService.instance.toggleLike(id);
      expect(second, isFalse);
      expect(UserInteractionService.instance.isLiked(id), isFalse);

      // Third toggle: liked again
      final third = await UserInteractionService.instance.toggleLike(id);
      expect(third, isTrue);
      expect(UserInteractionService.instance.isLiked(id), isTrue);
    });

    test('getLikeCount never returns negative', () async {
      const id = 'edge_case_content_2';
      // Toggle like on then off to create a delta of -1
      await UserInteractionService.instance.toggleLike(id);
      await UserInteractionService.instance.toggleLike(id);

      // With baseCount 0, result should never be negative
      final count = UserInteractionService.instance.getLikeCount(id, baseCount: 0);
      expect(count, greaterThanOrEqualTo(0));
    });

    test('getSavedContentIds returns empty list initially', () async {
      final ids = UserInteractionService.instance.getSavedContentIds();
      expect(ids, isEmpty);
    });

    test('trackShare does not throw', () async {
      expect(
        () async => UserInteractionService.instance.trackShare('share_content_1'),
        returnsNormally,
      );
      await UserInteractionService.instance.trackShare('share_content_2');
    });
  });

  group('Analytics', () {
    test('AnalyticsService initializes without error', () async {
      expect(
        () async => AnalyticsService.instance.initialize(),
        returnsNormally,
      );
      await AnalyticsService.instance.initialize();
    });

    test('trackUserInteraction does not throw', () async {
      await AnalyticsService.instance.initialize();
      expect(
        () async => AnalyticsService.instance.trackUserInteraction(
          action: 'test_action',
          screen: 'test_screen',
        ),
        returnsNormally,
      );
    });
  });
}
