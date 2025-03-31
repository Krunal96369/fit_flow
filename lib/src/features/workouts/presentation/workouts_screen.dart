import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common_widgets/app_scaffold.dart';

class WorkoutsScreen extends ConsumerWidget {
  const WorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      title: 'Workouts',
      body: Column(
        children: [
          // Recent workouts list
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent Workouts',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      children: [
                        _buildWorkoutItem(
                          context,
                          title: 'Upper Body',
                          date: 'Yesterday',
                          duration: '45 minutes',
                          exercises: 6,
                        ),
                        _buildWorkoutItem(
                          context,
                          title: 'Lower Body',
                          date: 'March 25, 2025',
                          duration: '60 minutes',
                          exercises: 8,
                        ),
                        _buildWorkoutItem(
                          context,
                          title: 'Cardio',
                          date: 'March 23, 2025',
                          duration: '30 minutes',
                          exercises: 3,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Add workout button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                // This would open the workout creation screen
              },
              icon: const Icon(Icons.add),
              label: const Text('Add New Workout'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add new workout
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildWorkoutItem(
    BuildContext context, {
    required String title,
    required String date,
    required String duration,
    required int exercises,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(Icons.fitness_center, color: Colors.white),
        ),
        title: Text(title),
        subtitle: Text(date),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(duration),
            Text('$exercises exercises'),
          ],
        ),
        onTap: () {
          // Navigate to workout details
        },
      ),
    );
  }
}
