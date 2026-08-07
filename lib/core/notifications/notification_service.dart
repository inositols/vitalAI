import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:vitalai/core/routing/router.dart';
import 'in_app_notification_banner.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    if (kIsWeb) return;

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
    await requestPermissions();
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint("Notification tapped with payload: ${response.payload}");
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return true;
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final androidGranted = await androidImplementation
        ?.requestNotificationsPermission();

    final iosImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final iosGranted = await iosImplementation?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    return (androidGranted ?? false) || (iosGranted ?? false);
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) {
      _showInAppNotification(title, body);
      return;
    }
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'vitals_alerts_channel',
        'Vitals Alerts',
        channelDescription: 'High-priority notifications for critical readings',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        largeIcon: DrawableResourceAndroidBitmap('ic_launcher'),
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notificationsPlugin.show(id, title, body, details, payload: payload);
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required Duration delay,
    String? payload,
  }) async {
    if (kIsWeb) {
      Future.delayed(delay, () {
        _showInAppNotification(title, body);
      });
      return;
    }
    final scheduledDate = tz.TZDateTime.now(tz.local).add(delay);

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'vitals_reminders_channel',
        'Vitals Reminders',
        channelDescription: 'Reminders for routine measurements',
        importance: Importance.high,
        priority: Priority.high,
        largeIcon: DrawableResourceAndroidBitmap('ic_launcher'),
      ),
      iOS: DarwinNotificationDetails(),
    );

    try {
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
    } catch (_) {
      try {
        await _notificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
      } catch (_) {}
    }
  }

  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    if (kIsWeb) return;
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
        largeIcon: DrawableResourceAndroidBitmap('ic_launcher'),
      ),
      iOS: DarwinNotificationDetails(),
    );

    try {
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
    } catch (_) {}
  }

  Future<void> cancelNotification(int id) async {
    if (kIsWeb) return;
    await _notificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    if (kIsWeb) return;
    await _notificationsPlugin.cancelAll();
  }

  Future<void> scheduleBPRecheckReminder() async {
    await scheduleNotification(
      id: 9991,
      title: "Blood Pressure Recheck",
      body: "It has been 30 minutes since your elevated reading. Please rest for 5 minutes and check your blood pressure again.",
      delay: const Duration(minutes: 30),
      payload: "bp_recheck",
    );
  }

  Future<void> notifyConsecutiveHighBP() async {
    await showNotification(
      id: 9992,
      title: "Consistently Elevated Blood Pressure",
      body: "Your blood pressure has been elevated over the last three readings. Please consider resting and contacting your healthcare provider.",
    );
  }

  Future<void> notifyConsecutiveHighGlucose() async {
    await showNotification(
      id: 9993,
      title: "Elevated Glucose Trend Detected",
      body: "Your blood glucose levels have been consistently high for several days. Review your food intake and consult your doctor.",
    );
  }

  Future<void> notifyMissedMedicationsWarning() async {
    await showNotification(
      id: 9994,
      title: "Missed Medication Reminders",
      body: "You have missed multiple scheduled medication confirmations. Consider reviewing your schedule or speaking with your doctor.",
    );
  }

  void _showInAppNotification(String title, String body) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Notification',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.topCenter,
          child: InAppNotificationBanner(title: title, body: body),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final slide = Tween<Offset>(
          begin: const Offset(0, -1.2),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutBack));

        return SlideTransition(position: slide, child: child);
      },
    );
  }
}
