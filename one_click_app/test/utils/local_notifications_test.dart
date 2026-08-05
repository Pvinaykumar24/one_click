import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:one_click_app/core/notifications/local_notifications_service.dart';

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('UTC'));
  });

  group('LocalNotificationsService.nextInstanceOfWeekdayAndTime', () {
    test('schedules for later today when class reminder is in the future today', () {
      // 2026-01-05 is a Monday (weekday 1)
      final now = tz.TZDateTime.utc(2026, 1, 5, 8, 0); // Monday at 08:00

      // Class on Monday (weekday 1) at 09:00, with 15 min reminder -> should trigger at 08:45
      final scheduled = LocalNotificationsService.nextInstanceOfWeekdayAndTime(
        1,
        9,
        0,
        15,
        now,
      );

      expect(scheduled.year, equals(2026));
      expect(scheduled.month, equals(1));
      expect(scheduled.day, equals(5));
      expect(scheduled.hour, equals(8));
      expect(scheduled.minute, equals(45));
      expect(scheduled.isBefore(now), isFalse);
    });

    test('schedules for next week when class reminder time today has already passed', () {
      // 2026-01-05 is a Monday (weekday 1)
      final now = tz.TZDateTime.utc(2026, 1, 5, 8, 50); // Monday at 08:50

      // Class on Monday (weekday 1) at 09:00, with 15 min reminder -> 08:45 already passed today
      final scheduled = LocalNotificationsService.nextInstanceOfWeekdayAndTime(
        1,
        9,
        0,
        15,
        now,
      );

      // Should jump 7 days to next Monday: 2026-01-12 at 08:45
      expect(scheduled.year, equals(2026));
      expect(scheduled.month, equals(1));
      expect(scheduled.day, equals(12));
      expect(scheduled.hour, equals(8));
      expect(scheduled.minute, equals(45));
      expect(scheduled.isAfter(now), isTrue);
    });

    test('schedules correctly for a different day of the week later in current week', () {
      // 2026-01-05 is Monday
      final now = tz.TZDateTime.utc(2026, 1, 5, 12, 0);

      // Class on Wednesday (weekday 3) at 10:30, with 30 min reminder -> Wednesday at 10:00
      final scheduled = LocalNotificationsService.nextInstanceOfWeekdayAndTime(
        3,
        10,
        30,
        30,
        now,
      );

      expect(scheduled.year, equals(2026));
      expect(scheduled.month, equals(1));
      expect(scheduled.day, equals(7)); // Wednesday Jan 7, 2026
      expect(scheduled.hour, equals(10));
      expect(scheduled.minute, equals(0));
    });
  });
}
