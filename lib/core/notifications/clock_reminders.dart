import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Daily Lagos-time clock reminders for staff (Mon–Fri).
///
/// These are scheduled local notifications on the device — they fire even when
/// the app is closed. True FCM push is not required for fixed daily times.
abstract final class ClockReminderNotifications {
  static const _prefsEnabled = 'berp_clock_reminders_enabled';

  /// New channel id — Android never updates sound settings on an existing channel.
  static const channelId = 'berp_staff_alerts_sound';
  static const channelName = 'BERP alerts';

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _ready = false;

  /// Shared details so clock reminders and admin pushes always ring.
  static NotificationDetails detailsFor(String body) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription:
            'Staff alerts with sound — clock reminders and HR pushes',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        category: AndroidNotificationCategory.reminder,
        audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
        styleInformation: BigTextStyleInformation(body),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );
  }

  static const reminders = <ClockReminderSpec>[
    ClockReminderSpec(
      id: 830,
      hour: 8,
      minute: 30,
      title: 'Have a beautiful day',
      body:
          'Head to work on time — a calm start makes for a beautiful day at VMO.',
    ),
    ClockReminderSpec(
      id: 845,
      hour: 8,
      minute: 45,
      title: 'Almost time',
      body:
          'Get to work on time so you can have a beautiful day. See you at the desk.',
    ),
    ClockReminderSpec(
      id: 855,
      hour: 8,
      minute: 55,
      title: 'Don\'t forget to clock in',
      body: 'Already at work? Clock in now so you do not get a call from HR.',
    ),
    ClockReminderSpec(
      id: 900,
      hour: 9,
      minute: 0,
      title: 'Clock in now',
      body:
          'It is 9:00am Lagos time. Clock in now — after this you may be marked late.',
    ),
  ];

  static FlutterLocalNotificationsPlugin get plugin => _plugin;

  /// Monday=1 … Friday=5
  static const _weekdays = [1, 2, 3, 4, 5];

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsEnabled) ?? true;
  }

  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsEnabled, enabled);
    if (enabled) {
      await scheduleAll();
    } else {
      await cancelAll();
    }
  }

  static Future<void> ensureInitialized() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Africa/Lagos'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );

    if (Platform.isAndroid) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.requestExactAlarmsPermission();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          channelId,
          channelName,
          description:
              'Staff alerts with sound — clock reminders and HR pushes',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );
    }

    _ready = true;
  }

  static Future<void> bootstrap() async {
    try {
      await ensureInitialized();
      if (await isEnabled()) {
        await scheduleAll();
      }
    } catch (error, stack) {
      debugPrint('Clock reminders failed: $error\n$stack');
    }
  }

  static int _notifId(int baseId, int weekday) => baseId * 10 + weekday;

  static Future<void> cancelAll() async {
    await ensureInitialized();
    for (final reminder in reminders) {
      for (final weekday in _weekdays) {
        await _plugin.cancel(id: _notifId(reminder.id, weekday));
      }
    }
  }

  static Future<void> scheduleAll() async {
    await ensureInitialized();
    await cancelAll();
    for (final reminder in reminders) {
      for (final weekday in _weekdays) {
        await _scheduleWeekday(reminder, weekday);
      }
    }
  }

  static Future<void> _scheduleWeekday(
    ClockReminderSpec reminder,
    int weekday,
  ) async {
    final when = _nextWeekday(weekday, reminder.hour, reminder.minute);
    await _plugin.zonedSchedule(
      id: _notifId(reminder.id, weekday),
      title: reminder.title,
      body: reminder.body,
      scheduledDate: when,
      notificationDetails: detailsFor(reminder.body),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  static tz.TZDateTime _nextWeekday(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    while (scheduled.weekday != weekday || !scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}

class ClockReminderSpec {
  const ClockReminderSpec({
    required this.id,
    required this.hour,
    required this.minute,
    required this.title,
    required this.body,
  });

  final int id;
  final int hour;
  final int minute;
  final String title;
  final String body;
}
