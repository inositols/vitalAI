import 'package:flutter/animation.dart';

/// Centralized Motion Design tokens for physics curves, durations, and entrance animations.
abstract class AppMotion {
  // Durations
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration extraSlow = Duration(milliseconds: 800);

  // Curves
  static const Curve easeOutCubic = Curves.easeOutCubic;
  static const Curve easeInOutCubic = Curves.easeInOutCubic;
  static const Curve springOut = Curves.elasticOut;
  static const Curve bounceOut = Curves.bounceOut;
  static const Curve decelerate = Curves.decelerate;

  // Stagger delays
  static Duration stagger(int index, {int baseMs = 50}) {
    return Duration(milliseconds: index * baseMs);
  }
}

abstract class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration extraSlow = Duration(milliseconds: 800);
}
