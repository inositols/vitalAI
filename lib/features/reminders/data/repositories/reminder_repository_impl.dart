import '../../../../core/database/db_service.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../data/models/reminder_model.dart';
import '../../domain/repositories/reminder_repository.dart';

class ReminderRepositoryImpl implements ReminderRepository {
  final DbService dbService;
  final NotificationService notificationService;

  ReminderRepositoryImpl({
    required this.dbService,
    required this.notificationService,
  });

  static List<ReminderModel> _getDefaultReminders(int patientId) => [
        ReminderModel(
          id: 'def_1',
          patientId: patientId,
          title: 'Blood Pressure Log',
          time: '09:00 AM',
          hour: 9,
          minute: 0,
          isCompleted: true,
          isEnabled: true,
          createdAt: DateTime.now(),
        ),
        ReminderModel(
          id: 'def_2',
          patientId: patientId,
          title: 'Fasting Blood Glucose',
          time: '08:00 AM',
          hour: 8,
          minute: 0,
          isCompleted: true,
          isEnabled: true,
          createdAt: DateTime.now(),
        ),
        ReminderModel(
          id: 'def_3',
          patientId: patientId,
          title: 'Evening Pulse & SpO2 Record',
          time: '08:00 PM',
          hour: 20,
          minute: 0,
          isCompleted: false,
          isEnabled: true,
          createdAt: DateTime.now(),
        ),
      ];

  @override
  Future<List<ReminderModel>> getReminders(int patientId) async {
    final existing = await dbService.getReminders(patientId);
    if (existing.isEmpty) {
      final defaults = _getDefaultReminders(patientId);
      await dbService.saveReminders(patientId, defaults);
      _syncNotifications(defaults);
      return defaults;
    }
    _syncNotifications(existing);
    return existing;
  }

  @override
  Future<void> addReminder(ReminderModel reminder) async {
    final list = await dbService.getReminders(reminder.patientId);
    final updated = [...list, reminder];
    await dbService.saveReminders(reminder.patientId, updated);
    _syncSingleNotification(reminder);
  }

  @override
  Future<void> updateReminder(ReminderModel reminder) async {
    final list = await dbService.getReminders(reminder.patientId);
    final index = list.indexWhere((r) => r.id == reminder.id);
    if (index != -1) {
      list[index] = reminder;
      await dbService.saveReminders(reminder.patientId, list);
      _syncSingleNotification(reminder);
    }
  }

  @override
  Future<void> deleteReminder(String id, int patientId) async {
    final list = await dbService.getReminders(patientId);
    list.removeWhere((r) => r.id == id);
    await dbService.saveReminders(patientId, list);
    await notificationService.cancelNotification(id.hashCode);
  }

  @override
  Future<void> toggleReminderCompletion(String id, int patientId) async {
    final list = await dbService.getReminders(patientId);
    final index = list.indexWhere((r) => r.id == id);
    if (index != -1) {
      list[index] = list[index].copyWith(isCompleted: !list[index].isCompleted);
      await dbService.saveReminders(patientId, list);
    }
  }

  void _syncSingleNotification(ReminderModel reminder) {
    if (reminder.isEnabled && !reminder.isCompleted) {
      notificationService.scheduleDailyReminder(
        id: reminder.id.hashCode,
        title: 'Health Reminder',
        body: reminder.title,
        hour: reminder.hour,
        minute: reminder.minute,
      );
    } else {
      notificationService.cancelNotification(reminder.id.hashCode);
    }
  }

  void _syncNotifications(List<ReminderModel> reminders) {
    for (var r in reminders) {
      _syncSingleNotification(r);
    }
  }
}
