import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'custom_colors.dart';

// --- Constants ---
const String _kThemeKey = 'theme_mode';
const String _kPreferencesBox = 'preferences';
const Color _kDefaultSeedColor = Colors.blue;

// --- Providers ---

/// Provides the current [ThemeMode] and allows changing it.
/// Persists the selected theme mode locally using Hive.
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  return ThemeModeNotifier();
});

/// Provider for theme with automatic accessibility corrections
/// This can be used when you want to ensure all colors meet WCAG standards
final accessibleThemeProvider = Provider<ThemeData>((ref) {
  final themeMode = ref.watch(themeModeProvider);
  final ThemeData baseTheme =
      themeMode == ThemeMode.dark ? getDarkTheme() : getLightTheme();

  return getAccessibleTheme(baseTheme);
});

// --- Notifier ---

/// Manages the application's [ThemeMode] state.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  /// Creates a [ThemeModeNotifier] and loads the saved theme.
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  /// Loads the saved theme mode from local storage.
  Future<void> _loadTheme() async {
    try {
      final Box<dynamic> box = await Hive.openBox<dynamic>(_kPreferencesBox);
      final String? savedTheme = box.get(_kThemeKey) as String?;
      if (savedTheme != null) {
        state = _themeModeFromString(savedTheme);
      }
    } catch (e) {
      // Handle potential Hive errors (e.g., initialization issues)
      debugPrint('Error loading theme from Hive: $e');
      // Keep default state (ThemeMode.system)
    }
  }

  /// Sets the application's theme mode and saves it locally.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (state == mode) return; // Avoid unnecessary updates and writes

    state = mode;
    try {
      final Box<dynamic> box = await Hive.openBox<dynamic>(_kPreferencesBox);
      await box.put(_kThemeKey, mode.toString());
    } catch (e) {
      // Handle potential Hive errors
      debugPrint('Error saving theme to Hive: $e');
    }
  }

  /// Converts a string representation back to a [ThemeMode].
  ThemeMode _themeModeFromString(String themeString) =>
      ThemeMode.values.firstWhere(
        (mode) => mode.toString() == themeString,
        orElse: () => ThemeMode.system, // Default to system if parsing fails
      );
}

// --- Theme Data Definitions ---

/// Returns the light theme configuration for the app.
///
/// Uses the provided [lightColorScheme] if available (e.g., from dynamic colors),
/// otherwise generates a scheme from the [_kDefaultSeedColor].
ThemeData getLightTheme([ColorScheme? lightColorScheme]) {
  final ColorScheme scheme = lightColorScheme ??
      ColorScheme.fromSeed(
        seedColor: _kDefaultSeedColor,
        brightness: Brightness.light,
      );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    // Add additional light theme customizations based on the scheme if needed
    // Example: appBarTheme, textTheme, etc.
    extensions: [
      CustomColors.light(),
    ],
  );
}

/// Returns the dark theme configuration for the app.
///
/// Uses the provided [darkColorScheme] if available (e.g., from dynamic colors),
/// otherwise generates a scheme from the [_kDefaultSeedColor].
ThemeData getDarkTheme([ColorScheme? darkColorScheme]) {
  final ColorScheme scheme = darkColorScheme ??
      ColorScheme.fromSeed(
        seedColor: _kDefaultSeedColor,
        brightness: Brightness.dark,
      );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    // Add additional dark theme customizations based on the scheme if needed
    // Example: appBarTheme, textTheme, etc.
    extensions: [
      CustomColors.dark(),
    ],
  );
}

/// Creates a version of the theme with accessible colors
///
/// Takes a base theme and ensures all custom colors meet WCAG AA standards
/// for normal text (4.5:1 contrast ratio)
ThemeData getAccessibleTheme(ThemeData baseTheme) {
  final CustomColors? customColors = baseTheme.extension<CustomColors>();
  if (customColors == null) {
    return baseTheme;
  }

  // Create a version of CustomColors with accessible colors
  final CustomColors accessibleColors = customColors.withAccessibleColors();

  // Return a new theme with the accessible colors
  return baseTheme.copyWith(
    extensions: <ThemeExtension<dynamic>>[
      accessibleColors,
    ],
  );
}

/// Utility method to verify the accessibility of all theme colors
///
/// Returns a report with contrast ratios and compliance levels
/// If fixIssues is true, it will also return a new theme with fixed colors
Map<String, dynamic> verifyThemeAccessibility(
  ThemeData theme, {
  bool fixIssues = false,
}) {
  final CustomColors? customColors = theme.extension<CustomColors>();
  if (customColors == null) {
    return {
      'status': 'error',
      'message': 'No CustomColors found in theme',
    };
  }

  // Get accessibility report for all color combinations
  final Map<String, Map<String, dynamic>> report =
      customColors.getAccessibilityReport();

  // Check if any color fails WCAG AA standard
  bool hasIssues = false;
  final List<String> failingPairs = [];

  report.forEach((key, data) {
    if (data['normal_text_compliance'] == 'Fail') {
      hasIssues = true;
      failingPairs.add(key);
    }
  });

  // If requested and there are issues, create a fixed theme
  ThemeData? fixedTheme;
  if (fixIssues && hasIssues) {
    fixedTheme = getAccessibleTheme(theme);
  }

  return {
    'status': hasIssues ? 'issues_found' : 'all_passed',
    'failing_pairs': failingPairs,
    'detailed_report': report,
    'fixed_theme': fixedTheme,
  };
}
