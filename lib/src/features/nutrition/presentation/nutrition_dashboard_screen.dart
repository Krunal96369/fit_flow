import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../common_widgets/app_scaffold.dart';
import '../../../features/auth/application/auth_controller.dart';
import '../application/nutrition_controller.dart';
import '../domain/nutrition_entry.dart';
import '../domain/nutrition_repository.dart';
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
    extends ConsumerState<NutritionDashboardScreen>
    with WidgetsBindingObserver {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh entries when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _refreshData();
    }
  }

  // Refresh when returning to this screen
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshData();
  }

  Future<void> _refreshData() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Quick toggle of loading to trigger refresh but not block UI
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Error refreshing data: ${e.toString()}';
        });
      }
    }
  }

  void _goToPreviousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
    _refreshData();
  }

  void _goToNextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
    _refreshData();
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
      _refreshData();
    }
  }

  void _addWater(int milliliters) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    try {
      await ref
          .read(nutritionControllerProvider)
          .logWaterIntake(user.uid, _selectedDate, milliliters);
      // No need to refresh data, stream will update
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
      _refreshData(); // Refresh data
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
    // Use the stream provider for real-time updates to the summary
    final summaryStreamAsync = ref.watch(
      dailyNutritionSummaryStreamProvider(_selectedDate),
    );

    // Debug: Check which repository implementation is being used
    final repoType =
        ref.read(nutritionRepositoryProvider).runtimeType.toString();
    debugPrint('NUTRITION DASHBOARD: Using repository type: $repoType');

    // Force refresh the entries provider when selected date changes
    // This is important to ensure real-time updates
    ref.listen<DateTime>(Provider<DateTime>((ref) => _selectedDate),
        (previous, current) {
      // Invalidate the entries provider when date changes
      ref.invalidate(dailyNutritionEntriesStreamProvider);
    });

    // Use the stream provider for entries to get real-time updates
    final entriesAsync = ref.watch(
      dailyNutritionEntriesStreamProvider(_selectedDate),
    );

    return AppScaffold(
      title: 'Nutrition Tracker',
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => context.push('/profile/nutrition-goals'),
          tooltip: 'Nutrition Goals',
        ),
      ],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _refreshData,
                  child: summaryStreamAsync.when(
                    data: (summary) {
                      return entriesAsync.when(
                        data: (entries) {
                          return ListView(
                            padding: const EdgeInsets.all(16.0),
                            children: [
                              _buildDateSelector(),
                              const SizedBox(height: 16),
                              _buildDailySummary(summary),
                              const SizedBox(height: 16),
                              _buildWaterTracker(summary),
                              const SizedBox(height: 16),
                              _buildTodaysEntries(entries),
                            ],
                          );
                        },
                        loading: () => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        error: (error, stack) => Center(
                          child: Text('Error loading entries: $error'),
                        ),
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (error, stack) => Center(
                      child: Text('Error loading nutrition data: $error'),
                    ),
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
    final isToday = _selectedDate.year == today.year &&
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

  Widget _buildDailySummary(DailyNutritionSummary summary) {
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

  Widget _buildWaterTracker(DailyNutritionSummary summary) {
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

  Widget _buildTodaysEntries(List<NutritionEntry> entries) {
    if (entries.isEmpty) {
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
            itemCount: entries.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final entry = entries[index];
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
