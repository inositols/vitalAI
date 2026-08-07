import 'package:flutter/material.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_card.dart';

class CaregiverPermissionsCard extends StatelessWidget {
  final bool shareVitals;
  final bool shareInsights;
  final bool notifyOnCritical;
  final ValueChanged<bool> onShareVitalsChanged;
  final ValueChanged<bool> onShareInsightsChanged;
  final ValueChanged<bool> onNotifyOnCriticalChanged;

  const CaregiverPermissionsCard({
    super.key,
    required this.shareVitals,
    required this.shareInsights,
    required this.notifyOnCritical,
    required this.onShareVitalsChanged,
    required this.onShareInsightsChanged,
    required this.onNotifyOnCriticalChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          CheckboxListTile(
            activeColor: AppColors.primary,
            title: const Text('Share Vitals Logs', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            subtitle: Text(
              'Includes blood pressure, glucose, SpO2, and weight',
              style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
            value: shareVitals,
            onChanged: (val) => onShareVitalsChanged(val ?? false),
          ),
          Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          CheckboxListTile(
            activeColor: AppColors.primary,
            title: const Text('Share AI Insight Summaries', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            subtitle: Text(
              'Includes automated AI clinical observations & suggestions',
              style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
            value: shareInsights,
            onChanged: (val) => onShareInsightsChanged(val ?? false),
          ),
          Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          CheckboxListTile(
            activeColor: AppColors.error,
            title: const Text('Critical Vitals Emergency Alerts', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            subtitle: Text(
              'Sends instant notification alerts for abnormal readings',
              style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
            value: notifyOnCritical,
            onChanged: (val) => onNotifyOnCriticalChanged(val ?? false),
          ),
        ],
      ),
    );
  }
}
