import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/exercise.dart';
import '../../domain/models/muscle.dart';
import '../../providers/exercise_providers.dart';
import '../../workout_router.dart';
import '../controllers/exercise_controller.dart';

class MuscleExercisesScreen extends ConsumerWidget {
  final Muscle muscle;

  const MuscleExercisesScreen({super.key, required this.muscle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(exercisesByMuscleProvider(muscle));
    final controllerState = ref.watch(exerciseControllerProvider);

    if (controllerState.operationState == ExerciseOperationState.success) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(exerciseControllerProvider.notifier).resetState();
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Operation completed successfully')),
        );
      });
    } else if (controllerState.operationState == ExerciseOperationState.error) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controllerState.errorMessage ?? 'An error occurred'),
            backgroundColor: Colors.red,
          ),
        );
        ref.read(exerciseControllerProvider.notifier).resetState();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${muscle.displayName} Exercises'),
      ),
      body: exercisesAsync.when(
        data: (exercises) {
          if (exercises.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.fitness_center,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No ${muscle.displayName} exercises found',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: exercises.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final exercise = exercises[index];
              return _buildExerciseListItem(context, exercise, ref);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading exercises: $error'),
        ),
      ),
    );
  }

  Widget _buildExerciseListItem(
      BuildContext context, Exercise exercise, WidgetRef ref) {
    final isFavorite = exercise.isFavorite ?? false;
    final isProcessing = ref.watch(exerciseControllerProvider).isProcessing;

    return ListTile(
      title: Text(
        exercise.name,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          if (exercise.secondaryMuscles != null &&
              exercise.secondaryMuscles!.isNotEmpty)
            Text(
              'Secondary: ${exercise.secondaryMuscles!.map((m) => m.displayName).join(", ")}',
              style: const TextStyle(fontSize: 12),
            ),
          if (exercise.equipmentNeeded != null &&
              exercise.equipmentNeeded!.isNotEmpty)
            Text(
              'Equipment: ${exercise.equipmentNeeded!.map((e) => e.displayName).join(", ")}',
              style: const TextStyle(fontSize: 12),
            ),
          if (exercise.difficulty != null)
            Text(
              'Difficulty: ${exercise.difficulty!.displayName}',
              style: const TextStyle(fontSize: 12),
            ),
        ],
      ),
      leading: exercise.imageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                exercise.imageUrl!,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            )
          : Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.fitness_center,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
      trailing: IconButton(
        icon: isProcessing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : null,
              ),
        onPressed: isProcessing
            ? null
            : () {
                ref
                    .read(exerciseControllerProvider.notifier)
                    .toggleFavorite(exercise.id, !isFavorite);
              },
      ),
      onTap: () {
        context.goToExerciseDetails(exercise.id);
      },
    );
  }
}
