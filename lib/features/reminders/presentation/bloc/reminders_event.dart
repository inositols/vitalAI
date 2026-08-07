import 'package:equatable/equatable.dart';
import '../../data/models/reminder_model.dart';

abstract class RemindersEvent extends Equatable {
  const RemindersEvent();

  @override
  List<Object?> get props => [];
}

class RemindersListRequested extends RemindersEvent {
  final int patientId;

  const RemindersListRequested(this.patientId);

  @override
  List<Object?> get props => [patientId];
}

class ReminderAdded extends RemindersEvent {
  final ReminderModel reminder;

  const ReminderAdded(this.reminder);

  @override
  List<Object?> get props => [reminder];
}

class ReminderUpdated extends RemindersEvent {
  final ReminderModel reminder;

  const ReminderUpdated(this.reminder);

  @override
  List<Object?> get props => [reminder];
}

class ReminderDeleted extends RemindersEvent {
  final String id;
  final int patientId;

  const ReminderDeleted({required this.id, required this.patientId});

  @override
  List<Object?> get props => [id, patientId];
}

class ReminderCompletionToggled extends RemindersEvent {
  final String id;
  final int patientId;

  const ReminderCompletionToggled({required this.id, required this.patientId});

  @override
  List<Object?> get props => [id, patientId];
}
