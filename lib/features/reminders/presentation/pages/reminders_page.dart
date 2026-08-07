import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../patients/presentation/bloc/patient_bloc.dart';
import '../../../patients/presentation/bloc/patient_state.dart';
import '../../data/models/reminder_model.dart';
import '../bloc/reminders_bloc.dart';
import '../bloc/reminders_event.dart';
import '../bloc/reminders_state.dart';
import '../widgets/add_reminder_sheet.dart';

class RemindersPage extends StatelessWidget {
  const RemindersPage({super.key});

  void _openAddSheet(BuildContext context, int patientId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => AddReminderSheet(patientId: patientId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final patientState = context.watch<PatientBloc>().state;
    final patientId = patientState is PatientLoadSuccess && patientState.activePatient != null
        ? patientState.activePatient!.id
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Reminders', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: 'Test Immediate Notification',
            onPressed: () {
              locator<NotificationService>().showNotification(
                id: DateTime.now().millisecond,
                title: 'Health Reminder Test',
                body: 'Your system health notifications are working perfectly!',
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<RemindersBloc, RemindersState>(
          builder: (context, state) {
            if (state is RemindersLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final list = state is RemindersLoadSuccess ? state.reminders : <ReminderModel>[];

            if (list.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.notifications_off_outlined, size: 56, color: AppColors.primary),
                    const SizedBox(height: 12),
                    const Text('No Health Reminders Set', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    const Text('Schedule daily vital checks or medication alerts'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _openAddSheet(context, patientId),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add First Reminder'),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...list.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: _ReminderItemTile(reminder: r, patientId: patientId),
                      )),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddSheet(context, patientId),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Reminder', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}

class _ReminderItemTile extends StatelessWidget {
  final ReminderModel reminder;
  final int patientId;

  const _ReminderItemTile({
    required this.reminder,
    required this.patientId,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: AppRadius.lg,
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              reminder.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: reminder.isCompleted ? AppColors.secondary : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
              size: 22,
            ),
            onPressed: () {
              context.read<RemindersBloc>().add(
                    ReminderCompletionToggled(id: reminder.id, patientId: patientId),
                  );
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: context.textTheme.bodyMedium?.copyWith(
                    decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
                    fontWeight: reminder.isCompleted ? FontWeight.w400 : FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Scheduled for ${reminder.time}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
            tooltip: 'Delete Reminder',
            onPressed: () {
              context.read<RemindersBloc>().add(
                    ReminderDeleted(id: reminder.id, patientId: patientId),
                  );
            },
          ),
        ],
      ),
    );
  }
}
