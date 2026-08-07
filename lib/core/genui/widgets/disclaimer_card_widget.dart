import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';

/// Standard healthcare disclaimer banner widget for AI generated insights.
class DisclaimerCardWidget extends StatelessWidget {
  final String? text;

  const DisclaimerCardWidget({super.key, this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disclaimerText = text ??
        'Educational purpose only. VitalAI recommendations do not replace clinical advice from a qualified healthcare professional.';

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.infoContainer.withValues(alpha: 0.15)
            : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: isDark
              ? AppColors.info.withValues(alpha: 0.3)
              : AppColors.info.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: AppColors.info,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              disclaimerText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    height: 1.3,
                    color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
