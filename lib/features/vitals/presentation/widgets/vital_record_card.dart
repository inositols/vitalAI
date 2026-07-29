import 'package:flutter/material.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_card.dart';
import '../../data/models/vital_record.dart';

class VitalRecordCard extends StatelessWidget {
  final VitalRecord record;
  final VoidCallback onDelete;

  const VitalRecordCard({
    super.key,
    required this.record,
    required this.onDelete,
  });

  List<Widget> _buildVitalBadges(BuildContext context) {
    final badges = <Widget>[];

    if (record.systolic != null && record.diastolic != null) {
      badges.add(_buildBadge(
        context,
        'BP: ${record.systolic!.toInt()}/${record.diastolic!.toInt()}',
        AppColors.bpVital,
        Icons.favorite_rounded,
      ));
    }
    if (record.glucoseValue != null) {
      badges.add(_buildBadge(
        context,
        'Glucose: ${record.glucoseValue!.toInt()} mg/dL',
        AppColors.glucoseVital,
        Icons.water_drop_rounded,
      ));
    }
    if (record.pulseRate != null) {
      badges.add(_buildBadge(
        context,
        'Pulse: ${record.pulseRate!.toInt()} bpm',
        AppColors.pulseVital,
        Icons.monitor_heart_rounded,
      ));
    }
    if (record.oxygenSaturation != null) {
      badges.add(_buildBadge(
        context,
        'SpO₂: ${record.oxygenSaturation!.toInt()}%',
        AppColors.spo2Vital,
        Icons.air_rounded,
      ));
    }
    if (record.bodyTemperature != null) {
      badges.add(_buildBadge(
        context,
        'Temp: ${record.bodyTemperature!.toStringAsFixed(1)}°C',
        AppColors.tempVital,
        Icons.thermostat_rounded,
      ));
    }
    if (record.weight != null) {
      badges.add(_buildBadge(
        context,
        'Weight: ${record.weight!.toStringAsFixed(1)}kg',
        AppColors.weightVital,
        Icons.scale_rounded,
      ));
    }

    return badges;
  }

  Widget _buildBadge(BuildContext context, String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final dt = record.dateTime;
    final formattedDate =
        '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} • ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    final badges = _buildVitalBadges(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: AppCard(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.health_and_safety_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (badges.isEmpty)
                    Text(
                      'Empty Log Entry',
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: badges,
                    ),
                  if (record.note != null && record.note!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Text(
                        'Note: ${record.note}',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
              tooltip: 'Delete entry',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
