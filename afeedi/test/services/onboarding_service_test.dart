import 'package:flutter_test/flutter_test.dart';
import 'package:afeedi/services/onboarding_service.dart';
import 'package:afeedi/models/genre.dart';

void main() {
  late OnboardingService onboardingService;

  setUp(() {
    onboardingService = OnboardingService.instance;
  });

  group('OnboardingService.generateSuggestions', () {
    test('returns name suggestions for inputs containing "name" or "call"', () {
      final suggestionsName = onboardingService.generateSuggestions(
        'what is your name?',
        [],
      );
      final suggestionsCall = onboardingService.generateSuggestions(
        'what should I call you?',
        [],
      );

      expect(suggestionsName, containsAll(['Alex', 'Sam', 'Jordan', 'Casey']));
      expect(suggestionsCall, containsAll(['Alex', 'Sam', 'Jordan', 'Casey']));
      expect(suggestionsName.length, lessThanOrEqualTo(4));
    });

    test(
      'returns mood suggestions for inputs containing "mood" or "feeling"',
      () {
        final suggestionsMood = onboardingService.generateSuggestions(
          'my mood is good',
          [],
        );
        final suggestionsFeeling = onboardingService.generateSuggestions(
          'I am feeling happy',
          [],
        );

        expect(suggestionsMood, contains('Excited for new discoveries! 🌟'));
        expect(suggestionsFeeling, contains('Looking for something chill 😌'));
        expect(suggestionsMood.length, lessThanOrEqualTo(4));
      },
    );

    test('returns genre-based suggestions for selected genres', () {
      final gamingGenre = Genre(
        name: 'Gaming',
        emoji: '🎮',
        category: 'Entertainment',
        keywords: ['gaming'],
      );
      final musicGenre = Genre(
        name: 'Music',
        emoji: '🎵',
        category: 'Entertainment',
        keywords: ['music'],
      );

      final suggestions = onboardingService.generateSuggestions('anything', [
        gamingGenre,
        musicGenre,
      ]);

      // Since the limit is 4, it might not contain all if there are many,
      // but it should contain some gaming or music suggestions
      expect(suggestions, isNotEmpty);
      expect(
        suggestions.any(
          (s) =>
              s.contains('competitive games') ||
              s.contains('indie music') ||
              s.contains('RPGs') ||
              s.contains('Pop music'),
        ),
        isTrue,
      );
    });

    test('limits suggestions to 4 and removes duplicates', () {
      final gamingGenre = Genre(
        name: 'Gaming',
        emoji: '🎮',
        category: 'Entertainment',
        keywords: ['gaming'],
      );
      final musicGenre = Genre(
        name: 'Music',
        emoji: '🎵',
        category: 'Entertainment',
        keywords: ['music'],
      );
      final foodGenre = Genre(
        name: 'Food',
        emoji: '🍕',
        category: 'Lifestyle',
        keywords: ['food'],
      );
      final travelGenre = Genre(
        name: 'Travel',
        emoji: '✈️',
        category: 'Lifestyle',
        keywords: ['travel'],
      );

      // This input triggers name, mood, and all genres, generating many suggestions
      final suggestions = onboardingService.generateSuggestions('name mood', [
        gamingGenre,
        musicGenre,
        foodGenre,
        travelGenre,
      ]);

      expect(suggestions.length, equals(4));
      // Ensure there are no duplicates
      expect(suggestions.toSet().length, equals(suggestions.length));
    });

    test('returns empty list for irrelevant input with no matching genres', () {
      final unexpectedGenre = Genre(
        name: 'Science',
        emoji: '🔬',
        category: 'Education',
        keywords: ['science'],
      );
      final suggestions = onboardingService.generateSuggestions('random text', [
        unexpectedGenre,
      ]);

      expect(suggestions, isEmpty);
    });
  });
}
