import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/app_data.dart';

final FlutterLocalNotificationsPlugin _plugin =
    FlutterLocalNotificationsPlugin();

Future<void> init() async {
  try {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: android,
        iOS: darwin,
        macOS: darwin,
      ),
    );
  } catch (e) {
    // No notification platform (e.g. under `flutter test`) — ignore, but log.
    debugPrint('Notifications.init failed: $e');
  }
}

Future<bool> requestPermission() async {
  try {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return (await android.requestNotificationsPermission()) ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return (await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          )) ??
          false;
    }
    final mac = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    if (mac != null) {
      return (await mac.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          )) ??
          false;
    }
    return true; // Linux / Windows: no runtime permission gate.
  } catch (_) {
    return false;
  }
}

const NotificationDetails _details = NotificationDetails(
  android: AndroidNotificationDetails(
    'tracker_reminders',
    'Reminders',
    channelDescription: 'Killzone & capture reminders',
    importance: Importance.high,
    priority: Priority.high,
  ),
  iOS: DarwinNotificationDetails(),
  macOS: DarwinNotificationDetails(),
);

bool _inQuietHours(int minutes, String start, String end) {
  int parse(String s) {
    final p = s.split(':');
    return (int.tryParse(p[0]) ?? 0) * 60 +
        (int.tryParse(p.length > 1 ? p[1] : '0') ?? 0);
  }

  final s = parse(start);
  final e = parse(end);
  return s < e ? (minutes >= s && minutes < e) : (minutes >= s || minutes < e);
}

/// Next occurrence of [hour]:[minute] in the local zone (today, or tomorrow if
/// it's already passed).
tz.TZDateTime _nextDaily(int hour, int minute) {
  final now = tz.TZDateTime.now(tz.local);
  var when = tz.TZDateTime(
    tz.local,
    now.year,
    now.month,
    now.day,
    hour,
    minute,
  );
  if (!when.isAfter(now)) when = when.add(const Duration(days: 1));
  return when;
}

Future<void> reschedule(AppData data) async {
  try {
    await _plugin.cancelAll();
    final notif = data.profile.notifications;
    if (!notif.master) return;
    var id = 0;

    // Killzones: repeat daily at (start − lead), skipping quiet hours / skipped.
    for (final kz in data.killzones) {
      if (!kz.alertOn) continue;
      if (kz.skipUntil != null &&
          DateTime.parse(kz.skipUntil!).isAfter(DateTime.now())) {
        continue;
      }
      final lead = kz.alertBefore;
      final fireMin = (kz.startMin - lead) % 1440; // Dart % is always >= 0 here
      if (_inQuietHours(fireMin, notif.quietStart, notif.quietEnd)) continue;
      await _plugin.zonedSchedule(
        id: id++,
        title: '${kz.name} opens soon',
        body: 'Starts in $lead min',
        scheduledDate: _nextDaily(fireMin ~/ 60, fireMin % 60),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // daily recurrence
      );
    }

    // Brain-dump reminders: one-shot, future only.
    for (final b in data.braindumps) {
      if (b.completed || b.reminderAt == null) continue;
      final dt = DateTime.tryParse(b.reminderAt!);
      if (dt == null || !dt.isAfter(DateTime.now())) continue;
      await _plugin.zonedSchedule(
        id: 1000 + id++,
        title: 'Reminder',
        body: b.text,
        scheduledDate: tz.TZDateTime.from(dt, tz.local),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }

    // Daily review: one repeating reminder at the configured time, unless it
    // falls inside quiet hours.
    final review = data.profile.dailyReviewTime.split(':');
    final rh = int.tryParse(review.isNotEmpty ? review[0] : '21') ?? 21;
    final rm = int.tryParse(review.length > 1 ? review[1] : '0') ?? 0;
    if (!_inQuietHours(rh * 60 + rm, notif.quietStart, notif.quietEnd)) {
      await _plugin.zonedSchedule(
        id: 9000,
        title: 'Daily review',
        body: 'Take a minute to review your day',
        scheduledDate: _nextDaily(rh, rm),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  } catch (e) {
    // No notification platform available — ignore, but log.
    debugPrint('Notifications.reschedule failed: $e');
  }
}
