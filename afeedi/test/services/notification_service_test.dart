import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:afeedi/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('NotificationService', () {
    test('singleton returns same instance', () {
      final a = NotificationService.instance;
      final b = NotificationService.instance;
      expect(identical(a, b), isTrue);
    });

    test('initialize() completes without throwing', () async {
      // flutter_local_notifications is a no-op on test platforms
      await expectLater(NotificationService.instance.initialize(), completes);
    });

    test(
      'scheduleCalendarReminder does not throw when not initialized',
      () async {
        // Service not initialized in test env — should silently no-op
        await expectLater(
          NotificationService.instance.scheduleCalendarReminder(
            id: 'test_item_1',
            title: 'Test Video',
            platform: 'youtube',
            scheduledAt: DateTime.now().add(const Duration(hours: 2)),
          ),
          completes,
        );
      },
    );

    test(
      'cancelCalendarReminder does not throw when not initialized',
      () async {
        await expectLater(
          NotificationService.instance.cancelCalendarReminder('test_item_1'),
          completes,
        );
      },
    );

    test('scheduleCalendarReminder silently skips past times', () async {
      // scheduledAt in the past — method should return without scheduling
      await expectLater(
        NotificationService.instance.scheduleCalendarReminder(
          id: 'past_item',
          title: 'Old Video',
          platform: 'tiktok',
          scheduledAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        completes,
      );
    });

    test(
      'schedulePersonalizedNotifications completes when not initialized',
      () async {
        await expectLater(
          NotificationService.instance.schedulePersonalizedNotifications(),
          completes,
        );
      },
    );

    test('requestPermission returns false on test platform', () async {
      final result = await NotificationService.instance.requestPermission();
      expect(result, isFalse);
    });
  });
}
