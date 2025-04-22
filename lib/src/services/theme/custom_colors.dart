import 'package:flutter/material.dart';

import '../accessibility/accessibility_utils.dart';

/// Custom color extension for the app theme
/// Provides semantic colors like warning, info, success that can be accessed via theme
@immutable
class CustomColors extends ThemeExtension<CustomColors> {
  final Color warning;
  final Color warningContainer;
  final Color onWarning;
  final Color onWarningContainer;

  final Color info;
  final Color infoContainer;
  final Color onInfo;
  final Color onInfoContainer;

  final Color success;
  final Color successContainer;
  final Color onSuccess;
  final Color onSuccessContainer;

  final Color danger; // Alternative to error for when you need both
  final Color dangerContainer;
  final Color onDanger;
  final Color onDangerContainer;

  const CustomColors({
    required this.warning,
    required this.warningContainer,
    required this.onWarning,
    required this.onWarningContainer,
    required this.info,
    required this.infoContainer,
    required this.onInfo,
    required this.onInfoContainer,
    required this.success,
    required this.successContainer,
    required this.onSuccess,
    required this.onSuccessContainer,
    required this.danger,
    required this.dangerContainer,
    required this.onDanger,
    required this.onDangerContainer,
  });

  /// Create light theme custom colors
  factory CustomColors.light() {
    return const CustomColors(
      warning:
          Color(0xFFD84315), // Deep Orange 800 (darker for better contrast)
      warningContainer: Color(0xFFFFDBC8),
      onWarning: Colors.white,
      onWarningContainer: Color(0xFF3E2816),

      info: Color(0xFF0277BD), // Light Blue 800
      infoContainer: Color(0xFFCBE6FF),
      onInfo: Colors.white,
      onInfoContainer: Color(0xFF0E2436),

      success: Color(0xFF2E7D32), // Green 800
      successContainer: Color(0xFFB8F5B9),
      onSuccess: Colors.white,
      onSuccessContainer: Color(0xFF0E2416),

      danger: Color(0xFFC62828), // Red 800
      dangerContainer: Color(0xFFFFDAD6),
      onDanger: Colors.white,
      onDangerContainer: Color(0xFF3B1613),
    );
  }

  /// Create dark theme custom colors
  factory CustomColors.dark() {
    return const CustomColors(
      warning: Color(0xFFFF9E67), // Brighter Deep Orange for dark mode
      warningContainer: Color(0xFF853500),
      onWarning: Color(0xFF241505), // Darker for better contrast
      onWarningContainer: Color(0xFFFFF1E7),

      info: Color(0xFF82CFFF), // Lighter Light Blue
      infoContainer: Color(0xFF00497C),
      onInfo: Color(0xFF0A1A24),
      onInfoContainer: Color(0xFFE1F4FF),

      success: Color(0xFF7AE177), // Lighter Green
      successContainer: Color(0xFF1B5E1F),
      onSuccess: Color(0xFF0A1E0D),
      onSuccessContainer: Color(0xFFE4F9E3),

      danger: Color(0xFFFF8A85), // Lighter Red
      dangerContainer: Color(0xFF8F0A0A),
      onDanger: Color(0xFF1F0E0D), // Darker for better contrast
      onDangerContainer: Color(0xFFFFE9E7),
    );
  }

  /// Used by Flutter to interpolate between themes during transitions
  @override
  CustomColors copyWith({
    Color? warning,
    Color? warningContainer,
    Color? onWarning,
    Color? onWarningContainer,
    Color? info,
    Color? infoContainer,
    Color? onInfo,
    Color? onInfoContainer,
    Color? success,
    Color? successContainer,
    Color? onSuccess,
    Color? onSuccessContainer,
    Color? danger,
    Color? dangerContainer,
    Color? onDanger,
    Color? onDangerContainer,
  }) {
    return CustomColors(
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarning: onWarning ?? this.onWarning,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      info: info ?? this.info,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfo: onInfo ?? this.onInfo,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      onSuccess: onSuccess ?? this.onSuccess,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      danger: danger ?? this.danger,
      dangerContainer: dangerContainer ?? this.dangerContainer,
      onDanger: onDanger ?? this.onDanger,
      onDangerContainer: onDangerContainer ?? this.onDangerContainer,
    );
  }

  /// Used by Flutter to interpolate between themes during transitions
  @override
  CustomColors lerp(ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) {
      return this;
    }
    return CustomColors(
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer:
          Color.lerp(warningContainer, other.warningContainer, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      onWarningContainer:
          Color.lerp(onWarningContainer, other.onWarningContainer, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
      success: Color.lerp(success, other.success, t)!,
      successContainer:
          Color.lerp(successContainer, other.successContainer, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      onSuccessContainer:
          Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerContainer: Color.lerp(dangerContainer, other.dangerContainer, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
      onDangerContainer:
          Color.lerp(onDangerContainer, other.onDangerContainer, t)!,
    );
  }

  /// Helper method to get custom colors from BuildContext
  ///
  /// Returns null if the extension isn't found in the theme
  static CustomColors? maybeOf(BuildContext context) {
    return Theme.of(context).extension<CustomColors>();
  }

  /// Helper method to get custom colors from BuildContext
  ///
  /// Throws an exception if the extension isn't found in the theme
  static CustomColors of(BuildContext context) {
    final CustomColors? colors = maybeOf(context);
    assert(colors != null, 'No CustomColors found in Theme');
    return colors!;
  }

  /// Calculate the contrast ratio between two colors according to WCAG 2.0
  static double calculateContrastRatio(Color foreground, Color background) {
    return AccessibilityUtils.calculateContrastRatio(foreground, background);
  }

  /// Check if a color pair meets WCAG AA requirements for normal text (4.5:1)
  static bool isAccessibleText(Color foreground, Color background) {
    return AccessibilityUtils.meetsWCAG_AA_Text(foreground, background);
  }

  /// Check if a color pair meets WCAG AA requirements for large text (3:1)
  static bool isAccessibleLargeText(Color foreground, Color background) {
    return AccessibilityUtils.meetsWCAG_AA_LargeText(foreground, background);
  }

  /// Check if a color pair meets WCAG AAA requirements for normal text (7:1)
  static bool isAccessibleTextAAA(Color foreground, Color background) {
    return AccessibilityUtils.meetsWCAG_AAA_Text(foreground, background);
  }

  /// Check if a color pair meets WCAG AAA requirements for large text (4.5:1)
  static bool isAccessibleLargeTextAAA(Color foreground, Color background) {
    return AccessibilityUtils.meetsWCAG_AAA_LargeText(foreground, background);
  }

  /// Get a formatted string representation of the contrast ratio
  ///
  /// Example: "4.50:1"
  static String formatContrastRatio(double ratio, {int precision = 2}) {
    return AccessibilityUtils.formatContrastRatio(ratio, precision: precision);
  }

  /// Get a suggested foreground color that meets accessibility standards
  /// when used with the provided background color
  ///
  /// If the provided foreground color already meets standards, it's returned unchanged
  static Color getSuggestedAccessibleForeground(
      Color foreground, Color background,
      {bool forLargeText = false}) {
    return AccessibilityUtils.suggestAccessibleForegroundColor(
        foreground, background,
        forLargeText: forLargeText);
  }

  /// Check if all semantic color combinations in this theme meet WCAG AA standards
  ///
  /// Returns a map with color pair names and their compliance status
  Map<String, bool> checkAllColorCombinations({bool forLargeText = false}) {
    final Map<String, bool> results = {};

    // Check warning colors
    results['warning-onWarning'] = forLargeText
        ? isAccessibleLargeText(onWarning, warning)
        : isAccessibleText(onWarning, warning);

    results['warningContainer-onWarningContainer'] = forLargeText
        ? isAccessibleLargeText(onWarningContainer, warningContainer)
        : isAccessibleText(onWarningContainer, warningContainer);

    // Check info colors
    results['info-onInfo'] = forLargeText
        ? isAccessibleLargeText(onInfo, info)
        : isAccessibleText(onInfo, info);

    results['infoContainer-onInfoContainer'] = forLargeText
        ? isAccessibleLargeText(onInfoContainer, infoContainer)
        : isAccessibleText(onInfoContainer, infoContainer);

    // Check success colors
    results['success-onSuccess'] = forLargeText
        ? isAccessibleLargeText(onSuccess, success)
        : isAccessibleText(onSuccess, success);

    results['successContainer-onSuccessContainer'] = forLargeText
        ? isAccessibleLargeText(onSuccessContainer, successContainer)
        : isAccessibleText(onSuccessContainer, successContainer);

    // Check danger colors
    results['danger-onDanger'] = forLargeText
        ? isAccessibleLargeText(onDanger, danger)
        : isAccessibleText(onDanger, danger);

    results['dangerContainer-onDangerContainer'] = forLargeText
        ? isAccessibleLargeText(onDangerContainer, dangerContainer)
        : isAccessibleText(onDangerContainer, dangerContainer);

    return results;
  }

  /// Get a diagnostic report of all color combinations with their contrast ratios
  /// and WCAG compliance levels
  ///
  /// Useful for debugging and ensuring accessibility compliance
  Map<String, Map<String, dynamic>> getAccessibilityReport() {
    final Map<String, Map<String, dynamic>> report = {};

    // Function to create a report entry for a color pair
    Map<String, dynamic> createReportEntry(
        String name, Color foreground, Color background) {
      final double ratio = calculateContrastRatio(foreground, background);
      final String compliance =
          AccessibilityUtils.getContrastComplianceLevel(foreground, background);
      final String complianceLarge =
          AccessibilityUtils.getContrastComplianceLevel(foreground, background,
              isLargeText: true);

      return {
        'ratio': ratio,
        'formatted_ratio': formatContrastRatio(ratio),
        'normal_text_compliance': compliance,
        'large_text_compliance': complianceLarge,
      };
    }

    // Add all color combinations to the report
    report['warning-onWarning'] =
        createReportEntry('Warning', onWarning, warning);
    report['warningContainer-onWarningContainer'] = createReportEntry(
        'Warning Container', onWarningContainer, warningContainer);

    report['info-onInfo'] = createReportEntry('Info', onInfo, info);
    report['infoContainer-onInfoContainer'] =
        createReportEntry('Info Container', onInfoContainer, infoContainer);

    report['success-onSuccess'] =
        createReportEntry('Success', onSuccess, success);
    report['successContainer-onSuccessContainer'] = createReportEntry(
        'Success Container', onSuccessContainer, successContainer);

    report['danger-onDanger'] = createReportEntry('Danger', onDanger, danger);
    report['dangerContainer-onDangerContainer'] = createReportEntry(
        'Danger Container', onDangerContainer, dangerContainer);

    return report;
  }

  /// Create a new CustomColors instance with automatically adjusted colors
  /// to ensure all color combinations meet WCAG AA accessibility standards
  ///
  /// Only adjusts foreground colors that don't meet standards
  CustomColors withAccessibleColors({bool forLargeText = false}) {
    // Helper function to get accessible foreground if needed
    Color getAccessibleForeground(Color foreground, Color background) {
      final bool isAccessible = forLargeText
          ? isAccessibleLargeText(foreground, background)
          : isAccessibleText(foreground, background);

      return isAccessible
          ? foreground
          : getSuggestedAccessibleForeground(foreground, background,
              forLargeText: forLargeText);
    }

    return CustomColors(
      // Keep background colors the same, adjust foreground colors if needed
      warning: warning,
      warningContainer: warningContainer,
      onWarning: getAccessibleForeground(onWarning, warning),
      onWarningContainer:
          getAccessibleForeground(onWarningContainer, warningContainer),

      info: info,
      infoContainer: infoContainer,
      onInfo: getAccessibleForeground(onInfo, info),
      onInfoContainer: getAccessibleForeground(onInfoContainer, infoContainer),

      success: success,
      successContainer: successContainer,
      onSuccess: getAccessibleForeground(onSuccess, success),
      onSuccessContainer:
          getAccessibleForeground(onSuccessContainer, successContainer),

      danger: danger,
      dangerContainer: dangerContainer,
      onDanger: getAccessibleForeground(onDanger, danger),
      onDangerContainer:
          getAccessibleForeground(onDangerContainer, dangerContainer),
    );
  }
}
