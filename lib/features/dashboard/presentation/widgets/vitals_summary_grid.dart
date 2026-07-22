import 'package:flutter/material.dart';
import '../../../../core/extensions/build_context_ext.dart';

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
            Text(
              'Latest Health Vitals',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (onAddVital != null)
              TextButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Log Vital'),
                onPressed: onAddVital,
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _VitalTile(
                icon: Icons.favorite,
                iconColor: Colors.redAccent,
                label: 'Blood Pressure',
                value: bp,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _VitalTile(
                icon: Icons.water_drop,
                iconColor: Colors.orangeAccent,
                label: 'Glucose',
                value: glucose,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _VitalTile(
                icon: Icons.monitor_heart,
                iconColor: Colors.purpleAccent,
                label: 'Pulse',
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
  final Color iconColor;
  final String label;
  final String value;

  const _VitalTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: iconColor.withValues(alpha: 0.15),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
