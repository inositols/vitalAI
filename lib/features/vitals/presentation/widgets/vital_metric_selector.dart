import 'package:flutter/material.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../../../../core/theme/design_tokens.dart';

class VitalMetricSelector extends StatelessWidget {
  final String activeTab;
  final ValueChanged<String> onSelectTab;

  const VitalMetricSelector({
    super.key,
    required this.activeTab,
    required this.onSelectTab,
  });

  static const _chips = [
    {'id': 'bp', 'label': 'Blood Pressure', 'icon': AppIcons.bloodPressure, 'color': AppColors.bpVital},
    {'id': 'glucose', 'label': 'Glucose', 'icon': AppIcons.glucose, 'color': AppColors.glucoseVital},
    {'id': 'pulse', 'label': 'Pulse Rate', 'icon': AppIcons.pulse, 'color': AppColors.pulseVital},
    {'id': 'temp', 'label': 'Temperature', 'icon': AppIcons.temperature, 'color': AppColors.tempVital},
    {'id': 'weight', 'label': 'Weight', 'icon': AppIcons.weight, 'color': AppColors.weightVital},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _chips.map((chip) {
          final id = chip['id'] as String;
          final isSelected = activeTab == id;
          final chipColor = chip['color'] as Color;

          return Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: FilterChip(
              avatar: Icon(
                chip['icon'] as IconData,
                color: isSelected ? Colors.white : chipColor,
                size: 18,
              ),
              label: Text(
                chip['label'] as String,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                ),
              ),
              selected: isSelected,
              selectedColor: chipColor,
              backgroundColor: isDark ? AppColors.darkCard : const Color(0xFFF1F5F9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.full),
                side: BorderSide(
                  color: isSelected ? chipColor : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  width: 1,
                ),
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
