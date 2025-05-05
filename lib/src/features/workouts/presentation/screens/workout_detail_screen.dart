import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/models/exercise.dart';
import '../../domain/models/workout_set.dart';
import '../../domain/models/weight_unit.dart';
import '../../providers/workout_providers.dart';
import '../../providers/exercise_providers.dart';

class WorkoutDetailScreen extends ConsumerWidget {
  final String workoutId;

  const WorkoutDetailScreen({super.key, required this.workoutId});

  String _formatDuration(DateTime start, DateTime? end) {
    if (end == null) return 'In Progress';
    final duration = end.difference(start);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutAsync = ref.watch(workoutByIdProvider(workoutId));
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: workoutAsync.when(
          data: (workout) => Text(
            workout != null
                ? DateFormat('MMM d, yyyy').format(workout.startTime)
                : 'Workout Details',
          ),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Error'),
        ),
      ),
      body: workoutAsync.when(
        data: (workout) {
          if (workout == null) {
            return const Center(child: Text('Workout not found.'));
          }

          final durationStr =
              _formatDuration(workout.startTime, workout.endTime);

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // --- Header Info ---
              Text('Workout Details', style: textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                  'Date: ${DateFormat.yMMMd().add_jm().format(workout.startTime)}'),
              Text('Duration: $durationStr'),
              if (workout.notes != null && workout.notes!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('Notes: ${workout.notes}'),
                ),
              const Divider(height: 32),

              // --- Exercises List ---
              if (workout.performedExercises.isEmpty)
                const Center(
                    child: Text('No exercises were logged for this workout.')),
              ...workout.performedExercises.entries.map((entry) {
                final exerciseId = entry.key;
                final sets = entry.value;

                return _buildExerciseDetails(context, ref, exerciseId, sets);
              }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('Error loading workout: $error'),
        ),
      ),
    );
  }

  // Helper widget to display details for a single exercise within the workout
  Widget _buildExerciseDetails(BuildContext context, WidgetRef ref,
      String exerciseId, List<WorkoutSet> sets) {
    final textTheme = Theme.of(context).textTheme;

    // Fetch Exercise object using exerciseId via the provider
    final exerciseAsync = ref.watch(exerciseByIdProvider(exerciseId));

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display Exercise Name (handle loading/error)
            exerciseAsync.when(
              data: (exercise) => Text(
                exercise?.name ?? 'Unknown Exercise',
                style: textTheme.titleLarge,
              ),
              loading: () => Text('Loading Exercise...',
                  style: textTheme.titleLarge?.copyWith(fontStyle: FontStyle.italic)),
              error: (error, _) => Text('Error',
                  style: textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.error)),
            ),
            const SizedBox(height: 12),
            // Sets Table Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Set', style: textTheme.labelMedium),
                Text('Reps', style: textTheme.labelMedium),
                Text('Weight', style: textTheme.labelMedium),
              ],
            ),
            const Divider(),
            // Sets List
            ...List.generate(sets.length, (index) {
              final set = sets[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${index + 1}', style: textTheme.bodyMedium),
                    Text('${set.reps}', style: textTheme.bodyMedium),
                    Text('${set.weight} ${set.weightUnit.name}',
                        style: textTheme.bodyMedium),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
