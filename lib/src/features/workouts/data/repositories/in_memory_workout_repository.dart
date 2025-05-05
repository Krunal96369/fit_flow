import '../../domain/models/workout_session.dart';
import '../../domain/repositories/workout_repository.dart';

/// An in-memory implementation of the WorkoutRepository for testing and development.
///
/// Simulates data storage with a simple in-memory Map.
class InMemoryWorkoutRepository implements WorkoutRepository {
  // In-memory storage for workout sessions
  final Map<String, Map<String, WorkoutSession>> _workouts = {};

  // Simulate network delay
  final Duration _delay = const Duration(milliseconds: 300);

  @override
  Future<void> deleteWorkout(String workoutId) async {
    await Future.delayed(_delay);
    _workouts.values.forEach((userWorkouts) => userWorkouts.remove(workoutId));
  }

  @override
  Future<WorkoutSession?> getWorkoutById(String workoutId) async {
    await Future.delayed(_delay);
    // Find workout across all users (simplification for in-memory)
    for (final userWorkouts in _workouts.values) {
      if (userWorkouts.containsKey(workoutId)) {
        return userWorkouts[workoutId];
      }
    }
    return null;
  }

  @override
  Future<List<WorkoutSession>> getWorkoutsForDate(
      String userId, DateTime date) async {
    await Future.delayed(_delay);

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _workouts[userId]?.values
        .where((workout) =>
            workout.startTime.isAfter(startOfDay) &&
            workout.startTime.isBefore(endOfDay))
        .toList() ??
        [];
  }

  @override
  Future<List<WorkoutSession>> getWorkoutsForDateRange(
      String userId, DateTime startDate, DateTime endDate) async {
    await Future.delayed(_delay);

    return _workouts[userId]?.values
        .where((workout) =>
            workout.startTime.isAfter(startDate) &&
            workout.startTime.isBefore(endDate.add(const Duration(days: 1))))
        .toList() ??
        [];
  }

  @override
  Future<List<WorkoutSession>> getRecentWorkouts(String userId,
      {int limit = 10}) async {
    await Future.delayed(_delay);

    final results = _workouts[userId]?.values.toList() ?? []
      // Sort by most recent first
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    // Limit to requested number
    return results.take(limit).toList();
  }

  @override
  Future<WorkoutSession> saveWorkoutSession(WorkoutSession workout) async {
    // Simulate saving
    _workouts.putIfAbsent(workout.userId, () => {});
    _workouts[workout.userId]![workout.id] = workout;
    return workout; // Return the saved workout
  }
}
