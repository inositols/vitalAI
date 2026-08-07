import 'package:flutter/material.dart';

/// Centralized Corner Radius tokens for VitalAI cards, dialogs, and buttons.
abstract class AppRadius {
  static const double xs = 6.0;
  static const double sm = 10.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 32.0;
  static const double pill = 999.0;
  static const double full = 999.0;

  // BorderRadius Presets
  static const BorderRadius borderXS = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius borderSM = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius borderMD = BorderRadius.all(Radius.circular(md));
  static const BorderRadius borderLG = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius borderXL = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius borderPill = BorderRadius.all(Radius.circular(pill));

  // Sheet / Modal Top Radius
  static const BorderRadius topSheetRadius = BorderRadius.vertical(top: Radius.circular(lg));
}
