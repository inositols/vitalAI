import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:vitalai/core/routing/router.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    if (kIsWeb) return;

    const androidSettings = AndroidInitializationSettings('app_icon');
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

  /// Display an immediate notification (e.g. for immediate vitals alert).
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    debugPrint(
      "NotificationService: showNotification called (id: $id, title: $title, body: $body)",
    );
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
        largeIcon: DrawableResourceAndroidBitmap('app_icon'),
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
      debugPrint(
        "Simulated scheduled notification: $title - $body after delay $delay",
      );
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
        largeIcon: DrawableResourceAndroidBitmap('app_icon'),
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
    } catch (e) {
      debugPrint("Failed to schedule exact alarm: $e");
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
      } catch (ex) {
        debugPrint("Failed to schedule inexact alarm fallback: $ex");
      }
    }
  }

  /// Schedule a recurring daily reminder at a specific hour and minute.
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
        largeIcon: DrawableResourceAndroidBitmap('app_icon'),
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
    } catch (e) {
      debugPrint("Failed to schedule daily exact alarm: $e");
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
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (ex) {
        debugPrint("Failed to schedule daily inexact alarm fallback: $ex");
      }
    }
  }

  /// Cancel a specific notification.
  Future<void> cancelNotification(int id) async {
    if (kIsWeb) return;
    await _notificationsPlugin.cancel(id);
  }

  /// Cancel all pending notifications.
  Future<void> cancelAllNotifications() async {
    if (kIsWeb) return;
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
      body:
          "It has been 30 minutes since your elevated reading. Please rest for 5 minutes and check your blood pressure again.",
      delay: const Duration(minutes: 30),
      payload: "bp_recheck",
    );
  }

  /// Notify the user that BP has been consistently elevated over 3 readings.
  Future<void> notifyConsecutiveHighBP() async {
    await showNotification(
      id: 9992,
      title: "Consistently Elevated Blood Pressure",
      body:
          "Your blood pressure has been elevated over the last three readings. Please consider resting and contacting your healthcare provider.",
    );
  }

  /// Notify the user that glucose has remained elevated.
  Future<void> notifyConsecutiveHighGlucose() async {
    await showNotification(
      id: 9993,
      title: "Elevated Glucose Trend Detected",
      body:
          "Your blood glucose levels have been consistently high for several days. Review your food intake and consult your doctor.",
    );
  }

  /// Suggest reviewing medication schedule when confirmations are repeatedly missed.
  Future<void> notifyMissedMedicationsWarning() async {
    await showNotification(
      id: 9994,
      title: "Missed Medication Reminders",
      body:
          "You have missed multiple scheduled medication confirmations. Consider reviewing your schedule or speaking with your doctor.",
    );
  }

  void _showInAppNotification(String title, String body) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) {
      debugPrint(
        "Could not show in-app notification: Navigator context is null.",
      );
      return;
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Notification',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.topCenter,
          child: _InAppNotificationBanner(title: title, body: body),
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

class _InAppNotificationBanner extends StatefulWidget {
  final String title;
  final String body;

  const _InAppNotificationBanner({required this.title, required this.body});

  @override
  State<_InAppNotificationBanner> createState() =>
      _InAppNotificationBannerState();
}

class _InAppNotificationBannerState extends State<_InAppNotificationBanner> {
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && !_dismissed) {
        _dismissed = true;
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.light
                  ? Colors.white
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.tertiary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.body,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    if (!_dismissed) {
                      _dismissed = true;
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
