import 'package:flutter/material.dart';

import 'custom_colors.dart';

/// Utility class to check color accessibility throughout the app
/// This helps developers ensure that all colors meet WCAG contrast requirements
class ColorAccessibilityChecker {
  /// Checks all semantic colors against text colors and returns any issues
  static List<AccessibilityIssue> checkThemeColors(ThemeData theme) {
    final issues = <AccessibilityIssue>[];
    final customColors = theme.extension<CustomColors>();

    if (customColors == null) {
      return [
        AccessibilityIssue(
          foreground: Colors.black,
          background: Colors.white,
          description: 'CustomColors extension not found in theme',
          contrastRatio: 21.0,
          isError: true,
        )
      ];
    }

    // Check primary semantic colors with on-colors
    _checkColorPair(
        issues, 'warning', customColors.warning, customColors.onWarning);
    _checkColorPair(issues, 'warningContainer', customColors.warningContainer,
        customColors.onWarningContainer);
    _checkColorPair(issues, 'info', customColors.info, customColors.onInfo);
    _checkColorPair(issues, 'infoContainer', customColors.infoContainer,
        customColors.onInfoContainer);
    _checkColorPair(
        issues, 'success', customColors.success, customColors.onSuccess);
    _checkColorPair(issues, 'successContainer', customColors.successContainer,
        customColors.onSuccessContainer);
    _checkColorPair(
        issues, 'danger', customColors.danger, customColors.onDanger);
    _checkColorPair(issues, 'dangerContainer', customColors.dangerContainer,
        customColors.onDangerContainer);

    // Check against Material theme colors
    _checkColorPair(issues, 'primary', theme.colorScheme.primary,
        theme.colorScheme.onPrimary);
    _checkColorPair(issues, 'secondary', theme.colorScheme.secondary,
        theme.colorScheme.onSecondary);
    _checkColorPair(issues, 'surface', theme.colorScheme.surface,
        theme.colorScheme.onSurface);
    _checkColorPair(issues, 'background', theme.colorScheme.surface,
        theme.colorScheme.onSurface);
    _checkColorPair(
        issues, 'error', theme.colorScheme.error, theme.colorScheme.onError);

    return issues;
  }

  /// Add issues for a specific color pair if they don't meet accessibility requirements
  static void _checkColorPair(List<AccessibilityIssue> issues, String colorName,
      Color background, Color foreground) {
    final contrastRatio =
        CustomColors.calculateContrastRatio(foreground, background);
    final isNormalTextAccessible =
        CustomColors.isAccessibleText(foreground, background);
    final isLargeTextAccessible =
        CustomColors.isAccessibleLargeText(foreground, background);

    if (!isNormalTextAccessible) {
      issues.add(AccessibilityIssue(
        foreground: foreground,
        background: background,
        description:
            '$colorName: Fails normal text contrast (${contrastRatio.toStringAsFixed(2)}:1)',
        contrastRatio: contrastRatio,
        isError: !isLargeTextAccessible,
      ));
    } else if (!isLargeTextAccessible) {
      // Should never happen since large text requirement is lower
      issues.add(AccessibilityIssue(
        foreground: foreground,
        background: background,
        description: '$colorName: Unusual contrast issue',
        contrastRatio: contrastRatio,
        isError: true,
      ));
    }
  }

  /// Generate an accessibility report as a string
  static String generateReport(BuildContext context) {
    final lightTheme = Theme.of(context).brightness == Brightness.light
        ? Theme.of(context)
        : Theme.of(context).copyWith(brightness: Brightness.light);

    final darkTheme = Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context)
        : Theme.of(context).copyWith(brightness: Brightness.dark);

    final lightIssues = checkThemeColors(lightTheme);
    final darkIssues = checkThemeColors(darkTheme);

    final buffer = StringBuffer();
    buffer.writeln('=== ACCESSIBILITY REPORT ===');

    buffer.writeln('\nLIGHT THEME ISSUES: ${lightIssues.length}');
    for (final issue in lightIssues) {
      buffer.writeln(
          '- ${issue.description} (${issue.isError ? 'ERROR' : 'WARNING'})');
    }

    buffer.writeln('\nDARK THEME ISSUES: ${darkIssues.length}');
    for (final issue in darkIssues) {
      buffer.writeln(
          '- ${issue.description} (${issue.isError ? 'ERROR' : 'WARNING'})');
    }

    return buffer.toString();
  }

  /// Show a dialog with accessibility issues
  static Future<void> showAccessibilityReport(BuildContext context) async {
    final report = generateReport(context);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Accessibility Report'),
        content: SingleChildScrollView(
          child: Text(report),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Represents an accessibility issue with color contrast
class AccessibilityIssue {
  final Color foreground;
  final Color background;
  final String description;
  final double contrastRatio;
  final bool isError;

  AccessibilityIssue({
    required this.foreground,
    required this.background,
    required this.description,
    required this.contrastRatio,
    required this.isError,
  });
}
