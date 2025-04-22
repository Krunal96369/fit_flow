import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider_pkg;

import '../../services/theme/custom_colors.dart';
import '../../services/theme/theme_provider.dart';
import '../../services/theme/theme_service.dart';

/// A demo screen showing the accessibility checker in action
class AccessibilityDemoScreen extends ConsumerWidget {
  const AccessibilityDemoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeProvider = provider_pkg.Provider.of<ThemeProvider>(context);
    final customColors = CustomColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    // Use current theme
    final currentTheme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accessibility Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.assessment),
            tooltip: 'Check Accessibility',
            onPressed: () {
              _showAccessibilityReport(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.auto_fix_high),
            tooltip: 'Auto-fix Accessibility Issues',
            onPressed: () {
              _showAutoFixDialog(context, currentTheme);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Color Contrast Demo',
              style: textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'WCAG Guidelines recommend:',
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('• At least 4.5:1 contrast ratio for normal text (AA)',
                style: textTheme.bodyMedium),
            Text('• At least 3:1 contrast ratio for large text (AA)',
                style: textTheme.bodyMedium),
            Text('• At least 7:1 contrast ratio for normal text (AAA)',
                style: textTheme.bodyMedium),
            Text('• At least 4.5:1 contrast ratio for large text (AAA)',
                style: textTheme.bodyMedium),
            const SizedBox(height: 24),

            // New accessibility compliance summary card
            _buildAccessibilitySummaryCard(context, customColors),

            const SizedBox(height: 24),
            Text(
              'Color Samples',
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // Primary colors
            _buildColorCard(
              context: context,
              title: 'Primary on Background',
              foreground: Theme.of(context).colorScheme.primary,
              background: Theme.of(context).colorScheme.surface,
            ),
            _buildColorCard(
              context: context,
              title: 'On Primary on Primary',
              foreground: Theme.of(context).colorScheme.onPrimary,
              background: Theme.of(context).colorScheme.primary,
            ),

            // Secondary colors
            _buildColorCard(
              context: context,
              title: 'Secondary on Background',
              foreground: Theme.of(context).colorScheme.secondary,
              background: Theme.of(context).colorScheme.surface,
            ),
            _buildColorCard(
              context: context,
              title: 'On Secondary on Secondary',
              foreground: Theme.of(context).colorScheme.onSecondary,
              background: Theme.of(context).colorScheme.secondary,
            ),

            // Custom colors
            _buildColorCard(
              context: context,
              title: 'Warning on Background',
              foreground: customColors.warning,
              background: Theme.of(context).colorScheme.surface,
            ),
            _buildColorCard(
              context: context,
              title: 'On Warning on Warning',
              foreground: customColors.onWarning,
              background: customColors.warning,
            ),

            _buildColorCard(
              context: context,
              title: 'Success on Background',
              foreground: customColors.success,
              background: Theme.of(context).colorScheme.surface,
            ),
            _buildColorCard(
              context: context,
              title: 'On Success on Success',
              foreground: customColors.onSuccess,
              background: customColors.success,
            ),

            _buildColorCard(
              context: context,
              title: 'Danger on Background',
              foreground: customColors.danger,
              background: Theme.of(context).colorScheme.surface,
            ),
            _buildColorCard(
              context: context,
              title: 'On Danger on Danger',
              foreground: customColors.onDanger,
              background: customColors.danger,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Toggle Theme',
        child: Icon(
          themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
        ),
        onPressed: () {
          themeProvider.toggleTheme();
        },
      ),
    );
  }

  /// Build a summary card showing overall accessibility compliance
  Widget _buildAccessibilitySummaryCard(
      BuildContext context, CustomColors customColors) {
    final report = customColors.checkAllColorCombinations();
    final totalChecks = report.length;
    final passCount = report.values.where((passes) => passes).length;
    final passPercentage = (passCount / totalChecks * 100).round();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Accessibility Compliance Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$passCount of $totalChecks checks pass',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '$passPercentage%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: passPercentage >= 100
                        ? Colors.green
                        : passPercentage >= 80
                            ? Colors.orange
                            : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: passCount / totalChecks,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                passPercentage >= 100
                    ? Colors.green
                    : passPercentage >= 80
                        ? Colors.orange
                        : Colors.red,
              ),
              minHeight: 10,
            ),
            const SizedBox(height: 16),
            Text(
              passPercentage >= 100
                  ? 'All color combinations meet WCAG AA standards!'
                  : passPercentage >= 80
                      ? 'Most color combinations meet WCAG AA standards.'
                      : 'Several color combinations fail WCAG AA standards.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (passPercentage < 100) ...[
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('View & Fix Issues'),
                onPressed: () {
                  _showAccessibilityReport(context);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildColorCard({
    required BuildContext context,
    required String title,
    required Color foreground,
    required Color background,
  }) {
    final contrastRatio =
        CustomColors.calculateContrastRatio(foreground, background);
    final meetsAA = CustomColors.isAccessibleText(foreground, background);
    final meetsAALargeText =
        CustomColors.isAccessibleLargeText(foreground, background);
    final meetsAAA = CustomColors.isAccessibleTextAAA(foreground, background);
    final meetsAAALargeText =
        CustomColors.isAccessibleLargeTextAAA(foreground, background);

    // Format contrast ratio as string
    final formattedRatio = CustomColors.formatContrastRatio(contrastRatio);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(title, style: Theme.of(context).textTheme.titleSmall),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: background,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sample Normal Text',
                  style: TextStyle(
                    color: foreground,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sample Large Text (18px)',
                  style: TextStyle(
                    color: foreground,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Contrast Ratio:'),
                    Text(formattedRatio),
                  ],
                ),
                const SizedBox(height: 8),
                _buildAccessibilityStatus('AA (Normal Text)', meetsAA),
                _buildAccessibilityStatus('AA (Large Text)', meetsAALargeText),
                _buildAccessibilityStatus('AAA (Normal Text)', meetsAAA),
                _buildAccessibilityStatus(
                    'AAA (Large Text)', meetsAAALargeText),
              ],
            ),
          ),
          if (!meetsAA)
            Padding(
              padding:
                  const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
              child: Row(
                children: [
                  const Icon(Icons.auto_fix_high,
                      size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    'Suggested Accessible Alternative:',
                    style: TextStyle(color: Colors.orange),
                  ),
                ],
              ),
            ),
          if (!meetsAA)
            _buildSuggestedAlternative(context, foreground, background),
        ],
      ),
    );
  }

  /// Build a preview of suggested accessible alternative
  Widget _buildSuggestedAlternative(
      BuildContext context, Color foreground, Color background) {
    // Get a suggested accessible foreground color
    final suggestedForeground =
        CustomColors.getSuggestedAccessibleForeground(foreground, background);

    // Calculate the new contrast ratio
    final newRatio =
        CustomColors.calculateContrastRatio(suggestedForeground, background);

    return Container(
      padding: const EdgeInsets.all(16),
      color: background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suggested Alternative Text',
            style: TextStyle(
              color: suggestedForeground,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'New Contrast Ratio: ${CustomColors.formatContrastRatio(newRatio)}',
            style: TextStyle(
              color: suggestedForeground,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessibilityStatus(String label, bool passes) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Row(
          children: [
            Icon(
              passes ? Icons.check_circle : Icons.cancel,
              color: passes ? Colors.green : Colors.red,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(passes ? 'Passes' : 'Fails'),
          ],
        ),
      ],
    );
  }

  void _showAccessibilityReport(BuildContext context) {
    final customColors = CustomColors.of(context);
    final theme = Theme.of(context);

    // Get detailed accessibility report
    final accessibilityReport = customColors.getAccessibilityReport();

    // Calculate overall stats
    int passCount = 0;
    int totalChecks = 0;

    // Prepare data for the report
    final List<MapEntry<String, Map<String, dynamic>>> sortedEntries =
        accessibilityReport.entries.toList()
          ..sort((a, b) => (a.value['ratio'] as double)
              .compareTo(b.value['ratio'] as double));

    for (final entry in accessibilityReport.entries) {
      final compliance = entry.value['normal_text_compliance'] as String;
      if (compliance != 'Fail') passCount++;
      totalChecks++;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accessibility Report'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(
                '$passCount of $totalChecks color combinations meet WCAG AA standards for normal text.',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Failing Color Combinations:'),
              const SizedBox(height: 8),
              ...sortedEntries
                  .where((entry) =>
                      entry.value['normal_text_compliance'] == 'Fail')
                  .map((entry) {
                final ratio = entry.value['ratio'] as double;
                final formattedRatio = entry.value['formatted_ratio'] as String;

                return ListTile(
                  title: Text(entry.key),
                  subtitle: Text('Contrast Ratio: $formattedRatio'),
                  trailing: Icon(
                    Icons.cancel,
                    color: Colors.red,
                  ),
                  dense: true,
                );
              }),
              if (sortedEntries
                  .where((entry) =>
                      entry.value['normal_text_compliance'] == 'Fail')
                  .isEmpty)
                const Text('All color combinations pass! 🎉'),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('CLOSE'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          if (sortedEntries
              .where((entry) => entry.value['normal_text_compliance'] == 'Fail')
              .isNotEmpty)
            ElevatedButton(
              child: const Text('AUTO-FIX ISSUES'),
              onPressed: () {
                Navigator.of(context).pop();
                _showAutoFixDialog(context, theme);
              },
            ),
        ],
      ),
    );
  }

  void _showAutoFixDialog(BuildContext context, ThemeData currentTheme) {
    // Use the verifyThemeAccessibility method to analyze and fix the theme
    final accessibilityCheck = verifyThemeAccessibility(
      currentTheme,
      fixIssues: true,
    );

    final bool hasIssues = accessibilityCheck['status'] == 'issues_found';
    final List<String> failingPairs =
        accessibilityCheck['failing_pairs'] as List<String>? ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(hasIssues ? 'Fix Accessibility Issues' : 'No Issues Found'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              if (hasIssues) ...[
                const Text(
                  'The following color combinations do not meet WCAG AA standards:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...failingPairs.map((pair) => ListTile(
                      leading: const Icon(Icons.warning, color: Colors.orange),
                      title: Text(pair),
                      dense: true,
                    )),
                const SizedBox(height: 16),
                const Text(
                  'An accessibility-optimized theme can be applied that adjusts text colors to meet WCAG AA standards.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ] else ...[
                const Text(
                  'All color combinations in the current theme already meet WCAG AA standards for normal text.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your theme is already accessible!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('CLOSE'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          if (hasIssues)
            ElevatedButton(
              child: const Text('APPLY ACCESSIBLE THEME'),
              onPressed: () {
                // In a real app, we would update the theme here
                // This is just for demo purposes
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Accessible theme would be applied in a real app'),
                    duration: Duration(seconds: 2),
                  ),
                );
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
    );
  }
}
