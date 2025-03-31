import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/nutrition_entry.dart';

/// Widget that displays a list of nutrition entries
class NutritionEntryList extends StatelessWidget {
  /// List of nutrition entries to display
  final List<NutritionEntry> entries;

  /// Callback for when an entry is deleted
  final Function(String) onDeleteEntry;

  /// Constructor for the widget
  const NutritionEntryList({
    super.key,
    required this.entries,
    required this.onDeleteEntry,
  });

  @override
  Widget build(BuildContext context) {
    // Sort entries by time consumed (newest first)
    final sortedEntries = List<NutritionEntry>.from(entries)
      ..sort((a, b) => b.consumedAt.compareTo(a.consumedAt));

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedEntries.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        return _NutritionEntryItem(
          entry: sortedEntries[index],
          onDelete: onDeleteEntry,
        );
      },
    );
  }
}

/// Widget that displays a single nutrition entry
class _NutritionEntryItem extends StatelessWidget {
  /// The nutrition entry to display
  final NutritionEntry entry;

  /// Callback for when the entry is deleted
  final Function(String) onDelete;

  /// Constructor for the widget
  const _NutritionEntryItem({required this.entry, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat.jm();

    return Dismissible(
      key: Key(entry.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Delete Entry'),
                content: const Text(
                  'Are you sure you want to delete this entry?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
        );
      },
      onDismissed: (direction) {
        onDelete(entry.id);
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
          child: Text(
            '${entry.calories}',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(entry.name),
        subtitle: Text(
          '${entry.servingSize} • ${entry.servings} servings • ${timeFormat.format(entry.consumedAt)}',
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${entry.protein.toStringAsFixed(1)}g',
              style: const TextStyle(color: Colors.green),
            ),
            Text(
              '${entry.carbs.toStringAsFixed(1)}g',
              style: const TextStyle(color: Colors.orange),
            ),
            Text(
              '${entry.fat.toStringAsFixed(1)}g',
              style: const TextStyle(color: Colors.blue),
            ),
          ],
        ),
        onTap: () {
          // TODO: Navigate to entry details/edit screen
        },
      ),
    );
  }
}
