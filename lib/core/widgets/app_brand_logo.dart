import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// Clean, resolution-independent vector brand emblem for VitalAI.
/// Replaces AI-generated bitmap image assets with pure Flutter vector graphics.
class AppBrandLogo extends StatelessWidget {
  final double size;
  final double iconSize;

  const AppBrandLogo({
    super.key,
    this.size = 56,
    this.iconSize = 28,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: size * 0.3,
            spreadRadius: 2,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: size * 0.82,
          height: size * 0.82,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? AppColors.darkBackground : Colors.white,
          ),
          child: Center(
            child: ShaderMask(
              shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
              child: Icon(
                AppIcons.pulse,
                size: iconSize,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
