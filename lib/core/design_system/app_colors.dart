import 'package:flutter/material.dart';

abstract class AppColors {
  // Primary Brand - Clinical Teal (#087F70)
  static const Color primary = Color(0xFF087F70);
  static const Color primaryLight = Color(0xFF0F766E);
  static const Color primaryDark = Color(0xFF065F54);
  static const Color primaryContainer = Color(0xFFE7F5F2);
  static const Color onPrimaryContainer = Color(0xFF065F54);
  static const Color onPrimary = Colors.white;

  // Secondary Brand - Deep Navy (#142B45)
  static const Color secondary = Color(0xFF142B45);
  static const Color secondaryLight = Color(0xFF1E3A5F);
  static const Color secondaryDark = Color(0xFF0B1B2D);
  static const Color secondaryContainer = Color(0xFFEDF2F7);
  static const Color onSecondaryContainer = Color(0xFF142B45);
  static const Color onSecondary = Colors.white;

  // Tertiary Brand - Intelligence Indigo & Calm Accents
  static const Color tertiary = Color(0xFF0F766E);
  static const Color tertiaryLight = Color(0xFF14B8A6);
  static const Color tertiaryDark = Color(0xFF042F2E);
  static const Color tertiaryContainer = Color(0xFFE7F5F2);
  static const Color onTertiaryContainer = Color(0xFF0F766E);
  static const Color onTertiary = Colors.white;

  // Light Surface & Neutral Palette (F8FAFC / E5E9EF / 142B45)
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightContainer = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE5E9EF);
  static const Color lightTextPrimary = Color(0xFF142B45);
  static const Color lightTextSecondary = Color(0xFF667085);
  static const Color lightTextMuted = Color(0xFF94A3B8);
  static const Color navy = Color(0xFF142B45);
  static const Color slate = Color(0xFF667085);

  // Subtle Teal Surface (#E7F5F2)
  static const Color subtleTealSurface = Color(0xFFE7F5F2);
  static const Color subtleTealBorder = Color(0xFFBCE3DC);

  // Dark Surface & Neutral Palette
  static const Color darkBackground = Color(0xFF0A1626);
  static const Color darkSurface = Color(0xFF14243B);
  static const Color darkContainer = Color(0xFF0F1E32);
  static const Color darkCard = Color(0xFF182B45);
  static const Color darkBorder = Color(0xFF223A5B);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // Vital Metric Badges & Color Tokens
  static const Color bpVital = Color(0xFFEF4444); // Blood Pressure - Coral Red
  static const Color glucoseVital = Color(0xFFF59E0B); // Glucose - Amber Gold
  static const Color pulseVital = Color(0xFFEF4444); // Heart Rate - Coral Red
  static const Color spo2Vital = Color(0xFF087F70); // SpO2 - Teal
  static const Color tempVital = Color(0xFF6366F1); // Temperature - Indigo
  static const Color weightVital = Color(0xFF10B981); // Weight / Steps - Green
  static const Color sleepVital = Color(0xFF0F766E); // Sleep - Deep Teal

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

  static const Color info = Color(0xFF087F70);
  static const Color infoContainer = Color(0xFFE7F5F2);
  static const Color onInfoContainer = Color(0xFF065F54);

  // Refined Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF087F70), Color(0xFF065F54)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGoalGradient = LinearGradient(
    colors: [Color(0xFF087F70), Color(0xFF0A6C60)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient aiGradient = LinearGradient(
    colors: [Color(0xFF087F70), Color(0xFF0E9F8E), Color(0xFF142B45)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient healthScoreGradient = LinearGradient(
    colors: [Color(0xFF087F70), Color(0xFF10B981)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient heroDarkGradient = LinearGradient(
    colors: [Color(0xFF0A1626), Color(0xFF14243B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient heroLightGradient = LinearGradient(
    colors: [Color(0xFFE7F5F2), Color(0xFFF8FAFC)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
