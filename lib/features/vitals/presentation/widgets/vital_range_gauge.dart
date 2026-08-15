import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

/// Sleek dynamic clinical range gauge bar that displays where the current reading
/// falls relative to target physiological ranges.
class VitalRangeGauge extends StatelessWidget {
  final double currentProgress; // 0.0 to 1.0
  final String statusText;
  final Color statusColor;
  final List<Color> gradientColors;
  final String? helperText;

  const VitalRangeGauge({
    super.key,
    required this.currentProgress,
    required this.statusText,
    required this.statusColor,
    this.gradientColors = const [
      AppColors.secondary,
      AppColors.warning,
      AppColors.error,
    ],
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = currentProgress.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(color: statusColor.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
            if (helperText != null)
              Text(
                helperText!,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Background Gradient Track
            Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(
                  colors: gradientColors,
                ),
              ),
            ),
            // Indicator Thumb
            LayoutBuilder(
              builder: (ctx, constraints) {
                final maxWidth = constraints.maxWidth;
                final offset = (maxWidth - 14) * clamped;

                return Positioned(
                  left: offset.clamp(0.0, maxWidth - 14),
                  top: -3,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: statusColor, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
