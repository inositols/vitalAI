import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/reminder_repository.dart';
import 'reminders_event.dart';
import 'reminders_state.dart';

class RemindersBloc extends Bloc<RemindersEvent, RemindersState> {
  final ReminderRepository repository;

  RemindersBloc({required this.repository}) : super(RemindersInitial()) {
    on<RemindersListRequested>(_onListRequested);
    on<ReminderAdded>(_onAdded);
    on<ReminderUpdated>(_onUpdated);
    on<ReminderDeleted>(_onDeleted);
    on<ReminderCompletionToggled>(_onCompletionToggled);
  }

  Future<void> _onListRequested(
    RemindersListRequested event,
    Emitter<RemindersState> emit,
  ) async {
    emit(RemindersLoading());
    try {
      final list = await repository.getReminders(event.patientId);
      emit(RemindersLoadSuccess(list));
    } catch (e) {
      emit(RemindersFailure('Failed to load reminders: ${e.toString()}'));
    }
  }

  Future<void> _onAdded(
    ReminderAdded event,
    Emitter<RemindersState> emit,
  ) async {
    try {
      await repository.addReminder(event.reminder);
      final list = await repository.getReminders(event.reminder.patientId);
      emit(RemindersLoadSuccess(list));
    } catch (e) {
      emit(RemindersFailure('Failed to add reminder: ${e.toString()}'));
    }
  }

  Future<void> _onUpdated(
    ReminderUpdated event,
    Emitter<RemindersState> emit,
  ) async {
    try {
      await repository.updateReminder(event.reminder);
      final list = await repository.getReminders(event.reminder.patientId);
      emit(RemindersLoadSuccess(list));
    } catch (e) {
      emit(RemindersFailure('Failed to update reminder: ${e.toString()}'));
    }
  }

  Future<void> _onDeleted(
    ReminderDeleted event,
    Emitter<RemindersState> emit,
  ) async {
    try {
      await repository.deleteReminder(event.id, event.patientId);
      final list = await repository.getReminders(event.patientId);
      emit(RemindersLoadSuccess(list));
    } catch (e) {
      emit(RemindersFailure('Failed to delete reminder: ${e.toString()}'));
    }
  }

  Future<void> _onCompletionToggled(
    ReminderCompletionToggled event,
    Emitter<RemindersState> emit,
  ) async {
    try {
      await repository.toggleReminderCompletion(event.id, event.patientId);
      final list = await repository.getReminders(event.patientId);
      emit(RemindersLoadSuccess(list));
    } catch (e) {
      emit(RemindersFailure('Failed to toggle reminder: ${e.toString()}'));
    }
  }
}
