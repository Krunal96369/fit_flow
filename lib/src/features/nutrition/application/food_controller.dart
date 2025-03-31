import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/barcode_scanner_service.dart';
import '../application/nutrition_controller.dart';
import '../domain/food_item.dart';
import '../domain/food_repository.dart';

/// Controller for food-related operations
class FoodController {
  /// Constructor
  FoodController({
    required this.foodRepository,
    required this.barcodeScannerService,
  });

  /// Repository for food data
  final FoodRepository foodRepository;

  /// Service for scanning barcodes
  final BarcodeScannerService barcodeScannerService;

  /// Search for food items by name
  Future<List<FoodItem>> searchFoodByName(String query,
      {int limit = 20}) async {
    debugPrint('========================================');
    debugPrint('FoodController: searchFoodByName START - query: "$query"');

    if (query.trim().isEmpty) {
      debugPrint('FoodController: Empty query, returning empty list.');
      return [];
    }

    try {
      debugPrint(
          'FoodController: Preparing to search repository for query: "$query"');

      // Check repository type before calling
      debugPrint(
          'FoodController: foodRepository type is ${foodRepository.runtimeType}');

      // CRITICAL: Breakpoint before repository call
      debugPrint(
          'CRITICAL BREAKPOINT: About to await foodRepository.searchFoodByName for "$query"');

      final results =
          await foodRepository.searchFoodByName(query, limit: limit);

      // CRITICAL: Breakpoint after repository call
      debugPrint(
          'CRITICAL BREAKPOINT: Returned from foodRepository.searchFoodByName with ${results.length} results');

      debugPrint(
          'FoodController: Repository search completed. Found ${results.length} results for "$query".');
      debugPrint('FoodController: searchFoodByName END');
      debugPrint('========================================');
      return results;
    } catch (e, stackTrace) {
      // Catch all errors during the repository call or processing
      debugPrint('CRITICAL ERROR in FoodController.searchFoodByName: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('========================================');
      rethrow; // Rethrow the error to be handled by the UI/caller
    }
  }

  /// Search for a food item by barcode
  Future<FoodItem?> searchFoodByBarcode() async {
    try {
      // Scan the barcode
      final barcode = await barcodeScannerService.scanProductBarcode();

      // If scanning was canceled or failed
      if (barcode == null) {
        return null;
      }

      // Search for the food with this barcode
      final foodItems = await foodRepository.searchFoodByBarcode(barcode);

      // Return the first match if found, otherwise null
      return foodItems.isNotEmpty ? foodItems.first : null;
    } catch (e) {
      debugPrint('Error in searchFoodByBarcode: $e');

      // Handle specific error cases
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('api credentials not') ||
          errorMessage.contains('api key') ||
          errorMessage.contains('unauthorized')) {
        debugPrint('FatSecret API credential issue in barcode search: $e');
        // Return null but don't throw, UI can handle null result
      } else if (errorMessage.contains('internet') ||
          errorMessage.contains('timeout') ||
          errorMessage.contains('connection')) {
        debugPrint('Connection issue while scanning barcode: $e');
        // Return null but don't throw, UI can handle null result
      } else if (errorMessage.contains('scanner') ||
          errorMessage.contains('camera') ||
          errorMessage.contains('permission')) {
        debugPrint('Scanner/camera issue: $e');
        // Return null but don't throw, UI can handle null result
      }

      return null;
    }
  }

  /// Search for food by a specific barcode
  Future<FoodItem?> searchByBarcode(String barcode) async {
    try {
      // Search for the food with this barcode
      final foodItems = await foodRepository.searchFoodByBarcode(barcode);

      // Return the first match if found, otherwise null
      return foodItems.isNotEmpty ? foodItems.first : null;
    } catch (e) {
      debugPrint('Error in searchByBarcode: $e');

      // Handle specific error cases
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('api credentials not') ||
          errorMessage.contains('api key') ||
          errorMessage.contains('unauthorized')) {
        debugPrint('FatSecret API credential issue in barcode search: $e');
        // Return null but don't throw, UI can handle null result
      } else if (errorMessage.contains('internet') ||
          errorMessage.contains('timeout') ||
          errorMessage.contains('connection')) {
        debugPrint('Connection issue while scanning barcode: $e');
        // Return null but don't throw, UI can handle null result
      }

      return null;
    }
  }

  /// Get a food item by its ID
  Future<FoodItem?> getFoodById(String id) {
    return foodRepository.getFoodById(id);
  }

  /// Get recently used food items
  Future<List<FoodItem>> getRecentFoods(String userId, {int limit = 10}) async {
    try {
      return await foodRepository.getRecentFoods(userId, limit: limit);
    } catch (e) {
      debugPrint('Error in getRecentFoods: $e');
      // Return empty list to avoid crashing the UI
      return [];
    }
  }

  /// Add a custom food item created by the user
  Future<FoodItem> addCustomFood(FoodItem food) {
    return foodRepository.addCustomFood(food);
  }

  /// Update a custom food item
  Future<FoodItem> updateCustomFood(FoodItem food) {
    return foodRepository.updateCustomFood(food);
  }

  /// Delete a custom food item
  Future<void> deleteCustomFood(String foodId) {
    return foodRepository.deleteCustomFood(foodId);
  }

  /// Get list of food categories
  Future<List<String>> getFoodCategories() {
    return foodRepository.getFoodCategories();
  }

  /// Get food items by category
  Future<List<FoodItem>> getFoodsByCategory(String category, {int limit = 20}) {
    return foodRepository.getFoodsByCategory(category, limit: limit);
  }

  /// Get user's favorite food items
  Future<List<FoodItem>> getFavoriteFoods(String userId) async {
    try {
      return await foodRepository.getFavoriteFoods(userId);
    } catch (e) {
      debugPrint('Error in getFavoriteFoods: $e');
      // Return empty list to avoid crashing the UI
      return [];
    }
  }

  /// Add a food item to user's favorites
  Future<void> addToFavorites(String userId, String foodId) {
    return foodRepository.addToFavorites(userId, foodId);
  }

  /// Remove a food item from user's favorites
  Future<void> removeFromFavorites(String userId, String foodId) {
    return foodRepository.removeFromFavorites(userId, foodId);
  }

  /// Mark a food as recently used
  Future<void> markFoodAsRecentlyUsed(String userId, String foodId) async {
    try {
      await foodRepository.markFoodAsRecentlyUsed(userId, foodId);
    } catch (e) {
      debugPrint('Error marking food as recently used: $e');
      // Swallow the error to not disrupt the UI flow
    }
  }

  /// Save a food item (adds as custom if new, updates if existing)
  Future<FoodItem> saveFoodItem(FoodItem foodItem) {
    if (foodItem.isCustom) {
      return foodRepository.updateCustomFood(foodItem);
    } else {
      return foodRepository.addCustomFood(foodItem);
    }
  }

  /// Toggle a food item's favorite status
  Future<void> toggleFoodFavorite(
    String userId,
    String foodId,
    bool isFavorite,
  ) {
    if (isFavorite) {
      return foodRepository.addToFavorites(userId, foodId);
    } else {
      return foodRepository.removeFromFavorites(userId, foodId);
    }
  }
}

/// Provider for the food controller
final foodControllerProvider = Provider<FoodController>((ref) {
  try {
    final foodRepository = ref.watch(baseFoodRepositoryProvider);
    final barcodeScannerService = ref.watch(barcodeScannerServiceProvider);

    // Add a critical check to ensure we're using the real implementation
    debugPrint(
        'FOOD CONTROLLER: Using repository of type: ${foodRepository.runtimeType}');

    // In release mode, throw an error if we got a mock implementation
    if (kReleaseMode &&
        foodRepository.runtimeType.toString().contains('Mock')) {
      throw Exception(
          'ERROR: Using mock repository in production. This should not happen!');
    }

    return FoodController(
      foodRepository: foodRepository,
      barcodeScannerService: barcodeScannerService,
    );
  } catch (e) {
    // Provide a fallback implementation or mock repository if the real one fails
    debugPrint('Error creating FoodController: $e');
    rethrow; // Re-throw so we don't hide the original error
  }
});

/// Provider for food search results
final foodSearchResultsProvider = FutureProvider.family<List<FoodItem>, String>(
  (ref, query) {
    final controller = ref.watch(foodControllerProvider);
    if (query.trim().isEmpty) {
      return Future.value([]);
    }
    return controller.searchFoodByName(query);
  },
);

/// Provider for recent foods
final recentFoodsProvider = FutureProvider<List<FoodItem>>((ref) {
  final userId = ref.read(currentUserIdProvider).value ?? '';
  final controller = ref.watch(foodControllerProvider);
  return controller.getRecentFoods(userId);
});

/// Provider for favorite foods
final favoriteFoodsProvider = FutureProvider<List<FoodItem>>((ref) {
  final userId = ref.read(currentUserIdProvider).value ?? '';
  final controller = ref.watch(foodControllerProvider);
  return controller.getFavoriteFoods(userId);
});

/// Provider for food categories
final foodCategoriesProvider = FutureProvider<List<String>>((ref) {
  final controller = ref.watch(foodControllerProvider);
  return controller.getFoodCategories();
});

/// Provider for foods by category
final foodsByCategoryProvider = FutureProvider.family<List<FoodItem>, String>((
  ref,
  category,
) {
  final controller = ref.watch(foodControllerProvider);
  return controller.getFoodsByCategory(category);
});
