/// Content freshness tests for ContentService.
///
/// Verifies that:
///   1. invalidateCache() can be called without error.
///   2. getOnboardingBasedRecommendations() returns results after cache
///      invalidation (even if the list is empty due to no logged-in user).
///   3. Each returned item has a non-null 'recommendationReason' metadata field.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:afeedi/services/content_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ContentService freshness', () {
    test('invalidateCache() can be called without error', () {
      // Full-cache clear
      expect(() => ContentService.instance.invalidateCache(), returnsNormally);
      // Key-specific clear
      expect(
        () => ContentService.instance.invalidateCache('some_key'),
        returnsNormally,
      );
    });

    test(
      'getOnboardingBasedRecommendations returns results after invalidateCache',
      () async {
        // Warm the cache.
        await ContentService.instance.getOnboardingBasedRecommendations(
          limit: 5,
        );

        // Flush the cache.
        ContentService.instance.invalidateCache();

        // Re-fetch — must return a list (may be empty when no user is signed in).
        final results = await ContentService.instance
            .getOnboardingBasedRecommendations(limit: 5);

        expect(results, isA<List>());
      },
    );

    test(
      'getOnboardingBasedRecommendations sets recommendationReason on returned items',
      () async {
        ContentService.instance.invalidateCache();

        final results = await ContentService.instance
            .getOnboardingBasedRecommendations(limit: 5);

        // Every item that is returned must carry a non-null recommendationReason.
        for (final item in results) {
          expect(
            item.metadata['recommendationReason'],
            isNotNull,
            reason:
                'Item ${item.id} is missing the recommendationReason metadata field',
          );
        }
      },
    );
  });
}
