import 'package:flutter/material.dart';

/// Design system theme provider for VitalAI.
/// Implements beautiful, accessible, and high-aesthetic Material 3 styling.
class AppTheme {
  // Brand color definitions (harmonious, premium palette)
  static const Color primaryLight = Color(0xFF0F62FE); // Deep Indigo
  static const Color secondaryLight = Color(0xFF008A5E); // Emerald Green
  static const Color tertiaryLight = Color(0xFF8A3FFC); // Vibrant Violet
  static const Color backgroundLight = Color(0xFFF4F6FA);
  static const Color surfaceLight = Colors.white;

  static const Color primaryDark = Color(0xFF78A9FF); // Soft Indigo-Blue
  static const Color secondaryDark = Color(0xFF39D391); // Soft Emerald Green
  static const Color tertiaryDark = Color(0xFFD4BBFF); // Soft Violet
  static const Color backgroundDark = Color(0xFF0F141C); // Deep Slate Gray
  static const Color surfaceDark = Color(0xFF1E2530);

  // High contrast palette
  static const Color primaryHcLight = Color(0xFF002D9C);
  static const Color backgroundHcLight = Colors.white;
  static const Color primaryHcDark = Color(0xFFD0E1FF);
  static const Color backgroundHcDark = Colors.black;

  /// Custom typography scaling focusing on readability for seniors
  static TextTheme _buildTextTheme(TextTheme base) {
    return base
        .copyWith(
          headlineLarge: base.headlineLarge?.copyWith(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            height: 1.25,
          ),
          headlineMedium: base.headlineMedium?.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
          titleLarge: base.titleLarge?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          bodyLarge: base.bodyLarge?.copyWith(
            fontSize: 18, // Enlarged for readability
            height: 1.5, // Increased line height for reduced cognitive load
            letterSpacing: 0.5,
          ),
          bodyMedium: base.bodyMedium?.copyWith(
            fontSize: 16,
            height: 1.45,
            letterSpacing: 0.25,
          ),
          labelLarge: base.labelLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        )
        .apply(fontFamily: 'Georgia');
  }

  /// Light Mode Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Georgia',
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryLight,
        brightness: Brightness.light,
        primary: primaryLight,
        secondary: secondaryLight,
        tertiary: tertiaryLight,
        background: backgroundLight,
        surface: surfaceLight,
      ),
      scaffoldBackgroundColor: backgroundLight,
      textTheme: _buildTextTheme(ThemeData.light().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceLight,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: const Border(
          bottom: BorderSide(
            color: Color(0xFFE5E7EB), // Gray 200 divider
            width: 1,
          ),
        ),
        titleTextStyle: const TextStyle(
          color: Color(0xFF111827), // Neutral 900
          fontWeight: FontWeight.bold,
          fontSize: 20,
          fontFamily: 'Georgia',
        ),
        iconTheme: const IconThemeData(color: Color(0xFF4B5563)), // Neutral 600
        actionsIconTheme: const IconThemeData(color: Color(0xFF4B5563)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceLight,
        indicatorColor: Colors.transparent, // Remove bulky pill
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: primaryLight,
              fontFamily: 'Georgia',
            );
          }
          return const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.normal,
            color: Color(0xFF6B7280), // Gray 500
            fontFamily: 'Georgia',
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryLight, size: 26);
          }
          return const IconThemeData(color: Color(0xFF6B7280), size: 26);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(88, 56), // Large touch targets
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// Dark Mode Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Georgia',
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryLight,
        brightness: Brightness.dark,
        primary: primaryDark,
        secondary: secondaryDark,
        tertiary: tertiaryDark,
        background: backgroundDark,
        surface: surfaceDark,
      ),
      scaffoldBackgroundColor: backgroundDark,
      textTheme: _buildTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceDark,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: const Border(
          bottom: BorderSide(
            color: Color(0xFF2D3748), // Dark slate divider
            width: 1,
          ),
        ),
        titleTextStyle: const TextStyle(
          color: Color(0xFFF9FAFB), // Neutral 50
          fontWeight: FontWeight.bold,
          fontSize: 20,
          fontFamily: 'Georgia',
        ),
        iconTheme: const IconThemeData(color: Color(0xFFD1D5DB)), // Neutral 300
        actionsIconTheme: const IconThemeData(color: Color(0xFFD1D5DB)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2D3748), width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceDark,
        indicatorColor: Colors.transparent, // Remove bulky pill
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: primaryDark,
              fontFamily: 'Georgia',
            );
          }
          return const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.normal,
            color: Color(0xFF9CA3AF), // Gray 400
            fontFamily: 'Georgia',
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryDark, size: 26);
          }
          return const IconThemeData(color: Color(0xFF9CA3AF), size: 26);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E2530),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(88, 56), // Large touch targets
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// High Contrast Light Mode Theme
  static ThemeData get highContrastLightTheme {
    return lightTheme.copyWith(
      colorScheme: const ColorScheme.light(
        primary: primaryHcLight,
        secondary: Colors.black,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundHcLight,
      appBarTheme: lightTheme.appBarTheme.copyWith(
        backgroundColor: Colors.white,
        shape: const Border(
          bottom: BorderSide(
            color: Colors.black, // Thick high contrast border
            width: 2,
          ),
        ),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 20,
          fontFamily: 'Georgia',
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actionsIconTheme: const IconThemeData(color: Colors.black),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: Colors.black,
            width: 2,
          ), // Visible thick borders
        ),
      ),
    );
  }

  /// High Contrast Dark Mode Theme
  static ThemeData get highContrastDarkTheme {
    return darkTheme.copyWith(
      colorScheme: const ColorScheme.dark(
        primary: primaryHcDark,
        secondary: Colors.white,
        surface: Color(0xFF121212),
      ),
      scaffoldBackgroundColor: backgroundHcDark,
      appBarTheme: darkTheme.appBarTheme.copyWith(
        backgroundColor: const Color(0xFF121212),
        shape: const Border(
          bottom: BorderSide(
            color: Colors.white, // Thick high contrast border
            width: 2,
          ),
        ),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
          fontFamily: 'Georgia',
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF121212),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: Colors.white,
            width: 2,
          ), // Visible thick borders
        ),
      ),
    );
  }
}
