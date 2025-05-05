import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/models/workout_session.dart';

/// A card widget to display a summary of a workout session.
class WorkoutCard extends StatelessWidget {
  final WorkoutSession workout;
  final VoidCallback? onTap;

  const WorkoutCard({super.key, required this.workout, this.onTap});

  String _formatDuration(DateTime start, DateTime? end) {
    if (end == null) return 'In Progress';
    final duration = end.difference(start);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '$hours h $minutes min';
    }
    return '$minutes min';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final formattedDate =
        DateFormat('MMM d, yyyy - hh:mm a').format(workout.startTime);
    final durationStr = _formatDuration(workout.startTime, workout.endTime);
    final exerciseCount = workout.performedExercises.length;
    final notesExist = workout.notes != null && workout.notes!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      clipBehavior: Clip.antiAlias, // Ensures InkWell splash is contained
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            // Wrap Row in Column to add notes below
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start, // Align items top
                children: [
                  Expanded(
                    // Allow date/exercise count to wrap if needed
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formattedDate,
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$exerciseCount exercises',
                          style: textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.outline),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16), // Add spacing between columns
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        durationStr,
                        style: textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      if (onTap != null) // Only show arrow if tappable
                        Icon(Icons.chevron_right, color: colorScheme.outline),
                    ],
                  ),
                ],
              ),
              if (notesExist) ...[
                // Conditionally display notes section
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Notes:',
                  style: textTheme.labelMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  workout.notes!, // Display the notes
                  style: textTheme.bodySmall,
                  maxLines: 3, // Limit lines shown
                  overflow:
                      TextOverflow.ellipsis, // Add ellipsis if notes overflow
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
