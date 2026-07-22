import 'package:flutter/material.dart';

/// Centralized Design System Tokens for VitalAI
abstract class AppColors {
  // Brand Primary & Accents
  static const Color primary = Color(0xFF0066FF);
  static const Color primaryVariant = Color(0xFF0052CC);
  static const Color primaryContainer = Color(0xFFE6F0FF);
  static const Color onPrimary = Colors.white;

  // Secondary & Tertiary
  static const Color secondary = Color(0xFF00C853);
  static const Color tertiary = Color(0xFF6C5CE7);
  static const Color tertiaryContainer = Color(0xFFE8E5FA);

  // Background & Surfaces
  static const Color lightSurface = Color(0xFFFAFAFC);
  static const Color lightContainer = Color(0xFFF1F3F9);
  static const Color darkSurface = Color(0xFF12161F);
  static const Color darkContainer = Color(0xFF1E2430);

  // Health Vital Badges
  static const Color bpVital = Color(0xFFFF5252);
  static const Color glucoseVital = Color(0xFFFF9800);
  static const Color pulseVital = Color(0xFFE91E63);
  static const Color spo2Vital = Color(0xFF00BCD4);
  static const Color tempVital = Color(0xFF9C27B0);
  static const Color weightVital = Color(0xFF4CAF50);

  // States & Alerts
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFFFA000);
  static const Color success = Color(0xFF388E3C);
  static const Color info = Color(0xFF1976D2);
}

abstract class AppSpacing {
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;

  static const EdgeInsets screenPadding = EdgeInsets.all(lg);
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets horizontalPadding = EdgeInsets.symmetric(horizontal: lg);
}

abstract class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 999.0;

  static const BorderRadius roundedSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius roundedMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius roundedLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius roundedXl = BorderRadius.all(Radius.circular(xl));
}

abstract class AppShadows {
  static List<BoxShadow> subtle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.05),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static List<BoxShadow> floating(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: isDark ? Colors.black45 : Colors.black.withValues(alpha: 0.1),
        blurRadius: 20,
        spreadRadius: 2,
        offset: const Offset(0, 8),
      ),
    ];
  }
}

abstract class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
}
