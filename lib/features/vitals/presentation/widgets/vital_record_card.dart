import 'package:flutter/material.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../../../../core/theme/design_tokens.dart';
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
        Icons.favorite,
      ));
    }
    if (record.glucoseValue != null) {
      badges.add(_buildBadge(
        context,
        'Glucose: ${record.glucoseValue!.toInt()}',
        AppColors.glucoseVital,
        Icons.water_drop,
      ));
    }
    if (record.pulseRate != null) {
      badges.add(_buildBadge(
        context,
        'Pulse: ${record.pulseRate!.toInt()}',
        AppColors.pulseVital,
        Icons.monitor_heart,
      ));
    }
    if (record.oxygenSaturation != null) {
      badges.add(_buildBadge(
        context,
        'SpO₂: ${record.oxygenSaturation!.toInt()}%',
        AppColors.spo2Vital,
        Icons.air,
      ));
    }
    if (record.bodyTemperature != null) {
      badges.add(_buildBadge(
        context,
        'Temp: ${record.bodyTemperature!.toStringAsFixed(1)}°C',
        AppColors.tempVital,
        Icons.thermostat,
      ));
    }
    if (record.weight != null) {
      badges.add(_buildBadge(
        context,
        'Weight: ${record.weight!.toStringAsFixed(1)}kg',
        AppColors.weightVital,
        Icons.scale,
      ));
    }

    return badges;
  }

  Widget _buildBadge(BuildContext context, String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dt = record.dateTime;
    final formattedDate =
        '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    final badges = _buildVitalBadges(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: context.colorScheme.primaryContainer,
              child: Icon(
                Icons.analytics_outlined,
                color: context.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formattedDate,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (badges.isEmpty)
                    Text(
                      'Empty Log Entry',
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: badges,
                    ),
                  if (record.note != null && record.note!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Note: ${record.note}',
                      style: context.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
