import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/genui_component_model.dart';
import '../services/genui_action_handler.dart';
import '../../theme/design_tokens.dart';

class ReminderCardWidget extends StatelessWidget {
  final GenUiReminderCardModel model;

  const ReminderCardWidget({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1.2,
        ),
        boxShadow: AppShadows.subtle(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  AppIcons.reminder,
                  color: AppColors.secondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      model.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                    ),
                    if (model.dosage != null && model.dosage!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        model.dosage!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule_rounded, size: 13, color: AppColors.secondary),
                    const SizedBox(width: 4),
                    Text(
                      model.time,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Action row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildActionChip(
                context,
                icon: Icons.add_alarm_rounded,
                label: 'Save to Schedule',
                color: AppColors.secondary,
                onTap: () => GenUiActionHandler.quickSaveReminder(
                  context,
                  title: model.title,
                  timeStr: model.time,
                  dosage: model.dosage,
                ),
              ),
              _buildActionChip(
                context,
                icon: Icons.edit_calendar_rounded,
                label: 'Customize Time',
                color: AppColors.primary,
                onTap: () => GenUiActionHandler.setReminder(context, title: model.title),
              ),
              _buildActionChip(
                context,
                icon: Icons.format_list_bulleted_rounded,
                label: 'View Reminders',
                color: const Color(0xFF64748B),
                onTap: () => context.push('/reminders'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
