import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../common_widgets/app_scaffold.dart';
import '../../../features/auth/application/auth_controller.dart';
import '../application/nutrition_controller.dart';
import '../domain/nutrition_entry.dart';
import '../domain/nutrition_summary.dart';

/// Dashboard screen for nutrition tracking
class NutritionDashboardScreen extends ConsumerStatefulWidget {
  /// Constructor
  const NutritionDashboardScreen({super.key});

  @override
  ConsumerState<NutritionDashboardScreen> createState() =>
      _NutritionDashboardScreenState();
}

class _NutritionDashboardScreenState
    extends ConsumerState<NutritionDashboardScreen> {
  DateTime _selectedDate = DateTime.now();
  DailyNutritionSummary? _summary;
  List<NutritionEntry> _entries = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Normalize date to start of day
      final date = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );

      try {
        // Load summary and entries for the selected date
        final summaryFuture = ref
            .read(nutritionControllerProvider)
            .getDailySummary(user.uid, date);
        final entriesFuture = ref
            .read(nutritionControllerProvider)
            .getEntriesForDate(user.uid, date);

        final results = await Future.wait([summaryFuture, entriesFuture]);

        if (mounted) {
          setState(() {
            _summary = results[0] as DailyNutritionSummary;
            _entries = results[1] as List<NutritionEntry>;
            _isLoading = false;
            _error = null;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            if (e.toString().contains('UnimplementedError')) {
              _error =
                  'Nutrition tracking is still being set up. Some features may not be available yet.';
            } else {
              _error = 'Error loading nutrition data: ${e.toString()}';
            }
            _summary = null;
            _entries = [];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Unexpected error: ${e.toString()}';
          _summary = null;
          _entries = [];
        });
      }
    }
  }

  void _goToPreviousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
    _loadData();
  }

  void _goToNextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
    _loadData();
  }

  void _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
      _loadData();
    }
  }

  void _addWater(int milliliters) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    try {
      await ref
          .read(nutritionControllerProvider)
          .logWaterIntake(user.uid, _selectedDate, milliliters);
      _loadData(); // Refresh data
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging water intake: $e')),
        );
      }
    }
  }

  void _deleteEntry(NutritionEntry entry) async {
    try {
      await ref.read(nutritionControllerProvider).deleteEntry(entry.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Entry deleted')));
      }
      _loadData(); // Refresh data
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting entry: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Nutrition Tracker',
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => context.push('/profile/nutrition-goals'),
          tooltip: 'Nutrition Goals',
        ),
      ],
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? _buildErrorState()
              : RefreshIndicator(
                onRefresh: _loadData,
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    _buildDateSelector(),
                    const SizedBox(height: 16),
                    _buildDailySummary(),
                    const SizedBox(height: 16),
                    _buildWaterTracker(),
                    const SizedBox(height: 16),
                    _buildTodaysEntries(),
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.go('/nutrition/add?date=${_selectedDate.toIso8601String()}');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDateSelector() {
    final today = DateTime.now();
    final isToday =
        _selectedDate.year == today.year &&
        _selectedDate.month == today.month &&
        _selectedDate.day == today.day;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: _goToPreviousDay,
            ),
            TextButton(
              onPressed: _selectDate,
              child: Text(
                isToday ? 'Today' : DateFormat.yMMMd().format(_selectedDate),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: _selectedDate.isBefore(today) ? _goToNextDay : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailySummary() {
    final summary = _summary;

    if (summary == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No nutrition data for this day'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text('Meals: ${summary.entryCount}'),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            _buildNutrientProgress(
              'Calories',
              summary.totalCalories,
              summary.calorieGoal,
              suffix: 'kcal',
            ),
            const SizedBox(height: 8),
            _buildNutrientProgress(
              'Protein',
              summary.totalProtein.round(),
              summary.proteinGoal.round(),
              suffix: 'g',
            ),
            const SizedBox(height: 8),
            _buildNutrientProgress(
              'Carbs',
              summary.totalCarbs.round(),
              summary.carbsGoal.round(),
              suffix: 'g',
            ),
            const SizedBox(height: 8),
            _buildNutrientProgress(
              'Fat',
              summary.totalFat.round(),
              summary.fatGoal.round(),
              suffix: 'g',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientProgress(
    String label,
    int current,
    int goal, {
    required String suffix,
  }) {
    final progress = goal > 0 ? current / goal : 0.0;
    final progressCapped = progress.clamp(0.0, 1.0);

    Color progressColor;
    if (progress < 0.75) {
      progressColor = Colors.orange;
    } else if (progress <= 1.0) {
      progressColor = Colors.green;
    } else {
      progressColor = Colors.red;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label), Text('$current / $goal $suffix')],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progressCapped,
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
          color: progressColor,
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildWaterTracker() {
    final summary = _summary;

    if (summary == null) {
      return const SizedBox.shrink();
    }

    final progress = summary.waterIntake / summary.waterGoal;
    final progressCapped = progress.clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Water', style: Theme.of(context).textTheme.titleMedium),
                Text(
                  '${(summary.waterIntake / 1000).toStringAsFixed(1)} / ${(summary.waterGoal / 1000).toStringAsFixed(1)} L',
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progressCapped,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              color: Colors.blue,
              minHeight: 10,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildWaterButton(200),
                _buildWaterButton(330),
                _buildWaterButton(500),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterButton(int milliliters) {
    return OutlinedButton.icon(
      onPressed: () => _addWater(milliliters),
      icon: const Icon(Icons.water_drop, color: Colors.blue),
      label: Text('${milliliters}ml'),
      style: OutlinedButton.styleFrom(foregroundColor: Colors.blue),
    );
  }

  Widget _buildTodaysEntries() {
    if (_entries.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.restaurant_menu, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No meals logged yet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the + button to add your first meal',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Today's Meals",
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _entries.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final entry = _entries[index];
              return Dismissible(
                key: Key(entry.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) => _deleteEntry(entry),
                child: ListTile(
                  title: Text(entry.name),
                  subtitle: Text(
                    '${entry.calories} kcal | ${entry.protein}g P | ${entry.carbs}g C | ${entry.fat}g F',
                  ),
                  trailing: Text(DateFormat.jm().format(entry.consumedAt)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _error ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                context.go(
                  '/nutrition/add?date=${_selectedDate.toIso8601String()}',
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Nutrition Entry'),
            ),
          ],
        ),
      ),
    );
  }
}
