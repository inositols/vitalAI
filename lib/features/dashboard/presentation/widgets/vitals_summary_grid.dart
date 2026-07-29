import 'package:flutter/material.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_card.dart';

class VitalsSummaryGrid extends StatelessWidget {
  final Map<String, String> latestVitals;
  final VoidCallback? onAddVital;

  const VitalsSummaryGrid({
    super.key,
    required this.latestVitals,
    this.onAddVital,
  });

  @override
  Widget build(BuildContext context) {
    final bp = latestVitals['bp'] ?? '120/80 mmHg';
    final glucose = latestVitals['glucose'] ?? '95 mg/dL';
    final pulse = latestVitals['pulse'] ?? '72 bpm';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.favorite_outline_rounded, color: AppColors.bpVital, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Latest Health Vitals',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
            if (onAddVital != null)
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                label: const Text('Log Vital', style: TextStyle(fontWeight: FontWeight.w700)),
                onPressed: onAddVital,
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _VitalTile(
                icon: Icons.favorite_rounded,
                badgeColor: AppColors.bpVital,
                label: 'Blood Pressure',
                value: bp,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _VitalTile(
                icon: Icons.water_drop_rounded,
                badgeColor: AppColors.glucoseVital,
                label: 'Glucose',
                value: glucose,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _VitalTile(
                icon: Icons.monitor_heart_rounded,
                badgeColor: AppColors.pulseVital,
                label: 'Pulse Rate',
                value: pulse,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _VitalTile extends StatelessWidget {
  final IconData icon;
  final Color badgeColor;
  final String label;
  final String value;

  const _VitalTile({
    required this.icon,
    required this.badgeColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return AppCard(
      padding: const EdgeInsets.all(14),
      borderRadius: AppRadius.xl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: badgeColor, size: 18),
              ),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
