import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../models/timetable_slot.dart';

class NotificationSettings {
  final bool enabled;
  final int minutesBefore;

  const NotificationSettings({
    this.enabled = true,
    this.minutesBefore = 15,
  });

  NotificationSettings copyWith({
    bool? enabled,
    int? minutesBefore,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      minutesBefore: minutesBefore ?? this.minutesBefore,
    );
  }
}

class NotificationSettingsNotifier extends Notifier<NotificationSettings> {
  static const String _boxName = 'settings_cache';
  static const String _keyEnabled = 'timetable_notifications_enabled';
  static const String _keyMinutesBefore = 'timetable_notifications_minutes_before';

  @override
  NotificationSettings build() {
    final box = Hive.box<dynamic>(_boxName);
    final bool enabled = box.get(_keyEnabled, defaultValue: true) as bool;
    final int minutesBefore = box.get(_keyMinutesBefore, defaultValue: 15) as int;
    return NotificationSettings(enabled: enabled, minutesBefore: minutesBefore);
  }

  Future<void> updateSettings({bool? enabled, int? minutesBefore}) async {
    final box = Hive.box<dynamic>(_boxName);
    final newEnabled = enabled ?? state.enabled;
    final newMinutesBefore = minutesBefore ?? state.minutesBefore;

    await box.put(_keyEnabled, newEnabled);
    await box.put(_keyMinutesBefore, newMinutesBefore);

    state = state.copyWith(enabled: newEnabled, minutesBefore: newMinutesBefore);
  }
}

final notificationSettingsProvider =
    NotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
  () => NotificationSettingsNotifier(),
);

class LocalNotificationsService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static const String _channelId = 'timetable_channel';
  static const String _channelName = 'Timetable Reminders';
  static const String _channelDescription =
      'Notifications for upcoming classes and lectures';

  /// Initializes timezone database and platform-specific local notifications.
  static Future<void> init() async {
    if (_initialized || kIsWeb) return;

    try {
      tz.initializeTimeZones();
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = tzInfo.identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('🕒 [NOTIFICATIONS] Timezone initialized to: $timeZoneName');
    } catch (e) {
      debugPrint('⚠️ [NOTIFICATIONS] Failed to set local timezone: $e');
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings: initSettings);

    // Create Android Notification Channel
    if (!kIsWeb && Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.high,
        );
        await androidImplementation.createNotificationChannel(channel);

        // Request POST_NOTIFICATIONS permission on Android 13+
        await androidImplementation.requestNotificationsPermission();
      }
    } else if (!kIsWeb && Platform.isIOS) {
      final IOSFlutterLocalNotificationsPlugin? iosImplementation =
          _plugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    _initialized = true;
    debugPrint('🚀 [NOTIFICATIONS] Local notifications plugin initialized');
  }

  /// Cancels existing timetable notifications and schedules recurring weekly reminders.
  static Future<void> syncTimetableNotifications(
    List<TimetableSlot> slots, {
    required bool enabled,
    required int minutesBefore,
  }) async {
    if (kIsWeb) return;

    // Cancel previously scheduled notifications
    await _plugin.cancelAll();
    debugPrint('🔔 [NOTIFICATIONS] Cleared previous timetable notifications');

    if (!enabled || slots.isEmpty) {
      debugPrint('🔔 [NOTIFICATIONS] Timetable reminders disabled or empty slots; sync finished.');
      return;
    }

    for (final slot in slots) {
      if (slot.start.isEmpty || !slot.start.contains(':')) continue;

      final parts = slot.start.split(':');
      final int hour = int.tryParse(parts[0]) ?? 0;
      final int minute = int.tryParse(parts[1]) ?? 0;

      final tz.TZDateTime scheduledDate = nextInstanceOfWeekdayAndTime(
        slot.day,
        hour,
        minute,
        minutesBefore,
      );

      final int notificationId = slot.id.hashCode & 0x7FFFFFFF;
      final String title = 'Upcoming Class: ${slot.subject}';
      final String body =
          'Starts at ${slot.start} in Room ${slot.room} ($minutesBefore min reminder)';

      final NotificationDetails details = const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      );

      try {
        await _plugin.zonedSchedule(
          id: notificationId,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
        debugPrint(
          '🔔 [NOTIFICATIONS] Scheduled #$notificationId ($title) for weekly ${scheduledDate.toLocal()}',
        );
      } catch (e) {
        // Fallback to inexact alarm mode if exact alarms are disabled on Android 14+
        debugPrint('⚠️ [NOTIFICATIONS] Exact alarm scheduling failed ($e), falling back to inexact.');
        try {
          await _plugin.zonedSchedule(
            id: notificationId,
            title: title,
            body: body,
            scheduledDate: scheduledDate,
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.inexact,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          );
        } catch (innerErr) {
          debugPrint('❌ [NOTIFICATIONS] Failed to schedule #$notificationId: $innerErr');
        }
      }
    }
  }

  /// Calculates the next occurrence of [targetWeekday] at [hour]:[minute], minus [minutesBefore].
  static tz.TZDateTime nextInstanceOfWeekdayAndTime(
    int targetWeekday,
    int hour,
    int minute,
    int minutesBefore, [
    tz.TZDateTime? nowOverride,
  ]) {
    final now = nowOverride ?? tz.TZDateTime.now(tz.local);

    // Create a candidate datetime for today at the class start time
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Adjust to target weekday (1 = Mon ... 7 = Sun)
    int dayDifference = targetWeekday - scheduledDate.weekday;
    if (dayDifference < 0) {
      dayDifference += 7;
    }
    scheduledDate = scheduledDate.add(Duration(days: dayDifference));

    // Subtract reminder lead time
    tz.TZDateTime reminderTime =
        scheduledDate.subtract(Duration(minutes: minutesBefore));

    // If reminderTime is already in the past this week (compared to now), jump to next week's occurrence
    if (reminderTime.isBefore(now)) {
      reminderTime = reminderTime.add(const Duration(days: 7));
    }

    return reminderTime;
  }

  /// Triggers an immediate local notification banner (used by FCM foreground pushes and Workmanager background tasks).
  static Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;
    if (!_initialized) {
      await init();
    }
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
      debugPrint('🔔 [NOTIFICATIONS] Displayed instant banner #$id ($title)');
    } catch (e) {
      debugPrint('❌ [NOTIFICATIONS] Failed to show instant notification #$id: $e');
    }
  }
}

