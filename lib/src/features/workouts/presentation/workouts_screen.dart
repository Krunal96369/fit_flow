import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../common_widgets/app_scaffold.dart';
import '../application/workout_controller.dart';
import '../domain/models/workout_session.dart';
import '../workout_router.dart';

class WorkoutsScreen extends ConsumerWidget {
  const WorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the recent workouts provider
    final recentWorkoutsAsync = ref.watch(recentWorkoutsProvider);

    return AppScaffold(
      title: 'Workouts',
      actions: [
        IconButton(
          icon: const Icon(Icons.fitness_center),
          onPressed: () {
            // Navigate to exercise library
            context.goToExerciseLibrary();
          },
          tooltip: 'Exercise Library',
        ),
      ],
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
                    child: recentWorkoutsAsync.when(
                      data: (workouts) {
                        if (workouts.isEmpty) {
                          return const Center(
                            child: Text('No recent workouts found.'),
                          );
                        }

                        return ListView.builder(
                          itemCount: workouts.length,
                          itemBuilder: (context, index) {
                            final workout = workouts[index];
                            return _buildWorkoutItem(
                              context,
                              workout: workout,
                            );
                          },
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (error, stack) => Center(
                        child: Text('Error loading workouts: $error'),
                      ),
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
                // Navigate to log workout screen
                context.goToLogWorkout();
              },
              icon: const Icon(Icons.add),
              label: const Text('Start New Workout'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to log workout screen
          context.goToLogWorkout();
        },
        tooltip: 'Start New Workout',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildWorkoutItem(
    BuildContext context, {
    required WorkoutSession workout,
  }) {
    // Format date and calculate duration
    final dateFormat = DateFormat.yMMMd().add_jm();
    final formattedDate = dateFormat.format(workout.startTime);

    // Calculate duration if the workout is complete
    final durationText = workout.duration != null
        ? '${workout.duration!.inMinutes} minutes'
        : 'In Progress';

    // Count exercises
    final exerciseCount = workout.performedExercises.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: workout.endTime != null
              ? const Icon(Icons.fitness_center, color: Colors.white)
              : const Icon(Icons.directions_run, color: Colors.white),
        ),
        title: Text(
            workout.endTime != null ? 'Completed Workout' : 'Active Workout'),
        subtitle: Text(formattedDate),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(durationText),
            Text('$exerciseCount exercises'),
          ],
        ),
        onTap: () {
          // Navigate to workout details
          // This would be implemented later
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Workout details coming soon!')),
          );
        },
      ),
    );
  }
}
