import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Centralized World-Class Typography system for VitalAI.
/// Uses Plus Jakarta Sans (Primary UI & Body) and Outfit (Hero Display & Vitals).
abstract class AppTypography {
  // Display & Hero Titles (Outfit - Ultra-Modern Geometric Display)
  static TextStyle displayLarge({Color? color}) => GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        height: 1.2,
        letterSpacing: -0.6,
        color: color ?? AppColors.lightTextPrimary,
      );

  static TextStyle displayMedium({Color? color}) => GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.5,
        color: color ?? AppColors.lightTextPrimary,
      );

  static TextStyle displaySmall({Color? color}) => GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: -0.3,
        color: color ?? AppColors.lightTextPrimary,
      );

  // Headlines (Plus Jakarta Sans - Precision Geometric UI)
  static TextStyle headlineLarge({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: -0.3,
        color: color ?? AppColors.lightTextPrimary,
      );

  static TextStyle headlineMedium({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.35,
        letterSpacing: -0.2,
        color: color ?? AppColors.lightTextPrimary,
      );

  static TextStyle headlineSmall({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.4,
        letterSpacing: -0.1,
        color: color ?? AppColors.lightTextPrimary,
      );

  // Titles (Plus Jakarta Sans)
  static TextStyle titleMedium({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: 1.4,
        letterSpacing: -0.1,
        color: color ?? AppColors.lightTextPrimary,
      );

  static TextStyle titleSmall({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: color ?? AppColors.lightTextPrimary,
      );

  // Body Text (Plus Jakarta Sans)
  static TextStyle bodyLarge({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: color ?? AppColors.lightTextPrimary,
      );

  static TextStyle bodyMedium({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: color ?? AppColors.lightTextPrimary,
      );

  static TextStyle bodySmall({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: color ?? AppColors.lightTextSecondary,
      );

  // Captions & Labels (Plus Jakarta Sans)
  static TextStyle labelLarge({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
        color: color ?? AppColors.lightTextPrimary,
      );

  static TextStyle labelMedium({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: color ?? AppColors.lightTextSecondary,
      );

  static TextStyle labelSmall({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: color ?? AppColors.lightTextMuted,
      );

  // Health Numerical Value Typography (Outfit - Ultra-Crisp Data Numbers)
  static TextStyle vitalValue({Color? color}) => GoogleFonts.outfit(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        height: 1.1,
        letterSpacing: -0.8,
        color: color ?? AppColors.lightTextPrimary,
      );

  static TextStyle vitalUnit({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.lightTextSecondary,
      );
}
