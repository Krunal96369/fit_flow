import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/workout_controller.dart';
import '../../domain/models/workout_session.dart';
import '../../workout_router.dart';

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
  bool _isLoading = false;
  bool _isStartingWorkout = false;

  @override
  void initState() {
    super.initState();
    _initWorkout();
  }

  Future<void> _initWorkout() async {
    setState(() {
      _isStartingWorkout = true;
    });

    try {
      // Get user ID from provider
      final userId = ref.read(currentUserIdProvider);

      // Start a new workout session
      final workout =
          await ref.read(workoutControllerProvider).startWorkout(userId);

      setState(() {
        _currentWorkout = workout;
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

  void _navigateToSelectExercise() {
    // This would navigate to a screen to select exercises
    // For now, we'll show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Select Exercise screen coming soon')),
    );
  }

  Future<void> _finishWorkout() async {
    if (_currentWorkout == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // End the workout
      await ref.read(workoutControllerProvider).endWorkout(_currentWorkout!);

      // Navigate back to workouts screen
      if (mounted) {
        context.goToWorkoutsDashboard();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error finishing workout: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Formatting for timestamp
    final startTimeText = _currentWorkout != null
        ? DateFormat.jm().format(_currentWorkout!.startTime)
        : '';

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
      body: _isStartingWorkout
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
                          Text('Started at $startTimeText'),
                        ],
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
                              itemCount:
                                  _currentWorkout!.performedExercises.length,
                              itemBuilder: (context, index) {
                                // TODO: Build exercise items with their sets
                                return const ListTile(
                                  title: Text('Exercise will be shown here'),
                                );
                              },
                            ),
                    ),
                  ],
                ),
      bottomNavigationBar: _currentWorkout != null
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
}
