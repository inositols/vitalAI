import 'package:flutter/material.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_card.dart';

class VitalsSummaryGrid extends StatelessWidget {
  final Map<String, String> latestVitals;
  final VoidCallback? onAddVital;
  final Function(String metricType)? onMetricTap;

  const VitalsSummaryGrid({
    super.key,
    required this.latestVitals,
    this.onAddVital,
    this.onMetricTap,
  });

  String _getBpStatus(String value) {
    if (value.contains('/')) {
      final parts = value.split('/');
      final sys = int.tryParse(parts[0].replaceAll(RegExp(r'[^0-9]'), ''));
      final dia = int.tryParse(parts[1].replaceAll(RegExp(r'[^0-9]'), ''));
      if (sys != null && dia != null) {
        if (sys >= 130 || dia >= 80) return 'Elevated';
        if (sys >= 120 && dia < 80) return 'Pre-high';
        return 'Normal';
      }
    }
    return 'Normal';
  }

  String _getGlucoseStatus(String value) {
    final val = double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), ''));
    if (val != null) {
      if (val > 120) return 'Elevated';
      return 'Normal';
    }
    return 'Normal';
  }

  @override
  Widget build(BuildContext context) {
    final bp = latestVitals['bp'];
    final glucose = latestVitals['glucose'];
    final pulse = latestVitals['pulse'];
    final spo2 = latestVitals['spo2'] ?? '98';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Favorites',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 10),

        // Row 1: Blood Pressure & Heart Rate
        Row(
          children: [
            Expanded(
              child: _AppleHealthTile(
                icon: Icons.favorite_rounded,
                iconColor: AppColors.bpVital,
                title: 'Blood Pressure',
                value: bp != null ? bp.replaceAll(' mmHg', '') : '--/--',
                unit: 'mmHg',
                subtitle: bp != null ? _getBpStatus(bp) : 'No data',
                statusColor: (bp != null && _getBpStatus(bp) == 'Normal')
                    ? AppColors.secondary
                    : AppColors.warning,
                onTap: () => onMetricTap?.call('bp'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _AppleHealthTile(
                icon: Icons.monitor_heart_rounded,
                iconColor: AppColors.pulseVital,
                title: 'Heart Rate',
                value: pulse != null ? pulse.replaceAll(' bpm', '') : '--',
                unit: 'BPM',
                subtitle: pulse != null ? 'Resting' : 'No data',
                statusColor: AppColors.secondary,
                onTap: () => onMetricTap?.call('pulse'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Row 2: Blood Glucose & Oxygen
        Row(
          children: [
            Expanded(
              child: _AppleHealthTile(
                icon: Icons.water_drop_rounded,
                iconColor: AppColors.glucoseVital,
                title: 'Blood Glucose',
                value: glucose != null ? glucose.replaceAll(' mg/dL', '') : '--',
                unit: 'mg/dL',
                subtitle: glucose != null ? 'Fasting' : 'No data',
                statusColor: (glucose != null && _getGlucoseStatus(glucose) == 'Normal')
                    ? AppColors.secondary
                    : AppColors.warning,
                onTap: () => onMetricTap?.call('glucose'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _AppleHealthTile(
                icon: Icons.air_rounded,
                iconColor: AppColors.spo2Vital,
                title: 'Oxygen (SpO₂)',
                value: spo2,
                unit: '%',
                subtitle: 'Optimal',
                statusColor: AppColors.secondary,
                onTap: () => onMetricTap?.call('spo2'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AppleHealthTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String unit;
  final String subtitle;
  final Color statusColor;
  final VoidCallback? onTap;

  const _AppleHealthTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.unit,
    required this.subtitle,
    required this.statusColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final hasData = value != '--' && value != '--/--';

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      borderRadius: AppRadius.xl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                  color: hasData
                      ? (isDark ? Colors.white : const Color(0xFF0F172A))
                      : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                ),
              ),
              if (hasData && unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: hasData ? statusColor : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
