import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/build_context_ext.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../reminders/data/models/reminder_model.dart';
import '../../../reminders/presentation/bloc/reminders_bloc.dart';
import '../../../reminders/presentation/bloc/reminders_event.dart';
import '../../../reminders/presentation/bloc/reminders_state.dart';

class TodayRemindersCard extends StatelessWidget {
  final VoidCallback? onManageReminders;

  const TodayRemindersCard({
    super.key,
    this.onManageReminders,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      borderRadius: AppRadius.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    AppIcons.reminder,
                    size: 17,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Today\'s Reminders',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              if (onManageReminders != null)
                GestureDetector(
                  onTap: onManageReminders,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Manage',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          AppIcons.chevronRight,
                          size: 13,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          BlocBuilder<RemindersBloc, RemindersState>(
            builder: (context, state) {
              if (state is RemindersLoading) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Center(child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))),
                );
              }

              final list = state is RemindersLoadSuccess ? state.reminders : <ReminderModel>[];

              if (list.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'No active reminders for today',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey),
                      ),
                      if (onManageReminders != null)
                        TextButton(
                          onPressed: onManageReminders,
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 28)),
                          child: const Text('+ Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                );
              }

              return Column(
                children: list.map((r) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: _ReminderTile(reminder: r),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  final ReminderModel reminder;

  const _ReminderTile({required this.reminder});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return InkWell(
      onTap: () {
        context.read<RemindersBloc>().add(
              ReminderCompletionToggled(
                id: reminder.id,
                patientId: reminder.patientId,
              ),
            );
      },
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: reminder.isCompleted
              ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC))
              : (isDark ? const Color(0xFF16203B) : Colors.white),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isDark ? const Color(0xFF2A365C) : const Color(0xFFE2E8F0),
            width: 0.6,
          ),
        ),
        child: Row(
          children: [
            Icon(
              reminder.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: 18,
              color: reminder.isCompleted ? AppColors.secondary : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
            ),
            const SizedBox(width: 10),
            Expanded(
            child: Text(
              reminder.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodyMedium?.copyWith(
                decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
                color: reminder.isCompleted
                    ? (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))
                    : (isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A)),
                fontWeight: reminder.isCompleted ? FontWeight.w400 : FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ),
          Text(
            reminder.time,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    ),
  );
}
}
