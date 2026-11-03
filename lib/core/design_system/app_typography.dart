import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Centralized World-Class Typography system for VitalAI.
/// Uses Plus Jakarta Sans (Primary UI & Body) and Outfit (Hero Display & Vitals).
///
/// Features OpenType tabular numbers (`tnum`) and slashed zeros to eliminate
/// numerical jitter and visual ambiguity in real-time medical data.
abstract class AppTypography {
  // Display & Hero Titles (Manrope - Screen Headings & Prominent Titles)
  static TextStyle displayLarge({Color? color}) => GoogleFonts.manrope(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        height: 1.2,
        letterSpacing: -0.6,
        color: color ?? AppColors.lightTextPrimary,
      );

  static TextStyle displayMedium({Color? color}) => GoogleFonts.manrope(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.5,
        color: color ?? AppColors.lightTextPrimary,
      );

  static TextStyle displaySmall({Color? color}) => GoogleFonts.manrope(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: -0.3,
        color: color ?? AppColors.lightTextPrimary,
      );

  // Headlines (Manrope)
  static TextStyle headlineLarge({Color? color}) => GoogleFonts.manrope(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: -0.3,
        color: color ?? AppColors.lightTextPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle headlineMedium({Color? color}) => GoogleFonts.manrope(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.35,
        letterSpacing: -0.2,
        color: color ?? AppColors.lightTextPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle headlineSmall({Color? color}) => GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.4,
        letterSpacing: -0.1,
        color: color ?? AppColors.lightTextPrimary,
      );

  // Section Titles (Manrope)
  static TextStyle titleLarge({Color? color}) => GoogleFonts.manrope(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.35,
        letterSpacing: -0.2,
        color: color ?? AppColors.lightTextPrimary,
      );

  static TextStyle titleMedium({Color? color}) => GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: -0.1,
        color: color ?? AppColors.lightTextPrimary,
      );

  static TextStyle titleSmall({Color? color}) => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: color ?? AppColors.lightTextPrimary,
      );

  // Body Text (Inter - Body text, form fields, and secondary info)
  static TextStyle bodyLarge({Color? color}) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: color ?? AppColors.lightTextPrimary,
      );

  static TextStyle bodyMedium({Color? color}) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: color ?? AppColors.lightTextPrimary,
      );

  static TextStyle bodySmall({Color? color}) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: color ?? AppColors.lightTextSecondary,
      );

  // Labels & Navigation (Inter)
  static TextStyle labelLarge({Color? color}) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: color ?? AppColors.lightTextPrimary,
      );

  static TextStyle labelMedium({Color? color}) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        color: color ?? AppColors.lightTextSecondary,
      );

  static TextStyle labelSmall({Color? color}) => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        color: color ?? AppColors.lightTextMuted,
      );

  // Health Numerical Value Typography (Manrope - Prominent Numbers with Tabular Figures)
  static TextStyle vitalValueLarge({Color? color}) => GoogleFonts.manrope(
        fontSize: 42,
        fontWeight: FontWeight.w800,
        height: 1.05,
        letterSpacing: -1.0,
        color: color ?? AppColors.lightTextPrimary,
        fontFeatures: const [
          FontFeature.tabularFigures(),
          FontFeature.slashedZero(),
        ],
      );

  static TextStyle vitalValue({Color? color}) => GoogleFonts.manrope(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        height: 1.1,
        letterSpacing: -0.8,
        color: color ?? AppColors.lightTextPrimary,
        fontFeatures: const [
          FontFeature.tabularFigures(),
          FontFeature.slashedZero(),
        ],
      );

  static TextStyle vitalValueMedium({Color? color}) => GoogleFonts.manrope(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -0.5,
        color: color ?? AppColors.lightTextPrimary,
        fontFeatures: const [
          FontFeature.tabularFigures(),
          FontFeature.slashedZero(),
        ],
      );

  static TextStyle vitalValueSmall({Color? color}) => GoogleFonts.manrope(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.3,
        color: color ?? AppColors.lightTextPrimary,
        fontFeatures: const [
          FontFeature.tabularFigures(),
          FontFeature.slashedZero(),
        ],
      );

  static TextStyle vitalUnit({Color? color}) => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        color: color ?? AppColors.lightTextSecondary,
      );

  /// Builds Material 3 [TextTheme] integrating Manrope for titles/headings and Inter for body/labels.
  static TextTheme createTextTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    final base = isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;
    final interTextTheme = GoogleFonts.interTextTheme(base);

    return interTextTheme.copyWith(
      displayLarge: GoogleFonts.manrope(
        textStyle: interTextTheme.displayLarge,
        fontSize: 32,
        fontWeight: FontWeight.w800,
        height: 1.2,
        letterSpacing: -0.6,
        color: primaryColor,
      ),
      displayMedium: GoogleFonts.manrope(
        textStyle: interTextTheme.displayMedium,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.5,
        color: primaryColor,
      ),
      displaySmall: GoogleFonts.manrope(
        textStyle: interTextTheme.displaySmall,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: -0.3,
        color: primaryColor,
      ),
      headlineLarge: GoogleFonts.manrope(
        textStyle: interTextTheme.headlineLarge,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: -0.3,
        color: primaryColor,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      headlineMedium: GoogleFonts.manrope(
        textStyle: interTextTheme.headlineMedium,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.35,
        letterSpacing: -0.2,
        color: primaryColor,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      headlineSmall: GoogleFonts.manrope(
        textStyle: interTextTheme.headlineSmall,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.4,
        letterSpacing: -0.1,
        color: primaryColor,
      ),
      titleLarge: GoogleFonts.manrope(
        textStyle: interTextTheme.titleLarge,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.35,
        letterSpacing: -0.2,
        color: primaryColor,
      ),
      titleMedium: GoogleFonts.manrope(
        textStyle: interTextTheme.titleMedium,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: -0.1,
        color: primaryColor,
      ),
      titleSmall: GoogleFonts.manrope(
        textStyle: interTextTheme.titleSmall,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: primaryColor,
      ),
      bodyLarge: GoogleFonts.inter(
        textStyle: interTextTheme.bodyLarge,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: primaryColor,
      ),
      bodyMedium: GoogleFonts.inter(
        textStyle: interTextTheme.bodyMedium,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: primaryColor,
      ),
      bodySmall: GoogleFonts.inter(
        textStyle: interTextTheme.bodySmall,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: secondaryColor,
      ),
      labelLarge: GoogleFonts.inter(
        textStyle: interTextTheme.labelLarge,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: primaryColor,
      ),
      labelMedium: GoogleFonts.inter(
        textStyle: interTextTheme.labelMedium,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        color: secondaryColor,
      ),
      labelSmall: GoogleFonts.inter(
        textStyle: interTextTheme.labelSmall,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        color: mutedColor,
      ),
    );
  }
}
