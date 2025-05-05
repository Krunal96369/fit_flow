import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For input formatters
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // Import GoRouter
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart'; // Import Uuid

import '../../application/workout_controller.dart';
import '../../domain/models/exercise.dart';
import '../../domain/models/workout_session.dart';
import '../../domain/models/workout_set.dart';
import '../../providers/rest_timer_provider.dart'; // Import rest timer provider
import '../../providers/settings_providers.dart'; // Import settings provider
import '../../workout_router.dart'; // Corrected import path

/// Screen for logging a workout.
class LogWorkoutScreen extends ConsumerStatefulWidget {
  /// Optional date for the workout
  final DateTime? date;

  /// Optional exercise ID to pre-select
  final String? preSelectedExerciseId;

  /// Constructor
  const LogWorkoutScreen({super.key, this.date, this.preSelectedExerciseId});

  @override
  ConsumerState<LogWorkoutScreen> createState() => _LogWorkoutScreenState();
}

class _LogWorkoutScreenState extends ConsumerState<LogWorkoutScreen> {
  WorkoutSession? _currentWorkout;
  bool _isStartingWorkout = false;
  bool _isFinishing = false; // Flag for finishing workout
  bool _isLoading = false;

  // Temporarily store details of added exercises for UI display
  final Map<String, Exercise> _addedExercises = {};
  final _uuid = const Uuid(); // Create a Uuid instance

  // Controllers for the Add Set dialog
  late final TextEditingController _repsController;
  late final TextEditingController _weightController;
  late final TextEditingController
      _setNotesController; // Add controller for set notes

  @override
  void initState() {
    super.initState();
    _repsController = TextEditingController();
    _weightController = TextEditingController();
    _setNotesController =
        TextEditingController(); // Initialize set notes controller
    _initWorkout();
  }

  @override
  void dispose() {
    _repsController.dispose();
    _weightController.dispose();
    _setNotesController.dispose(); // Dispose set notes controller
    super.dispose();
  }

  Future<void> _initWorkout() async {
    setState(() {
      _isStartingWorkout = true;
    });

    try {
      // Call startWorkout with NO arguments - controller gets ID internally
      final newWorkout =
          await ref.read(workoutControllerProvider).startWorkout();

      setState(() {
        _currentWorkout = newWorkout;
        _isStartingWorkout = false;
      });

      // If there's a pre-selected exercise, navigate to add set screen next
      if (widget.preSelectedExerciseId != null) {
        _navigateToSelectExercise();
      }
    } catch (e) {
      setState(() {
        _isStartingWorkout = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting workout: $e')),
        );
      }
    }
  }

  Future<void> _navigateToSelectExercise() async {
    // Use GoRouter directly to push the route and await the result
    final selectedExercise = await GoRouter.of(context).pushNamed<Exercise>(
      'exercise-library',
      extra: {'isSelecting': true}, // Indicate selection mode
    );

    if (selectedExercise != null && _currentWorkout != null) {
      // Create a new map for performedExercises, adding the new exercise if needed
      final currentPerformed = _currentWorkout!.performedExercises;
      if (!currentPerformed.containsKey(selectedExercise.id)) {
        final updatedPerformedExercises =
            Map<String, List<WorkoutSet>>.from(currentPerformed);
        updatedPerformedExercises[selectedExercise.id] =
            []; // Initialize with empty list

        setState(() {
          // Update _currentWorkout using copyWith
          _currentWorkout = _currentWorkout!.copyWith(
            performedExercises: updatedPerformedExercises,
          );
          // Store details for UI display
          _addedExercises[selectedExercise.id] = selectedExercise;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${selectedExercise.name} added')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('${selectedExercise.name} is already in the workout')),
        );
      }
    } else if (selectedExercise != null && _currentWorkout == null) {
      // Handle case where workout hasn't started yet (optional, maybe show message)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Start the workout before adding exercises.')),
      );
    }
  }

  Future<void> _finishWorkout() async {
    if (_currentWorkout == null ||
        (_currentWorkout?.performedExercises.isEmpty ?? true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Add at least one exercise before finishing.')),
      );
      return;
    }

    // Show the finish workout dialog
    final WorkoutSession? updatedWorkoutSession =
        await showDialog<WorkoutSession>(
      context: context,
      builder: (context) => _FinishWorkoutDialog(
        initialWorkout: _currentWorkout!,
      ),
    );

    // If the user saved the dialog
    if (updatedWorkoutSession != null) {
      setState(() {
        _isFinishing = true;
      });

      try {
        debugPrint(
            '--- _finishWorkout: Calling workoutController.endWorkout ---'); // Add log
        debugPrint(
            '--- Workout Data: ${updatedWorkoutSession.toJson()} ---'); // Log updated data

        // Pass the updated workout from the dialog to endWorkout
        await ref
            .read(workoutControllerProvider)
            .endWorkout(updatedWorkoutSession);
        debugPrint(
            '--- _finishWorkout: endWorkout completed successfully ---'); // Add log

        // Navigate back to workouts screen
        if (mounted) {
          context.goToWorkoutsDashboard();
        }
      } catch (e, stackTrace) {
        setState(() {
          _isFinishing = false;
        });

        debugPrint('--- _finishWorkout: Error caught ---'); // Add log
        debugPrint('Error: $e');
        debugPrint('StackTrace: $stackTrace'); // Log stack trace
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error finishing workout: $e')),
          );
        }
      }
    }
  }

  // Trigger the dialog to add a set
  void _addSet(String exerciseId) async {
    if (_currentWorkout == null) return;

    // Read the preferred unit here
    final preferredUnit = ref.read(preferredWeightUnitProvider);
    final exerciseName = _addedExercises[exerciseId]?.name ?? 'Exercise';
    // Clear previous values
    _repsController.clear();
    _weightController.clear();
    _setNotesController.clear(); // Clear set notes controller

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Set to $exerciseName'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: _repsController,
                  decoration: const InputDecoration(labelText: 'Reps'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                TextField(
                  controller: _weightController,
                  decoration: InputDecoration(
                      labelText:
                          'Weight (${preferredUnit.displayName})'), // Display preferred unit
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(
                        r'^\d+\.?\d{0,2}')), // Allow digits and decimal point
                  ],
                ),
                const SizedBox(height: 16), // Add spacing
                TextField(
                  // Add notes field for the set
                  controller: _setNotesController,
                  decoration: const InputDecoration(
                    labelText: 'Set Notes (Optional)',
                    hintText: 'e.g., good form, felt easy',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              onPressed: () async {
                // Make the callback async
                // Validate input
                final reps = int.tryParse(_repsController.text);
                final weight = double.tryParse(_weightController.text);
                final setNotes =
                    _setNotesController.text.trim(); // Get set notes

                if (reps != null && weight != null) {
                  // Use the read preferred unit when creating the set
                  final newSet = WorkoutSet(
                    exerciseId: exerciseId,
                    weightUnit: preferredUnit, // Use preferred unit
                    reps: reps,
                    weight: weight,
                    id: _uuid.v4(), // Generate unique ID
                    notes: setNotes.isNotEmpty
                        ? setNotes
                        : null, // Add notes if present
                  );

                  // Temporarily update local state for immediate UI feedback
                  setState(() {
                    // Update _currentWorkout using copyWith
                    _currentWorkout = _currentWorkout!.copyWith(
                      performedExercises: {
                        ..._currentWorkout!.performedExercises,
                        exerciseId: [
                          ..._currentWorkout!.performedExercises[exerciseId] ??
                              [],
                          newSet
                        ],
                      },
                    );
                  });

                  try {
                    // Call controller to save the set with notes
                    final updatedWorkout = await ref
                        .read(workoutControllerProvider)
                        .addSetToWorkout(
                          _currentWorkout!, // Current workout session
                          exerciseId, // Exercise ID
                          preferredUnit, // Pass the weight unit
                          reps, // Reps
                          weight, // Weight
                          notes: setNotes.isNotEmpty
                              ? setNotes
                              : null, // Pass notes
                        );
                    // Update local state with the confirmed workout from the controller
                    setState(() {
                      _currentWorkout = updatedWorkout;
                    });
                  } catch (e) {
                    // Handle error (e.g., show snackbar)
                    // Revert optimistic update if needed, though controller might handle state
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error adding set: $e')),
                      );
                    }
                  }

                  // Close dialog first
                  Navigator.of(context).pop();
                  // Start rest timer
                  ref.read(restTimerProvider.notifier).startTimer();
                  // Show confirmation
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('Added Set to $exerciseName. Rest started.')),
                  );
                } else {
                  // Show error if input is invalid
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Invalid input. Please enter numbers for reps and weight.')),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // Method to show exercise details in a bottom sheet
  void _showExerciseDetailsSheet(Exercise exercise) {
    showModalBottomSheet(
      useSafeArea: true,
      context: context,
      isScrollControlled: true, // Allows sheet to take more height if needed
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exercise.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(
                'Primary Muscle: ${exercise.primaryMuscle}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                // Format the list of equipment
                'Equipment: ${exercise.equipmentNeeded == null || exercise.equipmentNeeded!.isEmpty ? 'None' : exercise.equipmentNeeded!.map((e) => e.name).join(', ')}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Instructions:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              // Make instructions scrollable if they are long
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                      exercise.instructions ?? 'No instructions available.'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final restTimerState = ref.watch(restTimerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Workout'),
        actions: [
          if (_currentWorkout != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _finishWorkout,
              tooltip: 'Finish Workout',
            ),
        ],
      ),
      body: _isStartingWorkout ||
              _isFinishing // Show loading indicator while finishing
          ? const Center(child: CircularProgressIndicator())
          : _currentWorkout == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Could not start a workout session.'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _initWorkout,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Workout info header
                    Container(
                      padding: const EdgeInsets.all(16),
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Row(
                        children: [
                          const Icon(Icons.access_time),
                          const SizedBox(width: 8),
                          Text(
                            'Started: ${DateFormat.yMd().add_jm().format(_currentWorkout!.startTime)}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Rest timer display
                    if (restTimerState.isRunning)
                      Card(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Resting: ${restTimerState.remainingSeconds}s',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSecondaryContainer,
                                    ),
                              ),
                              const SizedBox(height: 16.0),
                              ElevatedButton(
                                onPressed: () {
                                  ref
                                      .read(restTimerProvider.notifier)
                                      .stopTimer();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.secondary,
                                  foregroundColor:
                                      Theme.of(context).colorScheme.onSecondary,
                                ),
                                child: const Text('Skip Rest'),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Exercises and sets
                    Expanded(
                      child: _currentWorkout!.performedExercises.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'No exercises added yet',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _navigateToSelectExercise,
                                    child: const Text('Add Exercise'),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              // Iterate over the keys (exercise IDs) of the map
                              itemCount: _currentWorkout!
                                  .performedExercises.keys.length,
                              itemBuilder: (context, index) {
                                final exerciseId = _currentWorkout!
                                    .performedExercises.keys
                                    .elementAt(index);
                                final sets = _currentWorkout!
                                    .performedExercises[exerciseId]!;
                                final exercise = _addedExercises[
                                    exerciseId]; // Get details from local map

                                // If exercise details aren't found (shouldn't happen with simulation),
                                // show a placeholder or handle error
                                if (exercise == null) {
                                  return ListTile(
                                      title: Text(
                                          'Error: Exercise $exerciseId details missing'));
                                }

                                // Build exercise items with their sets
                                return _buildExerciseLogItem(
                                    exercise, exerciseId, sets);
                              },
                            ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
      bottomNavigationBar: _currentWorkout?.performedExercises.isNotEmpty ??
              false
          ? BottomAppBar(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ElevatedButton(
                  onPressed: _navigateToSelectExercise,
                  child: const Text('Add Exercise'),
                ),
              ),
            )
          : null,
    );
  }

  // Widget to display a single logged exercise and its sets
  Widget _buildExerciseLogItem(
      Exercise exercise, String exerciseId, List<WorkoutSet> sets) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Make the title tappable
            InkWell(
              onTap: () => _showExerciseDetailsSheet(exercise),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 8.0), // Add padding for tap area
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        exercise.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const Icon(Icons.info_outline,
                        size: 20, color: Colors.grey), // Hint icon
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Display logged sets
            if (sets.isEmpty)
              const Text('No sets logged yet.',
                  style: TextStyle(fontStyle: FontStyle.italic))
            else
              ListView.builder(
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(), // Disable scrolling within the card
                itemCount: sets.length,
                itemBuilder: (context, setIndex) {
                  final set = sets[setIndex];
                  // Display weight with its specific unit
                  final weightDisplay = '${set.weight} ${set.weightUnit.name}';

                  return ListTile(
                    dense: true,
                    // Format: Set 1: 10 reps @ 50.0 kg
                    title: Text(
                        'Set ${setIndex + 1}: $weightDisplay x ${set.reps} reps'),
                    subtitle: set.notes != null &&
                            set.notes!.isNotEmpty // Display notes if available
                        ? Text(set.notes!,
                            style: const TextStyle(fontStyle: FontStyle.italic))
                        : null,
                    trailing: IconButton(
                      // Add delete button for sets
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () async {
                        if (_currentWorkout == null) return;

                        final setIdToDelete = set.id;
                        setState(() {
                          _isLoading = true; // Show loading indicator
                        });
                        try {
                          final updatedWorkout = await ref
                              .read(workoutControllerProvider)
                              .removeSetFromWorkout(
                                _currentWorkout!,
                                exerciseId,
                                setIdToDelete,
                              );
                          // Update local state
                          setState(() {
                            _currentWorkout = updatedWorkout;
                            _isLoading = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Set ${setIndex + 1} deleted from ${exercise.name}')),
                          );
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error deleting set: $e')),
                            );
                          }
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      },
                      tooltip: 'Delete Set',
                    ),
                  );
                },
              ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () =>
                  _addSet(exerciseId), // Pass exerciseId to _addSet
              icon: const Icon(Icons.add),
              label: const Text('Add Set'),
              style: ElevatedButton.styleFrom(
                visualDensity: VisualDensity.compact, // Make button smaller
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Finish Workout Dialog ---

class _FinishWorkoutDialog extends StatefulWidget {
  final WorkoutSession initialWorkout;

  const _FinishWorkoutDialog({required this.initialWorkout});

  @override
  State<_FinishWorkoutDialog> createState() => _FinishWorkoutDialogState();
}

class _FinishWorkoutDialogState extends State<_FinishWorkoutDialog> {
  late TextEditingController _notesController;
  late DateTime _startTime;
  late DateTime _endTime;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.initialWorkout.notes);
    _startTime = widget.initialWorkout.startTime;
    _endTime = widget.initialWorkout.endTime ??
        DateTime.now(); // Default to now if null
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(bool isStart) async {
    final initialDate = isStart ? _startTime : _endTime;
    final newDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate:
          DateTime.now().add(const Duration(days: 1)), // Allow up to tomorrow
    );

    if (newDate != null && mounted) {
      final newTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      if (newTime != null) {
        setState(() {
          final combinedDateTime = DateTime(
            newDate.year,
            newDate.month,
            newDate.day,
            newTime.hour,
            newTime.minute,
          );
          if (isStart) {
            // Ensure start time is not after end time
            if (combinedDateTime.isBefore(_endTime)) {
              _startTime = combinedDateTime;
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Start time cannot be after end time.')),
              );
            }
          } else {
            // Ensure end time is not before start time
            if (combinedDateTime.isAfter(_startTime)) {
              _endTime = combinedDateTime;
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('End time cannot be before start time.')),
              );
            }
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMd().add_jm();

    return AlertDialog(
      title: const Text('Finish Workout'),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            // Start Time Picker
            ListTile(
              title: const Text('Start Time'),
              subtitle: Text(dateFormat.format(_startTime)),
              trailing: const Icon(Icons.edit_calendar),
              onTap: () => _pickDateTime(true),
            ),
            const SizedBox(height: 8),
            // End Time Picker
            ListTile(
              title: const Text('End Time'),
              subtitle: Text(dateFormat.format(_endTime)),
              trailing: const Icon(Icons.edit_calendar),
              onTap: () => _pickDateTime(false),
            ),
            const SizedBox(height: 16),
            // Notes Field
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Workout Notes (Optional)',
                hintText: 'e.g., felt strong, focused on form',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop(); // Close dialog, return null
          },
        ),
        TextButton(
          child: const Text('Save Workout'),
          onPressed: () {
            // Create updated workout session
            final updatedWorkout = widget.initialWorkout.copyWith(
              startTime: _startTime,
              endTime: _endTime,
              notes: _notesController.text.trim(),
            );
            Navigator.of(context)
                .pop(updatedWorkout); // Close dialog, return updated data
          },
        ),
      ],
    );
  }
}
