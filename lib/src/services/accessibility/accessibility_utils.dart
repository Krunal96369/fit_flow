import 'dart:math';

import 'package:flutter/material.dart';

/// Utility class for accessibility-related functions
/// Contains methods for calculating color contrast and checking WCAG compliance
class AccessibilityUtils {
  // WCAG contrast ratio standards
  static const double kMinimumContrastAA =
      4.5; // Normal text (smaller than 18pt)
  static const double kMinimumContrastAALarge =
      3.0; // Large text (at least 18pt or 14pt bold)
  static const double kMinimumContrastAAA = 7.0; // Normal text (enhanced)
  static const double kMinimumContrastAAALarge = 4.5; // Large text (enhanced)

  /// Calculate the relative luminance of a color according to WCAG 2.0
  ///
  /// Relative luminance is the relative brightness of a color,
  /// normalized to 0 for black and 1 for white.
  /// Formula from: https://www.w3.org/TR/WCAG20/#relativeluminancedef
  static double calculateRelativeLuminance(Color color) {
    // Convert RGB to sRGB
    final List<double> sRGB = [
      color.r / 255.0,
      color.g / 255.0,
      color.b / 255.0
    ];

    // Convert sRGB to linear RGB values
    final List<double> linearRGB = sRGB.map((channel) {
      return channel <= 0.03928
          ? channel / 12.92
          : pow((channel + 0.055) / 1.055, 2.4).toDouble();
    }).toList();

    // Calculate luminance using the formula
    // L = 0.2126 * R + 0.7152 * G + 0.0722 * B
    return 0.2126 * linearRGB[0] +
        0.7152 * linearRGB[1] +
        0.0722 * linearRGB[2];
  }

  /// Calculate the contrast ratio between two colors according to WCAG 2.0
  ///
  /// Returns a value from 1 to 21
  /// 1:1 = no contrast (same color)
  /// 21:1 = max contrast (black on white)
  /// Formula from: https://www.w3.org/TR/WCAG20/#contrast-ratiodef
  static double calculateContrastRatio(Color foreground, Color background) {
    final double foregroundLuminance = calculateRelativeLuminance(foreground);
    final double backgroundLuminance = calculateRelativeLuminance(background);

    // Ensure lighter color is first in the formula
    final double lighter = max(foregroundLuminance, backgroundLuminance);
    final double darker = min(foregroundLuminance, backgroundLuminance);

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Check if colors meet WCAG AA requirements for normal text
  ///
  /// Text is considered accessible at AA level if the contrast ratio
  /// is at least 4.5:1 for normal text
  static bool meetsWCAG_AA_Text(Color foreground, Color background) {
    return calculateContrastRatio(foreground, background) >= kMinimumContrastAA;
  }

  /// Check if colors meet WCAG AA requirements for large text
  ///
  /// Large text is at least 18pt, or 14pt bold
  /// Text is considered accessible at AA level if the contrast ratio
  /// is at least 3:1 for large text
  static bool meetsWCAG_AA_LargeText(Color foreground, Color background) {
    return calculateContrastRatio(foreground, background) >=
        kMinimumContrastAALarge;
  }

  /// Check if colors meet WCAG AAA requirements for normal text
  ///
  /// Text is considered accessible at AAA level if the contrast ratio
  /// is at least 7:1 for normal text
  static bool meetsWCAG_AAA_Text(Color foreground, Color background) {
    return calculateContrastRatio(foreground, background) >=
        kMinimumContrastAAA;
  }

  /// Check if colors meet WCAG AAA requirements for large text
  ///
  /// Large text is at least 18pt, or 14pt bold
  /// Text is considered accessible at AAA level if the contrast ratio
  /// is at least 4.5:1 for large text
  static bool meetsWCAG_AAA_LargeText(Color foreground, Color background) {
    return calculateContrastRatio(foreground, background) >=
        kMinimumContrastAAALarge;
  }

  /// Determine the WCAG compliance level for a color pair
  ///
  /// Returns one of the following:
  /// - "AAA" - meets AAA requirements
  /// - "AA" - meets AA requirements
  /// - "Fail" - does not meet minimum requirements
  static String getContrastComplianceLevel(Color foreground, Color background,
      {bool isLargeText = false}) {
    final double ratio = calculateContrastRatio(foreground, background);

    if (isLargeText) {
      if (ratio >= kMinimumContrastAAALarge) return 'AAA';
      if (ratio >= kMinimumContrastAALarge) return 'AA';
    } else {
      if (ratio >= kMinimumContrastAAA) return 'AAA';
      if (ratio >= kMinimumContrastAA) return 'AA';
    }

    return 'Fail';
  }

  /// Suggest an adjusted color to meet contrast requirements
  ///
  /// This is a simple implementation that adjusts the brightness
  /// of the foreground color to meet minimum contrast requirements
  static Color suggestAccessibleForegroundColor(
      Color foreground, Color background,
      {bool forLargeText = false}) {
    final double ratio = calculateContrastRatio(foreground, background);
    final double targetRatio =
        forLargeText ? kMinimumContrastAALarge : kMinimumContrastAA;

    if (ratio >= targetRatio) {
      return foreground; // Already meets requirements
    }

    // Determine if we should lighten or darken the foreground
    final double bgLuminance = calculateRelativeLuminance(background);
    final bool shouldLighten = bgLuminance < 0.5;

    Color adjustedColor = foreground;
    double currentRatio = ratio;

    // Step size for color adjustment
    const double step = 0.05;

    // Maximum iterations to prevent infinite loop
    const int maxIterations = 20;
    int iterations = 0;

    // Adjust until we meet the target ratio or reach max iterations
    while (currentRatio < targetRatio && iterations < maxIterations) {
      if (shouldLighten) {
        // Lighten the color
        adjustedColor = Color.fromARGB(
          adjustedColor.alpha,
          min(255, adjustedColor.r + (255 - adjustedColor.r) * step).round(),
          min(255, adjustedColor.g + (255 - adjustedColor.g) * step).round(),
          min(255, adjustedColor.b + (255 - adjustedColor.b) * step).round(),
        );
      } else {
        // Darken the color
        adjustedColor = Color.fromARGB(
          adjustedColor.alpha,
          max(0, adjustedColor.r - adjustedColor.r * step).round(),
          max(0, adjustedColor.g - adjustedColor.g * step).round(),
          max(0, adjustedColor.b - adjustedColor.b * step).round(),
        );
      }

      currentRatio = calculateContrastRatio(adjustedColor, background);
      iterations++;
    }

    return adjustedColor;
  }

  /// Format contrast ratio as a string with fixed precision
  static String formatContrastRatio(double ratio, {int precision = 2}) {
    return '${ratio.toStringAsFixed(precision)}:1';
  }
}
