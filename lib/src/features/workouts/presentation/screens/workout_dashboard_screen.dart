import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common_widgets/app_scaffold.dart';
import '../../providers/dashboard_providers.dart';
import '../../workout_router.dart';
import '../widgets/workout_card.dart';

class WorkoutDashboardScreen extends ConsumerWidget {
  const WorkoutDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Define the refresh function
    Future<void> refreshData() async {
      // Invalidate and refetch the providers
      // Use ref.refresh which returns the Future needed by RefreshIndicator
      await ref.refresh(weeklyWorkoutCountProvider.future);
      await ref.refresh(recentWorkoutsProvider.future);
      // Add any other providers that need refreshing here
    }

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
      body: RefreshIndicator(
        onRefresh: refreshData, // Assign the refresh function
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // --- Activity Summary Section ---
            const Text('Activity Summary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildActivitySummary(context, ref),
            const SizedBox(height: 24),

            // --- Goal Progress Section ---
            _buildGoalProgress(context, ref),
            const SizedBox(height: 24),

            // --- Recent Workouts Section ---
            const Text('Recent Workouts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Consumer(
              builder: (context, ref, child) {
                final recentWorkoutsAsync = ref.watch(recentWorkoutsProvider);
                return recentWorkoutsAsync.when(
                  data: (workouts) {
                    if (workouts.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 32.0),
                          child: Text('No recent workouts logged.'),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap:
                          true, // Important for ListView inside ListView
                      physics:
                          const NeverScrollableScrollPhysics(), // Disable inner scrolling
                      itemCount: workouts.length,
                      itemBuilder: (context, index) {
                        final workout = workouts[index];
                        return WorkoutCard(
                          workout: workout,
                          onTap: () => context.pushWorkoutDetails(
                              workout.id), // Use navigation extension
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, stackTrace) => Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32.0),
                      child: Text(
                        'Error loading recent workouts: $error',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 80), // Space for the FAB
          ],
        ),
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

  // Helper Widget for Activity Summary
  Widget _buildActivitySummary(BuildContext context, WidgetRef ref) {
    // Use weeklyWorkoutCountProvider instead of weeklyExerciseCountProvider
    final weeklyCountAsync = ref.watch(weeklyWorkoutCountProvider);
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Activity This Week', style: textTheme.titleLarge),
            const SizedBox(height: 12),
            weeklyCountAsync.when(
              data: (count) => Text(
                // Update text to reflect total workouts
                '$count Workouts Logged',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              loading: () => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2)),
              error: (error, _) => Text('Error: $error',
                  style: textTheme.bodyMedium
                      ?.copyWith(color: Theme.of(context).colorScheme.error)),
            ),
            const SizedBox(height: 4),
            Text('Monday - Sunday', style: textTheme.labelSmall),
          ],
        ),
      ),
    );
  }

  // Helper Widget for Goal Progress
  Widget _buildGoalProgress(BuildContext context, WidgetRef ref) {
    // Use weeklyWorkoutGoalProvider and weeklyWorkoutCountProvider
    final goal = ref
        .watch(weeklyWorkoutGoalProvider); // Use goal from dashboard_providers
    final weeklyCountAsync =
        ref.watch(weeklyWorkoutCountProvider); // Use total workout count
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Update title
            Text('Weekly Workout Goal', style: textTheme.titleLarge),
            const SizedBox(height: 12),
            weeklyCountAsync.when(
              data: (count) {
                final progress =
                    (goal == 0) ? 0.0 : (count / goal).clamp(0.0, 1.0);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      // Update text
                      '$count / $goal Workouts',
                      style: textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                  child: Text('Loading progress...',
                      style: TextStyle(
                          fontStyle:
                              FontStyle.italic))), // Smaller loading indicator
              error: (error, _) => Text('Error: $error',
                  style: textTheme.bodyMedium
                      ?.copyWith(color: Theme.of(context).colorScheme.error)),
            ),
          ],
        ),
      ),
    );
  }
}
