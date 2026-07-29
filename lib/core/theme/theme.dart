import 'package:flutter/material.dart';
import 'design_tokens.dart';

class AppTheme {
  static const Color primaryLight = AppColors.primary;
  static const Color secondaryLight = AppColors.secondary;
  static const Color tertiaryLight = AppColors.tertiary;
  static const Color surfaceLight = AppColors.lightSurface;
  static const Color containerLight = AppColors.lightContainer;

  static const Color primaryDark = AppColors.primaryLight;
  static const Color secondaryDark = AppColors.secondaryLight;
  static const Color tertiaryDark = AppColors.tertiaryLight;
  static const Color surfaceDark = AppColors.darkSurface;
  static const Color containerDark = AppColors.darkContainer;

  static TextTheme _buildTextTheme(TextTheme base, {required bool isDark}) {
    final textColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final mutedColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return base.copyWith(
      displayLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: textColor, letterSpacing: -0.8, height: 1.2),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: textColor, letterSpacing: -0.5, height: 1.25),
      headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: textColor, letterSpacing: -0.4, height: 1.25),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textColor, letterSpacing: -0.3, height: 1.3),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor, letterSpacing: -0.2),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor, letterSpacing: -0.1),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: mutedColor),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: textColor, height: 1.5),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: textColor, height: 1.45),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: mutedColor, height: 1.4),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor, letterSpacing: 0.1),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: mutedColor, letterSpacing: 0.2),
      labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: mutedColor, letterSpacing: 0.3),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryLight,
        brightness: Brightness.light,
        primary: primaryLight,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: secondaryLight,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: tertiaryLight,
        tertiaryContainer: AppColors.tertiaryContainer,
        onTertiaryContainer: AppColors.onTertiaryContainer,
        surface: surfaceLight,
        surfaceContainerHighest: containerLight,
        outline: const Color(0xFFCBD5E1),
        outlineVariant: const Color(0xFFE2E8F0),
        error: AppColors.error,
        errorContainer: AppColors.errorContainer,
      ),
      scaffoldBackgroundColor: surfaceLight,
      textTheme: _buildTextTheme(ThemeData.light().textTheme, isDark: false),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceLight,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 20, letterSpacing: -0.3),
        iconTheme: IconThemeData(color: Color(0xFF475569)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryLight,
          foregroundColor: Colors.white,
          minimumSize: const Size(88, 52),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(88, 52),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
          foregroundColor: const Color(0xFF334155),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryLight,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: primaryLight.withValues(alpha: 0.15),
          selectedForegroundColor: primaryLight,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xxl)),
        titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        elevation: 6,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: Colors.white,
        indicatorColor: primaryLight.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: primaryLight);
          }
          return const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF64748B));
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryLight, size: 24);
          }
          return const IconThemeData(color: Color(0xFF64748B), size: 24);
        }),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryLight,
        brightness: Brightness.dark,
        primary: primaryDark,
        onPrimary: AppColors.darkSurface,
        primaryContainer: const Color(0xFF075985),
        onPrimaryContainer: const Color(0xFFE0F2FE),
        secondary: secondaryDark,
        secondaryContainer: const Color(0xFF065F46),
        onSecondaryContainer: const Color(0xFFD1FAE5),
        tertiary: tertiaryDark,
        tertiaryContainer: const Color(0xFF3730A3),
        onTertiaryContainer: const Color(0xFFEEF2FF),
        surface: surfaceDark,
        surfaceContainerHighest: containerDark,
        outline: AppColors.darkBorder,
        outlineVariant: const Color(0xFF1E293B),
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: surfaceDark,
      textTheme: _buildTextTheme(ThemeData.dark().textTheme, isDark: true),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceDark,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(color: Color(0xFFF8FAFC), fontWeight: FontWeight.w700, fontSize: 20, letterSpacing: -0.3),
        iconTheme: IconThemeData(color: Color(0xFF94A3B8)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.darkCard,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: primaryDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryDark,
          foregroundColor: const Color(0xFF0F172A),
          minimumSize: const Size(88, 52),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(88, 52),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          side: const BorderSide(color: AppColors.darkBorder, width: 1.5),
          foregroundColor: const Color(0xFFE2E8F0),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryDark,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: primaryDark.withValues(alpha: 0.2),
          selectedForegroundColor: primaryDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkCard,
        elevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xxl)),
        titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFFF8FAFC)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        elevation: 6,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: AppColors.darkSurface,
        indicatorColor: primaryDark.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: primaryDark);
          }
          return const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8));
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryDark, size: 24);
          }
          return const IconThemeData(color: Color(0xFF94A3B8), size: 24);
        }),
      ),
    );
  }

  static ThemeData get highContrastLightTheme {
    final baseLight = lightTheme;
    return baseLight.copyWith(
      scaffoldBackgroundColor: Colors.white,
      textTheme: baseLight.textTheme.copyWith(
        bodyLarge: baseLight.textTheme.bodyLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        bodyMedium: baseLight.textTheme.bodyMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black),
      ),
      colorScheme: baseLight.colorScheme.copyWith(
        primary: const Color(0xFF0284C7),
        surface: Colors.white,
        onSurface: Colors.black,
      ),
    );
  }

  static ThemeData get highContrastDarkTheme {
    final baseDark = darkTheme;
    return baseDark.copyWith(
      scaffoldBackgroundColor: Colors.black,
      textTheme: baseDark.textTheme.copyWith(
        bodyLarge: baseDark.textTheme.bodyLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        bodyMedium: baseDark.textTheme.bodyMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
      ),
      colorScheme: baseDark.colorScheme.copyWith(
        primary: const Color(0xFF38BDF8),
        surface: Colors.black,
        onSurface: Colors.white,
      ),
    );
  }
}
