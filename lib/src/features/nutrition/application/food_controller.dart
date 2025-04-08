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
      debugPrint('========================================');
      debugPrint(
          'FOOD CONTROLLER: searchByBarcode START - barcode: "$barcode"');

      if (barcode.isEmpty) {
        debugPrint('FOOD CONTROLLER: Empty barcode provided, returning null');
        return null;
      }

      // Log barcode properties
      debugPrint('FOOD CONTROLLER: Barcode length: ${barcode.length}');
      debugPrint(
          'FOOD CONTROLLER: Barcode type: ${_getBarcodeTypeDebug(barcode)}');

      // Clean the barcode (remove non-digits)
      final cleanBarcode = barcode.replaceAll(RegExp(r'[^\d]'), '');
      if (cleanBarcode != barcode) {
        debugPrint(
            'FOOD CONTROLLER: Cleaned barcode (digits only): "$cleanBarcode"');
      }

      // Show expected GTIN-13 format
      if (cleanBarcode.length == 12) {
        debugPrint(
            'FOOD CONTROLLER: This is a UPC-A barcode, should be converted to GTIN-13 by adding leading 0');
      }

      // Search for the food with this barcode
      debugPrint('FOOD CONTROLLER: Calling repository.searchFoodByBarcode');
      final foodItems = await foodRepository.searchFoodByBarcode(barcode);

      debugPrint(
          'FOOD CONTROLLER: Repository returned ${foodItems.length} items');

      // Return the first match if found, otherwise null
      if (foodItems.isNotEmpty) {
        debugPrint(
            'FOOD CONTROLLER: Returning first food item: ${foodItems.first.name}');
        return foodItems.first;
      } else {
        debugPrint(
            'FOOD CONTROLLER: No food items found for barcode "$barcode"');
        return null;
      }
    } catch (e) {
      debugPrint('FOOD CONTROLLER: Error in searchByBarcode: $e');
      debugPrint('FOOD CONTROLLER: Error type: ${e.runtimeType}');

      // Handle specific error cases
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('api credentials not') ||
          errorMessage.contains('api key') ||
          errorMessage.contains('unauthorized')) {
        debugPrint(
            'FOOD CONTROLLER: FatSecret API credential issue in barcode search: $e');
        // Return null but don't throw, UI can handle null result
      } else if (errorMessage.contains('internet') ||
          errorMessage.contains('timeout') ||
          errorMessage.contains('connection')) {
        debugPrint(
            'FOOD CONTROLLER: Connection issue while scanning barcode: $e');
        // Return null but don't throw, UI can handle null result
      } else if (errorMessage.contains('unauthenticated') ||
          errorMessage.contains('authentication') ||
          errorMessage.contains('auth')) {
        debugPrint(
            'FOOD CONTROLLER: Authentication issue with Cloud Functions: $e');
      }

      debugPrint('========================================');
      return null;
    }
  }

  /// Helper method to determine barcode type based on length for debugging
  String _getBarcodeTypeDebug(String barcode) {
    // Clean barcode (digits only)
    final cleanBarcode = barcode.replaceAll(RegExp(r'[^\d]'), '');

    switch (cleanBarcode.length) {
      case 8:
        return cleanBarcode.startsWith('0')
            ? 'UPC-E (8 digits)'
            : 'EAN-8 (8 digits)';
      case 12:
        return 'UPC-A (12 digits)';
      case 13:
        return 'EAN-13/GTIN-13 (13 digits)';
      case 14:
        return 'GTIN-14 (14 digits)';
      default:
        return 'Unknown format (${cleanBarcode.length} digits)';
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
  ///
  /// Adds food as custom if new, updates if existing
  /// [foodItem] The food item to save
  /// Returns the saved food item or the original on error
  Future<FoodItem> saveFoodItem(FoodItem foodItem) async {
    try {
      if (foodItem.isCustom) {
        return await foodRepository.updateCustomFood(foodItem);
      } else {
        return await foodRepository.addCustomFood(foodItem);
      }
    } catch (e) {
      // Log error but return the original food item to avoid UI breaks
      debugPrint('Error saving food item: $e');
      return foodItem;
    }
  }

  /// Toggle a food item's favorite status
  ///
  /// Adds or removes a food from the user's favorites collection
  /// [userId] The ID of the current user
  /// [foodId] The ID of the food to toggle
  /// [isFavorite] True if the food should be added to favorites, false if it should be removed
  /// Returns a Future that completes when the operation is done or silently handles errors
  Future<void> toggleFoodFavorite(
    String userId,
    String foodId,
    bool isFavorite,
  ) async {
    try {
      if (isFavorite) {
        await foodRepository.addToFavorites(userId, foodId);
      } else {
        await foodRepository.removeFromFavorites(userId, foodId);
      }
    } catch (e) {
      // Log the error but don't propagate it to the UI
      debugPrint('Error toggling food favorite: $e');
      // Return normally so UI doesn't break
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
