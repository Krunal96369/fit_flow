import 'package:flutter/material.dart';

import '../../domain/models/difficulty.dart';
import '../../domain/models/exercise.dart';

/// A card widget that displays detailed information about an exercise
class ExerciseDetailCard extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback? onFavoriteTap;

  const ExerciseDetailCard({
    super.key,
    required this.exercise,
    this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise header with name, type, and favorite button
          _buildHeader(context),

          // Exercise image
          if (exercise.imageUrl != null) _buildImage(),

          // Main information section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                if (exercise.description != null) _buildDescription(),

                const SizedBox(height: 16),

                // Muscle groups
                _buildMuscleGroups(),

                const SizedBox(height: 16),

                // Equipment needed
                if (exercise.equipmentNeeded != null &&
                    exercise.equipmentNeeded!.isNotEmpty)
                  _buildEquipmentList(),

                const SizedBox(height: 16),

                // Difficulty level
                if (exercise.difficulty != null) _buildDifficulty(),

                const SizedBox(height: 16),

                // Step-by-step instructions
                if (exercise.instructions != null) _buildInstructions(),

                const SizedBox(height: 16),

                // Proper form
                if (exercise.properForm != null) _buildProperForm(),

                const SizedBox(height: 16),

                // Common mistakes
                if (exercise.commonMistakes != null) _buildCommonMistakes(),

                const SizedBox(height: 16),

                // Alternative exercises
                if (exercise.alternativeExercises != null &&
                    exercise.alternativeExercises!.isNotEmpty)
                  _buildAlternatives(),

                const SizedBox(height: 16),

                // Video link button
                if (exercise.videoUrl != null) _buildVideoButton(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  exercise.isCompoundMovement == true
                      ? 'Compound Movement'
                      : 'Isolation Movement',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              exercise.isFavorite == true
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: Colors.white,
            ),
            onPressed: onFavoriteTap,
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(exercise.imageUrl!),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildDescription() {
    return Text(
      exercise.description!,
      style: const TextStyle(
        fontSize: 16,
      ),
    );
  }

  Widget _buildMuscleGroups() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Muscle Groups',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
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

        // Visualization image
        if (exercise.muscleGroupImageUrl != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Image.asset(
              exercise.muscleGroupImageUrl!,
              height: 100,
              fit: BoxFit.contain,
            ),
          ),
      ],
    );
  }

  Widget _buildEquipmentList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Equipment Needed',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          exercise.equipmentNeeded!
              .map((equipment) => equipment.displayName)
              .join(', '),
        ),

        // Equipment variations
        if (exercise.equipmentVariations != null &&
            exercise.equipmentVariations!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Variations:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(exercise.equipmentVariations!.join(', ')),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDifficulty() {
    Color difficultyColor;

    switch (exercise.difficulty) {
      case Difficulty.beginner:
        difficultyColor = Colors.green;
        break;
      case Difficulty.intermediate:
        difficultyColor = Colors.orange;
        break;
      case Difficulty.advanced:
        difficultyColor = Colors.red;
        break;
      default:
        difficultyColor = Colors.grey;
    }

    return Row(
      children: [
        const Text(
          'Difficulty: ',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: difficultyColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            _getDifficultyText(exercise.difficulty),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  String _getDifficultyText(Difficulty? difficulty) {
    switch (difficulty) {
      case Difficulty.beginner:
        return 'Beginner';
      case Difficulty.intermediate:
        return 'Intermediate';
      case Difficulty.advanced:
        return 'Advanced';
      default:
        return 'Unknown';
    }
  }

  Widget _buildInstructions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Instructions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(exercise.instructions!),
      ],
    );
  }

  Widget _buildProperForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Proper Form',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(exercise.properForm!),
      ],
    );
  }

  Widget _buildCommonMistakes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Common Mistakes to Avoid',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(exercise.commonMistakes!),
      ],
    );
  }

  Widget _buildAlternatives() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Alternative Exercises',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(exercise.alternativeExercises!.join(', ')),
      ],
    );
  }

  Widget _buildVideoButton(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.play_circle_outline),
      label: const Text('Watch Demonstration'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
      onPressed: () {
        // Launch video URL - In a real app, this would open the video
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening video: ${exercise.videoUrl}'),
          ),
        );
      },
    );
  }
}
