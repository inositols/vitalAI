import 'package:flutter/material.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../../../../core/theme/design_tokens.dart';

class DashboardQuickActions extends StatelessWidget {
  final VoidCallback onLogVitals;
  final VoidCallback onAskAi;
  final VoidCallback onViewCharts;
  final VoidCallback onViewHistory;

  const DashboardQuickActions({
    super.key,
    required this.onLogVitals,
    required this.onAskAi,
    required this.onViewCharts,
    required this.onViewHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ActionPill(
                icon: AppIcons.add,
                label: 'Log Vitals',
                onTap: onLogVitals,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionPill(
                icon: AppIcons.aiAssistant,
                label: 'Ask AI',
                onTap: onAskAi,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionPill(
                icon: AppIcons.chart,
                label: 'Analytics',
                onTap: onViewCharts,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionPill(
                icon: AppIcons.history,
                label: 'History',
                onTap: onViewHistory,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Material(
      color: isDark ? AppColors.darkCard : const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
              width: 0.8,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: context.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 10.5,
                  color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
