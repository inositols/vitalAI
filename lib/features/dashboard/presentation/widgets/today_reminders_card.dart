import 'package:flutter/material.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../../data/models/dashboard_reminder_model.dart';

class TodayRemindersCard extends StatelessWidget {
  final List<DashboardReminderModel>? reminders;
  final VoidCallback? onManageReminders;

  const TodayRemindersCard({
    super.key,
    this.reminders,
    this.onManageReminders,
  });

  static const _defaultReminders = [
    DashboardReminderModel(
      id: '1',
      title: 'Blood Pressure Check',
      time: '09:00 AM',
      icon: Icons.favorite,
      isCompleted: true,
    ),
    DashboardReminderModel(
      id: '2',
      title: 'Fasting Blood Glucose',
      time: '08:00 AM',
      icon: Icons.water_drop,
      isCompleted: true,
    ),
    DashboardReminderModel(
      id: '3',
      title: 'Evening Vital Record',
      time: '08:00 PM',
      icon: Icons.alarm,
      isCompleted: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final list = reminders ?? _defaultReminders;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.notifications_active_outlined,
                    size: 20,
                    color: context.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Today\'s Reminders',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (onManageReminders != null)
                TextButton(
                  onPressed: onManageReminders,
                  child: const Text('Manage'),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ...list.map((r) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _ReminderTile(reminder: r),
            );
          }),
        ],
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  final DashboardReminderModel reminder;

  const _ReminderTile({required this.reminder});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          reminder.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 18,
          color: reminder.isCompleted ? Colors.green : context.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            reminder.title,
            style: context.textTheme.bodyMedium?.copyWith(
              decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
              color: reminder.isCompleted
                  ? context.colorScheme.onSurfaceVariant
                  : context.colorScheme.onSurface,
            ),
          ),
        ),
        Text(
          reminder.time,
          style: context.textTheme.labelSmall?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
