import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/application/auth_controller.dart';
import '../../../features/nutrition/application/nutrition_controller.dart';
import '../../../features/nutrition/domain/nutrition_summary.dart';

/// Screen for managing nutrition goals in the profile section
class NutritionGoalsScreen extends ConsumerStatefulWidget {
  /// Constructor
  const NutritionGoalsScreen({super.key});

  @override
  ConsumerState<NutritionGoalsScreen> createState() =>
      _NutritionGoalsScreenState();
}

class _NutritionGoalsScreenState extends ConsumerState<NutritionGoalsScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;
  late final TextEditingController _waterController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _caloriesController = TextEditingController();
    _proteinController = TextEditingController();
    _carbsController = TextEditingController();
    _fatController = TextEditingController();
    _waterController = TextEditingController();

    _loadCurrentGoals();
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _waterController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentGoals() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final user = ref.read(authStateProvider).value;
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User not authenticated')));
        return;
      }

      final goals = await ref
          .read(nutritionControllerProvider)
          .getUserNutritionGoals(user.uid);

      // Populate form fields with current values
      _caloriesController.text = goals.calorieGoal.toString();
      _proteinController.text = goals.proteinGoal.toString();
      _carbsController.text = goals.carbsGoal.toString();
      _fatController.text = goals.fatGoal.toString();
      _waterController.text =
          (goals.waterGoal / 1000).toString(); // Convert to liters for display
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading goals: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveGoals() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final user = ref.read(authStateProvider).value;
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User not authenticated')));
        return;
      }

      // Create updated goals object
      final goals = NutritionGoals(
        userId: user.uid,
        calorieGoal: int.parse(_caloriesController.text),
        proteinGoal: double.parse(_proteinController.text),
        carbsGoal: double.parse(_carbsController.text),
        fatGoal: double.parse(_fatController.text),
        waterGoal:
            (double.parse(_waterController.text) * 1000)
                .toInt(), // Convert from liters to ml
      );

      // Save to repository
      await ref.read(nutritionControllerProvider).updateNutritionGoals(goals);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nutrition goals updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving goals: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading && _caloriesController.text.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nutrition Goals')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Nutrition Goals')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Text(
              'Set Your Daily Nutrition Goals',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 24),

            // Calorie goal
            _buildNumberInput(
              controller: _caloriesController,
              label: 'Daily Calorie Goal',
              icon: Icons.local_fire_department,
              helperText: 'Recommended: ${_getRecommendedCalories()} kcal',
              validator: _validateIntegerInput,
            ),
            const SizedBox(height: 16),

            // Macronutrient distribution header
            Text('Macronutrients (grams)', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),

            // Macronutrient inputs
            _buildNumberInput(
              controller: _proteinController,
              label: 'Protein Goal (g)',
              helperText: 'Recommended: 0.8-1.6g per kg of body weight',
              validator: _validateDecimalInput,
            ),
            const SizedBox(height: 16),

            _buildNumberInput(
              controller: _carbsController,
              label: 'Carbohydrates Goal (g)',
              helperText: 'Typically 45-65% of daily calories',
              validator: _validateDecimalInput,
            ),
            const SizedBox(height: 16),

            _buildNumberInput(
              controller: _fatController,
              label: 'Fat Goal (g)',
              helperText: 'Typically 20-35% of daily calories',
              validator: _validateDecimalInput,
            ),
            const SizedBox(height: 24),

            // Water intake
            Text('Hydration', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),

            _buildNumberInput(
              controller: _waterController,
              label: 'Daily Water Goal (liters)',
              icon: Icons.water_drop,
              helperText: 'Recommended: 2.5-3.5 liters per day',
              validator: _validateDecimalInput,
            ),
            const SizedBox(height: 32),

            // Auto calculate button
            OutlinedButton.icon(
              onPressed: _calculateRecommendedValues,
              icon: const Icon(Icons.calculate),
              label: const Text('Auto Calculate Based on Profile'),
            ),
            const SizedBox(height: 16),

            // Save button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveGoals,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Save Nutrition Goals'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberInput({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    String? helperText,
    IconData? icon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        helperText: helperText,
        prefixIcon: icon != null ? Icon(icon) : null,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: validator,
    );
  }

  String? _validateIntegerInput(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a value';
    }

    if (int.tryParse(value) == null) {
      return 'Please enter a valid number';
    }

    if (int.parse(value) <= 0) {
      return 'Value must be greater than 0';
    }

    return null;
  }

  String? _validateDecimalInput(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a value';
    }

    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }

    if (double.parse(value) <= 0) {
      return 'Value must be greater than 0';
    }

    return null;
  }

  // Estimated recommendation based on average needs
  int _getRecommendedCalories() {
    return 2000; // Default for adult
  }

  void _calculateRecommendedValues() {
    // In a real app, this would be calculated based on user profile data
    // such as age, gender, weight, height, activity level
    _caloriesController.text = _getRecommendedCalories().toString();

    // Recommended macro distribution (this is simplified)
    // Protein: 25% of calories, 4 calories per gram
    final proteinGrams = (_getRecommendedCalories() * 0.25 / 4).round();
    _proteinController.text = proteinGrams.toString();

    // Carbs: 50% of calories, 4 calories per gram
    final carbsGrams = (_getRecommendedCalories() * 0.50 / 4).round();
    _carbsController.text = carbsGrams.toString();

    // Fat: 25% of calories, 9 calories per gram
    final fatGrams = (_getRecommendedCalories() * 0.25 / 9).round();
    _fatController.text = fatGrams.toString();

    // Water: 2.5 liters is a standard recommendation
    _waterController.text = '2.5';
  }
}
