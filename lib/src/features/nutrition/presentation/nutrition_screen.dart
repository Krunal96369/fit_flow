import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common_widgets/app_scaffold.dart';
import '../../auth/application/auth_controller.dart';
import '../application/nutrition_controller.dart';
import '../domain/nutrition_summary.dart';

class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});

  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Initial date setup - truncate to day
    _selectedDate = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
  }

  Future<void> _loadData() async {
    // Manual refresh functionality, just wait a bit to trigger stream refresh
    await Future.delayed(const Duration(milliseconds: 300));
    // The actual data will be refreshed by the stream
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state
    final authState = ref.watch(authStateProvider);

    // Listen to real-time nutrition summary updates
    final summaryStream =
        ref.watch(dailyNutritionSummaryStreamProvider(_selectedDate));

    return AppScaffold(
      title: 'Nutrition',
      body: authState.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('Please sign in to view your nutrition data'),
            );
          }

          return summaryStream.when(
            data: (summary) => _buildScreenContent(summary),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) =>
                _buildErrorState('Error loading nutrition data: $error'),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            _buildErrorState('Authentication error: $error'),
      ),
    );
  }

  Widget _buildScreenContent(DailyNutritionSummary summary) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Nutrition summary
              _buildSummaryCard(summary),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  context.go(
                      '/nutrition/add?date=${_selectedDate.toIso8601String()}');
                },
                icon: const Icon(Icons.add),
                label: const Text('Log Food'),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () {
                  context.go('/nutrition/dashboard');
                },
                icon: const Icon(Icons.dashboard),
                label: const Text('View Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(DailyNutritionSummary summary) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Today\'s Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NutritionStat(
                  label: 'Calories',
                  value: '${summary.totalCalories}',
                  goal: '${summary.calorieGoal}',
                  icon: Icons.local_fire_department,
                  color: Colors.red,
                ),
                _NutritionStat(
                  label: 'Protein',
                  value: '${summary.totalProtein.round()}g',
                  goal: '${summary.proteinGoal.round()}g',
                  icon: Icons.fitness_center,
                  color: Colors.blue,
                ),
                _NutritionStat(
                  label: 'Carbs',
                  value: '${summary.totalCarbs.round()}g',
                  goal: '${summary.carbsGoal.round()}g',
                  icon: Icons.grain,
                  color: Colors.amber,
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: summary.calorieGoal > 0
                  ? (summary.totalCalories / summary.calorieGoal)
                      .clamp(0.0, 1.0)
                  : 0.0,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Meals logged: ${summary.entryCount}',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NutritionStat extends StatelessWidget {
  final String label;
  final String value;
  final String goal;
  final IconData icon;
  final Color color;

  const _NutritionStat({
    required this.label,
    required this.value,
    required this.goal,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text('$value / $goal'),
      ],
    );
  }
}
