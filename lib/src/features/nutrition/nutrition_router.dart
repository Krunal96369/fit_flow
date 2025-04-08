import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'domain/food_item.dart';
import 'presentation/add_nutrition_entry_screen.dart';
import 'presentation/food_search_screen.dart';
import 'presentation/nutrition_dashboard_screen.dart';

/// Router configuration for nutrition feature
final nutritionRoutes = [
  GoRoute(
    path: '/nutrition',
    name: 'nutrition',
    builder: (context, state) => const NutritionDashboardScreen(),
    routes: [
      GoRoute(
        path: 'add',
        name: 'add-nutrition',
        builder: (context, state) {
          final date = state.uri.queryParameters['date'] != null
              ? DateTime.parse(state.uri.queryParameters['date']!)
              : DateTime.now();

          // Check if we have a food item passed in the extra parameter
          final FoodItem? foodItem = state.extra as FoodItem?;

          return AddNutritionEntryScreen(date: date, foodItem: foodItem);
        },
      ),
      GoRoute(
        path: 'search',
        name: 'food-search',
        builder: (context, state) {
          final date = state.uri.queryParameters['date'] != null
              ? DateTime.parse(state.uri.queryParameters['date']!)
              : DateTime.now();

          return FoodSearchScreen(date: date);
        },
      ),
    ],
  ),
];

/// Extension methods for navigating to nutrition screens
extension NutritionRouterExtension on BuildContext {
  /// Navigate to the nutrition dashboard
  void goToNutritionDashboard() {
    GoRouter.of(this).goNamed('nutrition');
  }

  /// Navigate to add nutrition entry screen
  void goToAddNutrition({DateTime? date, FoodItem? foodItem}) {
    final queryParams = <String, String>{};
    if (date != null) {
      queryParams['date'] = date.toIso8601String();
    }
    GoRouter.of(
      this,
    ).goNamed('add-nutrition', queryParameters: queryParams, extra: foodItem);
  }

  /// Navigate to food search screen
  void goToFoodSearch({required DateTime date}) {
    final queryParams = <String, String>{'date': date.toIso8601String()};
    GoRouter.of(this).goNamed('food-search', queryParameters: queryParams);
  }
}
