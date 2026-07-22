import 'package:flutter/material.dart';
import '../../../../core/extensions/build_context_ext.dart';

class HistoryFilterBar extends StatelessWidget {
  final String? selectedVitalType;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool abnormalOnly;
  final ValueChanged<String?> onTypeChanged;
  final VoidCallback onSelectDateRange;
  final VoidCallback onClearDateRange;
  final ValueChanged<bool> onAbnormalChanged;

  const HistoryFilterBar({
    super.key,
    required this.selectedVitalType,
    required this.startDate,
    required this.endDate,
    required this.abnormalOnly,
    required this.onTypeChanged,
    required this.onSelectDateRange,
    required this.onClearDateRange,
    required this.onAbnormalChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: selectedVitalType,
                  decoration: const InputDecoration(
                    labelText: 'Vital Category',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Categories')),
                    DropdownMenuItem(value: 'bp', child: Text('Blood Pressure')),
                    DropdownMenuItem(value: 'glucose', child: Text('Glucose')),
                    DropdownMenuItem(value: 'pulse', child: Text('Pulse')),
                    DropdownMenuItem(value: 'spo2', child: Text('SpO₂')),
                    DropdownMenuItem(value: 'temp', child: Text('Temperature')),
                    DropdownMenuItem(value: 'weight', child: Text('Weight')),
                  ],
                  onChanged: onTypeChanged,
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: Text(
                  startDate != null
                      ? '${startDate!.month}/${startDate!.day} - ${endDate?.month}/${endDate?.day}'
                      : 'Date Range',
                ),
                selected: startDate != null,
                onSelected: (_) => startDate != null ? onClearDateRange() : onSelectDateRange(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Checkbox(
                value: abnormalOnly,
                onChanged: (val) => onAbnormalChanged(val ?? false),
              ),
              const Text('Show Out-of-Range Readings Only'),
            ],
          ),
        ],
      ),
    );
  }
}
