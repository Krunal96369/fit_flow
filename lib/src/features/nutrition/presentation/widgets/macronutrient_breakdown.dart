import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/nutrition_summary.dart';

/// Widget that displays a pie chart of macronutrient breakdown
class MacronutrientBreakdown extends StatelessWidget {
  /// Daily nutrition summary containing the macronutrient data
  final DailyNutritionSummary summary;

  /// Constructor
  const MacronutrientBreakdown({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calculate total macros
    final totalMacros =
        summary.totalProtein + summary.totalCarbs + summary.totalFat;

    // If no data, show placeholder
    if (totalMacros <= 0) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'No macronutrient data available for today',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
      );
    }

    // Calculate percentages
    final proteinPercentage =
        (summary.totalProtein / totalMacros * 100).round();
    final carbsPercentage = (summary.totalCarbs / totalMacros * 100).round();
    final fatPercentage = (summary.totalFat / totalMacros * 100).round();

    // Define colors
    const proteinColor = Color(0xFF4CAF50); // Green
    const carbsColor = Color(0xFF2196F3); // Blue
    const fatColor = Color(0xFFFFC107); // Amber

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Macronutrient Breakdown', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                // Pie chart
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 150,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 35,
                        sections: [
                          PieChartSectionData(
                            value: summary.totalProtein.toDouble(),
                            title: '$proteinPercentage%',
                            color: proteinColor,
                            radius: 50,
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          PieChartSectionData(
                            value: summary.totalCarbs.toDouble(),
                            title: '$carbsPercentage%',
                            color: carbsColor,
                            radius: 50,
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          PieChartSectionData(
                            value: summary.totalFat.toDouble(),
                            title: '$fatPercentage%',
                            color: fatColor,
                            radius: 50,
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Legend
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _MacroLegendItem(
                        color: proteinColor,
                        label: 'Protein',
                        value: '${summary.totalProtein.toInt()}g',
                        percentage: proteinPercentage,
                      ),
                      const SizedBox(height: 8),
                      _MacroLegendItem(
                        color: carbsColor,
                        label: 'Carbs',
                        value: '${summary.totalCarbs.toInt()}g',
                        percentage: carbsPercentage,
                      ),
                      const SizedBox(height: 8),
                      _MacroLegendItem(
                        color: fatColor,
                        label: 'Fat',
                        value: '${summary.totalFat.toInt()}g',
                        percentage: fatPercentage,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget for displaying a macro legend item
class _MacroLegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final int percentage;

  const _MacroLegendItem({
    required this.color,
    required this.label,
    required this.value,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label ($percentage%)',
            style: theme.textTheme.bodySmall,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
