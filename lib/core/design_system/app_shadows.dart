import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Centralized Elevation and Glassmorphism Shadow tokens for VitalAI.
abstract class AppShadows {
  // Soft Card Elevation
  static final List<BoxShadow> cardShadowLight = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.02),
      blurRadius: 4,
      offset: const Offset(0, 1),
      spreadRadius: 0,
    ),
  ];

  static final List<BoxShadow> cardShadowDark = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 16,
      offset: const Offset(0, 6),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> subtle(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? cardShadowDark
        : cardShadowLight;
  }

  // AI Active Glow
  static final List<BoxShadow> _aiGlowList = [
    BoxShadow(
      color: AppColors.tertiary.withValues(alpha: 0.35),
      blurRadius: 20,
      offset: const Offset(0, 6),
      spreadRadius: 2,
    ),
  ];

  static List<BoxShadow> get aiGlow => _aiGlowList;
  static List<BoxShadow> aiGlowCall([BuildContext? context]) => _aiGlowList;

  // Floating Action / Button Shadow
  static final List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.25),
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  // Modal Sheet Shadow
  static final List<BoxShadow> modalShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 30,
      offset: const Offset(0, -10),
      spreadRadius: 0,
    ),
  ];
}
