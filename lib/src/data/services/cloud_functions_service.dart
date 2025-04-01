import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../../features/nutrition/domain/food_item.dart';

/// Service for interacting with Firebase Cloud Functions
class CloudFunctionsService {
  CloudFunctionsService({
    FirebaseFunctions? functions,
  }) : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  /// Search for food items in the FatSecret API
  Future<List<FoodItem>> searchFoods(String query,
      {int maxResults = 50}) async {
    try {
      debugPrint('======================================================');
      debugPrint(
          'CLOUD FUNCTIONS SERVICE: Starting API call to searchFoods cloud function');
      debugPrint(
          'CLOUD FUNCTIONS SERVICE: Query: "$query", Max Results: $maxResults');

      // CRITICAL: This is a key breakpoint location - SET BREAKPOINT HERE
      debugPrint(
          'CRITICAL BREAKPOINT: About to call Firebase Functions HTTP callable for searchFoods');

      // Call the searchFoods cloud function
      final HttpsCallable callable = _functions.httpsCallable('searchFoods');

      debugPrint(
          'CLOUD FUNCTIONS SERVICE: Making HTTP request to Firebase Function');

      // CRITICAL: Another key breakpoint location - SET BREAKPOINT HERE
      debugPrint(
          'CRITICAL BREAKPOINT: Calling callable.call() with parameters');
      final response = await callable.call({
        'query': query,
        'maxResults': maxResults,
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
        // Throw an error instead of returning empty list
        throw Exception('Cloud Function returned null response');
      }

      // Log the raw data for debugging
      if (data is Map) {
        debugPrint(
            'CLOUD FUNCTIONS SERVICE: Response data keys: ${data.keys.toList()}');
      }

      if (data == null ||
          data['foods'] == null ||
          data['foods']['food'] == null) {
        debugPrint(
            'CLOUD FUNCTIONS SERVICE: No valid food data found in response');
        debugPrint('======================================================');
        // Throw an error with the actual response for debugging
        throw Exception('Invalid response structure: $data');
      }

      final foodsData = data['foods']['food'];

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
      final foodItems =
          foodsList.map<FoodItem>((item) => _parseFoodItem(item)).toList();
      debugPrint(
          'CLOUD FUNCTIONS SERVICE: Successfully parsed ${foodItems.length} food items');
      debugPrint('======================================================');
      return foodItems;
    } catch (e) {
      debugPrint('CRITICAL ERROR: Cloud Functions call failed with error: $e');
      debugPrint('======================================================');
      // Rethrow to see actual errors
      rethrow;
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
      if (data == null || data['food'] == null) {
        return null;
      }

      return _parseFoodItem(data['food']);
    } catch (e) {
      debugPrint('Error calling getFoodById cloud function: $e');
      return null;
    }
  }

  /// Search for food by barcode using FatSecret API
  Future<List<FoodItem>> searchFoodsByBarcode(String barcode) async {
    try {
      debugPrint('======================================================');
      debugPrint(
          'CLOUD FUNCTIONS SERVICE: Starting barcode search for: "$barcode"');

      // Format barcode to GTIN-13 if needed (pad with leading zeros)
      final formattedBarcode = _formatBarcodeToGTIN13(barcode);
      debugPrint(
          'CLOUD FUNCTIONS SERVICE: Formatted barcode: "$formattedBarcode"');

      // Call the searchFoodsByBarcode cloud function
      final HttpsCallable callable =
          _functions.httpsCallable('searchFoodsByBarcode');

      debugPrint(
          'CRITICAL BREAKPOINT: About to call searchFoodsByBarcode cloud function');
      final result = await callable.call({
        'barcode': formattedBarcode,
        'maxResults': 10,
      });

      debugPrint(
          'CLOUD FUNCTIONS SERVICE: Received response from barcode search');

      // Parse the response
      final data = result.data;
      if (data == null) {
        debugPrint('CLOUD FUNCTIONS SERVICE: Response data is null');
        debugPrint('======================================================');
        throw Exception('Cloud Function returned null response');
      }

      debugPrint(
          'CLOUD FUNCTIONS SERVICE: Response data type: ${data.runtimeType}');
      debugPrint('CLOUD FUNCTIONS SERVICE: Raw data: $data');

      if (data['foods'] == null || data['foods']['food'] == null) {
        debugPrint(
            'CLOUD FUNCTIONS SERVICE: No valid food data found in response');
        debugPrint('======================================================');
        return [];
      }

      final foodsData = data['foods']['food'];

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

      // Convert to FoodItem objects and add barcode
      final foodItems = foodsList.map<FoodItem>((item) {
        final foodItem = _parseFoodItem(item);
        return foodItem.copyWith(barcode: barcode);
      }).toList();

      debugPrint(
          'CLOUD FUNCTIONS SERVICE: Successfully parsed ${foodItems.length} food items');
      debugPrint('======================================================');
      return foodItems;
    } catch (e) {
      debugPrint('CRITICAL ERROR: Cloud Functions barcode search failed: $e');
      debugPrint('======================================================');
      rethrow; // Let the repository handle the error
    }
  }

  /// Helper method to format barcode to GTIN-13 format
  /// FatSecret requires barcodes in GTIN-13 format (13 digits)
  String _formatBarcodeToGTIN13(String barcode) {
    // Remove any non-digit characters
    final digitsOnly = barcode.replaceAll(RegExp(r'[^\d]'), '');

    // If it's already 13 digits, return as is
    if (digitsOnly.length == 13) {
      return digitsOnly;
    }

    // If it's UPC-A (12 digits), add leading zero
    if (digitsOnly.length == 12) {
      return '0$digitsOnly';
    }

    // If it's EAN-8 (8 digits), pad with zeros
    if (digitsOnly.length == 8) {
      return '00000$digitsOnly';
    }

    // For other formats, pad with zeros to make 13 digits
    if (digitsOnly.length < 13) {
      return digitsOnly.padLeft(13, '0');
    }

    // If longer than 13 digits, truncate to first 13
    return digitsOnly.substring(0, 13);
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

      // Create serving size string (quantity + unit)
      final servingSize =
          '${_parseServingSize(data)} ${_parseServingUnit(data)}';

      // Create FoodItem with nutritional information if available
      return FoodItem(
        id: id,
        userId: '', // This will be set by the repository when used by the user
        name: name,
        description: description,
        brand: brand,
        servingSize: servingSize,
        calories: _parseCalories(data),
        protein: _parseNutrient(data, 'protein'),
        fat: _parseNutrient(data, 'fat'),
        carbs: _parseNutrient(data, 'carbohydrate'),
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
      if (data['servings'] != null && data['servings']['serving'] != null) {
        final serving = data['servings']['serving'];

        // Handle single serving or first from list
        final targetServing = serving is List ? serving.first : serving;

        if (targetServing[nutrientName] != null) {
          return double.tryParse(targetServing[nutrientName].toString()) ?? 0.0;
        }
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }
}
