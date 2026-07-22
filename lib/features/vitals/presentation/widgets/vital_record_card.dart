import 'package:flutter/material.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../../data/models/vital_record.dart';

class VitalRecordCard extends StatelessWidget {
  final VitalRecord record;
  final VoidCallback onDelete;

  const VitalRecordCard({
    super.key,
    required this.record,
    required this.onDelete,
  });

  String _formatVitalSummary() {
    final parts = <String>[];
    if (record.systolic != null && record.diastolic != null) {
      parts.add('BP: ${record.systolic!.toInt()}/${record.diastolic!.toInt()} mmHg');
    }
    if (record.glucoseValue != null) {
      parts.add('Glucose: ${record.glucoseValue!.toInt()} mg/dL (${record.glucoseMealContext ?? 'Fasting'})');
    }
    if (record.pulseRate != null) {
      parts.add('Pulse: ${record.pulseRate!.toInt()} bpm');
    }
    if (record.oxygenSaturation != null) {
      parts.add('SpO₂: ${record.oxygenSaturation!.toInt()}%');
    }
    if (record.bodyTemperature != null) {
      parts.add('Temp: ${record.bodyTemperature!.toStringAsFixed(1)}°C');
    }
    if (record.weight != null) {
      parts.add('Weight: ${record.weight!.toStringAsFixed(1)} kg');
    }
    return parts.isEmpty ? 'Logged Reading' : parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final dt = record.dateTime;
    final formattedDate = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: context.colorScheme.primaryContainer,
              child: Icon(
                Icons.favorite_border,
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
                    _formatVitalSummary(),
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
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
