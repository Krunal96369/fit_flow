import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common_widgets/app_scaffold.dart';

class NutritionScreen extends ConsumerWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      title: 'Nutrition',
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // Nutrition summary
            const Card(
              elevation: 2,
              margin: EdgeInsets.all(16),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Today\'s Summary',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _NutritionStat(
                          label: 'Calories',
                          value: '0',
                          goal: '2000',
                          icon: Icons.local_fire_department,
                          color: Colors.red,
                        ),
                        _NutritionStat(
                          label: 'Protein',
                          value: '0g',
                          goal: '150g',
                          icon: Icons.fitness_center,
                          color: Colors.blue,
                        ),
                        _NutritionStat(
                          label: 'Carbs',
                          value: '0g',
                          goal: '250g',
                          icon: Icons.grain,
                          color: Colors.amber,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                // This would open the food logging screen
              },
              icon: const Icon(Icons.add),
              label: const Text('Log Food'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NutritionStat extends StatelessWidget {
  final String label;
  final String value;
  final String goal;
  final IconData icon;
  final Color color;

  const _NutritionStat({
    required this.label,
    required this.value,
    required this.goal,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text('$value / $goal'),
      ],
    );
  }
}
