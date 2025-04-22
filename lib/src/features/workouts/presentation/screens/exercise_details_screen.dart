import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/models/difficulty.dart';
import '../../domain/models/exercise.dart';
import '../../providers/exercise_providers.dart';

/// Screen that displays detailed information about a single exercise
class ExerciseDetailsScreen extends ConsumerWidget {
  final String exerciseId;

  const ExerciseDetailsScreen({
    super.key,
    required this.exerciseId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(exerciseByIdProvider(exerciseId)).when(
          data: (exercise) {
            if (exercise == null) {
              return Scaffold(
                appBar: AppBar(title: const Text('Exercise Not Found')),
                body: const Center(
                  child: Text('The exercise could not be found.'),
                ),
              );
            }
            return _buildExerciseDetails(context, exercise, ref);
          },
          loading: () => const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stackTrace) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Text('Error loading exercise: $error'),
            ),
          ),
        );
  }

  Widget _buildExerciseDetails(
      BuildContext context, Exercise exercise, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, exercise, ref),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  if (exercise.description != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      exercise.description!,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],

                  // Muscle groups
                  const SizedBox(height: 24),
                  _buildSectionTitle('Muscle Groups'),
                  const SizedBox(height: 8),

                  // Primary muscle
                  Row(
                    children: [
                      const Text(
                        'Primary: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(exercise.primaryMuscle.displayName),
                    ],
                  ),

                  // Secondary muscles
                  if (exercise.secondaryMuscles != null &&
                      exercise.secondaryMuscles!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Secondary: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Expanded(
                            child: Text(
                              exercise.secondaryMuscles!
                                  .map((muscle) => muscle.displayName)
                                  .join(', '),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Muscle group visualization
                  if (exercise.muscleGroupImageUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Center(
                        child: _buildMuscleGroupImage(exercise.muscleGroupImageUrl!),
                      ),
                    ),

                  // Difficulty and type
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      if (exercise.difficulty != null) ...[
                        _buildDifficultyChip(exercise.difficulty!),
                        const SizedBox(width: 8),
                      ],
                      if (exercise.isCompoundMovement != null)
                        _buildTypeChip(exercise.isCompoundMovement!),
                    ],
                  ),

                  // Equipment needed
                  if (exercise.equipmentNeeded != null &&
                      exercise.equipmentNeeded!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSectionTitle('Equipment Needed'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: exercise.equipmentNeeded!.map((equipment) {
                        return Chip(
                          label: Text(equipment.displayName),
                          backgroundColor: Colors.grey[200],
                        );
                      }).toList(),
                    ),
                  ],

                  // Equipment variations
                  if (exercise.equipmentVariations != null &&
                      exercise.equipmentVariations!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Variations:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(exercise.equipmentVariations!.join(', ')),
                  ],

                  // Instructions
                  if (exercise.instructions != null) ...[
                    const SizedBox(height: 24),
                    _buildSectionTitle('Instructions'),
                    const SizedBox(height: 8),
                    Text(exercise.instructions!),
                  ],

                  // Proper form
                  if (exercise.properForm != null) ...[
                    const SizedBox(height: 24),
                    _buildSectionTitle('Proper Form'),
                    const SizedBox(height: 8),
                    Text(exercise.properForm!),
                  ],

                  // Common mistakes
                  if (exercise.commonMistakes != null) ...[
                    const SizedBox(height: 24),
                    _buildSectionTitle('Common Mistakes to Avoid'),
                    const SizedBox(height: 8),
                    Text(exercise.commonMistakes!),
                  ],

                  // Alternative exercises
                  if (exercise.alternativeExercises != null &&
                      exercise.alternativeExercises!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSectionTitle('Alternative Exercises'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: exercise.alternativeExercises!.map((alt) {
                        return Chip(
                          label: Text(alt),
                          backgroundColor: Colors.blue[100],
                        );
                      }).toList(),
                    ),
                  ],

                  // Video button
                  if (exercise.videoUrl != null) ...[
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.play_circle_outline),
                      label: const Text('Watch Demonstration'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      onPressed: () => _launchVideoUrl(exercise.videoUrl!),
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Add to workout
        },
        icon: const Icon(Icons.fitness_center),
        label: const Text('Add to Workout'),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, Exercise exercise, WidgetRef ref) {
    return SliverAppBar(
      expandedHeight: 200.0,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(exercise.name),
        background: exercise.imageUrl != null
            ? _buildExerciseHeaderImage(exercise.imageUrl!)
            : Container(
                color: Theme.of(context).primaryColor,
                child: Center(
                  child: Text(
                    exercise.name[0],
                    style: const TextStyle(
                      fontSize: 48,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            exercise.isFavorite == true
                ? Icons.favorite
                : Icons.favorite_border,
            color: exercise.isFavorite == true ? Colors.red : Colors.white,
          ),
          onPressed: () {
            final isFavorite = !(exercise.isFavorite ?? false);
            final toggleFavorite = ref.read(
              toggleFavoriteControllerProvider((exercise.id, isFavorite)),
            );
            toggleFavorite();
          },
        ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {
            // Share exercise
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sharing is not implemented yet'),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMuscleGroupImage(String imageUrl) {
    // Check if it's an asset path or a URL
    if (imageUrl.startsWith('assets/') || imageUrl.startsWith('/assets/')) {
      return Image.asset(
        imageUrl,
        height: 200,
        fit: BoxFit.contain,
      );
    } else {
      // If it's a GitHub URL, convert it to raw content URL
      final String effectiveUrl = _processGitHubUrl(imageUrl);

      return Image.network(
        effectiveUrl,
        height: 200,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                      (loadingProgress.expectedTotalBytes ?? 1)
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return SizedBox(
            height: 200,
            child: Center(
              child: Icon(
                Icons.image_not_supported,
                size: 50,
                color: Colors.grey[500],
              ),
            ),
          );
        },
      );
    }
  }

  Widget _buildExerciseHeaderImage(String imageUrl) {
    // Check if it's an asset path or a URL
    if (imageUrl.startsWith('assets/') || imageUrl.startsWith('/assets/')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
      );
    } else {
      // If it's a GitHub URL, convert it to raw content URL
      final String effectiveUrl = _processGitHubUrl(imageUrl);

      return Image.network(
        effectiveUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                      (loadingProgress.expectedTotalBytes ?? 1)
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: Center(
              child: Icon(
                Icons.fitness_center,
                size: 50,
                color: Colors.grey[700],
              ),
            ),
          );
        },
      );
    }
  }

  String _processGitHubUrl(String url) {
    final bool isGitHubUrl = url.contains('github.com') && url.contains('/blob/');
    return isGitHubUrl
        ? url.replaceFirst('github.com', 'raw.githubusercontent.com').replaceFirst('/blob/', '/')
        : url;
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDifficultyChip(Difficulty difficulty) {
    Color backgroundColor;

    switch (difficulty) {
      case Difficulty.beginner:
        backgroundColor = Colors.green;
        break;
      case Difficulty.intermediate:
        backgroundColor = Colors.orange;
        break;
      case Difficulty.advanced:
        backgroundColor = Colors.red;
        break;
    }

    return Chip(
      label: Text(
        _getDifficultyText(difficulty),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: backgroundColor,
    );
  }

  Widget _buildTypeChip(bool isCompound) {
    return Chip(
      label: Text(
        isCompound ? 'Compound' : 'Isolation',
        style: TextStyle(
          color: isCompound ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: isCompound ? Colors.purple : Colors.grey[300],
    );
  }

  String _getDifficultyText(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.beginner:
        return 'Beginner';
      case Difficulty.intermediate:
        return 'Intermediate';
      case Difficulty.advanced:
        return 'Advanced';
    }
  }

  Future<void> _launchVideoUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Handle error
      debugPrint('Could not launch $url');
    }
  }
}
