import 'package:flutter/material.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_card.dart';
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
      title: 'Blood Pressure Log',
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
      title: 'Evening Pulse & SpO2 Record',
      time: '08:00 PM',
      icon: Icons.alarm,
      isCompleted: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final list = reminders ?? _defaultReminders;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Today\'s Reminders',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              if (onManageReminders != null)
                TextButton(
                  onPressed: onManageReminders,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                  child: const Text('Manage', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          ...list.map((r) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
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
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: reminder.isCompleted
            ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))
            : (isDark ? const Color(0xFF16203B) : Colors.white),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Icon(
            reminder.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 20,
            color: reminder.isCompleted ? AppColors.secondary : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              reminder.title,
              style: context.textTheme.bodyMedium?.copyWith(
                decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
                color: reminder.isCompleted
                    ? (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))
                    : (isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A)),
                fontWeight: reminder.isCompleted ? FontWeight.w400 : FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              reminder.time,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
