import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/difficulty.dart';
import '../../domain/models/equipment.dart';
import '../../domain/models/exercise.dart';
import '../../domain/models/muscle.dart';
import '../controllers/exercise_controller.dart';

class AddExerciseScreen extends ConsumerStatefulWidget {
  const AddExerciseScreen({super.key});

  @override
  ConsumerState<AddExerciseScreen> createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends ConsumerState<AddExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _videoUrlController = TextEditingController();
  final _caloriesController = TextEditingController();

  Muscle? _selectedPrimaryMuscle;
  final List<Muscle> _selectedSecondaryMuscles = [];
  Difficulty? _selectedDifficulty;
  final List<Equipment> _selectedEquipment = [];
  final bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Reset the controller state when the screen is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(exerciseControllerProvider.notifier).resetState();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    _imageUrlController.dispose();
    _videoUrlController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  Future<void> _saveExercise() async {
    if (_formKey.currentState!.validate() && _selectedPrimaryMuscle != null) {
      // Create a new Exercise instance
      final exercise = Exercise(
        id: const Uuid().v4(), // The controller will handle ID generation
        name: _nameController.text.trim(),
        primaryMuscle: _selectedPrimaryMuscle!,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        secondaryMuscles: _selectedSecondaryMuscles.isNotEmpty
            ? _selectedSecondaryMuscles
            : null,
        difficulty: _selectedDifficulty,
        equipmentNeeded:
            _selectedEquipment.isNotEmpty ? _selectedEquipment : null,
        imageUrl: _imageUrlController.text.trim().isNotEmpty
            ? _imageUrlController.text.trim()
            : null,
        videoUrl: _videoUrlController.text.trim().isNotEmpty
            ? _videoUrlController.text.trim()
            : null,
        instructions: _instructionsController.text.trim().isNotEmpty
            ? _instructionsController.text.trim()
            : null,
        calories: _caloriesController.text.trim().isNotEmpty
            ? int.tryParse(_caloriesController.text.trim())
            : null,
        isFavorite: false,
      );

      // Use the controller to add the exercise
      final controller = ref.read(exerciseControllerProvider.notifier);
      final newExercise = await controller.addExercise(exercise);

      if (newExercise != null) {
        if (!mounted) return;

        // Show success message and pop
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exercise added successfully')),
        );
        Navigator.of(context).pop();
      } else {
        if (!mounted) return;

        // Error message will be shown via the controller state
        final errorMessage = ref.read(exerciseControllerProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage ?? 'Failed to add exercise'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Show validation error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to the controller state to show loading indicator
    final controllerState = ref.watch(exerciseControllerProvider);
    final isSaving = controllerState.isProcessing;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Exercise'),
        actions: [
          TextButton.icon(
            onPressed: isSaving ? null : _saveExercise,
            icon: isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Exercise name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Exercise Name *',
                hintText: 'e.g. Barbell Bench Press',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Primary muscle
            DropdownButtonFormField<Muscle>(
              value: _selectedPrimaryMuscle,
              decoration: const InputDecoration(
                labelText: 'Primary Muscle *',
                hintText: 'Select primary muscle group',
              ),
              items: Muscle.values
                  .map((muscle) => DropdownMenuItem(
                        value: muscle,
                        child: Text(muscle.displayName),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPrimaryMuscle = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a primary muscle';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Secondary muscles
            const Text(
              'Secondary Muscles (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: Muscle.values
                  .map((muscle) => FilterChip(
                        label: Text(muscle.displayName),
                        selected: _selectedSecondaryMuscles.contains(muscle),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedSecondaryMuscles.add(muscle);
                            } else {
                              _selectedSecondaryMuscles.remove(muscle);
                            }
                          });
                        },
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),

            // Difficulty
            DropdownButtonFormField<Difficulty>(
              value: _selectedDifficulty,
              decoration: const InputDecoration(
                labelText: 'Difficulty (Optional)',
                hintText: 'Select difficulty level',
              ),
              items: Difficulty.values
                  .map((difficulty) => DropdownMenuItem(
                        value: difficulty,
                        child: Text(difficulty.displayName),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDifficulty = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Equipment
            const Text(
              'Equipment Needed (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: Equipment.values
                  .map((equipment) => FilterChip(
                        label: Text(equipment.displayName),
                        selected: _selectedEquipment.contains(equipment),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedEquipment.add(equipment);
                            } else {
                              _selectedEquipment.remove(equipment);
                            }
                          });
                        },
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Brief description of the exercise',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Instructions
            TextFormField(
              controller: _instructionsController,
              decoration: const InputDecoration(
                labelText: 'Instructions (Optional)',
                hintText: 'Step-by-step instructions',
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),

            // Calories
            TextFormField(
              controller: _caloriesController,
              decoration: const InputDecoration(
                labelText: 'Calories (Optional)',
                hintText: 'Calories burned in 30 minutes',
                suffixText: 'kcal',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Image URL
            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'Image URL (Optional)',
                hintText: 'URL to exercise image',
              ),
            ),
            const SizedBox(height: 16),

            // Video URL
            TextFormField(
              controller: _videoUrlController,
              decoration: const InputDecoration(
                labelText: 'Video URL (Optional)',
                hintText: 'URL to demonstration video',
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
