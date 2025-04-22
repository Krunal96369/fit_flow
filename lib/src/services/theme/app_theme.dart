import 'dart:math';

import 'package:flutter/material.dart';

class AppTheme {
  // Light theme colors
  static const Color lightPrimary = Color(0xFF2196F3);
  static const Color lightSecondary = Color(0xFF4CAF50);
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF212121);
  static const Color lightError = Color(0xFFB00020);

  // Dark theme colors
  static const Color darkPrimary = Color(0xFF64B5F6);
  static const Color darkSecondary = Color(0xFF81C784);
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkText = Color(0xFFEEEEEE);
  static const Color darkError = Color(0xFFCF6679);

  // Theme data
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: lightPrimary,
    colorScheme: const ColorScheme.light(
      primary: lightPrimary,
      secondary: lightSecondary,
      surface: lightSurface,
      error: lightError,
    ),
    scaffoldBackgroundColor: lightBackground,
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: darkPrimary,
    colorScheme: const ColorScheme.dark(
      primary: darkPrimary,
      secondary: darkSecondary,
      surface: darkSurface,
      error: darkError,
    ),
    scaffoldBackgroundColor: darkBackground,
  );

  // Color contrast utilities
  static double calculateContrastRatio(Color foreground, Color background) {
    // Calculate relative luminance for both colors
    double l1 = _calculateRelativeLuminance(foreground);
    double l2 = _calculateRelativeLuminance(background);

    // Calculate contrast ratio
    // (L1 + 0.05) / (L2 + 0.05) where L1 is the lighter color and L2 is the darker color
    double lighterL = max(l1, l2);
    double darkerL = min(l1, l2);

    return (lighterL + 0.05) / (darkerL + 0.05);
  }

  static double _calculateRelativeLuminance(Color color) {
    // Convert RGB to linear values
    double r = _linearizeColorChannel(color.red / 255);
    double g = _linearizeColorChannel(color.green / 255);
    double b = _linearizeColorChannel(color.blue / 255);

    // Calculate relative luminance
    // L = 0.2126 * R + 0.7152 * G + 0.0722 * B
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  static double _linearizeColorChannel(double value) {
    return value <= 0.03928
        ? value / 12.92
        : pow((value + 0.055) / 1.055, 2.4).toDouble();
  }

  // WCAG standards
  static const double minimumAARatio = 4.5; // Normal text
  static const double minimumAARatioLarge =
      3.0; // Large text (18pt or 14pt bold)
  static const double minimumAAARatio = 7.0; // Enhanced contrast

  // Color accessibility checks
  static bool passesAA(double contrastRatio, {bool isLargeText = false}) {
    return isLargeText
        ? contrastRatio >= minimumAARatioLarge
        : contrastRatio >= minimumAARatio;
  }

  static bool passesAAA(double contrastRatio, {bool isLargeText = false}) {
    return isLargeText
        ? contrastRatio >= minimumAARatio
        : contrastRatio >= minimumAAARatio;
  }

  static String getContrastLevel(double contrastRatio,
      {bool isLargeText = false}) {
    if (passesAAA(contrastRatio, isLargeText: isLargeText)) {
      return 'AAA';
    } else if (passesAA(contrastRatio, isLargeText: isLargeText)) {
      return 'AA';
    } else {
      return 'Fail';
    }
  }

  // Sample color pairs for demonstration
  static List<Map<String, dynamic>> getSampleColorPairs(bool isDarkMode) {
    if (isDarkMode) {
      return [
        {
          'name': 'Primary on Surface',
          'foreground': darkPrimary,
          'background': darkSurface,
          'isLargeText': false,
        },
        {
          'name': 'Secondary on Surface',
          'foreground': darkSecondary,
          'background': darkSurface,
          'isLargeText': false,
        },
        {
          'name': 'Text on Background',
          'foreground': darkText,
          'background': darkBackground,
          'isLargeText': false,
        },
        {
          'name': 'Error on Surface',
          'foreground': darkError,
          'background': darkSurface,
          'isLargeText': false,
        },
      ];
    } else {
      return [
        {
          'name': 'Primary on Surface',
          'foreground': lightPrimary,
          'background': lightSurface,
          'isLargeText': false,
        },
        {
          'name': 'Secondary on Surface',
          'foreground': lightSecondary,
          'background': lightSurface,
          'isLargeText': false,
        },
        {
          'name': 'Text on Background',
          'foreground': lightText,
          'background': lightBackground,
          'isLargeText': false,
        },
        {
          'name': 'Error on Surface',
          'foreground': lightError,
          'background': lightSurface,
          'isLargeText': false,
        },
      ];
    }
  }
}
