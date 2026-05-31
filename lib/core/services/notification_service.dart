import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io';
import 'dart:ui' as ui;

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    // Android Init
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS Init
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _notificationsPlugin.initialize(initializationSettings);

    if (Platform.isAndroid) {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      await androidImplementation?.requestNotificationsPermission();

      // Create channels explicitly to ensure they exist with correct settings
      await androidImplementation?.createNotificationChannel(
        const AndroidNotificationChannel(
          'daily_reminders',
          'Daily Reminders',
          description: 'Reminds you to check in daily',
          importance: Importance.max,
        ),
      );

      await androidImplementation?.createNotificationChannel(
        const AndroidNotificationChannel(
          'emergency_alerts',
          'Emergency Alerts',
          description: 'Critical alerts when check-in is overdue',
          importance: Importance.max,
          playSound: true,
        ),
      );

      await androidImplementation?.createNotificationChannel(
        const AndroidNotificationChannel(
          'check_in_reminders',
          'Check-in Reminders',
          description: 'Reminders before check-in is overdue',
          importance: Importance.high,
        ),
      );
    }
  }

  Future<void> scheduleDailyCheckInReminder() async {
    await _notificationsPlugin.zonedSchedule(
      0,
      'Check-in Reminder',
      'Please open the app to confirm you are okay.',
      _nextInstanceOfNineAM(),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminders',
          'Daily Reminders',
          channelDescription: 'Reminds you to check in daily',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleOverdueNotification(Duration delay) async {
    // ID 1 for Overdue Alert
    // We schedule it 'delay' from now.
    final scheduledDate = tz.TZDateTime.now(tz.local).add(delay);

    await _notificationsPlugin.zonedSchedule(
      1,
      '⚠️ ALERT: Check-in Overdue',
      'You have missed your check-in time. Emergency contacts will be notified soon if you do not respond.',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'emergency_alerts',
          'Emergency Alerts',
          channelDescription: 'Critical alerts when check-in is overdue',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
          color: ui.Color(0xFFFF0000),
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentSound: true,
          presentAlert: true,
          presentBanner: true,
          interruptionLevel:
              InterruptionLevel.timeSensitive, // Standard high priority
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> schedulePreDueNotification(Duration durationUntilDue) async {
    // Calculate when to show the pre-due alert: 1h 10m before due time
    final delay = durationUntilDue - const Duration(hours: 1, minutes: 10);

    if (delay.isNegative) {
      // Less than 1h 10m remaining or already passed logic (though durationUntilDue means future).
      // If we are checkin in, durationUntilDue is typically 'frequency' (e.g. 24h).
      // So delay will be 22h 50m.
      return;
    }

    final scheduledDate = tz.TZDateTime.now(tz.local).add(delay);

    await _notificationsPlugin.zonedSchedule(
      2, // ID 2 for Pre-Due Alert
      'Upcoming Check-in Required',
      'Please check in soon. You have 1 hour 10 minutes remaining.',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'check_in_reminders',
          'Check-in Reminders',
          channelDescription: 'Reminders before check-in is overdue',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  tz.TZDateTime _nextInstanceOfNineAM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      9,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
