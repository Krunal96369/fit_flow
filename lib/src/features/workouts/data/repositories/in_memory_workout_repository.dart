import '../../domain/models/workout_session.dart';
import '../../domain/repositories/workout_repository.dart';

/// An in-memory implementation of the WorkoutRepository for testing and development.
///
/// Simulates data storage with a simple in-memory Map.
class InMemoryWorkoutRepository implements WorkoutRepository {
  // In-memory storage for workout sessions
  final Map<String, WorkoutSession> _workouts = {};

  // Simulate network delay
  final Duration _delay = const Duration(milliseconds: 300);

  @override
  Future<void> deleteWorkout(String workoutId) async {
    await Future.delayed(_delay);
    _workouts.remove(workoutId);
  }

  @override
  Future<WorkoutSession?> getWorkoutById(String workoutId) async {
    await Future.delayed(_delay);
    return _workouts[workoutId];
  }

  @override
  Future<List<WorkoutSession>> getWorkoutsForDate(
      String userId, DateTime date) async {
    await Future.delayed(_delay);

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _workouts.values
        .where((workout) =>
            workout.userId == userId &&
            workout.startTime.isAfter(startOfDay) &&
            workout.startTime.isBefore(endOfDay))
        .toList();
  }

  @override
  Future<List<WorkoutSession>> getWorkoutsForDateRange(
      String userId, DateTime startDate, DateTime endDate) async {
    await Future.delayed(_delay);

    return _workouts.values
        .where((workout) =>
            workout.userId == userId &&
            workout.startTime.isAfter(startDate) &&
            workout.startTime.isBefore(endDate.add(const Duration(days: 1))))
        .toList();
  }

  @override
  Future<List<WorkoutSession>> getRecentWorkouts(String userId,
      {int limit = 10}) async {
    await Future.delayed(_delay);

    final results =
        _workouts.values.where((workout) => workout.userId == userId).toList()
          // Sort by most recent first
          ..sort((a, b) => b.startTime.compareTo(a.startTime));

    // Limit to requested number
    return results.take(limit).toList();
  }

  @override
  Future<WorkoutSession> saveWorkout(WorkoutSession workout) async {
    await Future.delayed(_delay);
    _workouts[workout.id] = workout;
    return workout;
  }
}
