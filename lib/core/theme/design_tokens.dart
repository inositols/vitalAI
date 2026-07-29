import 'package:flutter/material.dart';

/// Centralized Premium Design System Tokens for VitalAI
abstract class AppColors {
  // Primary Brand - Modern Health Sapphire & Emerald
  static const Color primary = Color(0xFF0284C7); // Sapphire Sky
  static const Color primaryLight = Color(0xFF38BDF8);
  static const Color primaryDark = Color(0xFF0369A1);
  static const Color primaryContainer = Color(0xFFE0F2FE);
  static const Color onPrimaryContainer = Color(0xFF075985);
  static const Color onPrimary = Colors.white;

  // Secondary Brand - Vitality Emerald
  static const Color secondary = Color(0xFF10B981); // Emerald Vitality
  static const Color secondaryLight = Color(0xFF34D399);
  static const Color secondaryDark = Color(0xFF059669);
  static const Color secondaryContainer = Color(0xFFD1FAE5);
  static const Color onSecondaryContainer = Color(0xFF065F46);

  // Tertiary Brand - AI & Intelligence Violet
  static const Color tertiary = Color(0xFF6366F1); // Intelligence Indigo
  static const Color tertiaryLight = Color(0xFF818CF8);
  static const Color tertiaryDark = Color(0xFF4338CA);
  static const Color tertiaryContainer = Color(0xFFEEF2FF);
  static const Color onTertiaryContainer = Color(0xFF3730A3);

  // Background & Surfaces
  static const Color lightSurface = Color(0xFFF8FAFC);
  static const Color lightContainer = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);

  static const Color darkSurface = Color(0xFF0B132B);
  static const Color darkContainer = Color(0xFF1C2541);
  static const Color darkCard = Color(0xFF16203B);
  static const Color darkBorder = Color(0xFF2A365C);

  // Health Vital Badges & Themes
  static const Color bpVital = Color(0xFFF43F5E);      // Blood Pressure - Ruby Rose
  static const Color glucoseVital = Color(0xFFF59E0B); // Glucose - Amber Gold
  static const Color pulseVital = Color(0xFFEC4899);   // Pulse Rate - Hot Pink
  static const Color spo2Vital = Color(0xFF06B6D4);    // SpO2 - Cyan
  static const Color tempVital = Color(0xFFA855F7);    // Temperature - Violet
  static const Color weightVital = Color(0xFF10B981);  // Weight - Emerald

  // States & Alerts
  static const Color error = Color(0xFFEF4444);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color success = Color(0xFF10B981);
  static const Color successContainer = Color(0xFFD1FAE5);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoContainer = Color(0xFFDBEAFE);

  // Gradients
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

abstract class AppSpacing {
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 16);
  static const EdgeInsets cardPadding = EdgeInsets.all(16);
  static const EdgeInsets horizontalPadding = EdgeInsets.symmetric(horizontal: 20);
}

abstract class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 28.0;
  static const double full = 999.0;

  static const BorderRadius roundedSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius roundedMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius roundedLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius roundedXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius roundedXxl = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius roundedFull = BorderRadius.all(Radius.circular(full));
}

abstract class AppShadows {
  static List<BoxShadow> subtle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: 0.35)
            : const Color(0xFF64748B).withValues(alpha: 0.08),
        blurRadius: 16,
        spreadRadius: 0,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static List<BoxShadow> floating(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: 0.5)
            : const Color(0xFF0284C7).withValues(alpha: 0.18),
        blurRadius: 28,
        spreadRadius: 2,
        offset: const Offset(0, 10),
      ),
    ];
  }

  static List<BoxShadow> aiGlow(BuildContext context) {
    return [
      BoxShadow(
        color: AppColors.tertiary.withValues(alpha: 0.25),
        blurRadius: 20,
        spreadRadius: 1,
        offset: const Offset(0, 6),
      ),
    ];
  }
}

abstract class AppDurations {
  static const Duration ultraFast = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
}
