import 'package:flutter/material.dart';

/// Centralized Design System Colors for VitalAI
/// Inspired by premium health platforms (Apple Health, Fitbit, Oura, Samsung Health).
abstract class AppColors {
  // Primary Brand - Sapphire Sky
  static const Color primary = Color(0xFF0284C7);
  static const Color primaryLight = Color(0xFF38BDF8);
  static const Color primaryDark = Color(0xFF0369A1);
  static const Color primaryContainer = Color(0xFFE0F2FE);
  static const Color onPrimaryContainer = Color(0xFF075985);
  static const Color onPrimary = Colors.white;

  // Secondary Brand - Vitality Emerald
  static const Color secondary = Color(0xFF10B981);
  static const Color secondaryLight = Color(0xFF34D399);
  static const Color secondaryDark = Color(0xFF059669);
  static const Color secondaryContainer = Color(0xFFD1FAE5);
  static const Color onSecondaryContainer = Color(0xFF065F46);
  static const Color onSecondary = Colors.white;

  // Tertiary Brand - Intelligence Indigo & AI Violet
  static const Color tertiary = Color(0xFF6366F1);
  static const Color tertiaryLight = Color(0xFF818CF8);
  static const Color tertiaryDark = Color(0xFF4338CA);
  static const Color tertiaryContainer = Color(0xFFEEF2FF);
  static const Color onTertiaryContainer = Color(0xFF3730A3);
  static const Color onTertiary = Colors.white;

  // Light Surface & Neutral Palette
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightContainer = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightTextMuted = Color(0xFF94A3B8);

  // Dark Surface & Neutral Palette
  static const Color darkBackground = Color(0xFF0B132B);
  static const Color darkSurface = Color(0xFF1C2541);
  static const Color darkContainer = Color(0xFF16203B);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF2A365C);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // Vital Metric Badges & Color Tokens
  static const Color bpVital = Color(0xFFF43F5E);      // Blood Pressure - Ruby Rose
  static const Color glucoseVital = Color(0xFFF59E0B); // Glucose - Amber Gold
  static const Color pulseVital = Color(0xFFEC4899);   // Pulse Rate - Hot Pink
  static const Color spo2Vital = Color(0xFF06B6D4);    // SpO2 - Cyan Blue
  static const Color tempVital = Color(0xFFA855F7);    // Temperature - Violet
  static const Color weightVital = Color(0xFF10B981);  // Weight - Emerald

  // States & Alerts
  static const Color error = Color(0xFFEF4444);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color onErrorContainer = Color(0xFF991B1B);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color onWarningContainer = Color(0xFF92400E);

  static const Color success = Color(0xFF10B981);
  static const Color successContainer = Color(0xFFD1FAE5);
  static const Color onSuccessContainer = Color(0xFF065F46);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoContainer = Color(0xFFDBEAFE);
  static const Color onInfoContainer = Color(0xFF1E40AF);

  // Premium Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient aiGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient healthScoreGradient = LinearGradient(
    colors: [Color(0xFF0284C7), Color(0xFF10B981)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient heroDarkGradient = LinearGradient(
    colors: [Color(0xFF0B132B), Color(0xFF1C2541)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient heroLightGradient = LinearGradient(
    colors: [Color(0xFFE0F2FE), Color(0xFFF8FAFC)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
