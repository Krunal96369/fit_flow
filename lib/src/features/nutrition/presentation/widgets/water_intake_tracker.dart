import 'package:flutter/material.dart';

/// Widget that displays a water intake tracker
class WaterIntakeTracker extends StatelessWidget {
  /// Current water intake in milliliters
  final int currentIntake;

  /// Water intake goal in milliliters
  final int goal;

  /// Callback for when water is added
  final Function(int) onAddWater;

  /// Constructor for the widget
  const WaterIntakeTracker({
    super.key,
    required this.currentIntake,
    required this.goal,
    required this.onAddWater,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (currentIntake / goal).clamp(0.0, 1.0);
    final remaining = goal - currentIntake > 0 ? goal - currentIntake : 0;

    // Convert to a more readable format
    final currentLiters = (currentIntake / 1000).toStringAsFixed(1);
    final goalLiters = (goal / 1000).toStringAsFixed(1);

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
                Text('Water Intake', style: theme.textTheme.titleMedium),
                Text(
                  '$currentLiters / $goalLiters L',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 20,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                color: Colors.blue,
              ),
            ),

            if (remaining > 0) ...[
              const SizedBox(height: 8),
              Text(
                'You need ${(remaining / 1000).toStringAsFixed(1)} L more water today',
                style: theme.textTheme.bodySmall,
              ),
            ],

            const SizedBox(height: 16),

            // Quick add buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _WaterAddButton(amount: 200, onAdd: onAddWater),
                _WaterAddButton(amount: 330, onAdd: onAddWater),
                _WaterAddButton(amount: 500, onAdd: onAddWater),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Button to add water quickly
class _WaterAddButton extends StatelessWidget {
  /// Amount of water to add in milliliters
  final int amount;

  /// Callback for when the button is pressed
  final Function(int) onAdd;

  const _WaterAddButton({required this.amount, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OutlinedButton(
      onPressed: () => onAdd(amount),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.blue,
        side: const BorderSide(color: Colors.blue),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.water_drop),
          Text('${amount}ml', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
