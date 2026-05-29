import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import 'package:afeedi/services/user_interaction_service.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('afeedi_interaction_test');

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
    // Re-initialize the service with fresh prefs each test
    await UserInteractionService.instance.initialize();
  });

  group('UserInteractionService', () {
    test('toggleLike returns true on first call', () async {
      final result = await UserInteractionService.instance.toggleLike('content_1');
      expect(result, isTrue);
    });

    test('toggleLike returns false on second call (toggle off)', () async {
      await UserInteractionService.instance.toggleLike('content_2');
      final result = await UserInteractionService.instance.toggleLike('content_2');
      expect(result, isFalse);
    });

    test('isLiked returns correct state', () async {
      const contentId = 'content_3';
      expect(UserInteractionService.instance.isLiked(contentId), isFalse);

      await UserInteractionService.instance.toggleLike(contentId);
      expect(UserInteractionService.instance.isLiked(contentId), isTrue);

      await UserInteractionService.instance.toggleLike(contentId);
      expect(UserInteractionService.instance.isLiked(contentId), isFalse);
    });

    test('getLikeCount adjusts base by delta', () async {
      const contentId = 'content_4';
      const base = 100;

      // Before any like, count equals base
      expect(
        UserInteractionService.instance.getLikeCount(contentId, baseCount: base),
        equals(base),
      );

      // After one like, count increases by 1
      await UserInteractionService.instance.toggleLike(contentId, baseCount: base);
      expect(
        UserInteractionService.instance.getLikeCount(contentId, baseCount: base),
        equals(base + 1),
      );

      // After un-like, count goes back to base
      await UserInteractionService.instance.toggleLike(contentId, baseCount: base);
      expect(
        UserInteractionService.instance.getLikeCount(contentId, baseCount: base),
        equals(base),
      );
    });

    test('toggleSave persists correctly', () async {
      const contentId = 'content_5';

      expect(UserInteractionService.instance.isSaved(contentId), isFalse);

      final saved = await UserInteractionService.instance.toggleSave(contentId);
      expect(saved, isTrue);
      expect(UserInteractionService.instance.isSaved(contentId), isTrue);

      final unsaved = await UserInteractionService.instance.toggleSave(contentId);
      expect(unsaved, isFalse);
      expect(UserInteractionService.instance.isSaved(contentId), isFalse);
    });

    test('toggleFollow persists correctly', () async {
      const creatorId = 'creator_1';

      expect(UserInteractionService.instance.isFollowed(creatorId), isFalse);

      final followed = await UserInteractionService.instance.toggleFollow(creatorId);
      expect(followed, isTrue);
      expect(UserInteractionService.instance.isFollowed(creatorId), isTrue);

      final unfollowed =
          await UserInteractionService.instance.toggleFollow(creatorId);
      expect(unfollowed, isFalse);
      expect(UserInteractionService.instance.isFollowed(creatorId), isFalse);
    });

    test('getSavedContentIds returns all saved', () async {
      await UserInteractionService.instance.toggleSave('save_a');
      await UserInteractionService.instance.toggleSave('save_b');
      await UserInteractionService.instance.toggleSave('save_c');

      final saved = UserInteractionService.instance.getSavedContentIds();
      expect(saved, containsAll(['save_a', 'save_b', 'save_c']));
      expect(saved.length, greaterThanOrEqualTo(3));
    });

    test('getFollowedCreatorIds returns all followed', () async {
      await UserInteractionService.instance.toggleFollow('creator_a');
      await UserInteractionService.instance.toggleFollow('creator_b');

      final followed = UserInteractionService.instance.getFollowedCreatorIds();
      expect(followed, containsAll(['creator_a', 'creator_b']));
      expect(followed.length, greaterThanOrEqualTo(2));
    });
  });
}
