import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../features/auth/application/auth_controller.dart';
import '../application/food_controller.dart';
import '../application/nutrition_controller.dart';
import '../domain/food_item.dart';
import '../domain/nutrition_entry.dart';

/// Screen for adding a new nutrition entry
class AddNutritionEntryScreen extends ConsumerStatefulWidget {
  /// Date for which the entry is being added
  final DateTime date;

  /// Food item to pre-fill (optional)
  final FoodItem? foodItem;

  /// Constructor
  const AddNutritionEntryScreen({super.key, required this.date, this.foodItem});

  @override
  ConsumerState<AddNutritionEntryScreen> createState() =>
      _AddNutritionEntryScreenState();
}

class _AddNutritionEntryScreenState
    extends ConsumerState<AddNutritionEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;
  late final TextEditingController _servingSizeController;
  late final TextEditingController _servingsController;

  String? _selectedMealType;
  TimeOfDay _consumedTime = TimeOfDay.now();
  bool _isFavorite = false;
  bool _isLoading = false;

  // List of meal types
  final List<String> _mealTypes = [
    'Breakfast',
    'Morning Snack',
    'Lunch',
    'Afternoon Snack',
    'Dinner',
    'Evening Snack',
  ];

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _nameController = TextEditingController();
    _caloriesController = TextEditingController();
    _proteinController = TextEditingController();
    _carbsController = TextEditingController();
    _fatController = TextEditingController();
    _servingSizeController = TextEditingController();
    _servingsController = TextEditingController(text: '1');

    // Set default meal type based on current time
    _setDefaultMealType();

    // Pre-fill with food item if provided
    if (widget.foodItem != null) {
      _prefillWithFoodItem(widget.foodItem!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _servingSizeController.dispose();
    _servingsController.dispose();
    super.dispose();
  }

  void _setDefaultMealType() {
    final hour = TimeOfDay.now().hour;

    if (hour >= 5 && hour < 10) {
      _selectedMealType = 'Breakfast';
    } else if (hour >= 10 && hour < 12) {
      _selectedMealType = 'Morning Snack';
    } else if (hour >= 12 && hour < 15) {
      _selectedMealType = 'Lunch';
    } else if (hour >= 15 && hour < 18) {
      _selectedMealType = 'Afternoon Snack';
    } else if (hour >= 18 && hour < 21) {
      _selectedMealType = 'Dinner';
    } else {
      _selectedMealType = 'Evening Snack';
    }
  }

  void _prefillWithFoodItem(FoodItem foodItem) {
    _nameController.text = foodItem.name;
    _caloriesController.text = foodItem.calories.toString();
    _proteinController.text = foodItem.protein.toString();
    _carbsController.text = foodItem.carbs.toString();
    _fatController.text = foodItem.fat.toString();
    _servingSizeController.text = foodItem.servingSize;
    _isFavorite = foodItem.isFavorite;
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // Get current user ID
      final user = ref.read(authStateProvider).value;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not authenticated')),
          );
        }
        return;
      }

      // Prepare entry data
      final servings = double.parse(_servingsController.text);
      final calories = (int.parse(_caloriesController.text) * servings).toInt();
      final protein = double.parse(_proteinController.text) * servings;
      final carbs = double.parse(_carbsController.text) * servings;
      final fat = double.parse(_fatController.text) * servings;

      // Create a DateTime with the date from widget.date and time from _consumedTime
      final consumedAt = DateTime(
        widget.date.year,
        widget.date.month,
        widget.date.day,
        _consumedTime.hour,
        _consumedTime.minute,
      );

      // Create the nutrition entry
      final entry = NutritionEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        userId: user.uid,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        servingSize: _servingSizeController.text,
        servings: servings,
        mealType: _selectedMealType ?? 'Other',
        consumedAt: consumedAt,
      );

      // Save the entry
      await ref.read(nutritionControllerProvider).addEntry(entry);

      // Explicitly invalidate related providers to force refresh
      ref.invalidate(dailyNutritionEntriesProvider(widget.date));
      ref.invalidate(dailyNutritionSummaryProvider(widget.date));

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${entry.name} added to your log'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Save or update food item if it's marked as favorite
      if (_isFavorite) {
        try {
          final foodItem = FoodItem(
            id: widget.foodItem?.id ??
                DateTime.now().millisecondsSinceEpoch.toString(),
            name: _nameController.text,
            calories: int.parse(_caloriesController.text),
            protein: double.parse(_proteinController.text),
            carbs: double.parse(_carbsController.text),
            fat: double.parse(_fatController.text),
            servingSize: _servingSizeController.text,
            category: 'User Foods',
            isFavorite: true,
            isCustom: true,
            description: '',
            userId: user.uid,
            createdAt: DateTime.now(),
          );

          await ref
              .read(foodControllerProvider)
              .saveFoodItem(foodItem)
              .catchError((error) {
            // Log the error but don't fail the entire operation
            debugPrint('Error saving favorite food: $error');

            // Show a snackbar if mounted
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Food entry saved, but could not save as favorite due to permission issues.'),
                  duration: Duration(seconds: 3),
                ),
              );
            }
            return foodItem; // Return the original food item instead of null
          });
        } catch (favError) {
          // Log error but don't prevent navigation back
          debugPrint('Error handling favorite: $favError');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('Food entry saved, but could not save as favorite.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }

      if (mounted) {
        // Return to previous screen
        GoRouter.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving entry: ${e.toString()}')),
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

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _consumedTime,
    );

    if (picked != null && picked != _consumedTime) {
      setState(() {
        _consumedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Add Food - ${DateFormat.yMMMd().format(widget.date)}'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Search food button
            if (widget.foodItem == null)
              OutlinedButton.icon(
                onPressed: () {
                  context.go(
                    '/nutrition/search?date=${widget.date.toIso8601String()}',
                  );
                },
                icon: const Icon(Icons.search),
                label: const Text('Search Food Database'),
              ),

            const SizedBox(height: 16),

            // Food name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Food Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.restaurant),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a food name';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Meal type dropdown
            DropdownButtonFormField<String>(
              value: _selectedMealType,
              decoration: const InputDecoration(
                labelText: 'Meal',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: _mealTypes.map((String mealType) {
                return DropdownMenuItem<String>(
                  value: mealType,
                  child: Text(mealType),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedMealType = newValue;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a meal type';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Time consumed
            InkWell(
              onTap: _selectTime,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Time Consumed',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                ),
                child: Text(_consumedTime.format(context)),
              ),
            ),

            const SizedBox(height: 24),

            // Nutrition info header
            Text(
              'Nutrition Info (per serving)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // Calories
            TextFormField(
              controller: _caloriesController,
              decoration: const InputDecoration(
                labelText: 'Calories',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_fire_department),
                suffixText: 'kcal',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter calories';
                }
                if (int.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Macronutrients row
            Row(
              children: [
                // Protein
                Expanded(
                  child: TextFormField(
                    controller: _proteinController,
                    decoration: const InputDecoration(
                      labelText: 'Protein',
                      border: OutlineInputBorder(),
                      suffixText: 'g',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(width: 8),

                // Carbs
                Expanded(
                  child: TextFormField(
                    controller: _carbsController,
                    decoration: const InputDecoration(
                      labelText: 'Carbs',
                      border: OutlineInputBorder(),
                      suffixText: 'g',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(width: 8),

                // Fat
                Expanded(
                  child: TextFormField(
                    controller: _fatController,
                    decoration: const InputDecoration(
                      labelText: 'Fat',
                      border: OutlineInputBorder(),
                      suffixText: 'g',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Serving info
            Text(
              'Serving Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // Serving size
            TextFormField(
              controller: _servingSizeController,
              decoration: const InputDecoration(
                labelText: 'Serving Size',
                hintText: 'e.g., 100g, 1 cup, 1 slice',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.scale),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter serving size';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Number of servings
            TextFormField(
              controller: _servingsController,
              decoration: const InputDecoration(
                labelText: 'Number of Servings',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.exposure),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter servings';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                if (double.parse(value) <= 0) {
                  return 'Must be greater than 0';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Save as favorite checkbox
            CheckboxListTile(
              title: const Text('Save as Favorite'),
              subtitle: const Text(
                'Add this food to your favorites for quick access',
              ),
              value: _isFavorite,
              onChanged: (bool? value) {
                setState(() {
                  _isFavorite = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),

            const SizedBox(height: 24),

            // Save button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveEntry,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Food Entry'),
            ),
          ],
        ),
      ),
    );
  }
}
