import 'package:flutter/material.dart';

extension BuildContextExt on BuildContext {
  /// Theme Data shorthand
  ThemeData get theme => Theme.of(this);

  /// Text Theme shorthand
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Color Scheme shorthand
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Check if current theme is Dark Mode
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// MediaQuery Size shorthand
  Size get screenSize => MediaQuery.of(this).size;

  /// Screen Width shorthand
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Screen Height shorthand
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Show SnackBar Helper
  void showSnackBar(
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : colorScheme.primary,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
