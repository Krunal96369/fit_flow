import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/difficulty.dart';
import '../../domain/models/equipment.dart';
import '../../domain/models/exercise.dart';
import '../../domain/models/movement_pattern.dart';
import '../../domain/models/muscle.dart';
import '../../providers/exercise_providers.dart';
import '../../workout_router.dart';
import '../widgets/exercise_card.dart';

/// Screen that displays a searchable and filterable library of exercises
class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  final bool isSelecting;

  // Constructor accepting the isSelecting parameter
  const ExerciseLibraryScreen({super.key, required this.isSelecting});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() =>
      _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Filter states
  Muscle? _selectedMuscle;
  Equipment? _selectedEquipment;
  Difficulty? _selectedDifficulty;
  MovementPattern? _selectedMovementPattern;
  bool? _isCompoundMovement;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(
            child: _buildExerciseList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search exercises...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    // Only show this row if we have active filters
    if (_selectedMuscle == null &&
        _selectedEquipment == null &&
        _selectedDifficulty == null &&
        _selectedMovementPattern == null &&
        _isCompoundMovement == null) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (_selectedMuscle != null)
            _buildFilterChip(
              label: _selectedMuscle!.displayName,
              onDeleted: () => setState(() => _selectedMuscle = null),
            ),
          if (_selectedEquipment != null)
            _buildFilterChip(
              label: _selectedEquipment!.displayName,
              onDeleted: () => setState(() => _selectedEquipment = null),
            ),
          if (_selectedDifficulty != null)
            _buildFilterChip(
              label: _getDifficultyText(_selectedDifficulty!),
              onDeleted: () => setState(() => _selectedDifficulty = null),
            ),
          if (_selectedMovementPattern != null)
            _buildFilterChip(
              label: _selectedMovementPattern!.displayName,
              onDeleted: () => setState(() => _selectedMovementPattern = null),
            ),
          if (_isCompoundMovement != null)
            _buildFilterChip(
              label: _isCompoundMovement! ? 'Compound' : 'Isolation',
              onDeleted: () => setState(() => _isCompoundMovement = null),
            ),
          TextButton.icon(
            icon: const Icon(Icons.clear_all),
            label: const Text('Clear All'),
            onPressed: _clearAllFilters,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
      {required String label, required VoidCallback onDeleted}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label),
        deleteIcon: const Icon(Icons.close, size: 18),
        onDeleted: onDeleted,
      ),
    );
  }

  Widget _buildExerciseList() {
    return ref.watch(allExercisesProvider).when(
          data: (exercises) {
            final filteredExercises = _filterExercises(exercises);

            if (filteredExercises.isEmpty) {
              return const Center(
                child: Text('No exercises found matching your criteria.'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredExercises.length,
              itemBuilder: (context, index) {
                final exercise = filteredExercises[index];
                return ExerciseCard(
                  exercise: exercise,
                  onTap: () {
                    if (widget.isSelecting) {
                      // Return selected exercise if in selection mode
                      Navigator.of(context).pop(exercise);
                    } else {
                      // Default behavior: navigate to details
                      _navigateToExerciseDetails(exercise);
                    }
                  },
                  onFavoriteTap: () => _toggleFavorite(exercise),
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stackTrace) => Center(
            child: Text('Error loading exercises: $error'),
          ),
        );
  }

  List<Exercise> _filterExercises(List<Exercise> exercises) {
    return exercises.where((exercise) {
      // Apply search query filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final nameMatch = exercise.name.toLowerCase().contains(query);
        final descriptionMatch =
            exercise.description?.toLowerCase().contains(query) ?? false;

        if (!nameMatch && !descriptionMatch) {
          return false;
        }
      }

      // Apply muscle filter
      if (_selectedMuscle != null) {
        final primaryMuscleMatch = exercise.primaryMuscle == _selectedMuscle;
        final secondaryMuscleMatch =
            exercise.secondaryMuscles?.contains(_selectedMuscle) ?? false;

        if (!primaryMuscleMatch && !secondaryMuscleMatch) {
          return false;
        }
      }

      // Apply equipment filter
      if (_selectedEquipment != null) {
        if (!(exercise.equipmentNeeded?.contains(_selectedEquipment) ??
            false)) {
          return false;
        }
      }

      // Apply difficulty filter
      if (_selectedDifficulty != null &&
          exercise.difficulty != _selectedDifficulty) {
        return false;
      }

      // Apply movement pattern filter
      if (_selectedMovementPattern != null &&
          exercise.movementPattern != _selectedMovementPattern) {
        return false;
      }

      // Apply compound/isolation filter
      if (_isCompoundMovement != null &&
          exercise.isCompoundMovement != _isCompoundMovement) {
        return false;
      }

      return true;
    }).toList();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              maxChildSize: 0.9,
              minChildSize: 0.5,
              expand: false,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            'Filter Exercises',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Muscle group filter
                        const Text(
                          'Muscle Group',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: Muscle.values.map((muscle) {
                            return ChoiceChip(
                              label: Text(muscle.displayName),
                              selected: _selectedMuscle == muscle,
                              onSelected: (selected) {
                                setModalState(() {
                                  _selectedMuscle = selected ? muscle : null;
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // Equipment filter
                        const Text(
                          'Equipment',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: Equipment.values.map((equipment) {
                            return ChoiceChip(
                              label: Text(equipment.displayName),
                              selected: _selectedEquipment == equipment,
                              onSelected: (selected) {
                                setModalState(() {
                                  _selectedEquipment =
                                      selected ? equipment : null;
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // Difficulty filter
                        const Text(
                          'Difficulty',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: Difficulty.values.map((difficulty) {
                            return ChoiceChip(
                              label: Text(_getDifficultyText(difficulty)),
                              selected: _selectedDifficulty == difficulty,
                              onSelected: (selected) {
                                setModalState(() {
                                  _selectedDifficulty =
                                      selected ? difficulty : null;
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // Movement pattern filter
                        const Text(
                          'Movement Pattern',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: MovementPattern.values.map((pattern) {
                            return ChoiceChip(
                              label: Text(pattern.displayName),
                              selected: _selectedMovementPattern == pattern,
                              onSelected: (selected) {
                                setModalState(() {
                                  _selectedMovementPattern =
                                      selected ? pattern : null;
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // Exercise type filter
                        const Text(
                          'Exercise Type',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('Compound'),
                              selected: _isCompoundMovement == true,
                              onSelected: (selected) {
                                setModalState(() {
                                  _isCompoundMovement = selected ? true : null;
                                });
                              },
                            ),
                            ChoiceChip(
                              label: const Text('Isolation'),
                              selected: _isCompoundMovement == false,
                              onSelected: (selected) {
                                setModalState(() {
                                  _isCompoundMovement = selected ? false : null;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                setModalState(() {
                                  _clearFiltersInModal();
                                });
                              },
                              child: const Text('Clear All'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  // Apply the filters selected in the modal
                                  // to the main state
                                });
                                Navigator.pop(context);
                              },
                              child: const Text('Apply Filters'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    ).then((_) {
      // Update the main state when bottom sheet is closed
      setState(() {});
    });
  }

  void _clearFiltersInModal() {
    _selectedMuscle = null;
    _selectedEquipment = null;
    _selectedDifficulty = null;
    _selectedMovementPattern = null;
    _isCompoundMovement = null;
  }

  void _clearAllFilters() {
    setState(() {
      _clearFiltersInModal();
    });
  }

  void _navigateToExerciseDetails(Exercise exercise) {
    context.goToExerciseDetails(exercise.id);
  }

  void _toggleFavorite(Exercise exercise) {
    final exerciseId = exercise.id;
    final isFavorite = !(exercise.isFavorite ?? false);

    // Update favorite status in repository
    final toggleFavorite = ref.read(
      toggleFavoriteControllerProvider((exerciseId, isFavorite)),
    );
    toggleFavorite();
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
