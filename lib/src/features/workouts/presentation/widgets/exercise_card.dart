import 'package:flutter/material.dart';

import '../../domain/models/difficulty.dart';
import '../../domain/models/exercise.dart';

/// A card widget that displays basic information about an exercise
class ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.onTap,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise image if available
            if (exercise.imageUrl != null)
              SizedBox(
                height: 160,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: _buildExerciseImage(),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          exercise.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          exercise.isFavorite == true
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: exercise.isFavorite == true
                              ? Colors.red
                              : Colors.grey,
                        ),
                        onPressed: onFavoriteTap,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Primary Muscle: ${exercise.primaryMuscle.displayName}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (exercise.difficulty != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Difficulty: ${_getDifficultyText(exercise.difficulty!)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  if (exercise.description != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        exercise.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseImage() {
    final String imageUrl = exercise.imageUrl!;

    // Check if the URL is a GitHub URL that needs to be modified for raw content
    final bool isGitHubUrl =
        imageUrl.contains('github.com') && imageUrl.contains('/blob/');

    // If it's a GitHub URL, convert it to raw content URL
    final String effectiveUrl = isGitHubUrl
        ? imageUrl
            .replaceFirst('github.com', 'raw.githubusercontent.com')
            .replaceFirst('/blob/', '/')
        : imageUrl;

    return Image.network(
      effectiveUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    (loadingProgress.expectedTotalBytes ?? 1)
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[200],
          child: Center(
            child: Icon(
              Icons.fitness_center,
              size: 50,
              color: Colors.grey[500],
            ),
          ),
        );
      },
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
}
