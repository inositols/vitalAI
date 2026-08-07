import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../models/genui_component_model.dart';

typedef GenUiEducationalTipModel = GenUiEducationCardModel;

/// Dynamic GenUI callout widget for health educational tips.
class GenUiEducationalTipWidget extends StatelessWidget {
  final GenUiEducationCardModel model;

  const GenUiEducationalTipWidget({
    super.key,
    required this.model,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.tertiaryDark.withValues(alpha: 0.2) : AppColors.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.tertiary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_rounded,
            color: AppColors.tertiary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  model.title,
                  style: AppTypography.titleSmall(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.onTertiaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  model.definition,
                  style: AppTypography.bodySmall(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
