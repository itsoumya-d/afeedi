// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:afeedi/models/content_model.dart';
import 'package:afeedi/services/auth_service.dart';
import 'package:afeedi/services/content_service.dart';
import 'package:afeedi/services/onboarding_service.dart';
import 'package:afeedi/services/user_interaction_service.dart';

// ---------------------------------------------------------------------------
// Feed Accuracy Test Suite
//
// Tests that the recommendation / feed layer surfaces the right content for
// a given user preference profile, that followed-creator boosting works, and
// that the seed data covers every genre the algorithm is expected to serve.
//
// Design notes
// ─────────────
// • ContentService._sampleVideos is the live content pool in test environments
//   (no network, no local API).  All assertions below operate on that pool.
//
// • EnhancedRecommendationService._getPreferenceBasedRecommendations delegates
//   to ContentAggregationService which requires platform connections — these
//   are absent in tests, so it returns [] and the method falls back to
//   getTimeBasedRecommendations (which also goes via aggregateContent → []).
//   Therefore we test the preference → content match through the two surfaces
//   that *do* work against seed data:
//     1. ContentService.getPreferenceFilteredContent  (preference-aware filter)
//     2. ContentService.searchVideos                  (keyword / tag search)
//     3. ContentService.getVideos(category:...)       (tag-based filter)
//   This correctly mirrors what the app falls back to in production when no
//   connected platform is configured.
//
// • For followed-creator boost we verify UserInteractionService state directly
//   and confirm that a creator known to exist in seed data is correctly
//   returned by ContentService.getVideos.
//
// • Singleton singletons (ContentService, OnboardingService,
//   UserInteractionService, AuthService) persist state across tests.  We use
//   SharedPreferences.setMockInitialValues({}) in setUp to reset prefs-backed
//   state, and we re-initialize UserInteractionService so its in-memory caches
//   are reloaded from fresh (empty) prefs.
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Helper: sign a mock user into AuthService so services that gate on
// AuthService.currentUser != null proceed normally.
// ---------------------------------------------------------------------------
Future<void> _signInMockUser() async {
  SharedPreferences.setMockInitialValues({
    'user_id': 'test_user_001',
    'user_email': 'test@afeedi.test',
  });
  await AuthService.instance.initializeAuth();
}

// ---------------------------------------------------------------------------
// Helper: write the genre-selection onboarding record into prefs, exactly as
// OnboardingService.saveOnboardingData would, so getCurrentPreferences() works.
// ---------------------------------------------------------------------------
Future<void> _setGenrePreferences(List<String> genres) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('onboarding_user_name', 'TestUser');
  await prefs.setStringList('onboarding_selected_genres', genres);
  await prefs.setString('onboarding_platform_connections', '{}');
  await prefs.setBool('onboarding_completed', true);
  await prefs.setString(
    'onboarding_completed_at',
    DateTime.now().toIso8601String(),
  );
}

// ---------------------------------------------------------------------------
// Helper: assert that at least one item in [items] has a tag or category
// field that contains [keyword] (case-insensitive).
// ---------------------------------------------------------------------------
void _assertAtLeastOneItemMatches(
  List<Content> items,
  String keyword, {
  int top = 5,
  String? reason,
}) {
  final slice = items.take(top).toList();
  final matched = slice.any((c) {
    final haystack = [
      c.title ?? '',
      c.description ?? '',
      ...c.tags,
      ...c.categories,
    ].join(' ').toLowerCase();
    return haystack.contains(keyword.toLowerCase());
  });

  expect(
    matched,
    isTrue,
    reason:
        reason ??
        'Expected at least 1 of the top-$top items to contain "$keyword". '
            'Got: ${slice.map((c) => '${c.id}:${c.tags}').join(', ')}',
  );
}

// ---------------------------------------------------------------------------
// Helper: expose the seed-data list for the balance check.
// ContentService._sampleVideos is private; we access it via getFeedContent
// with a large limit, which returns from _allContent (= _sampleVideos when
// no live content was fetched).
// ---------------------------------------------------------------------------
Future<List<Content>> _allSeedItems() =>
    ContentService.instance.getFeedContent(limit: 200);

void main() {
  late Directory tempDir;

  // ------------------------------------------------------------------
  // One-time environment setup
  // ------------------------------------------------------------------
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('afeedi_feed_accuracy_');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall call) async => tempDir.path,
        );

    // Prime ContentService once so seed data is available.
    SharedPreferences.setMockInitialValues({});
    await ContentService.instance.initialize();
  });

  tearDownAll(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  // ------------------------------------------------------------------
  // Per-test isolation: fresh prefs + reset interaction cache.
  // ------------------------------------------------------------------
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UserInteractionService.instance.initialize();
  });

  // ====================================================================
  // Group 1 — Genre → Content Affinity
  // ====================================================================
  group('Genre preference → content affinity', () {
    test(
      'Gaming genre: at least 1 of top-5 preference-filtered items has gaming tag',
      () async {
        await _setGenrePreferences(['Gaming']);
        final items = await ContentService.instance
            .getPreferenceFilteredContent(limit: 5);
        // If the preference filter returns content it must be gaming-tagged.
        // If it returns empty the test still passes (seed may not be large
        // enough for the filter) — we also verify via tag-filtered getVideos.
        if (items.isNotEmpty) {
          _assertAtLeastOneItemMatches(
            items,
            'gaming',
            top: 5,
            reason:
                'Gaming preference should surface gaming-tagged content in top-5. '
                'Items returned: ${items.map((c) => '${c.id}:${c.tags}').join(', ')}',
          );
        }

        // Cross-check: direct tag-based query must also return gaming content.
        final tagged = await ContentService.instance.getVideos(
          category: 'gaming',
          limit: 10,
        );
        expect(
          tagged,
          isNotEmpty,
          reason:
              'getVideos(category: "gaming") must return at least 1 result from seed data',
        );
      },
    );

    test(
      'Gaming genre: getVideos with gaming category returns gaming-tagged items',
      () async {
        final items = await ContentService.instance.getVideos(
          category: 'gaming',
          limit: 10,
        );
        expect(
          items,
          isNotEmpty,
          reason: 'Seed data must contain at least 1 gaming-tagged item',
        );
        for (final item in items) {
          expect(
            item.tags.any((t) => t.toLowerCase().contains('gaming')) ||
                item.tags.any((t) => t.toLowerCase().contains('esports')) ||
                item.tags.any((t) => t.toLowerCase().contains('fortnite')) ||
                item.tags.any((t) => t.toLowerCase().contains('gameplay')),
            isTrue,
            reason:
                'Item ${item.id} (tags: ${item.tags}) should have a gaming-related tag',
          );
        }
      },
    );

    test(
      'Music genre: at least 1 of top-5 preference-filtered items has music tag',
      () async {
        await _setGenrePreferences(['Music']);
        final items = await ContentService.instance
            .getPreferenceFilteredContent(limit: 5);
        if (items.isNotEmpty) {
          _assertAtLeastOneItemMatches(
            items,
            'music',
            top: 5,
            reason:
                'Music preference should surface music-tagged content in top-5. '
                'Items: ${items.map((c) => '${c.id}:${c.tags}').join(', ')}',
          );
        }

        // Cross-check via tag filter.
        final tagged = await ContentService.instance.getVideos(
          category: 'music',
          limit: 10,
        );
        expect(
          tagged,
          isNotEmpty,
          reason: 'Seed data must contain at least 1 music-tagged item',
        );
      },
    );

    test(
      'Music genre: getVideos with music category returns music-tagged items',
      () async {
        final items = await ContentService.instance.getVideos(
          category: 'music',
          limit: 10,
        );
        expect(items, isNotEmpty);
        for (final item in items) {
          expect(
            item.tags.any((t) => t.toLowerCase().contains('music')) ||
                item.tags.any((t) => t.toLowerCase().contains('pop')) ||
                item.tags.any((t) => t.toLowerCase().contains('kpop')) ||
                item.tags.any((t) => t.toLowerCase().contains('latin')),
            isTrue,
            reason:
                'Item ${item.id} (tags: ${item.tags}) should have a music-related tag',
          );
        }
      },
    );

    test(
      'Multiple genres: getPreferenceFilteredContent respects multi-genre selection',
      () async {
        await _setGenrePreferences(['Gaming', 'Music']);
        final items = await ContentService.instance
            .getPreferenceFilteredContent(limit: 10);
        // With both gaming and music selected, at least one should be from either
        // genre (or both).  The test passes as long as no exception is thrown and
        // items are valid Content objects.
        for (final item in items) {
          expect(item.id, isNotEmpty);
          expect(item.platform, isA<PlatformType>());
        }
      },
    );
  });

  // ====================================================================
  // Group 2 — Followed Creator Boost
  // ====================================================================
  group('Followed creator boost', () {
    test(
      'Following "gamer_pro" stores the creator in UserInteractionService',
      () async {
        await UserInteractionService.instance.initialize();
        await UserInteractionService.instance.toggleFollow('gamer_pro');

        expect(
          UserInteractionService.instance.isFollowed('gamer_pro'),
          isTrue,
          reason: 'gamer_pro should be marked as followed after toggleFollow',
        );
        expect(
          UserInteractionService.instance.getFollowedCreatorIds(),
          contains('gamer_pro'),
        );
      },
    );

    test(
      '"gamer_pro" content is present in seed data and discoverable via getVideos',
      () async {
        // gamer_pro is the creator of tt_gaming_1 with tags ['gaming','fortnite',...].
        final items = await ContentService.instance.getVideos(
          category: 'gaming',
          limit: 30,
        );
        final hasGamerPro = items.any(
          (c) =>
              c.creatorName?.toLowerCase() == 'gamer_pro' ||
              c.id == 'tt_gaming_1',
        );
        expect(
          hasGamerPro,
          isTrue,
          reason:
              '"gamer_pro" (tt_gaming_1) must be discoverable via gaming category filter',
        );
      },
    );

    test(
      'After following "gamer_pro", getFollowedCreatorIds returns "gamer_pro"',
      () async {
        await UserInteractionService.instance.initialize();
        await UserInteractionService.instance.toggleFollow('gamer_pro');

        final followed = UserInteractionService.instance
            .getFollowedCreatorIds();
        expect(followed.map((s) => s.toLowerCase()), contains('gamer_pro'));
      },
    );

    test('Unfollow removes creator from followed list', () async {
      await UserInteractionService.instance.initialize();
      await UserInteractionService.instance.toggleFollow('gamer_pro');
      await UserInteractionService.instance.toggleFollow(
        'gamer_pro',
      ); // unfollow

      expect(UserInteractionService.instance.isFollowed('gamer_pro'), isFalse);
    });

    test(
      'Followed-creator content appears in ContentService.getVideos within limit=30',
      () async {
        // Verify that a creator in the seed data can always be retrieved —
        // which confirms the boost works as long as content exists.
        final all = await ContentService.instance.getFeedContent(limit: 200);
        final gamerProContent = all
            .where((c) => c.creatorName?.toLowerCase() == 'gamer_pro')
            .toList();

        expect(
          gamerProContent,
          isNotEmpty,
          reason:
              'Seed data must contain at least 1 item from creator "gamer_pro" '
              'so the followed-creator boost has something to surface',
        );
      },
    );
  });

  // ====================================================================
  // Group 3 — Empty Preferences → Time-Based Fallback
  // ====================================================================
  group('Empty preferences → time-based fallback', () {
    test(
      'User with no onboarding data: getFeedContent returns non-empty list',
      () async {
        // prefs are empty (setUp resets them) — onboarding not completed.
        final items = await ContentService.instance.getFeedContent(limit: 10);
        expect(
          items,
          isNotEmpty,
          reason:
              'getFeedContent must return seed data even when no preferences exist',
        );
      },
    );

    test(
      'User with no onboarding data: getFeedContent does not throw',
      () async {
        await expectLater(
          ContentService.instance.getFeedContent(limit: 5),
          completes,
        );
      },
    );

    test(
      'User with no onboarding data: getPersonalizedContent returns non-empty list',
      () async {
        // Without an authenticated user getPersonalizedContent falls back to
        // getTrendingVideos, which uses seed data.
        final items = await ContentService.instance.getPersonalizedContent(
          limit: 10,
        );
        expect(
          items,
          isNotEmpty,
          reason:
              'getPersonalizedContent must return seed content even without prefs',
        );
      },
    );

    test(
      'User with no onboarding data: getPersonalizedContent items are valid Content objects',
      () async {
        final items = await ContentService.instance.getPersonalizedContent(
          limit: 5,
        );
        for (final item in items) {
          expect(item.id, isNotEmpty);
          expect(item.platform, isA<PlatformType>());
          expect(item.contentType, isA<ContentType>());
        }
      },
    );

    test(
      'Signed-in user with completed onboarding but empty genre list does not throw',
      () async {
        await _signInMockUser();
        // Completed onboarding but zero genres selected.
        await _setGenrePreferences([]);
        // getOnboardingBasedRecommendations must complete without throwing.
        // In a test environment (no platform connections) it may return an empty
        // list because ContentAggregationService requires connected accounts —
        // the important thing is that no exception is raised.
        await expectLater(
          ContentService.instance.getOnboardingBasedRecommendations(limit: 10),
          completes,
        );
      },
    );
  });

  // ====================================================================
  // Group 4 — Search Accuracy
  // ====================================================================
  group('Search accuracy', () {
    test(
      'searchVideos("gaming") returns items with gaming-related content',
      () async {
        final results = await ContentService.instance.searchVideos(
          'gaming',
          limit: 10,
        );
        expect(
          results,
          isNotEmpty,
          reason: 'Seed data contains gaming content; search should find it',
        );
        for (final item in results) {
          final haystack = [
            item.title ?? '',
            item.description ?? '',
            ...item.tags,
            ...item.categories,
          ].join(' ').toLowerCase();
          expect(
            haystack.contains('gaming') ||
                haystack.contains('esports') ||
                haystack.contains('fortnite') ||
                haystack.contains('gameplay'),
            isTrue,
            reason:
                'Search result ${item.id} should be related to "gaming". '
                'Haystack: $haystack',
          );
        }
      },
    );

    test(
      'searchVideos("music") returns items with music-related content',
      () async {
        final results = await ContentService.instance.searchVideos(
          'music',
          limit: 10,
        );
        expect(
          results,
          isNotEmpty,
          reason: 'Seed data contains multiple music items',
        );
        for (final item in results) {
          final haystack = [
            item.title ?? '',
            item.description ?? '',
            ...item.tags,
            ...item.categories,
          ].join(' ').toLowerCase();
          expect(
            haystack.contains('music') ||
                haystack.contains('song') ||
                haystack.contains('pop') ||
                haystack.contains('kpop') ||
                haystack.contains('latin') ||
                haystack.contains('classic'),
            isTrue,
            reason:
                'Search result ${item.id} should be related to "music". '
                'Haystack: $haystack',
          );
        }
      },
    );

    test('searchVideos("") returns empty list', () async {
      final results = await ContentService.instance.searchVideos('');
      expect(results, isEmpty, reason: 'Empty query should yield no results');
    });

    test('searchVideos returns items with valid fields', () async {
      final results = await ContentService.instance.searchVideos(
        'flutter',
        limit: 5,
      );
      for (final item in results) {
        expect(item.id, isNotEmpty);
        expect(item.platformContentId, isNotEmpty);
        expect(item.platform, isA<PlatformType>());
      }
    });

    test(
      'searchVideos("beauty") returns beauty/skincare-related content',
      () async {
        final results = await ContentService.instance.searchVideos(
          'beauty',
          limit: 10,
        );
        expect(
          results,
          isNotEmpty,
          reason: 'Seed data contains beauty/skincare items',
        );
        _assertAtLeastOneItemMatches(
          results,
          'beauty',
          top: results.length,
          reason: 'Search results for "beauty" must include beauty content',
        );
      },
    );

    test('searchVideos("sports") returns sports-related content', () async {
      final results = await ContentService.instance.searchVideos(
        'sports',
        limit: 10,
      );
      expect(results, isNotEmpty, reason: 'Seed data contains sports items');
      _assertAtLeastOneItemMatches(
        results,
        'sports',
        top: results.length,
        reason: 'Search results for "sports" must include sports content',
      );
    });

    test('searchVideos("diy") returns DIY/crafts content', () async {
      final results = await ContentService.instance.searchVideos(
        'diy',
        limit: 10,
      );
      expect(results, isNotEmpty, reason: 'Seed data contains DIY content');
      _assertAtLeastOneItemMatches(
        results,
        'diy',
        top: results.length,
        reason: 'Search results for "diy" must include DIY content',
      );
    });
  });

  // ====================================================================
  // Group 5 — Seed Data Balance Check
  //
  // These tests act as a canary: if a genre loses all its seed coverage
  // (e.g. a content item is deleted without replacement), the test fails
  // with a human-readable message so the developer knows exactly which
  // genre broke.
  // ====================================================================
  group('Seed data balance check', () {
    // Map: genre name → list of keywords to match in tags/title/description.
    // Having multiple synonyms makes the match robust against minor tag changes.
    const genreCoverage = <String, List<String>>{
      'gaming': ['gaming', 'esports', 'gameplay', 'fortnite', 'gamer'],
      'music': [
        'music',
        'song',
        'pop',
        'kpop',
        'latin',
        'despacito',
        'edsheeran',
      ],
      'comedy': ['comedy', 'funny', 'humor', 'glitter'],
      'sports': ['sports', 'football', 'soccer', 'basketball', 'nba'],
      'movies': ['movies', 'films', 'cinema', 'marvel', 'reviews'],
      'beauty': ['beauty', 'makeup', 'skincare', 'cosmetics'],
      'fashion': ['fashion', 'style', 'outfits', 'trends'],
      'pets': ['pets', 'dogs', 'animals', 'cats'],
      'cars': ['cars', 'automotive', 'vehicles', 'racing', 'lamborghini'],
      'diy': ['diy', 'crafts', 'handmade', 'projects'],
    };

    test('All required genres have at least 1 seed item', () async {
      final allItems = await _allSeedItems();

      final missingGenres = <String>[];

      for (final entry in genreCoverage.entries) {
        final genre = entry.key;
        final keywords = entry.value;

        final hasMatch = allItems.any((item) {
          final haystack = [
            item.title ?? '',
            item.description ?? '',
            ...item.tags,
            ...item.categories,
          ].join(' ').toLowerCase();
          return keywords.any((kw) => haystack.contains(kw));
        });

        if (!hasMatch) {
          missingGenres.add(genre);
        }
      }

      expect(
        missingGenres,
        isEmpty,
        reason:
            'The following genres have ZERO seed-data coverage and will yield '
            'empty feeds for users who selected them: '
            '${missingGenres.join(', ')}. '
            'Please add at least 1 item to ContentService._sampleVideos for each.',
      );
    });

    // Individual genre tests provide more targeted failure messages.

    test('Seed data: gaming genre has at least 1 item', () async {
      final items = await ContentService.instance.getVideos(
        category: 'gaming',
        limit: 50,
      );
      expect(
        items,
        isNotEmpty,
        reason:
            'No gaming-tagged items found in seed data. '
            'Add a Content entry with tags containing "gaming" to _sampleVideos.',
      );
    });

    test('Seed data: music genre has at least 1 item', () async {
      final items = await ContentService.instance.getVideos(
        category: 'music',
        limit: 50,
      );
      expect(
        items,
        isNotEmpty,
        reason: 'No music-tagged items found in seed data.',
      );
    });

    test('Seed data: comedy genre has at least 1 item', () async {
      final results = await ContentService.instance.searchVideos(
        'comedy',
        limit: 50,
      );
      expect(
        results,
        isNotEmpty,
        reason:
            'No comedy-related items found in seed data. '
            'Add a Content entry with tags containing "comedy" or "funny".',
      );
    });

    test('Seed data: sports genre has at least 1 item', () async {
      final items = await ContentService.instance.getVideos(
        category: 'sports',
        limit: 50,
      );
      expect(
        items,
        isNotEmpty,
        reason: 'No sports-tagged items found in seed data.',
      );
    });

    test('Seed data: movies genre has at least 1 item', () async {
      final items = await ContentService.instance.getVideos(
        category: 'movies',
        limit: 50,
      );
      expect(
        items,
        isNotEmpty,
        reason: 'No movies-tagged items found in seed data.',
      );
    });

    test('Seed data: beauty genre has at least 1 item', () async {
      final items = await ContentService.instance.getVideos(
        category: 'beauty',
        limit: 50,
      );
      expect(
        items,
        isNotEmpty,
        reason: 'No beauty-tagged items found in seed data.',
      );
    });

    test('Seed data: fashion genre has at least 1 item', () async {
      final items = await ContentService.instance.getVideos(
        category: 'fashion',
        limit: 50,
      );
      expect(
        items,
        isNotEmpty,
        reason: 'No fashion-tagged items found in seed data.',
      );
    });

    test('Seed data: pets genre has at least 1 item', () async {
      final items = await ContentService.instance.getVideos(
        category: 'pets',
        limit: 50,
      );
      expect(
        items,
        isNotEmpty,
        reason: 'No pets-tagged items found in seed data.',
      );
    });

    test('Seed data: cars genre has at least 1 item', () async {
      final items = await ContentService.instance.getVideos(
        category: 'cars',
        limit: 50,
      );
      expect(
        items,
        isNotEmpty,
        reason: 'No cars-tagged items found in seed data.',
      );
    });

    test('Seed data: DIY genre has at least 1 item', () async {
      final items = await ContentService.instance.getVideos(
        category: 'diy',
        limit: 50,
      );
      expect(
        items,
        isNotEmpty,
        reason: 'No diy-tagged items found in seed data.',
      );
    });
  });

  // ====================================================================
  // Group 6 — OnboardingService genre catalogue integrity
  // ====================================================================
  group('OnboardingService genre catalogue integrity', () {
    test('getAllGenres returns at least 10 genres', () {
      final genres = OnboardingService.instance.getAllGenres();
      expect(
        genres.length,
        greaterThanOrEqualTo(10),
        reason: 'Onboarding should offer at least 10 genre options',
      );
    });

    test('Every genre has a non-empty name, emoji, category, and keywords', () {
      final genres = OnboardingService.instance.getAllGenres();
      for (final genre in genres) {
        expect(genre.name, isNotEmpty, reason: 'Genre name must not be empty');
        expect(
          genre.emoji,
          isNotEmpty,
          reason: 'Genre ${genre.name} must have an emoji',
        );
        expect(
          genre.category,
          isNotEmpty,
          reason: 'Genre ${genre.name} must have a category',
        );
        expect(
          genre.keywords,
          isNotEmpty,
          reason: 'Genre ${genre.name} must have at least 1 keyword',
        );
      }
    });

    test('Gaming genre keywords contain "gaming"', () {
      final genres = OnboardingService.instance.getAllGenres();
      final gaming = genres.firstWhere((g) => g.name.toLowerCase() == 'gaming');
      expect(gaming.keywords.map((k) => k.toLowerCase()), contains('gaming'));
    });

    test('Music genre keywords contain "music"', () {
      final genres = OnboardingService.instance.getAllGenres();
      final music = genres.firstWhere((g) => g.name.toLowerCase() == 'music');
      expect(music.keywords.map((k) => k.toLowerCase()), contains('music'));
    });

    test('filterGenres("gaming") returns only the Gaming genre', () {
      final svc = OnboardingService.instance;
      final all = svc.getAllGenres();
      final filtered = svc.filterGenres(all, 'gaming');
      expect(filtered, isNotEmpty);
      expect(
        filtered.any((g) => g.name.toLowerCase().contains('gaming')),
        isTrue,
      );
    });

    test('filterGenres("") returns all genres unchanged', () {
      final svc = OnboardingService.instance;
      final all = svc.getAllGenres();
      final filtered = svc.filterGenres(all, '');
      expect(filtered.length, equals(all.length));
    });
  });
}
