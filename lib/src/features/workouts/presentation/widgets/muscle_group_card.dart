import 'package:flutter/material.dart';

import '../../domain/models/muscle.dart';
import '../../workout_router.dart';

/// A card widget displaying a muscle group that users can tap to view exercises
class MuscleGroupCard extends StatelessWidget {
  final Muscle muscle;

  const MuscleGroupCard({super.key, required this.muscle});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          context.goToMuscleExercises(muscle);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: _getGradientColors(muscle),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getMuscleIcon(muscle),
                size: 48,
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              Text(
                muscle.displayName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _getGradientColors(Muscle muscle) {
    switch (muscle) {
      case Muscle.chest:
        return [Colors.red.shade400, Colors.red.shade700];
      case Muscle.back:
        return [Colors.blue.shade400, Colors.blue.shade700];
      case Muscle.shoulders:
        return [Colors.orange.shade400, Colors.orange.shade700];
      case Muscle.biceps:
        return [Colors.green.shade400, Colors.green.shade700];
      case Muscle.triceps:
        return [Colors.purple.shade400, Colors.purple.shade700];
      case Muscle.forearms:
        return [Colors.amber.shade400, Colors.amber.shade700];
      case Muscle.abs:
        return [Colors.teal.shade400, Colors.teal.shade700];
      case Muscle.quads:
        return [Colors.indigo.shade400, Colors.indigo.shade700];
      case Muscle.hamstrings:
        return [Colors.pink.shade400, Colors.pink.shade700];
      case Muscle.calves:
        return [Colors.cyan.shade400, Colors.cyan.shade700];
      case Muscle.glutes:
        return [Colors.deepPurple.shade400, Colors.deepPurple.shade700];
      case Muscle.traps:
        return [Colors.deepOrange.shade400, Colors.deepOrange.shade700];
      case Muscle.lats:
        return [Colors.lightBlue.shade400, Colors.lightBlue.shade700];
      case Muscle.obliques:
        return [Colors.lime.shade400, Colors.lime.shade700];
      case Muscle.lowerBack:
        return [Colors.brown.shade400, Colors.brown.shade700];
      case Muscle.upperBack:
        return [Colors.blueGrey.shade400, Colors.blueGrey.shade700];
      case Muscle.fullBody:
        return [Colors.grey.shade400, Colors.grey.shade700];
    }
  }

  IconData _getMuscleIcon(Muscle muscle) {
    switch (muscle) {
      case Muscle.chest:
        return Icons.fitness_center;
      case Muscle.back:
        return Icons.directions_boat;
      case Muscle.shoulders:
        return Icons.expand_more;
      case Muscle.biceps:
        return Icons.sports_handball;
      case Muscle.triceps:
        return Icons.sports_handball;
      case Muscle.forearms:
        return Icons.front_hand;
      case Muscle.abs:
        return Icons.rectangle;
      case Muscle.quads:
        return Icons.accessibility_new;
      case Muscle.hamstrings:
        return Icons.accessibility_new;
      case Muscle.calves:
        return Icons.directions_walk;
      case Muscle.glutes:
        return Icons.chair;
      case Muscle.traps:
        return Icons.arrow_upward;
      case Muscle.lats:
        return Icons.arrow_outward;
      case Muscle.obliques:
        return Icons.pivot_table_chart;
      case Muscle.lowerBack:
        return Icons.arrow_downward;
      case Muscle.upperBack:
        return Icons.arrow_upward;
      case Muscle.fullBody:
        return Icons.person;
    }
  }
}
