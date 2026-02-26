import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tap logic here
      },
    );
  }

  Future<void> requestPermissions() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_channel_id',
          'Task Reminders',
          channelDescription: 'Notifications for task reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents:
          matchDateTimeComponents ?? DateTimeComponents.dateAndTime,
    );
  }

  Future<void> scheduleIntervalNotifications({
    required int baseId,
    required String title,
    required String body,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required int count,
  }) async {
    final now = DateTime.now();
    var startDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      startTime.hour,
      startTime.minute,
    );
    var endDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      endTime.hour,
      endTime.minute,
    );

    // If end is before start, assume next day? For water tracking usually same day.
    // We will assume same day for 'Water' feature.

    final totalDurationMinutes = endDateTime
        .difference(startDateTime)
        .inMinutes;
    if (totalDurationMinutes <= 0 || count <= 1) return;

    final intervalMinutes = totalDurationMinutes / (count - 1);

    for (int i = 0; i < count; i++) {
      final notificationTime = startDateTime.add(
        Duration(minutes: (intervalMinutes * i).round()),
      );

      // If time passed, schedule for tomorrow?
      // For now, allow today. If passed, it initiates immediately or errors?
      // zonedSchedule allows past times? No, usually throws ArgumentError.

      var actualScheduledTime = notificationTime;
      if (actualScheduledTime.isBefore(now)) {
        actualScheduledTime = actualScheduledTime.add(const Duration(days: 1));
      }

      // Use unique IDs: baseId * 100 + i
      // This limits us to 100 sub-notifications per task. Reasonable.
      await scheduleNotification(
        id: (baseId * 100) + i,
        title: '$title (${i + 1}/$count)',
        body: body,
        scheduledDate: actualScheduledTime,
        matchDateTimeComponents:
            DateTimeComponents.time, // Repeat daily at this time
      );
    }
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
