import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import 'package:afeedi/services/user_interaction_service.dart';

// ---------------------------------------------------------------------------
// NOTE ON SINGLETON DESIGN
// ---------------------------------------------------------------------------
// UserInteractionService is a singleton with in-memory caches (_likeCache,
// _saveCache, _followCache, _countsCache).  initialize() appends from prefs
// but does NOT clear those caches first.  To avoid cross-test contamination
// each test uses a globally unique content/creator ID so that leftovers from
// a previous test do not affect later assertions.
// ---------------------------------------------------------------------------

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp(
      'afeedi_interaction_flow_test_',
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall call) async => tempDir.path,
        );

    // Do one initial initialization so the singleton has _prefs set.
    SharedPreferences.setMockInitialValues({});
    await UserInteractionService.instance.initialize();
  });

  tearDownAll(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  // Each test gets a fresh SharedPreferences, but the singleton's in-memory
  // caches are NOT reset between tests.  We work around this by using unique
  // IDs per test rather than resetting the singleton.
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UserInteractionService.instance.initialize();
  });

  final svc = UserInteractionService.instance;

  group('UserInteractionService full flow', () {
    // ------------------------------------------------------------------
    // Like round-trip
    // ------------------------------------------------------------------

    test('toggleLike returns true on first call', () async {
      final result = await svc.toggleLike('t_like_01');
      expect(result, isTrue);
    });

    test('isLiked returns true after one toggleLike', () async {
      await svc.toggleLike('t_like_02');
      expect(svc.isLiked('t_like_02'), isTrue);
    });

    test('toggleLike again returns false (un-like)', () async {
      await svc.toggleLike('t_like_03');
      final result = await svc.toggleLike('t_like_03');
      expect(result, isFalse);
    });

    test('isLiked returns false after toggle off', () async {
      await svc.toggleLike('t_like_04');
      await svc.toggleLike('t_like_04');
      expect(svc.isLiked('t_like_04'), isFalse);
    });

    // ------------------------------------------------------------------
    // getLikeCount
    // ------------------------------------------------------------------

    test('getLikeCount returns 100 when not liked (baseCount: 100)', () {
      // Fresh id — never touched before
      expect(svc.getLikeCount('t_cnt_01', baseCount: 100), equals(100));
    });

    test('getLikeCount returns 101 when liked (baseCount: 100)', () async {
      await svc.toggleLike('t_cnt_02', baseCount: 100);
      expect(svc.getLikeCount('t_cnt_02', baseCount: 100), equals(101));
    });

    test('getLikeCount goes back to base after un-like', () async {
      await svc.toggleLike('t_cnt_03', baseCount: 100); // like   → +1
      await svc.toggleLike('t_cnt_03', baseCount: 100); // unlike → −1
      expect(svc.getLikeCount('t_cnt_03', baseCount: 100), equals(100));
    });

    // ------------------------------------------------------------------
    // Save round-trip
    // ------------------------------------------------------------------

    test('toggleSave returns true on first call', () async {
      final result = await svc.toggleSave('t_save_01');
      expect(result, isTrue);
    });

    test('isSaved returns true after toggleSave', () async {
      await svc.toggleSave('t_save_02');
      expect(svc.isSaved('t_save_02'), isTrue);
    });

    test('toggleSave again returns false', () async {
      await svc.toggleSave('t_save_03');
      final result = await svc.toggleSave('t_save_03');
      expect(result, isFalse);
    });

    test('isSaved returns false after second toggleSave', () async {
      await svc.toggleSave('t_save_04');
      await svc.toggleSave('t_save_04');
      expect(svc.isSaved('t_save_04'), isFalse);
    });

    // ------------------------------------------------------------------
    // Follow round-trip
    // ------------------------------------------------------------------

    test('toggleFollow returns true on first call', () async {
      final result = await svc.toggleFollow('t_cr_01');
      expect(result, isTrue);
    });

    test('isFollowed returns true after toggleFollow', () async {
      await svc.toggleFollow('t_cr_02');
      expect(svc.isFollowed('t_cr_02'), isTrue);
    });

    test('toggleFollow again returns false (unfollow)', () async {
      await svc.toggleFollow('t_cr_03');
      final result = await svc.toggleFollow('t_cr_03');
      expect(result, isFalse);
    });

    test('isFollowed returns false after unfollow', () async {
      await svc.toggleFollow('t_cr_04');
      await svc.toggleFollow('t_cr_04');
      expect(svc.isFollowed('t_cr_04'), isFalse);
    });

    // ------------------------------------------------------------------
    // getSavedContentIds — accumulation
    // ------------------------------------------------------------------

    test(
      'getSavedContentIds returns correct list after multiple saves',
      () async {
        await svc.toggleSave('t_savelist_a');
        await svc.toggleSave('t_savelist_b');
        await svc.toggleSave('t_savelist_c');

        final saved = svc.getSavedContentIds();
        expect(
          saved,
          containsAll(['t_savelist_a', 't_savelist_b', 't_savelist_c']),
        );
      },
    );

    test('getSavedContentIds excludes un-saved items', () async {
      await svc.toggleSave('t_saveex_a'); // save
      await svc.toggleSave('t_saveex_b'); // save then …
      await svc.toggleSave('t_saveex_b'); // … unsave

      final saved = svc.getSavedContentIds();
      expect(saved, contains('t_saveex_a'));
      expect(saved, isNot(contains('t_saveex_b')));
    });

    // ------------------------------------------------------------------
    // getFollowedCreatorIds — accumulation
    // ------------------------------------------------------------------

    test(
      'getFollowedCreatorIds returns correct list after multiple follows',
      () async {
        await svc.toggleFollow('t_fol_a');
        await svc.toggleFollow('t_fol_b');
        await svc.toggleFollow('t_fol_c');

        final followed = svc.getFollowedCreatorIds();
        expect(followed, containsAll(['t_fol_a', 't_fol_b', 't_fol_c']));
      },
    );

    test('getFollowedCreatorIds excludes unfollowed creators', () async {
      await svc.toggleFollow('t_folx_a'); // follow
      await svc.toggleFollow('t_folx_b'); // follow
      await svc.toggleFollow('t_folx_b'); // unfollow

      final followed = svc.getFollowedCreatorIds();
      expect(followed, contains('t_folx_a'));
      expect(followed, isNot(contains('t_folx_b')));
    });

    // ------------------------------------------------------------------
    // Persistence: state survives re-initialization (same prefs mock).
    //
    // We do NOT call setMockInitialValues({}) between the action and the
    // re-initialize here, so prefs still hold the data written in the
    // first phase.
    // ------------------------------------------------------------------

    test('Liked state persists across re-initialization', () async {
      const id = 't_persist_like';
      await svc.toggleLike(id);
      expect(svc.isLiked(id), isTrue, reason: 'Liked before re-init');

      // Re-init without resetting prefs → data must still be there
      await svc.initialize();
      expect(
        svc.isLiked(id),
        isTrue,
        reason: 'Liked state should survive re-initialization',
      );
    });

    test('Saved state persists across re-initialization', () async {
      const id = 't_persist_save';
      await svc.toggleSave(id);
      await svc.initialize(); // no prefs reset
      expect(
        svc.isSaved(id),
        isTrue,
        reason: 'Saved state should survive re-initialization',
      );
    });

    test('Followed state persists across re-initialization', () async {
      const id = 't_persist_follow';
      await svc.toggleFollow(id);
      await svc.initialize(); // no prefs reset
      expect(
        svc.isFollowed(id),
        isTrue,
        reason: 'Follow state should survive re-initialization',
      );
    });
  });
}
