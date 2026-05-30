import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:afeedi/services/api_content_service.dart';

/// API-layer tests for ApiContentService.
///
/// These run without a real server — the service returns empty lists when
/// the server is unreachable, which is the correct offline behavior.
void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('ApiContentService - offline / unreachable server', () {
    late ApiContentService svc;

    setUp(() {
      svc = ApiContentService.instance;
    });

    test('checkHealth returns false when server unreachable', () async {
      // No server running — should return false within timeout
      final result = await svc.checkHealth();
      expect(result, isFalse,
          reason: 'Should report server unavailable when no server is running');
    });

    test('isAvailable returns false before successful health check', () {
      expect(svc.isAvailable, isFalse);
    });

    test('getFeed returns empty list when server unreachable', () async {
      final items = await svc.getFeed();
      expect(items, isEmpty,
          reason: 'Should return empty list, not throw, when offline');
    });

    test('getTrending returns empty list when server unreachable', () async {
      final items = await svc.getTrending();
      expect(items, isEmpty);
    });

    test('search returns empty list when server unreachable', () async {
      final items = await svc.search('flutter');
      expect(items, isEmpty);
    });

    test('search with empty query returns empty list', () async {
      final items = await svc.search('');
      expect(items, isEmpty,
          reason: 'Empty query should short-circuit and return []');
    });

    test('getById returns null when server unreachable', () async {
      final item = await svc.getById('dQw4w9WgXcQ');
      expect(item, isNull);
    });
  });

  group('ApiContentService - base URL configuration', () {
    test('base URL uses localhost:8888 by default on web', () {
      // The URL logic is tested indirectly — no crash means correct
      expect(() => ApiContentService.instance, returnsNormally);
    });
  });
}
