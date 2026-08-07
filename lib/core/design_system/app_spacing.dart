import 'package:flutter/material.dart';

/// Centralized Spacing tokens and EdgeInsets utilities for VitalAI.
abstract class AppSpacing {
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;

  // EdgeInsets Presets
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 16);
  static const EdgeInsets cardPadding = EdgeInsets.all(16);
  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(12);
  static const EdgeInsets horizontalPadding = EdgeInsets.symmetric(horizontal: 20);
  static const EdgeInsets verticalPadding = EdgeInsets.symmetric(vertical: 16);
  static const EdgeInsets chipPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 6);
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 14);

  // Spacers
  static const SizedBox spaceXXS = SizedBox(width: xxs, height: xxs);
  static const SizedBox spaceXS = SizedBox(width: xs, height: xs);
  static const SizedBox spaceSM = SizedBox(width: sm, height: sm);
  static const SizedBox spaceMD = SizedBox(width: md, height: md);
  static const SizedBox spaceLG = SizedBox(width: lg, height: lg);
  static const SizedBox spaceXL = SizedBox(width: xl, height: xl);
  static const SizedBox spaceXXL = SizedBox(width: xxl, height: xxl);
}
