import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/repository_providers.dart';
import 'food_item.dart';

/// Repository for food data management
abstract class FoodRepository {
  /// Search for food items by name
  Future<List<FoodItem>> searchFoodByName(String query, {int limit = 20});

  /// Search for food items by barcode
  Future<List<FoodItem>> searchFoodByBarcode(String barcode);

  /// Get food item by ID
  Future<FoodItem?> getFoodById(String id);

  /// Get all food items created by the user
  Future<List<FoodItem>> getCustomFoods(String userId);

  /// Add a custom food item created by the user
  Future<FoodItem> addCustomFood(FoodItem food);

  /// Update an existing custom food item
  Future<FoodItem> updateCustomFood(FoodItem food);

  /// Delete a custom food item
  Future<void> deleteCustomFood(String foodId);

  /// Get a list of food categories
  Future<List<String>> getFoodCategories();

  /// Get food items by category
  Future<List<FoodItem>> getFoodsByCategory(String category, {int limit = 20});

  /// Get food items marked as favorite by the user
  Future<List<FoodItem>> getFavoriteFoods(String userId);

  /// Get recently used food items
  Future<List<FoodItem>> getRecentFoods(String userId, {int limit = 10});

  /// Add a food item to the user's favorites
  Future<void> addToFavorites(String userId, String foodId);

  /// Remove a food item from the user's favorites
  Future<void> removeFromFavorites(String userId, String foodId);

  /// Mark a food item as recently used
  Future<void> markFoodAsRecentlyUsed(String userId, String foodId);
}

/// Base provider for the food repository
/// This provider is overridden in repository_providers.dart with the real implementation
final baseFoodRepositoryProvider = Provider<FoodRepository>((ref) {
  // Always use the real implementation from repository_providers.dart
  return ref.watch(foodRepositoryProvider);
});
