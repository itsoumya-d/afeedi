import 'package:flutter_test/flutter_test.dart';
import 'package:afeedi/services/onboarding_service.dart';
import 'package:afeedi/models/genre.dart';

void main() {
  late OnboardingService onboardingService;

  setUp(() {
    onboardingService = OnboardingService.instance;
  });

  group('OnboardingService - getAllGenres', () {
    test('returns a non-empty list of genres', () {
      final genres = onboardingService.getAllGenres();
      expect(genres, isNotEmpty);
    });

    test('returns at least 20 genres', () {
      final genres = onboardingService.getAllGenres();
      expect(genres.length, greaterThanOrEqualTo(20));
    });

    test('contains expected specific genres', () {
      final genres = onboardingService.getAllGenres();

      final gamingGenre = genres.firstWhere((g) => g.name == 'Gaming');
      expect(gamingGenre.emoji, '🎮');
      expect(gamingGenre.category, 'Entertainment');
      expect(gamingGenre.keywords, contains('esports'));

      final techGenre = genres.firstWhere((g) => g.name == 'Technology');
      expect(techGenre.emoji, '📱');
      expect(techGenre.category, 'Education');
      expect(techGenre.keywords, contains('innovation'));
    });

    test('all genres have required properties properly populated', () {
      final genres = onboardingService.getAllGenres();

      for (final genre in genres) {
        expect(genre.name, isNotEmpty, reason: 'Genre name should not be empty');
        expect(genre.emoji, isNotEmpty, reason: 'Genre emoji should not be empty');
        expect(genre.category, isNotEmpty, reason: 'Genre category should not be empty');
        expect(genre.keywords, isNotEmpty, reason: 'Genre keywords should not be empty');
      }
    });
  });

  group('OnboardingService - filterGenres', () {
    late List<Genre> allGenres;

    setUp(() {
      allGenres = onboardingService.getAllGenres();
    });

    test('returns all genres when query is empty', () {
      final filtered = onboardingService.filterGenres(allGenres, '');
      expect(filtered.length, allGenres.length);
    });

    test('filters correctly by name', () {
      final filtered = onboardingService.filterGenres(allGenres, 'Gaming');
      expect(filtered.length, 1);
      expect(filtered.first.name, 'Gaming');
    });

    test('filters correctly by category', () {
      final filtered = onboardingService.filterGenres(allGenres, 'Entertainment');
      expect(filtered, isNotEmpty);
      for (final genre in filtered) {
        // filterGenres searches in name, category, and keywords
        // So they either match the category or have it in their keywords/name
        final matchesCategory = genre.category.toLowerCase().contains('entertainment');
        final matchesName = genre.name.toLowerCase().contains('entertainment');
        final matchesKeyword = genre.keywords.any((k) => k.toLowerCase().contains('entertainment'));

        expect(matchesCategory || matchesName || matchesKeyword, isTrue);
      }
    });

    test('filters correctly by keyword', () {
      final filtered = onboardingService.filterGenres(allGenres, 'esports');
      expect(filtered.length, 1);
      expect(filtered.first.name, 'Gaming');
    });

    test('filtering is case-insensitive', () {
      final lowerFiltered = onboardingService.filterGenres(allGenres, 'gaming');
      final upperFiltered = onboardingService.filterGenres(allGenres, 'GAMING');

      expect(lowerFiltered.length, upperFiltered.length);
      expect(lowerFiltered.first.name, upperFiltered.first.name);
    });

    test('returns empty list when no match found', () {
      final filtered = onboardingService.filterGenres(allGenres, 'NonExistentGenre123');
      expect(filtered, isEmpty);
    });
  });
}
