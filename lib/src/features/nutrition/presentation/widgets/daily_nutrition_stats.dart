import 'package:flutter/material.dart';

import '../../domain/nutrition_summary.dart';

/// Widget that displays the daily nutrition statistics
class DailyNutritionStats extends StatelessWidget {
  /// The nutrition summary to display
  final DailyNutritionSummary summary;

  /// Constructor for the widget
  const DailyNutritionStats({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Daily Summary', style: theme.textTheme.titleMedium),
                Chip(
                  label: Text('${summary.entryCount} meals'),
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Calories progress
            Text('Calories', style: theme.textTheme.bodyLarge),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: summary.calorieProgress,
                      minHeight: 10,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      color: _getProgressColor(summary.calorieProgress, theme),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${summary.totalCalories} / ${summary.calorieGoal}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Macro nutrients
            Row(
              children: [
                _NutrientStat(
                  label: 'Protein',
                  consumed: summary.totalProtein.toInt(),
                  goal: summary.proteinGoal.toInt(),
                  unit: 'g',
                  color: Colors.red.shade300,
                ),
                _NutrientStat(
                  label: 'Carbs',
                  consumed: summary.totalCarbs.toInt(),
                  goal: summary.carbsGoal.toInt(),
                  unit: 'g',
                  color: Colors.blue.shade300,
                ),
                _NutrientStat(
                  label: 'Fat',
                  consumed: summary.totalFat.toInt(),
                  goal: summary.fatGoal.toInt(),
                  unit: 'g',
                  color: Colors.yellow.shade700,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getProgressColor(double progress, ThemeData theme) {
    if (progress >= 0.95) {
      return Colors.red;
    } else if (progress >= 0.8) {
      return Colors.orange;
    } else {
      return theme.colorScheme.primary;
    }
  }
}

/// Widget that displays a nutrient statistic
class _NutrientStat extends StatelessWidget {
  final String label;
  final int consumed;
  final int goal;
  final String unit;
  final Color color;

  const _NutrientStat({
    required this.label,
    required this.consumed,
    required this.goal,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Column(
        children: [
          Text(label, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$consumed',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text('/$goal$unit', style: theme.textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
