import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../auth/auth_service.dart';
import '../data/berp_cloud.dart';
import '../data/device_fingerprint.dart';
import 'clock_reminders.dart';

/// Syncs admin-scheduled pushes from Supabase onto the device, and logs
/// clock-reminder / delivery events so HR can see them in BHR.
abstract final class PushInbox {
  static const _adminIdBase = 500000;

  static Future<void> sync() async {
    try {
      await ClockReminderNotifications.ensureInitialized();
      await _logClockRemindersVisible();
      await _scheduleAdminMessages();
    } catch (error, stack) {
      debugPrint('PushInbox.sync failed: $error\n$stack');
    }
  }

  static Future<void> _logClockRemindersVisible() async {
    if (!await ClockReminderNotifications.isEnabled()) return;
    if (!AuthService.isSignedIn) return;

    // One delivery row per reminder per Lagos day (avoid spam on every launch).
    final lagos = tz.TZDateTime.now(tz.getLocation('Africa/Lagos'));
    final dayKey =
        '${lagos.year}-${lagos.month.toString().padLeft(2, '0')}-${lagos.day.toString().padLeft(2, '0')}';

    final device = await DeviceFingerprint.current(refreshIp: false);
    for (final reminder in ClockReminderNotifications.reminders) {
      await BerpCloud.logPushDeliveryOncePerDay(
        dedupeKey: 'clock-${reminder.id}-$dayKey',
        title: reminder.title,
        body: reminder.body,
        status: 'scheduled',
        deviceId: device.deviceId,
        meta: {
          'kind': 'clock_reminder',
          'lagos_time':
              '${reminder.hour.toString().padLeft(2, '0')}:'
              '${reminder.minute.toString().padLeft(2, '0')}',
          'weekdays': 'Mon-Fri',
          'day': dayKey,
        },
      );
    }
  }

  static Future<void> _scheduleAdminMessages() async {
    if (!AuthService.isSignedIn) return;
    final messages = await BerpCloud.pendingAdminPushes();
    final lagos = tz.getLocation('Africa/Lagos');
    final now = tz.TZDateTime.now(lagos);
    final prefs = await SharedPreferences.getInstance();

    for (final message in messages) {
      final at = message.scheduledAt;
      if (at == null) continue;
      final when = tz.TZDateTime.from(at.toUtc(), lagos);
      if (!when.isAfter(now.subtract(const Duration(minutes: 1)))) {
        await _showNow(message, prefs);
        continue;
      }

      final notifId = _adminIdBase + message.id.hashCode.abs() % 100000;
      await ClockReminderNotifications.plugin.zonedSchedule(
        id: notifId,
        title: message.title,
        body: message.body,
        scheduledDate: when,
        notificationDetails:
            ClockReminderNotifications.detailsFor(message.body),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      final device = await DeviceFingerprint.current(refreshIp: false);
      await BerpCloud.logPushDeliveryOncePerDay(
        messageId: message.id,
        dedupeKey: 'admin-sched-${message.id}',
        title: message.title,
        body: message.body,
        status: 'scheduled',
        deviceId: device.deviceId,
        meta: {
          'kind': 'admin',
          'message_id': message.id,
          'scheduled_at': at.toUtc().toIso8601String(),
          'local_notif_id': notifId,
        },
      );
    }
  }

  static Future<void> _showNow(
    BerpPushMessage message,
    SharedPreferences prefs,
  ) async {
    final shownKey = 'berp_push_shown_${message.id}';
    if (prefs.getBool(shownKey) == true) return;

    final notifId = _adminIdBase + message.id.hashCode.abs() % 100000;
    await ClockReminderNotifications.plugin.show(
      id: notifId,
      title: message.title,
      body: message.body,
      notificationDetails: ClockReminderNotifications.detailsFor(message.body),
    );
    await prefs.setBool(shownKey, true);

    final device = await DeviceFingerprint.current(refreshIp: false);
    await BerpCloud.logPushDelivery(
      messageId: message.id,
      title: message.title,
      body: message.body,
      status: 'shown',
      deviceId: device.deviceId,
      meta: {'kind': 'admin', 'immediate': true},
    );
    await BerpCloud.markPushSent(message.id);
  }
}

class BerpPushMessage {
  const BerpPushMessage({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.status,
    this.scheduledAt,
    this.recurLabel,
  });

  final String id;
  final String kind;
  final String title;
  final String body;
  final String status;
  final DateTime? scheduledAt;
  final String? recurLabel;

  factory BerpPushMessage.fromJson(Map<String, dynamic> json) {
    return BerpPushMessage(
      id: '${json['id'] ?? ''}',
      kind: '${json['kind'] ?? 'admin'}',
      title: '${json['title'] ?? ''}',
      body: '${json['body'] ?? ''}',
      status: '${json['status'] ?? 'scheduled'}',
      scheduledAt: DateTime.tryParse('${json['scheduled_at'] ?? ''}'),
      recurLabel: _emptyToNull(json['recur_label']),
    );
  }

  static String? _emptyToNull(dynamic value) {
    final text = '$value'.trim();
    return text.isEmpty || text == 'null' ? null : text;
  }
}
