import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/exercise.dart';
import '../../providers/exercise_providers.dart';

/// Screen to display detailed information about a specific exercise.
class ExerciseDetailScreen extends ConsumerWidget {
  /// The ID of the exercise to display
  final String exerciseId;

  /// Constructor
  const ExerciseDetailScreen({super.key, required this.exerciseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the exercise by ID provider
    final exerciseAsync = ref.watch(exerciseByIdProvider(exerciseId));

    return Scaffold(
      body: exerciseAsync.when(
        data: (exercise) {
          // Handle null exercise (not found)
          if (exercise == null) {
            return const Center(
              child: Text('Exercise not found'),
            );
          }

          return _buildExerciseDetail(context, exercise, ref);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading exercise: $error'),
        ),
      ),
    );
  }

  Widget _buildExerciseDetail(
      BuildContext context, Exercise exercise, WidgetRef ref) {
    final isFavorite = exercise.isFavorite ?? false;

    final String imageUrl = exercise.imageUrl!;

    // Check if the URL is a GitHub URL that needs to be modified for raw content
    final bool isGitHubUrl =
        imageUrl.contains('github.com') || imageUrl.contains('/blob/');

    // If it's a GitHub URL, convert it to raw content URL
    final String effectiveUrl = isGitHubUrl
        ? imageUrl
            .replaceFirst('github.com', 'raw.githubusercontent.com')
            .replaceFirst('/blob/', '/')
        : imageUrl;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 240,
          pinned: true,
          actions: [
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : null,
              ),
              onPressed: () {
                final favoriteController = ref.read(
                  toggleFavoriteControllerProvider((exercise.id, !isFavorite)),
                );
                favoriteController();
              },
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            title: Text(exercise.name),
            background: exercise.imageUrl != null
                ? Image.network(
                    effectiveUrl,
                    fit: BoxFit.cover,
                  )
                : Container(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Center(
                      child: Icon(
                        Icons.fitness_center,
                        size: 80,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Muscle information
                _buildSectionHeader(context, 'Muscle Groups'),
                _buildInfoCard(
                  context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        'Primary',
                        exercise.primaryMuscle.displayName,
                      ),
                      if (exercise.secondaryMuscles != null &&
                          exercise.secondaryMuscles!.isNotEmpty)
                        _buildInfoRow(
                          'Secondary',
                          exercise.secondaryMuscles!
                              .map((m) => m.displayName)
                              .join(', '),
                        ),
                    ],
                  ),
                ),

                // Details
                _buildSectionHeader(context, 'Details'),
                _buildInfoCard(
                  context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (exercise.difficulty != null)
                        _buildInfoRow(
                          'Difficulty',
                          exercise.difficulty!.displayName,
                        ),
                      if (exercise.equipmentNeeded != null &&
                          exercise.equipmentNeeded!.isNotEmpty)
                        _buildInfoRow(
                          'Equipment',
                          exercise.equipmentNeeded!
                              .map((e) => e.displayName)
                              .join(', '),
                        ),
                      if (exercise.calories != null)
                        _buildInfoRow(
                          'Est. Calories',
                          '${exercise.calories} kcal/30min',
                        ),
                    ],
                  ),
                ),

                // Description
                if (exercise.description != null) ...[
                  _buildSectionHeader(context, 'Description'),
                  _buildInfoCard(
                    context,
                    child: Text(exercise.description!),
                  ),
                ],

                // Instructions
                if (exercise.instructions != null) ...[
                  _buildSectionHeader(context, 'Instructions'),
                  _buildInfoCard(
                    context,
                    child: Text(exercise.instructions!),
                  ),
                ],

                // Video
                if (exercise.videoUrl != null) ...[
                  _buildSectionHeader(context, 'Video'),
                  _buildInfoCard(
                    context,
                    child: Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Play Video'),
                        onPressed: () {
                          // TODO: Implement video player or open URL
                        },
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, {required Widget child}) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
