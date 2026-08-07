import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

enum VitalStatusLevel {
  normal,
  elevated,
  high,
  low,
}

class VitalsStatusBadge extends StatelessWidget {
  final VitalStatusLevel level;
  final String? customLabel;

  const VitalsStatusBadge({
    super.key,
    required this.level,
    this.customLabel,
  });

  Color get _badgeColor {
    switch (level) {
      case VitalStatusLevel.normal:
        return AppColors.success;
      case VitalStatusLevel.elevated:
        return AppColors.warning;
      case VitalStatusLevel.high:
        return AppColors.error;
      case VitalStatusLevel.low:
        return AppColors.info;
    }
  }

  String get _label {
    if (customLabel != null && customLabel!.isNotEmpty) {
      return customLabel!;
    }
    switch (level) {
      case VitalStatusLevel.normal:
        return 'Normal';
      case VitalStatusLevel.elevated:
        return 'Elevated';
      case VitalStatusLevel.high:
        return 'High';
      case VitalStatusLevel.low:
        return 'Low';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _badgeColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              _label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
