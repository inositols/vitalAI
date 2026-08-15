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

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  void _loadReminders() {
    final patientState = context.read<PatientBloc>().state;
    final patientId = patientState is PatientLoadSuccess && patientState.activePatient != null
        ? patientState.activePatient!.id
        : 1;
    context.read<RemindersBloc>().add(RemindersListRequested(patientId));
  }

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
        : 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Reminders', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: 'Test Alert Banner',
            onPressed: () {
              locator<NotificationService>().showNotification(
                id: DateTime.now().millisecond,
                title: 'Health Reminder Test',
                body: 'Your VitalAI reminder alerts are configured and active!',
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
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.notifications_none_rounded, size: 48, color: AppColors.primary),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No Reminders Scheduled',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Set daily notifications for blood pressure checks, fasting glucose, or medications.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => _openAddSheet(context, patientId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
                        ),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add Reminder', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
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
