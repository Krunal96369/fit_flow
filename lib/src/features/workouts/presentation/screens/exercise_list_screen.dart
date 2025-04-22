import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/exercise_repository_provider.dart';
import '../../domain/models/exercise.dart';
import '../../workout_router.dart';

/// Screen that displays a list of available exercises.
class ExerciseListScreen extends ConsumerStatefulWidget {
  const ExerciseListScreen({super.key});

  @override
  ConsumerState<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends ConsumerState<ExerciseListScreen> {
  String _searchQuery = '';
  String? _selectedMuscleGroup;
  final TextEditingController _searchController = TextEditingController();

  // Common muscle groups for filtering
  final List<String> _muscleGroups = [
    'All',
    'Chest',
    'Back',
    'Shoulders',
    'Biceps',
    'Triceps',
    'Legs',
    'Abs',
    'Quadriceps',
    'Hamstrings',
    'Glutes',
    'Calves',
    'Lower Back',
    'Lats',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the provider that fetches the list of exercises
    final AsyncValue<List<Exercise>> exercisesAsync =
        ref.watch(exercisesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showInfoDialog(context);
            },
            tooltip: 'About Exercise Library',
          )
        ],
      ),
      body: Column(
        children: [
          // Search and filter section
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search exercises...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 8),

                // Muscle group filter chips
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _muscleGroups.length,
                    itemBuilder: (context, index) {
                      final muscleGroup = _muscleGroups[index];
                      final bool isSelected = muscleGroup == 'All'
                          ? _selectedMuscleGroup == null
                          : _selectedMuscleGroup == muscleGroup;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(muscleGroup),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (muscleGroup == 'All') {
                                _selectedMuscleGroup = null;
                              } else {
                                _selectedMuscleGroup =
                                    selected ? muscleGroup : null;
                              }
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Exercise list
          Expanded(
            child: exercisesAsync.when(
              // Data loaded successfully
              data: (exercises) {
                // Filter exercises based on search query and selected muscle group
                final filteredExercises = exercises.where((exercise) {
                  final matchesSearch = _searchQuery.isEmpty ||
                      exercise.name
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase());

                  final matchesMuscle = _selectedMuscleGroup == null ||
                      exercise.primaryMuscle == _selectedMuscleGroup ||
                      (exercise.secondaryMuscles
                              ?.contains(_selectedMuscleGroup) ??
                          false);

                  return matchesSearch && matchesMuscle;
                }).toList();

                if (filteredExercises.isEmpty) {
                  return const Center(child: Text('No exercises found.'));
                }

                // Display the list using ListView.builder
                return ListView.builder(
                  itemCount: filteredExercises.length,
                  itemBuilder: (context, index) {
                    final exercise = filteredExercises[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          child: const Icon(Icons.fitness_center,
                              color: Colors.white),
                        ),
                        title: Text(exercise.name),
                        subtitle: Text(
                            'Primary: ${exercise.primaryMuscle}${exercise.secondaryMuscles != null && exercise.secondaryMuscles!.isNotEmpty ? '\nSecondary: ${exercise.secondaryMuscles!.join(", ")}' : ''}'),
                        isThreeLine: exercise.secondaryMuscles != null &&
                            exercise.secondaryMuscles!.isNotEmpty,
                        onTap: () {
                          context.goToExerciseDetails(exercise.id);
                        },
                      ),
                    );
                  },
                );
              },
              // Loading state
              loading: () => const Center(child: CircularProgressIndicator()),
              // Error state
              error: (error, stackTrace) => Center(
                child: Text(
                  'Failed to load exercises: \n$error',
                  textAlign: TextAlign.center,
                ),
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
        tooltip: 'Log a Workout',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exercise Library'),
        content: const SingleChildScrollView(
          child: Text(
            'The exercise library contains a collection of exercises organized by muscle groups.\n\n'
            'You can search for exercises by name or filter them by muscle group. '
            'Tap on an exercise to view detailed information.\n\n'
            'Use the "Add to Workout" button from the exercise details screen to start '
            'logging a workout with that exercise.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
