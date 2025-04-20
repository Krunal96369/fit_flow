import 'package:flutter/material.dart';

/// The goal setting step in the onboarding process
class GoalSettingStep extends StatefulWidget {
  /// Constructor
  const GoalSettingStep({super.key});

  @override
  State<GoalSettingStep> createState() => _GoalSettingStepState();
}

class _GoalSettingStepState extends State<GoalSettingStep> {
  String? _selectedGoal;
  int _workoutsPerWeek = 3;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Set Your Fitness Goals',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Tell us what you want to achieve so we can help you get there',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 32),

            // Primary fitness goal
            const Text(
              'What is your primary fitness goal?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 16),

            // Goal selection cards
            _buildGoalOption(
              title: 'Lose Weight',
              icon: Icons.trending_down,
              description: 'Burn fat and reduce body weight',
              goal: 'lose_weight',
            ),

            const SizedBox(height: 12),

            _buildGoalOption(
              title: 'Build Muscle',
              icon: Icons.fitness_center,
              description: 'Increase strength and muscle mass',
              goal: 'build_muscle',
            ),

            const SizedBox(height: 12),

            _buildGoalOption(
              title: 'Improve Fitness',
              icon: Icons.directions_run,
              description: 'Enhance overall health and endurance',
              goal: 'improve_fitness',
            ),

            const SizedBox(height: 12),

            _buildGoalOption(
              title: 'Maintain Weight',
              icon: Icons.balance,
              description: 'Keep current weight and improve tone',
              goal: 'maintain',
            ),

            const SizedBox(height: 32),

            // Workouts per week
            const Text(
              'How many workouts per week?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 8),

            // Slider for workout frequency
            Slider(
              value: _workoutsPerWeek.toDouble(),
              min: 1,
              max: 7,
              divisions: 6,
              label: '$_workoutsPerWeek days',
              onChanged: (value) {
                setState(() {
                  _workoutsPerWeek = value.round();
                });
              },
            ),

            // Workout frequency description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('1', style: TextStyle(color: Colors.grey)),
                  Text(
                    '$_workoutsPerWeek days',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const Text('7', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Suggestion based on selection
            Text(
              _getWorkoutSuggestion(),
              style: const TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalOption({
    required String title,
    required IconData icon,
    required String description,
    required String goal,
  }) {
    final isSelected = _selectedGoal == goal;
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final surfaceColor = colorScheme.surface;
    final bgColor = isSelected ? primaryColor.withOpacity(0.05) : surfaceColor;
    final borderColor = isSelected ? primaryColor : Colors.grey.shade300;
    final textColor = isSelected ? primaryColor : colorScheme.onSurface;
    final descColor = isSelected
        ? primaryColor.withOpacity(0.7)
        : colorScheme.onSurface.withOpacity(0.6);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedGoal = goal;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2 : 1,
          ),
          color: bgColor,
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryColor.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? primaryColor : Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: descColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? primaryColor : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  String _getWorkoutSuggestion() {
    if (_workoutsPerWeek <= 2) {
      return 'Great for beginners! We\'ll focus on effective workouts for your limited schedule.';
    } else if (_workoutsPerWeek <= 4) {
      return 'A balanced approach that works well for most people.';
    } else {
      return 'An intensive schedule. We\'ll help you plan recovery to avoid overtraining.';
    }
  }
}
