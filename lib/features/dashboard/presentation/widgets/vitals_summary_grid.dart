import 'package:flutter/material.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_card.dart';
import 'vitals_status_badge.dart';

class VitalsSummaryGrid extends StatelessWidget {
  final Map<String, String> latestVitals;
  final VoidCallback? onAddVital;

  const VitalsSummaryGrid({
    super.key,
    required this.latestVitals,
    this.onAddVital,
  });

  VitalStatusLevel _getBpStatus(String value) {
    if (value.contains('/')) {
      final parts = value.split('/');
      final sys = int.tryParse(parts[0].replaceAll(RegExp(r'[^0-9]'), ''));
      final dia = int.tryParse(parts[1].replaceAll(RegExp(r'[^0-9]'), ''));
      if (sys != null && dia != null) {
        if (sys < 90 || dia < 60) return VitalStatusLevel.low;
        if (sys >= 130 || dia > 80) return VitalStatusLevel.high;
        if (sys > 120) return VitalStatusLevel.elevated;
        return VitalStatusLevel.normal;
      }
    }
    return VitalStatusLevel.normal;
  }

  VitalStatusLevel _getGlucoseStatus(String value) {
    final val = double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), ''));
    if (val != null) {
      if (val < 70) return VitalStatusLevel.low;
      if (val > 140) return VitalStatusLevel.high;
      if (val > 120) return VitalStatusLevel.elevated;
      return VitalStatusLevel.normal;
    }
    return VitalStatusLevel.normal;
  }

  VitalStatusLevel _getPulseStatus(String value) {
    final val = double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), ''));
    if (val != null) {
      if (val < 60) return VitalStatusLevel.low;
      if (val > 100) return VitalStatusLevel.high;
      return VitalStatusLevel.normal;
    }
    return VitalStatusLevel.normal;
  }

  @override
  Widget build(BuildContext context) {
    final bp = latestVitals['bp'];
    final glucose = latestVitals['glucose'];
    final pulse = latestVitals['pulse'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(AppIcons.vitals, color: AppColors.primary, size: 17),
            const SizedBox(width: 8),
            Text(
              'Latest Health Vitals',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _VitalTile(
                icon: AppIcons.bloodPressure,
                badgeColor: AppColors.bpVital,
                label: 'Blood Pressure',
                value: bp,
                normalRange: '≤ 120/80 mmHg',
                statusLevel: bp != null ? _getBpStatus(bp) : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _VitalTile(
                icon: AppIcons.glucose,
                badgeColor: AppColors.glucoseVital,
                label: 'Glucose',
                value: glucose,
                normalRange: '70–120 mg/dL',
                statusLevel: glucose != null ? _getGlucoseStatus(glucose) : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _VitalTile(
                icon: AppIcons.pulse,
                badgeColor: AppColors.pulseVital,
                label: 'Pulse Rate',
                value: pulse,
                normalRange: '60–100 bpm',
                statusLevel: pulse != null ? _getPulseStatus(pulse) : null,
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
  final String? value;
  final String normalRange;
  final VitalStatusLevel? statusLevel;

  const _VitalTile({
    required this.icon,
    required this.badgeColor,
    required this.label,
    required this.value,
    required this.normalRange,
    required this.statusLevel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final hasData = value != null && value!.isNotEmpty;

    return AppCard(
      padding: const EdgeInsets.all(12),
      borderRadius: AppRadius.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: badgeColor, size: 16),
              const SizedBox(width: 4),
              if (hasData && statusLevel != null)
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: VitalsStatusBadge(level: statusLevel!),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04)),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    'No Data',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
              fontSize: 10.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            hasData ? value! : '--',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: hasData
                  ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                  : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Normal: $normalRange',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}
