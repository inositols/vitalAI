import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Service that handles app-wide local notifications and adaptive alert logic.
class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initialize notification settings and timezones.
  Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Callback when a notification is tapped.
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint("Notification tapped with payload: ${response.payload}");
  }

  /// Request permissions dynamically for Android 13+ and iOS.
  Future<bool> requestPermissions() async {
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final androidGranted = await androidImplementation?.requestNotificationsPermission();

    final iosImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    final iosGranted = await iosImplementation?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    return (androidGranted ?? false) || (iosGranted ?? false);
  }

  /// Display an immediate notification (e.g. for immediate vitals alert).
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'vitals_alerts_channel',
        'Vitals Alerts',
        channelDescription: 'High-priority notifications for critical readings',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notificationsPlugin.show(id, title, body, details, payload: payload);
  }

  /// Schedule a one-shot notification after a specified duration.
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required Duration delay,
    String? payload,
  }) async {
    final scheduledDate = tz.TZDateTime.now(tz.local).add(delay);

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'vitals_reminders_channel',
        'Vitals Reminders',
        channelDescription: 'Reminders for routine measurements',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// Schedule a recurring daily reminder at a specific hour and minute.
  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_reminders_channel',
        'Daily Reminders',
        channelDescription: 'Scheduled daily measurements and activities',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Cancel a specific notification.
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  /// Cancel all pending notifications.
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  // ==========================================
  // Adaptive Reminder Business Logic
  // ==========================================

  /// Check if the user wants another reminder in 30 minutes to recheck after resting.
  /// Scheduled automatically if a high blood pressure reading is captured.
  Future<void> scheduleBPRecheckReminder() async {
    await scheduleNotification(
      id: 9991,
      title: "Blood Pressure Recheck",
      body: "It has been 30 minutes since your elevated reading. Please rest for 5 minutes and check your blood pressure again.",
      delay: const Duration(minutes: 30),
      payload: "bp_recheck",
    );
  }

  /// Notify the user that BP has been consistently elevated over 3 readings.
  Future<void> notifyConsecutiveHighBP() async {
    await showNotification(
      id: 9992,
      title: "Consistently Elevated Blood Pressure",
      body: "Your blood pressure has been elevated over the last three readings. Please consider resting and contacting your healthcare provider.",
    );
  }

  /// Notify the user that glucose has remained elevated.
  Future<void> notifyConsecutiveHighGlucose() async {
    await showNotification(
      id: 9993,
      title: "Elevated Glucose Trend Detected",
      body: "Your blood glucose levels have been consistently high for several days. Review your food intake and consult your doctor.",
    );
  }

  /// Suggest reviewing medication schedule when confirmations are repeatedly missed.
  Future<void> notifyMissedMedicationsWarning() async {
    await showNotification(
      id: 9994,
      title: "Missed Medication Reminders",
      body: "You have missed multiple scheduled medication confirmations. Consider reviewing your schedule or speaking with your doctor.",
    );
  }
}
