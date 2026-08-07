import '../../data/models/reminder_model.dart';

abstract class ReminderRepository {
  Future<List<ReminderModel>> getReminders(int patientId);
  Future<void> addReminder(ReminderModel reminder);
  Future<void> updateReminder(ReminderModel reminder);
  Future<void> deleteReminder(String id, int patientId);
  Future<void> toggleReminderCompletion(String id, int patientId);
}
