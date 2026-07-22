import 'package:flutter/material.dart';
import '../../../../core/extensions/build_context_ext.dart';

class VitalMetricSelector extends StatelessWidget {
  final String activeTab;
  final ValueChanged<String> onSelectTab;

  const VitalMetricSelector({
    super.key,
    required this.activeTab,
    required this.onSelectTab,
  });

  static const _chips = [
    {'id': 'bp', 'label': 'Blood Pressure', 'icon': Icons.favorite_outline},
    {'id': 'glucose', 'label': 'Glucose', 'icon': Icons.opacity},
    {'id': 'pulse', 'label': 'Pulse Rate', 'icon': Icons.heart_broken_outlined},
    {'id': 'temp', 'label': 'Temperature', 'icon': Icons.thermostat_outlined},
    {'id': 'weight', 'label': 'Weight', 'icon': Icons.scale_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _chips.map((chip) {
          final id = chip['id'] as String;
          final isSelected = activeTab == id;
          return Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: ChoiceChip(
              avatar: Icon(
                chip['icon'] as IconData,
                color: isSelected ? Colors.white : context.colorScheme.primary,
                size: 18,
              ),
              label: Text(
                chip['label'] as String,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : context.colorScheme.onSurface,
                ),
              ),
              selected: isSelected,
              selectedColor: context.colorScheme.primary,
              backgroundColor: context.theme.brightness == Brightness.light
                  ? Colors.grey.withValues(alpha: 0.08)
                  : context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? context.colorScheme.primary : Colors.transparent,
                  width: 1,
                ),
              ),
              showCheckmark: false,
              onSelected: (val) {
                if (val) onSelectTab(id);
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
