import 'package:flutter/material.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_card.dart';

class CaregiverSharingToggle extends StatelessWidget {
  final bool isSharingEnabled;
  final ValueChanged<bool> onChanged;

  const CaregiverSharingToggle({
    super.key,
    required this.isSharingEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: SwitchListTile(
          title: Text(
            'Enable Remote Data Sharing',
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          subtitle: Text(
            'Allow authorized caregivers to view vitals & receive alerts',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          value: isSharingEnabled,
          activeTrackColor: AppColors.primary,
          secondary: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.share_rounded, color: AppColors.primary, size: 22),
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
