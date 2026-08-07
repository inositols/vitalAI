import 'package:equatable/equatable.dart';
import '../../data/models/reminder_model.dart';

abstract class RemindersState extends Equatable {
  const RemindersState();

  @override
  List<Object?> get props => [];
}

class RemindersInitial extends RemindersState {}

class RemindersLoading extends RemindersState {}

class RemindersLoadSuccess extends RemindersState {
  final List<ReminderModel> reminders;

  const RemindersLoadSuccess(this.reminders);

  @override
  List<Object?> get props => [reminders];
}

class RemindersFailure extends RemindersState {
  final String message;

  const RemindersFailure(this.message);

  @override
  List<Object?> get props => [message];
}
