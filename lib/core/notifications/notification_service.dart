import 'dart:async';
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

  final Map<int, Timer> _activeTimers = {};
  final Set<String> _firedRemindersToday = {};
  Timer? _heartbeatTimer;

  Future<void> init() async {
    try {
      tz.initializeTimeZones();
    } catch (_) {}

    _startHeartbeat();

    if (kIsWeb) return;

    if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
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

      try {
        await _notificationsPlugin.initialize(
          initSettings,
          onDidReceiveNotificationResponse: _onNotificationTapped,
        );
        await requestPermissions();
      } catch (e) {
        debugPrint("LocalNotifications init error: $e");
      }
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      final now = DateTime.now();
      // Clean fired cache after midnight
      if (now.hour == 0 && now.minute == 0) {
        _firedRemindersToday.clear();
      }
    });
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint("Notification tapped with payload: ${response.payload}");
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return true;
    if (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS) {
      return true;
    }

    try {
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
    } catch (_) {
      return true;
    }
  }

  /// Show an immediate alert notification (both in-app banner and system alert).
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    _showInAppNotification(title, body);

    if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS)) {
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

    try {
      await _notificationsPlugin.show(id, title, body, details, payload: payload);
    } catch (_) {}
  }

  /// Schedule a one-shot notification after [delay].
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required Duration delay,
    String? payload,
  }) async {
    _activeTimers[id]?.cancel();
    _activeTimers[id] = Timer(delay, () {
      showNotification(id: id, title: title, body: body, payload: payload);
    });

    if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS)) {
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
    } catch (_) {}
  }

  /// Schedule a daily recurring reminder for a specific time of day (works on Windows, Mac, Linux, Web, Android, iOS).
  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    // 1. Calculate time until next trigger
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    final delay = scheduled.difference(now);

    // 2. Set accurate in-app / desktop timer
    _activeTimers[id]?.cancel();
    _activeTimers[id] = Timer(delay, () {
      showNotification(id: id, title: title, body: body);
      // Re-schedule for next day
      scheduleDailyReminder(id: id, title: title, body: body, hour: hour, minute: minute);
    });

    // 3. Mobile native notification registration
    if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }

    final tzNow = tz.TZDateTime.now(tz.local);
    var tzScheduled = tz.TZDateTime(
      tz.local,
      tzNow.year,
      tzNow.month,
      tzNow.day,
      hour,
      minute,
    );
    if (tzScheduled.isBefore(tzNow)) {
      tzScheduled = tzScheduled.add(const Duration(days: 1));
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
        tzScheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {}
  }

  Future<void> cancelNotification(int id) async {
    _activeTimers[id]?.cancel();
    _activeTimers.remove(id);

    if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }
    try {
      await _notificationsPlugin.cancel(id);
    } catch (_) {}
  }

  Future<void> cancelAllNotifications() async {
    for (var timer in _activeTimers.values) {
      timer.cancel();
    }
    _activeTimers.clear();

    if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }
    try {
      await _notificationsPlugin.cancelAll();
    } catch (_) {}
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
