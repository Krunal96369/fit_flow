# Accessibility Utilities Usage Guide

This document provides examples of how to use the enhanced accessibility utilities in the FitFlow app.

## CustomColors Accessibility Methods

### Basic Contrast Checking

```dart
// Check if text meets WCAG AA standards
bool isAccessible = CustomColors.isAccessibleText(textColor, backgroundColor);

// Check if large text meets WCAG AA standards
bool isAccessibleLargeText = CustomColors.isAccessibleLargeText(textColor, backgroundColor);

// Calculate contrast ratio between two colors
double contrastRatio = CustomColors.calculateContrastRatio(textColor, backgroundColor);

// Format contrast ratio as a string
String formattedRatio = CustomColors.formatContrastRatio(contrastRatio); // "4.50:1"
```

### Advanced Accessibility Utilities

```dart
// Get a suggested foreground color that meets accessibility standards
Color accessibleColor = CustomColors.getSuggestedAccessibleForeground(
  textColor,
  backgroundColor,
  forLargeText: false, // Set to true for large text (18pt+)
);

// Instance methods on CustomColors
final customColors = CustomColors.of(context);

// Check all color combinations in the theme for accessibility
Map<String, bool> accessibilityResults = customColors.checkAllColorCombinations();

// Get a detailed report of all color combinations with contrast ratios and compliance levels
Map<String, Map<String, dynamic>> report = customColors.getAccessibilityReport();

// Create a new CustomColors instance with automatically adjusted colors to ensure accessibility
CustomColors accessibleColors = customColors.withAccessibleColors();
```

## Theme Accessibility

The `theme_service.dart` file provides utilities for verifying and fixing theme accessibility:

```dart
// Using the verifyThemeAccessibility function
Map<String, dynamic> accessibilityCheck = verifyThemeAccessibility(
  theme,
  fixIssues: true, // Set to true to get a fixed theme
);

// Check results
if (accessibilityCheck['status'] == 'issues_found') {
  List<String> failingPairs = accessibilityCheck['failing_pairs'];
  ThemeData fixedTheme = accessibilityCheck['fixed_theme'];
  // Use the fixed theme...
}

// Using the accessibleThemeProvider with Riverpod
// This will automatically provide an accessible version of the current theme
final accessibleTheme = ref.watch(accessibleThemeProvider);
```

## Integration with Theme System

To automatically provide an accessible theme in your app:

```dart
// In your MaterialApp
return MaterialApp(
  theme: themeMode == ThemeMode.light
    ? getLightTheme()
    : getDarkTheme(),
  // For users who need accessible colors, use:
  // theme: getAccessibleTheme(getLightTheme()),
  // darkTheme: getAccessibleTheme(getDarkTheme()),
  themeMode: themeMode,
  // ...
);

// Or with Riverpod:
return Consumer(
  builder: (context, ref, _) {
    final useAccessibleColors = ref.watch(accessibilitySettingsProvider).useAccessibleColors;
    final themeMode = ref.watch(themeModeProvider);

    final theme = useAccessibleColors
      ? ref.watch(accessibleThemeProvider)
      : (themeMode == ThemeMode.dark ? getDarkTheme() : getLightTheme());

    return MaterialApp(
      theme: theme,
      // ...
    );
  }
);
```

## Performing Accessibility Checks in Development

During development, you can check your theme's accessibility with:

```dart
void checkThemeAccessibility() {
  final lightTheme = getLightTheme();
  final darkTheme = getDarkTheme();

  final lightCheck = verifyThemeAccessibility(lightTheme);
  final darkCheck = verifyThemeAccessibility(darkTheme);

  print('Light theme: ${lightCheck['status']}');
  print('Dark theme: ${darkCheck['status']}');

  if (lightCheck['status'] == 'issues_found') {
    print('Light theme has ${lightCheck['failing_pairs'].length} failing pairs');
  }

  if (darkCheck['status'] == 'issues_found') {
    print('Dark theme has ${darkCheck['failing_pairs'].length} failing pairs');
  }
}
```

## Best Practices

1. **Always check foreground/background combinations**: Ensure all text has sufficient contrast with its background.
2. **Consider both normal and large text**: WCAG standards have different requirements based on text size.
3. **Test in both light and dark themes**: Colors that work well in one theme may fail in another.
4. **Use the automatic fixing utilities**: Instead of manually adjusting colors, use the `withAccessibleColors()` method.
5. **Include accessibility checks in your testing**: Verify that your UI meets accessibility standards as part of your testing process.
