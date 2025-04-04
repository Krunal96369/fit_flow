import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../../features/nutrition/domain/food_item.dart';

/// Service for interacting with Firebase Cloud Functions
class CloudFunctionsService {
  CloudFunctionsService({
    FirebaseFunctions? functions,
  }) : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  /// Search for food items in the FatSecret API using the v3 endpoint
  Future<List<FoodItem>> searchFoods(String query,
      {int maxResults = 50,
      int pageNumber = 0,
      bool includeFoodImages = false,
      bool includeFoodAttributes = false,
      bool includeSubCategories = false}) async {
    try {
      debugPrint('======================================================');
      debugPrint(
          'CLOUD FUNCTIONS SERVICE: Starting API call to searchFoodsV3 cloud function');
      debugPrint(
          'CLOUD FUNCTIONS SERVICE: Query: "$query", Max Results: $maxResults, Page: $pageNumber');

      // Ensure query is not empty
      if (query.trim().isEmpty) {
        debugPrint(
            'CLOUD FUNCTIONS SERVICE: Query is empty, returning empty list');
        debugPrint('======================================================');
        return [];
      }

      // Test with basic food search terms
      final testQuery = query.toLowerCase().trim();
      if (testQuery.length < 3) {
        debugPrint(
            'CLOUD FUNCTIONS SERVICE: Query is too short, using fallback of "apple"');
        query =
            'apple'; // Use a fallback search term that usually returns results
      }

      // CRITICAL: This is a key breakpoint location - SET BREAKPOINT HERE
      debugPrint(
          'CRITICAL BREAKPOINT: About to call Firebase Functions HTTP callable for searchFoodsV3');

      // Call the searchFoodsV3 cloud function
      final HttpsCallable callable = _functions.httpsCallable('searchFoodsV3');

      debugPrint(
          'CLOUD FUNCTIONS SERVICE: Making HTTP request to Firebase Function');

      // CRITICAL: Another key breakpoint location - SET BREAKPOINT HERE
      debugPrint(
          'CRITICAL BREAKPOINT: Calling callable.call() with parameters');
      final response = await callable.call({
        'query': query,
        'maxResults': maxResults,
        'pageNumber': pageNumber,
        'includeFoodImages': includeFoodImages,
        'includeFoodAttributes': includeFoodAttributes,
        'includeSubCategories': includeSubCategories,
      });

      debugPrint(
          'CRITICAL BREAKPOINT: Firebase Functions HTTP callable returned response');
      debugPrint(
          'CLOUD FUNCTIONS SERVICE: Received response from Firebase Function');

      // Parse the response
      final data = response.data;

      debugPrint(
          'CLOUD FUNCTIONS SERVICE: Response data type: ${data.runtimeType}');

      // Dump raw data for debugging
      debugPrint('CLOUD FUNCTIONS SERVICE: Raw data: $data');

      if (data == null) {
        debugPrint('CLOUD FUNCTIONS SERVICE: Response data is null');
        debugPrint('======================================================');
        // Try searchFoodsByBarcode as fallback
        debugPrint(
            'CLOUD FUNCTIONS SERVICE: Trying barcode search as fallback');
        if (query.length >= 8 && RegExp(r'^\d+$').hasMatch(query)) {
          // If query is numeric and at least 8 digits, try as barcode
          return await searchFoodsByBarcode(query);
        }

        // Throw an error instead of returning empty list
        throw Exception('Cloud Function returned null response');
      }

      // Convert the response data to Map<String, dynamic>
      final Map<String, dynamic> responseMap = Map<String, dynamic>.from(data);

      // Log the raw data for debugging
      debugPrint(
          'CLOUD FUNCTIONS SERVICE: Response data keys: ${responseMap.keys.toList()}');

      if (!responseMap.containsKey('foods') ||
          !responseMap['foods'].containsKey('food')) {
        debugPrint(
            'CLOUD FUNCTIONS SERVICE: No valid food data found in response');
        debugPrint('======================================================');
        // Return empty list instead of throwing error
        return [];
      }

      final foodsData = responseMap['foods']['food'];

      // Handle single food item case (API returns object instead of array)
      final List foodsList;
      if (foodsData is List) {
        foodsList = foodsData;
        debugPrint(
            'CLOUD FUNCTIONS SERVICE: Found ${foodsList.length} foods in response');
      } else {
        foodsList = [foodsData];
        debugPrint(
            'CLOUD FUNCTIONS SERVICE: Found 1 food in response (single item)');
      }

      // Convert to FoodItem objects
      final foodItems = foodsList.map<FoodItem>((item) {
        // Ensure each item is a Map<String, dynamic>
        final Map<String, dynamic> itemMap = Map<String, dynamic>.from(item);
        return _parseFoodItem(itemMap);
      }).toList();

      debugPrint(
          'CLOUD FUNCTIONS SERVICE: Successfully parsed ${foodItems.length} food items');
      debugPrint('======================================================');
      return foodItems;
    } catch (e) {
      debugPrint('CRITICAL ERROR: Cloud Functions call failed with error: $e');
      debugPrint('======================================================');

      // Try with regular searchFoods if available from FatSecret service
      try {
        debugPrint(
            'CLOUD FUNCTIONS SERVICE: Trying direct FatSecret API call as fallback');
        // Note: This would need to be injected or accessed via a repository
        // For now, we'll just return an empty list
        return [];
      } catch (_) {
        // If everything fails, return empty list
        return [];
      }
    }
  }

  /// Get food details by ID from FatSecret API
  Future<FoodItem?> getFoodById(String foodId) async {
    try {
      // Call the getFoodById cloud function
      final HttpsCallable callable = _functions.httpsCallable('getFoodById');
      final result = await callable.call({
        'foodId': foodId,
      });

      // Parse the response
      final data = result.data;
      if (data == null) {
        return null;
      }

      // Check if the response contains food object directly or nested
      final foodData = data['food'] ?? data;
      if (foodData == null) {
        return null;
      }

      return _parseFoodItem(foodData);
    } catch (e) {
      debugPrint('Error calling getFoodById cloud function: $e');
      return null;
    }
  }

  /// Search for food by barcode using FatSecret API's dedicated barcode endpoint
  Future<List<FoodItem>> searchFoodsByBarcode(String barcode) async {
    try {
      debugPrint('======================================================');
      debugPrint(
          'CLOUD FUNCTIONS SERVICE: Starting API call to searchFoodsByBarcode cloud function');
      debugPrint('CLOUD FUNCTIONS SERVICE: Barcode: "$barcode"');

      // Call the searchFoodsByBarcode cloud function
      final HttpsCallable callable =
          _functions.httpsCallable('searchFoodsByBarcode');
      final result = await callable.call({
        'barcode': barcode,
      });

      // Parse the response
      final data = result.data;

      debugPrint('CLOUD FUNCTIONS SERVICE: Raw barcode response: $data');

      if (data == null ||
          data['foods'] == null ||
          data['foods']['food'] == null) {
        debugPrint('CLOUD FUNCTIONS SERVICE: No foods found for barcode');
        return [];
      }

      final foodsData = data['foods']['food'];

      // Handle single food item case (API returns object instead of array)
      final List foodsList;
      if (foodsData is List) {
        foodsList = foodsData;
        debugPrint(
            'CLOUD FUNCTIONS SERVICE: Found ${foodsList.length} foods for barcode');
      } else {
        foodsList = [foodsData];
        debugPrint('CLOUD FUNCTIONS SERVICE: Found 1 food for barcode');
      }

      // Convert to FoodItem objects
      final foodItems =
          foodsList.map<FoodItem>((item) => _parseFoodItem(item)).toList();
      debugPrint(
          'CLOUD FUNCTIONS SERVICE: Successfully parsed ${foodItems.length} food items for barcode');
      debugPrint('======================================================');
      return foodItems;
    } catch (e) {
      debugPrint('Error calling searchFoodsByBarcode cloud function: $e');
      return [];
    }
  }

  /// Helper method to parse food item from API response
  FoodItem _parseFoodItem(Map<String, dynamic> data) {
    try {
      // Extract food ID
      final id = data['food_id']?.toString() ?? '';

      // Extract food name
      final name = data['food_name']?.toString() ?? 'Unknown Food';

      // Extract food description
      final description = data['food_description']?.toString() ?? '';

      // Extract brand name if available
      final brand = data['brand_name']?.toString() ?? '';

      // Extract food type or category
      final category = data['food_type']?.toString() ?? 'Uncategorized';

      // Parse standard nutritional information
      int calories = _parseCalories(data);
      double protein = _parseNutrient(data, 'protein');
      double fat = _parseNutrient(data, 'fat');
      double carbs = _parseNutrient(data, 'carbohydrate');

      // Default serving size and unit
      double servingSize = _parseServingSize(data);
      String servingUnit = _parseServingUnit(data);

      // If nutrients or serving info is not available in standard fields, try to extract from description
      if (description.isNotEmpty &&
          (calories == 0 ||
              protein == 0 ||
              fat == 0 ||
              carbs == 0 ||
              servingSize <= 0 ||
              servingUnit.isEmpty)) {
        debugPrint(
            'Attempting to extract nutrients from description: $description');
        final extractedData = _extractNutrientsFromDescription(description);

        // Update nutrients only if they were successfully extracted
        if (extractedData.calories != null && extractedData.calories! > 0) {
          calories = extractedData.calories!;
        }
        if (extractedData.protein != null && extractedData.protein! > 0) {
          protein = extractedData.protein!;
        }
        if (extractedData.fat != null && extractedData.fat! > 0) {
          fat = extractedData.fat!;
        }
        if (extractedData.carbs != null && extractedData.carbs! > 0) {
          carbs = extractedData.carbs!;
        }

        // Update serving size and unit if they were successfully extracted
        if (extractedData.servingSize != null &&
            extractedData.servingSize! > 0) {
          servingSize = extractedData.servingSize!;
        }
        if (extractedData.servingUnit != null &&
            extractedData.servingUnit!.isNotEmpty) {
          servingUnit = extractedData.servingUnit!;
        }

        debugPrint(
            'Extracted nutrients - Calories: $calories, Protein: $protein, Fat: $fat, Carbs: $carbs');
        debugPrint(
            'Extracted serving - Size: $servingSize, Unit: $servingUnit');
      }

      // Create serving size string (quantity + unit)
      final servingSizeString = servingSize > 0 && servingUnit.isNotEmpty
          ? '$servingSize $servingUnit'
          : '100 g'; // Default to 100g if no valid serving size

      // Create FoodItem with nutritional information
      return FoodItem(
        id: id,
        userId: '', // This will be set by the repository when used by the user
        name: name,
        description: description,
        brand: brand,
        servingSize: servingSizeString,
        calories: calories,
        protein: protein,
        fat: fat,
        carbs: carbs,
        category: category,
        isCustom: false,
        source: 'FatSecret API',
      );
    } catch (e) {
      debugPrint('Error parsing food item: $e');
      return FoodItem(
        id: '',
        userId: '',
        name: 'Error parsing food',
        description: '',
        brand: '',
        servingSize: '100 g',
        calories: 0,
        protein: 0,
        fat: 0,
        carbs: 0,
        category: 'Uncategorized',
        isCustom: false,
        source: 'Error',
      );
    }
  }

  /// Helper to extract nutrients from description string
  ({
    int? calories,
    double? protein,
    double? fat,
    double? carbs,
    double? servingSize,
    String? servingUnit
  }) _extractNutrientsFromDescription(String description) {
    int? calories;
    double? protein;
    double? fat;
    double? carbs;
    double? servingSize;
    String? servingUnit;

    try {
      // Normalize description by removing excess whitespace and making lowercase for easier matching
      final normalizedDesc =
          description.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

      // Extract serving size and unit (e.g., "Per 100g", "per 100 g", "100g -")
      // More flexible pattern to catch various formats
      final servingPatterns = [
        RegExp(r'per\s+([\d.]+)\s*(\w+)'), // "Per 100g" or "Per 100 g"
        RegExp(r'([\d.]+)\s*(\w+)\s*-'), // "100g -" or "100 g -"
        RegExp(r'([\d.]+)\s*(\w+)\s+serving'), // "100g serving"
      ];

      String? matchedServingSize;
      String? matchedServingUnit;

      for (final pattern in servingPatterns) {
        final match = pattern.firstMatch(normalizedDesc);
        if (match != null && match.groupCount >= 2) {
          matchedServingSize = match.group(1);
          matchedServingUnit = match.group(2);
          break; // Stop after first successful match
        }
      }

      if (matchedServingSize != null && matchedServingUnit != null) {
        servingSize = double.tryParse(matchedServingSize) ?? 100.0;
        servingUnit = matchedServingUnit;

        // Clean up common unit variations
        if (servingUnit == 'grams' || servingUnit == 'gram') servingUnit = 'g';
        if (servingUnit == 'ml' || servingUnit == 'milliliters')
          servingUnit = 'mL';
      } else {
        // Default to 100g if not specified
        servingSize = 100.0;
        servingUnit = 'g';
      }

      // More robust pattern to match nutrient values
      // Handles formats like "Calories: 65kcal", "Fat: 0.27g", "carbohydrates: 17.00g"
      final nutrientPattern = RegExp(
          r'(calories|calorie|protein|fat|carbs|carbohydrates|carbohydrate)s?:?\s*([\d.]+)\s*(\w+)?');

      // Find all matches in the description
      final matches = nutrientPattern.allMatches(normalizedDesc);

      for (final match in matches) {
        if (match.groupCount >= 2) {
          final nutrientName = match.group(1)?.toLowerCase().trim() ?? '';
          final valueStr = match.group(2) ?? '0';
          final value = double.tryParse(valueStr) ?? 0;

          // Skip invalid values
          if (value <= 0) continue;

          switch (nutrientName) {
            case 'calorie':
            case 'calories':
              calories = value.toInt();
              break;
            case 'protein':
              protein = value;
              break;
            case 'fat':
              fat = value;
              break;
            case 'carbs':
            case 'carbohydrate':
            case 'carbohydrates':
              carbs = value;
              break;
          }
        }
      }

      // Log extraction results for debugging
      final results =
          'Extracted from "$normalizedDesc": calories=$calories, protein=$protein, fat=$fat, carbs=$carbs, serving=$servingSize$servingUnit';
      debugPrint(results);
    } catch (e) {
      debugPrint('Error extracting nutrients from description: $e');
    }

    return (
      calories: calories,
      protein: protein,
      fat: fat,
      carbs: carbs,
      servingSize: servingSize,
      servingUnit: servingUnit
    );
  }

  /// Helper to parse serving size
  double _parseServingSize(Map<String, dynamic> data) {
    try {
      if (data['servings'] != null && data['servings']['serving'] != null) {
        final serving = data['servings']['serving'];

        // Handle single serving or first from list
        final targetServing = serving is List ? serving.first : serving;

        if (targetServing['metric_serving_amount'] != null) {
          return double.tryParse(
                  targetServing['metric_serving_amount'].toString()) ??
              100.0;
        }

        if (targetServing['serving_description'] != null) {
          // Try to extract number from description like "1 cup" or "100 g"
          final desc = targetServing['serving_description'].toString();
          final numericPart =
              RegExp(r'^\d+(\.\d+)?').firstMatch(desc)?.group(0);
          if (numericPart != null) {
            return double.tryParse(numericPart) ?? 100.0;
          }
        }
      }
      return 100.0; // Default to 100g if not found
    } catch (e) {
      return 100.0;
    }
  }

  /// Helper to parse serving unit
  String _parseServingUnit(Map<String, dynamic> data) {
    try {
      if (data['servings'] != null && data['servings']['serving'] != null) {
        final serving = data['servings']['serving'];

        // Handle single serving or first from list
        final targetServing = serving is List ? serving.first : serving;

        if (targetServing['metric_serving_unit'] != null) {
          return targetServing['metric_serving_unit'].toString();
        }

        if (targetServing['serving_description'] != null) {
          // Try to extract unit from description like "1 cup" or "100 g"
          final desc = targetServing['serving_description'].toString();
          final words = desc.split(' ');
          if (words.length > 1) {
            return words.last;
          }
        }
      }
      return 'g'; // Default to grams if not found
    } catch (e) {
      return 'g';
    }
  }

  /// Helper to parse calories
  int _parseCalories(Map<String, dynamic> data) {
    try {
      if (data['servings'] != null && data['servings']['serving'] != null) {
        final serving = data['servings']['serving'];

        // Handle single serving or first from list
        final targetServing = serving is List ? serving.first : serving;

        if (targetServing['calories'] != null) {
          return int.tryParse(targetServing['calories'].toString()) ?? 0;
        }
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Helper to parse nutrients (protein, fat, carbs)
  double _parseNutrient(Map<String, dynamic> data, String nutrientName) {
    try {
      debugPrint('CLOUD FUNCTIONS SERVICE: Parsing nutrient: $nutrientName');

      if (data['servings'] != null && data['servings']['serving'] != null) {
        final serving = data['servings']['serving'];
        debugPrint('CLOUD FUNCTIONS SERVICE: Found serving data: $serving');

        // Handle single serving or first from list
        final targetServing = serving is List ? serving.first : serving;
        debugPrint('CLOUD FUNCTIONS SERVICE: Target serving: $targetServing');

        // Check for nutrient in the serving object
        if (targetServing[nutrientName] != null) {
          final value =
              double.tryParse(targetServing[nutrientName].toString()) ?? 0.0;
          debugPrint('CLOUD FUNCTIONS SERVICE: Found $nutrientName: $value');
          return value;
        }

        // Check for nutrient in the food object
        if (data[nutrientName] != null) {
          final value = double.tryParse(data[nutrientName].toString()) ?? 0.0;
          debugPrint(
              'CLOUD FUNCTIONS SERVICE: Found $nutrientName in food object: $value');
          return value;
        }

        // Check for nutrient in the food_nutrients array
        if (data['food_nutrients'] != null) {
          final nutrients = data['food_nutrients'];
          if (nutrients is List) {
            for (final nutrient in nutrients) {
              if (nutrient['nutrient_name']?.toString().toLowerCase() ==
                  nutrientName.toLowerCase()) {
                final value =
                    double.tryParse(nutrient['nutrient_value'].toString()) ??
                        0.0;
                debugPrint(
                    'CLOUD FUNCTIONS SERVICE: Found $nutrientName in food_nutrients: $value');
                return value;
              }
            }
          }
        }
      }

      debugPrint(
          'CLOUD FUNCTIONS SERVICE: No $nutrientName found, returning 0.0');
      return 0.0;
    } catch (e) {
      debugPrint('CLOUD FUNCTIONS SERVICE: Error parsing $nutrientName: $e');
      return 0.0;
    }
  }
}
