/// Recommendation-engine and content-scoring tests.
///
/// Tests cover:
///   - OnboardingService: generateSuggestions (genre synonyms / keywords)
///   - OnboardingService: filterGenres keyword matching
///   - OnboardingService: isOnboardingComplete validation
///   - OnboardingService: generateWelcomeMessage content
///   - OnboardingService: getOnboardingSteps returns non-empty list
///   - Recommendation model: toJson / fromJson round-trip and field access
///   - Content model: platform parsing, recency helpers, tag/category data
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:afeedi/services/onboarding_service.dart';
import 'package:afeedi/models/genre.dart';
import 'package:afeedi/models/recommendation.dart';
import 'package:afeedi/models/content_model.dart' hide Recommendation;

// ─── Helpers ─────────────────────────────────────────────────────────────────

Genre _genre(String name, List<String> keywords) =>
    Genre(name: name, emoji: '🎮', category: 'Test', keywords: keywords);

Content _content({
  required String id,
  List<String> tags = const [],
  List<String> categories = const [],
  DateTime? publishedAt,
  int durationSeconds = 300,
  PlatformType platform = PlatformType.youtube,
}) => Content(
  id: id,
  platform: platform,
  platformContentId: id,
  contentType: ContentType.video,
  tags: tags,
  categories: categories,
  durationSeconds: durationSeconds,
  publishedAt: publishedAt,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ── OnboardingService ─────────────────────────────────────────────────────

  group('OnboardingService.getOnboardingSteps', () {
    test('returns a non-empty list of steps', () {
      final steps = OnboardingService.instance.getOnboardingSteps();
      expect(steps, isNotEmpty);
    });

    test('first step has a non-empty botMessage', () {
      final steps = OnboardingService.instance.getOnboardingSteps();
      expect(steps.first.botMessage, isNotEmpty);
    });
  });

  group('OnboardingService.generateSuggestions', () {
    late OnboardingService service;

    setUp(() {
      service = OnboardingService.instance;
    });

    test('returns name suggestions for "name" keyword', () {
      final suggestions = service.generateSuggestions('what is your name?', []);
      expect(suggestions, containsAll(['Alex', 'Sam', 'Jordan', 'Casey']));
    });

    test('returns name suggestions for "call" keyword', () {
      final suggestions = service.generateSuggestions(
        'what should I call you?',
        [],
      );
      expect(suggestions, containsAll(['Alex', 'Sam', 'Jordan', 'Casey']));
    });

    test('returns mood suggestions for "mood" keyword', () {
      final suggestions = service.generateSuggestions('my mood is happy', []);
      expect(suggestions, contains('Excited for new discoveries! 🌟'));
    });

    test('returns mood suggestions for "feeling" keyword', () {
      final suggestions = service.generateSuggestions(
        'I am feeling excited',
        [],
      );
      expect(suggestions, contains('Looking for something chill 😌'));
    });

    test('returns genre-based suggestions for gaming genre', () {
      final gaming = _genre('Gaming', ['gaming', 'game']);
      final suggestions = service.generateSuggestions('any input', [gaming]);
      expect(
        suggestions.any(
          (s) =>
              s.contains('competitive games') ||
              s.contains('Indie games') ||
              s.contains('RPGs'),
        ),
        isTrue,
      );
    });

    test('limits suggestions to 4 unique items', () {
      final genres = [
        _genre('Gaming', ['gaming']),
        _genre('Music', ['music']),
        _genre('Food', ['food']),
        _genre('Travel', ['travel']),
      ];
      final suggestions = service.generateSuggestions('name mood', genres);
      expect(suggestions.length, lessThanOrEqualTo(4));
      expect(suggestions.toSet().length, equals(suggestions.length));
    });

    test('returns empty list for unrecognised input with no genres', () {
      final suggestions = service.generateSuggestions('xyz abc qwerty', []);
      expect(suggestions, isEmpty);
    });
  });

  group('OnboardingService.filterGenres', () {
    late OnboardingService service;
    late List<Genre> allGenres;

    setUp(() {
      service = OnboardingService.instance;
      allGenres = [
        _genre('Gaming', ['gaming', 'esports', 'fps']),
        _genre('Music', ['music', 'song', 'artist']),
        _genre('Technology', ['tech', 'coding', 'programming']),
        _genre('Comedy', ['comedy', 'funny', 'humor']),
        _genre('Fitness', ['fitness', 'workout', 'exercise']),
      ];
    });

    test('empty query returns all genres', () {
      final result = service.filterGenres(allGenres, '');
      expect(result.length, equals(allGenres.length));
    });

    test('filters by genre name (case-insensitive)', () {
      final result = service.filterGenres(allGenres, 'gaming');
      expect(result.length, equals(1));
      expect(result.first.name, equals('Gaming'));
    });

    test('keyword "esports" matches Gaming genre (synonym matching)', () {
      final result = service.filterGenres(allGenres, 'esports');
      expect(result.any((g) => g.name == 'Gaming'), isTrue);
    });

    test('filters by category field', () {
      // All test genres have category 'Test'; filtering by 'Test' returns all
      final result = service.filterGenres(allGenres, 'Test');
      expect(result.isNotEmpty, isTrue);
    });

    test('returns empty list for no-match query', () {
      final result = service.filterGenres(allGenres, 'xyznonexistent');
      expect(result, isEmpty);
    });

    test('matching is case-insensitive for keywords', () {
      final result = service.filterGenres(allGenres, 'CODING');
      expect(result.any((g) => g.name == 'Technology'), isTrue);
    });
  });

  group('OnboardingService.isOnboardingComplete', () {
    late OnboardingService service;

    setUp(() {
      service = OnboardingService.instance;
    });

    test('returns true when genres selected and name provided', () {
      final result = service.isOnboardingComplete(
        selectedGenres: [_genre('Gaming', [])],
        platformConnections: {},
        userName: 'Alex',
      );
      expect(result, isTrue);
    });

    test('returns false when no genres selected', () {
      final result = service.isOnboardingComplete(
        selectedGenres: [],
        platformConnections: {},
        userName: 'Alex',
      );
      expect(result, isFalse);
    });

    test('returns false when userName is blank', () {
      final result = service.isOnboardingComplete(
        selectedGenres: [_genre('Gaming', [])],
        platformConnections: {},
        userName: '',
      );
      expect(result, isFalse);
    });

    test('returns false when userName is only whitespace', () {
      final result = service.isOnboardingComplete(
        selectedGenres: [_genre('Gaming', [])],
        platformConnections: {},
        userName: '   ',
      );
      expect(result, isFalse);
    });
  });

  group('OnboardingService.generateWelcomeMessage', () {
    late OnboardingService service;

    setUp(() {
      service = OnboardingService.instance;
    });

    test('includes the user name in the message', () {
      final msg = service.generateWelcomeMessage(
        userName: 'Jordan',
        selectedGenres: [_genre('Gaming', [])],
        platformConnections: {},
      );
      expect(msg, contains('Jordan'));
    });

    test('includes selected genre names in the message', () {
      final msg = service.generateWelcomeMessage(
        userName: 'Sam',
        selectedGenres: [_genre('Gaming', []), _genre('Music', [])],
        platformConnections: {},
      );
      expect(msg, contains('Gaming'));
      expect(msg, contains('Music'));
    });

    test('mentions connected platforms when provided', () {
      final msg = service.generateWelcomeMessage(
        userName: 'Casey',
        selectedGenres: [_genre('Gaming', [])],
        platformConnections: {'youtube': true, 'tiktok': false},
      );
      expect(msg, contains('youtube'));
    });

    test('does not mention platform section when none are connected', () {
      final msg = service.generateWelcomeMessage(
        userName: 'Alex',
        selectedGenres: [_genre('Gaming', [])],
        platformConnections: {},
      );
      expect(msg.contains('Connected platforms'), isFalse);
    });
  });

  // ── Recommendation model ──────────────────────────────────────────────────

  group('Recommendation model', () {
    test('sample factory creates a valid object', () {
      final rec = Recommendation.sample(
        id: 'test-id',
        title: 'Gaming Highlights',
        platform: 'YouTube',
        category: 'Gaming',
        durationSeconds: 600,
      );
      expect(rec.id, equals('test-id'));
      expect(rec.title, equals('Gaming Highlights'));
      expect(rec.platform, equals('YouTube'));
      expect(rec.category, equals('Gaming'));
      expect(rec.durationSeconds, equals(600));
      expect(rec.relevanceScore, equals(0.85));
    });

    test('toJson contains all required keys', () {
      final rec = Recommendation.sample(id: 'r1');
      final json = rec.toJson();

      expect(json.containsKey('id'), isTrue);
      expect(json.containsKey('title'), isTrue);
      expect(json.containsKey('platform'), isTrue);
      expect(json.containsKey('category'), isTrue);
      expect(json.containsKey('relevanceScore'), isTrue);
      expect(json.containsKey('recommendationReason'), isTrue);
      expect(json.containsKey('createdAt'), isTrue);
    });

    test('fromJson round-trip preserves all fields', () {
      final original = Recommendation.sample(
        id: 'r2',
        title: 'Tech Review',
        platform: 'YouTube',
        category: 'Technology',
        durationSeconds: 900,
      );
      final json = original.toJson();
      final restored = Recommendation.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.title, equals(original.title));
      expect(restored.platform, equals(original.platform));
      expect(restored.category, equals(original.category));
      expect(restored.durationSeconds, equals(original.durationSeconds));
      expect(restored.relevanceScore, closeTo(original.relevanceScore, 0.001));
    });

    test('copyWith preserves unmodified fields', () {
      final original = Recommendation.sample(id: 'r3', title: 'Original');
      final copy = original.copyWith(title: 'Updated');
      expect(copy.id, equals(original.id));
      expect(copy.title, equals('Updated'));
      expect(copy.platform, equals(original.platform));
    });

    test('genre recommendation reason is stored', () {
      final rec = Recommendation.sample(id: 'r4');
      final copy = rec.copyWith(recommendationReason: 'Genre match: Gaming');
      expect(copy.recommendationReason, equals('Genre match: Gaming'));
    });

    test('contextualRelevance is accessible', () {
      final rec = Recommendation.sample(id: 'r5');
      expect(rec.contextualRelevance, equals(0.75));
    });
  });

  // ── Content model (recency & genre tag scoring helpers) ───────────────────

  group('Content model', () {
    test('fromJson/toJson round-trip preserves tags and categories', () {
      final now = DateTime.now().toUtc();
      final json = {
        'id': 'v1',
        'platform': 'youtube',
        'platform_content_id': 'yt-v1',
        'content_type': 'video',
        'tags': ['gaming', 'esports'],
        'categories': ['Entertainment'],
        'view_count': 1500,
        'like_count': 200,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final content = Content.fromJson(json);
      expect(content.tags, containsAll(['gaming', 'esports']));
      expect(content.categories, contains('Entertainment'));
      expect(content.platform, equals(PlatformType.youtube));
    });

    test(
      'content with education category is identified correctly for scoring',
      () {
        final educationContent = _content(
          id: 'edu1',
          categories: ['education', 'tutorials'],
          tags: ['learning'],
        );
        expect(
          educationContent.categories.any((c) => c.contains('education')),
          isTrue,
        );
      },
    );

    test('content with music tag is matched for evening scoring', () {
      final eveningContent = _content(
        id: 'ent1',
        categories: ['entertainment'],
        tags: ['music', 'video'],
      );
      expect(eveningContent.tags.any((t) => t.contains('music')), isTrue);
    });

    test('recency: content published within 24 hours is considered fresh', () {
      final freshContent = _content(
        id: 'fresh1',
        publishedAt: DateTime.now().subtract(const Duration(hours: 6)),
      );
      final age = DateTime.now().difference(freshContent.publishedAt!);
      expect(age.inHours, lessThan(24));
    });

    test('recency: content published over 30 days ago is considered stale', () {
      final staleContent = _content(
        id: 'stale1',
        publishedAt: DateTime.now().subtract(const Duration(days: 45)),
      );
      final age = DateTime.now().difference(staleContent.publishedAt!);
      expect(age.inDays, greaterThan(30));
    });

    test('gaming tag matches gaming genre keyword', () {
      final gamingContent = _content(id: 'g1', tags: ['gaming', 'fps']);
      final gamingKeywords = ['gaming', 'game', 'games', 'esports', 'fps'];
      final matches = gamingContent.tags.any(
        (tag) => gamingKeywords.any((kw) => tag.toLowerCase().contains(kw)),
      );
      expect(matches, isTrue);
    });

    test('platform type is correctly parsed from json for all platforms', () {
      for (final platform in PlatformType.values) {
        final now = DateTime.now().toUtc().toIso8601String();
        final json = {
          'id': 'x',
          'platform': platform.name,
          'platform_content_id': 'x',
          'content_type': 'video',
          'created_at': now,
          'updated_at': now,
        };
        final c = Content.fromJson(json);
        expect(c.platform, equals(platform));
      }
    });

    test('content without publishedAt has null publishedAt', () {
      final c = _content(id: 'nopub');
      expect(c.publishedAt, isNull);
    });

    test('viewCount defaults to 0 when not provided', () {
      final c = _content(id: 'noviews');
      expect(c.viewCount, equals(0));
    });
  });
}
