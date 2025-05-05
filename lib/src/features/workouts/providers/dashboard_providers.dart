import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/workout_session.dart';
import '../domain/repositories/workout_repository.dart';
import '../../auth/application/auth_controller.dart'; // Import auth state provider

// Provider for the current user ID (workaround)
// TODO: Remove this or move it when auth is implemented
// REMOVED: final currentUserIdProvider = Provider<String>((ref) => 'test-user-id');

/// Calculates the start of the current week (Monday).
DateTime _getStartOfWeek(DateTime date) {
  final daysToSubtract = date.weekday - DateTime.monday;
  final startOfWeekDate = date.subtract(Duration(days: daysToSubtract));
  return DateTime(startOfWeekDate.year, startOfWeekDate.month, startOfWeekDate.day);
}

/// Calculates the end of the current week (Sunday end of day).
DateTime _getEndOfWeek(DateTime date) {
  final startOfWeek = _getStartOfWeek(date);
  final endOfWeekDate = startOfWeek.add(const Duration(days: 6));
  // Use end of day for the range query
  return DateTime(endOfWeekDate.year, endOfWeekDate.month, endOfWeekDate.day, 23, 59, 59);
}

// Provider for the user's weekly workout goal (hardcoded for now)
final weeklyWorkoutGoalProvider = Provider<int>((ref) {
  // TODO: Load this from user settings eventually
  return 3;
});

/// Provider to fetch the count of workouts logged in the current week (Mon-Sun).
final weeklyWorkoutCountProvider = FutureProvider<int>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.asData?.value; // Get the user object

  // If user is not logged in, return 0 workouts
  if (user == null) {
    return 0;
  }
  final userId = user.uid; // Get the actual user ID
  final repository = ref.watch(workoutRepositoryProvider);

  final now = DateTime.now();
  final startDate = _getStartOfWeek(now);
  final endDate = _getEndOfWeek(now);

  // Fetch workouts for the date range from the repository
  final workouts = await repository.getWorkoutsForDateRange(userId, startDate, endDate);
  return workouts.length;
});

/// Provider to fetch recent workout sessions.
final recentWorkoutsProvider = FutureProvider<List<WorkoutSession>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.asData?.value;

  // If user is not logged in, return empty list
  if (user == null) {
    return [];
  }
  final userId = user.uid;
  final repository = ref.watch(workoutRepositoryProvider);

  // Fetch recent workouts (default limit is 10 in repository)
  return repository.getRecentWorkouts(userId);
});
