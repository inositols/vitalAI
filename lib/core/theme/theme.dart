import 'package:flutter/material.dart';
import 'design_tokens.dart';

class AppTheme {
  static const Color primaryLight = AppColors.primary;
  static const Color secondaryLight = AppColors.secondary;
  static const Color tertiaryLight = AppColors.tertiary;
  static const Color surfaceLight = AppColors.lightSurface;
  static const Color containerLight = AppColors.lightContainer;

  static const Color primaryDark = Color(0xFF78A9FF);
  static const Color secondaryDark = Color(0xFF39D391);
  static const Color tertiaryDark = Color(0xFFD4BBFF);
  static const Color surfaceDark = AppColors.darkSurface;
  static const Color containerDark = AppColors.darkContainer;

  static TextTheme _buildTextTheme(TextTheme base) {
    return base.copyWith(
      headlineLarge: base.headlineLarge?.copyWith(fontSize: 34, fontWeight: FontWeight.bold, height: 1.25),
      headlineMedium: base.headlineMedium?.copyWith(fontSize: 26, fontWeight: FontWeight.w600, height: 1.3),
      titleLarge: base.titleLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.w600),
      bodyLarge: base.bodyLarge?.copyWith(fontSize: 18, height: 1.5),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: 16, height: 1.45),
      labelLarge: base.labelLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
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
        secondary: secondaryLight,
        tertiary: tertiaryLight,
        surface: surfaceLight,
      ),
      scaffoldBackgroundColor: surfaceLight,
      textTheme: _buildTextTheme(ThemeData.light().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.bold, fontSize: 20),
        iconTheme: IconThemeData(color: Color(0xFF4B5563)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.all(AppSpacing.lg),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(88, 56),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
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
        secondary: secondaryDark,
        tertiary: tertiaryDark,
        surface: surfaceDark,
      ),
      scaffoldBackgroundColor: surfaceDark,
      textTheme: _buildTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: containerDark,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(color: Color(0xFFF9FAFB), fontWeight: FontWeight.bold, fontSize: 20),
        iconTheme: IconThemeData(color: Color(0xFFD1D5DB)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: containerDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: Color(0xFF2D3748), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1F2937),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.all(AppSpacing.lg),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(88, 56),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      ),
    );
  }

  static ThemeData get highContrastLightTheme {
    final baseLight = lightTheme;
    return baseLight.copyWith(
      scaffoldBackgroundColor: Colors.white,
      textTheme: baseLight.textTheme.copyWith(
        bodyLarge: baseLight.textTheme.bodyLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
        bodyMedium: baseLight.textTheme.bodyMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black),
      ),
      colorScheme: baseLight.colorScheme.copyWith(
        primary: const Color(0xFF002D9C),
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
        bodyLarge: baseDark.textTheme.bodyLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        bodyMedium: baseDark.textTheme.bodyMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      colorScheme: baseDark.colorScheme.copyWith(
        primary: const Color(0xFFD0E1FF),
        surface: Colors.black,
        onSurface: Colors.white,
      ),
    );
  }
}
