import 'package:flutter/material.dart';
import '../design_system/app_theme.dart' as ds;

export '../design_system/app_colors.dart';
export '../design_system/app_icons.dart';
export '../design_system/app_motion.dart';
export '../design_system/app_radius.dart';
export '../design_system/app_shadows.dart';
export '../design_system/app_spacing.dart';
export '../design_system/app_theme.dart';
export '../design_system/app_typography.dart';

/// Legacy Theme adapter delegating to [ds.AppTheme] for backward compatibility.
abstract class AppTheme {
  static ThemeData get lightTheme => ds.AppTheme.lightTheme;
  static ThemeData get darkTheme => ds.AppTheme.darkTheme;
  static ThemeData get highContrastLightTheme => ds.AppTheme.highContrastLightTheme;
  static ThemeData get highContrastDarkTheme => ds.AppTheme.highContrastDarkTheme;
}
