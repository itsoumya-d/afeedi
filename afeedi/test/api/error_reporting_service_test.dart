import 'package:flutter_test/flutter_test.dart';

import '../../lib/services/error_reporting_service.dart';

void main() {
  late ErrorReportingService svc;

  setUp(() {
    svc = ErrorReportingService.instance;
    svc.initialize();
  });

  group('ErrorReportingService', () {
    test('initialize() does not throw', () {
      expect(() => svc.initialize(), returnsNormally);
    });

    test('recordError increments totalErrors', () {
      final before = svc.totalErrors;
      svc.recordError(Exception('test error'), null, context: 'test');
      expect(svc.totalErrors, greaterThan(before));
    });

    test('recordWarning increments totalWarnings', () {
      final before = svc.totalWarnings;
      svc.recordWarning('test warning', context: 'test');
      expect(svc.totalWarnings, greaterThan(before));
    });

    test('recentErrors contains recorded error', () {
      svc.recordError(Exception('unique_error_12345'), null, context: 'ctx');
      final messages = svc.recentErrors.map((e) => e['message'] as String);
      expect(messages.any((m) => m.contains('unique_error_12345')), isTrue);
    });

    test('diagnostics returns valid map', () {
      final d = svc.diagnostics;
      expect(d['total_errors'], isA<int>());
      expect(d['total_warnings'], isA<int>());
      expect(d['uptime_seconds'], isA<int>());
      expect(d['session_start'], isA<String>());
    });

    test('onZoneError does not throw', () {
      expect(
        () => svc.onZoneError(Exception('zone error'), StackTrace.current),
        returnsNormally,
      );
    });
  });
}
