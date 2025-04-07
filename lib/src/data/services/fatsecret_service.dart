import 'dart:async';
import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../features/nutrition/domain/food_item.dart';

/// Service that provides access to the FatSecret Food API
/// This implementation uses OAuth 2.0 authentication
class FatSecretService {
  // FatSecret API credentials (stored in Remote Config for security)
  String? _clientId;
  String? _clientSecret;
  final http.Client _httpClient;
  final FirebaseRemoteConfig _remoteConfig;

  /// API endpoint URLs
  static const String _baseUrl =
      'https://platform.fatsecret.com/rest/server.api';
  static const String _oauthUrl = 'https://oauth.fatsecret.com/connect/token';

  /// Remote Config keys
  static const String _apiKeyConfigKey = 'fatsecret_api_key';
  static const String _apiSecretConfigKey = 'fatsecret_api_secret';

  /// OAuth token storage
  String? _accessToken;
  DateTime? _tokenExpiry;
  bool _initialized = false;

  /// Creates a [FatSecretService].
  FatSecretService({
    required FirebaseRemoteConfig remoteConfig,
    http.Client? httpClient,
  })  : _remoteConfig = remoteConfig,
        _httpClient = httpClient ?? http.Client();

  /// Initialize the service by fetching credentials from Remote Config
  Future<bool> initialize() async {
    try {
      // Fetch the latest config
      await _remoteConfig.fetchAndActivate();

      // Get credentials
      _clientId = _remoteConfig.getString(_apiKeyConfigKey);
      _clientSecret = _remoteConfig.getString(_apiSecretConfigKey);

      // Check if credentials are missing or empty
      final hasValidKey = _clientId != null && _clientId!.isNotEmpty;
      final hasValidSecret = _clientSecret != null && _clientSecret!.isNotEmpty;

      if (!hasValidKey || !hasValidSecret) {
        debugPrint(
          'Warning: FatSecret API credentials not found in Remote Config',
        );
        _initialized = false;
        return false;
      } else {
        _initialized = true;
        return true;
      }
    } catch (e) {
      debugPrint('Error initializing FatSecret service: $e');
      _initialized = false;
      return false;
    }
  }

  /// Get an OAuth 2.0 access token
  Future<String?> _getAccessToken() async {
    try {
      // Ensure the service is initialized
      if (!_initialized) {
        final success = await initialize();
        if (!success) {
          return null;
        }
      }

      // Check if credentials are available
      if (_clientId == null ||
          _clientSecret == null ||
          _clientId!.isEmpty ||
          _clientSecret!.isEmpty) {
        debugPrint('FatSecret API credentials not set in Remote Config');
        return null;
      }

      // Check if we already have a valid token
      if (_accessToken != null &&
          _tokenExpiry != null &&
          _tokenExpiry!.isAfter(DateTime.now())) {
        return _accessToken!;
      }

      // Create Basic Auth header with client_id:client_secret
      final basicAuth =
          'Basic ${base64Encode(utf8.encode('$_clientId:$_clientSecret'))}';

      try {
        // Request a new token
        final response = await _httpClient.post(
          Uri.parse(_oauthUrl),
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Authorization': basicAuth,
          },
          body: {
            'grant_type': 'client_credentials',
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          _accessToken = data['access_token'];

          // Set token expiry (subtract 5 minutes for safety margin)
          final expiresIn = data['expires_in'] as int;
          _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 300));

          debugPrint('FatSecret: Successfully obtained OAuth token');
          return _accessToken!;
        } else {
          debugPrint(
            'Failed to get access token: ${response.statusCode} ${response.body}',
          );
          return null;
        }
      } catch (e) {
        debugPrint('Error getting FatSecret access token: $e');
        return null;
      }
    } catch (e) {
      debugPrint('Unexpected error in _getAccessToken: $e');
      return null;
    }
  }

  /// Search for food items in the FatSecret database
  Future<List<FoodItem>> searchFoods(
    String query, {
    int maxResults = 20,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      // Get an access token
      final token = await _getAccessToken();
      if (token == null) {
        debugPrint('Could not obtain access token for FatSecret API');
        return [];
      }

      debugPrint('FatSecret: Searching for "$query" with OAuth 2.0');

      // Execute request with Bearer token - POST request with form-encoded parameters
      final response = await _httpClient.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'method': 'foods.search',
          'search_expression': query,
          'max_results': maxResults.toString(),
          'format': 'json',
        },
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException(
            'FatSecret API search timed out after 10 seconds');
      });

      if (response.statusCode == 200) {
        debugPrint('FatSecret: Received 200 response for "$query"');
        debugPrint('FatSecret: Received response for "$response"');

        final Map<String, dynamic> data = json.decode(response.body);

        // Add response data debugging
        debugPrint('FatSecret response keys: ${data.keys.join(', ')}');

        // Check if foods were found
        if (data['foods'] == null) {
          debugPrint('FatSecret: No "foods" key in response');
          return [];
        }

        if (data['foods']['total_results'] != null) {
          debugPrint(
              'FatSecret: Total results: ${data['foods']['total_results']}');
        }

        if (data['foods']['food'] == null) {
          debugPrint('FatSecret: No "food" key in response');
          return [];
        }

        // Extract food items
        final foodsData = data['foods']['food'];
        debugPrint('FatSecret: Found results, extracting food items');

        // Handle single food item case (API returns object instead of array)
        final List foodsList;
        if (foodsData is List) {
          foodsList = foodsData;
          debugPrint(
              'FatSecret: Response contains a list of ${foodsList.length} foods');
        } else {
          foodsList = [foodsData];
          debugPrint('FatSecret: Response contains a single food item');
        }

        // Convert to FoodItem objects
        final foods = foodsList
            .map<FoodItem>((dynamic foodData) =>
                _parseFoodItem(foodData as Map<String, dynamic>))
            .toList();
        debugPrint('FatSecret: Converted ${foods.length} food items');

        return foods;
      } else {
        final error =
            'FatSecret API error: ${response.statusCode} ${response.body}';
        debugPrint(error);
        return [];
      }
    } catch (e) {
      debugPrint('FatSecret search error: $e');
      return [];
    }
  }

  /// Normalizes barcode to GTIN-13 format required by FatSecret API
  /// Per FatSecret docs: "Barcodes must be specified as GTIN-13 numbers - a 13-digit number filled in with zeros for the spaces to the left.
  /// UPC-A, EAN-13 and EAN-8 barcodes may be specified. UPC-E barcodes should be converted to their UPC-A equivalent
  /// (and then specified as GTIN-13 numbers)."
  String _normalizeBarcode(String barcode) {
    debugPrint('FatSecret: Normalizing barcode: $barcode');

    // Remove any non-digit characters
    barcode = barcode.replaceAll(RegExp(r'[^\d]'), '');

    // Handle empty or invalid barcodes
    if (barcode.isEmpty) {
      debugPrint('FatSecret: Empty barcode provided');
      return '';
    }

    // Check if it's a UPC-E code (8 digits with leading 0)
    if (barcode.length == 8 && barcode.startsWith('0')) {
      debugPrint('FatSecret: Converting UPC-E to UPC-A: $barcode');

      // Convert UPC-E to UPC-A (12 digits)
      final String upcA = _convertUpcEToUpcA(barcode);
      debugPrint('FatSecret: Converted to UPC-A: $upcA');

      // Convert UPC-A to GTIN-13 by adding leading 0
      final normalizedBarcode = '0$upcA';
      debugPrint('FatSecret: Normalized UPC-E to GTIN-13: $normalizedBarcode');
      return normalizedBarcode;
    }

    // Handle EAN-8 (8 digits without leading 0)
    if (barcode.length == 8 && !barcode.startsWith('0')) {
      debugPrint('FatSecret: Converting EAN-8 to GTIN-13: $barcode');
      // For EAN-8, add 5 leading zeros to get 13 digits
      final normalizedBarcode = '00000$barcode';
      debugPrint('FatSecret: Normalized EAN-8 to GTIN-13: $normalizedBarcode');
      return normalizedBarcode;
    }

    // Handle UPC-A (12 digits) - add single leading zero to make GTIN-13
    if (barcode.length == 12) {
      final normalizedBarcode = '0$barcode';
      debugPrint(
          'FatSecret: Converted UPC-A (12-digit) to GTIN-13: $normalizedBarcode');
      return normalizedBarcode;
    }

    // Handle EAN-13 / GTIN-13 (already 13 digits)
    if (barcode.length == 13) {
      debugPrint('FatSecret: Barcode already in GTIN-13 format');
      return barcode;
    }

    // Handle other unusual cases by padding with leading zeros to 13 digits
    debugPrint(
        'FatSecret: Unusual barcode length (${barcode.length}), padding to 13 digits');
    final normalizedBarcode = barcode.padLeft(13, '0');
    debugPrint('FatSecret: Normalized to GTIN-13: $normalizedBarcode');
    return normalizedBarcode;
  }

  /// Converts UPC-E (8 digits) to UPC-A (12 digits)
  /// Based on standard UPC-E to UPC-A conversion algorithm
  String _convertUpcEToUpcA(String upcE) {
    try {
      // Ensure we have 8 digits (including check digit)
      if (upcE.length != 8) {
        return upcE.padLeft(12, '0'); // Invalid UPC-E, so just pad and return
      }

      // Extract the number system digit (should be 0 for UPC-E)
      final numberSystem = upcE[0];
      if (numberSystem != '0') {
        debugPrint(
            'FatSecret: Warning - UPC-E should start with 0, got: $numberSystem');
      }

      // Extract code (6 digits + check digit)
      final code = upcE.substring(1, 7);
      final checkDigit = upcE[7];

      // Use the last digit of the code (position 6) to determine conversion pattern
      String manufacturer;
      String product;

      switch (code[5]) {
        case '0':
        case '1':
        case '2':
          // Manufacturer: first 2 digits + last digit of code + "00"
          // Product: digits 3-5
          manufacturer = '${code.substring(0, 2)}${code[5]}00';
          product = code.substring(2, 5);
          break;
        case '3':
          // Manufacturer: first 3 digits + "00"
          // Product: digits 4-5
          manufacturer = '${code.substring(0, 3)}00';
          product = code.substring(3, 5);
          break;
        case '4':
          // Manufacturer: first 4 digits + "0"
          // Product: digit 5
          manufacturer = '${code.substring(0, 4)}0';
          product = code.substring(4, 5);
          break;
        default: // 5-9
          // Manufacturer: first 5 digits
          // Product: last digit of code
          manufacturer = code.substring(0, 5);
          product = code[5];
          break;
      }

      // Combine to form UPC-A: NumberSystem + Manufacturer + Product + CheckDigit
      final upcA = '$numberSystem$manufacturer$product$checkDigit';

      // Ensure we have 12 digits for UPC-A
      if (upcA.length != 12) {
        debugPrint(
            'FatSecret: Error - Converted UPC-A has ${upcA.length} digits instead of 12');
        return upcE.padLeft(
            12, '0'); // Return padded original if conversion failed
      }

      return upcA;
    } catch (e) {
      debugPrint('FatSecret: Error converting UPC-E to UPC-A: $e');
      return upcE.padLeft(12, '0'); // Return padded original on error
    }
  }

  /// Search for food items by barcode
  /// Note: FatSecret doesn't directly support barcode search, so we search by the barcode as a term
  /// This method might need to be improved based on actual API behavior with barcodes
  Future<List<FoodItem>> searchFoodsByBarcode(String barcode) async {
    try {
      debugPrint(
          'FatSecret: Starting barcode search with original barcode: "$barcode"');

      // Normalize the barcode to GTIN-13 format as required by FatSecret API
      final normalizedBarcode = _normalizeBarcode(barcode);
      if (normalizedBarcode.isEmpty) {
        debugPrint('FatSecret: Invalid barcode provided');
        return [];
      }

      debugPrint('FatSecret: Using normalized barcode: "$normalizedBarcode"');

      // Get an access token
      final token = await _getAccessToken();
      if (token == null) {
        debugPrint('Could not obtain access token for FatSecret API');
        return [];
      }

      debugPrint(
          'FatSecret: Searching for barcode "$normalizedBarcode" with OAuth 2.0');

      // Try direct barcode endpoint first if available
      try {
        debugPrint(
            'FatSecret: Trying dedicated barcode endpoint food.find_id_for_barcode');
        final barcodeResponse = await _httpClient.post(
          Uri.parse(_baseUrl),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: {
            'method': 'food.find_id_for_barcode',
            'barcode': normalizedBarcode,
            'format': 'json',
          },
        ).timeout(const Duration(seconds: 10));

        if (barcodeResponse.statusCode == 200) {
          final barcodeData = json.decode(barcodeResponse.body);
          debugPrint('FatSecret: Barcode endpoint response: $barcodeData');

          // If we get a food_id, fetch the full food details
          if (barcodeData['food_id'] != null) {
            final foodId = barcodeData['food_id'].toString();
            debugPrint(
                'FatSecret: Found food ID $foodId for barcode, fetching details');

            final foodItem = await getFoodById(foodId);
            if (foodItem != null) {
              // Return the item with the barcode attached
              final foodWithBarcode =
                  foodItem.copyWith(barcode: normalizedBarcode);
              return [foodWithBarcode];
            }
          }
        }
      } catch (e) {
        debugPrint('FatSecret: Error using barcode endpoint: $e');
        // Continue to fallback method
      }

      // Fallback: Execute regular search with barcode as search term
      debugPrint(
          'FatSecret: Falling back to regular search with barcode as term');
      final response = await _httpClient.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'method': 'foods.search',
          'search_expression':
              normalizedBarcode, // Use normalized barcode as search term
          'max_results': '10', // Limit results
          'format': 'json',
        },
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException(
            'FatSecret API barcode search timed out after 10 seconds');
      });

      if (response.statusCode == 200) {
        debugPrint(
            'FatSecret: Received 200 response for barcode "$normalizedBarcode"');

        final Map<String, dynamic> data = json.decode(response.body);

        // Check if foods were found
        if (data['foods'] == null || data['foods']['food'] == null) {
          debugPrint(
              'FatSecret: No foods found for barcode "$normalizedBarcode"');
          return [];
        }

        // Extract food items
        final foodsData = data['foods']['food'];
        debugPrint(
            'FatSecret: Found results for barcode, extracting food items');

        // Handle single food item case (API returns object instead of array)
        final List foodsList;
        if (foodsData is List) {
          foodsList = foodsData;
        } else {
          foodsList = [foodsData];
        }

        // Convert to FoodItem objects
        final foods = foodsList
            .map<FoodItem>((dynamic foodData) =>
                _parseFoodItem(foodData as Map<String, dynamic>))
            .toList();

        // Add barcode to food items
        final foodsWithBarcode = foods.map((food) {
          return food.copyWith(barcode: normalizedBarcode);
        }).toList();

        return foodsWithBarcode;
      } else {
        final error =
            'FatSecret API barcode search error: ${response.statusCode} ${response.body}';
        debugPrint(error);
        return [];
      }
    } catch (e) {
      debugPrint('FatSecret barcode search error: $e');
      return [];
    }
  }

  /// Get detailed food information by ID
  Future<FoodItem?> getFoodById(String foodId) async {
    try {
      // Get an access token
      final token = await _getAccessToken();
      if (token == null) {
        debugPrint('Could not obtain access token for FatSecret API');
        return null;
      }

      debugPrint('FatSecret: Getting food details for ID "$foodId"');

      // Execute request with Bearer token - use POST with form-encoded parameters
      final response = await _httpClient.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'method': 'food.get',
          'food_id': foodId,
          'format': 'json',
        },
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException(
            'FatSecret API get food timed out after 10 seconds');
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['food'] == null) {
          debugPrint('FatSecret: No "food" key in response');
          return null;
        }

        // Parse the food item
        return _parseFoodItem(data['food']);
      } else {
        final error =
            'FatSecret API error: ${response.statusCode} ${response.body}';
        debugPrint(error);
        return null;
      }
    } catch (e) {
      debugPrint('Error getting food by ID: $e');
      return null;
    }
  }

  /// Parse a food item from FatSecret API response
  FoodItem _parseFoodItem(Map<String, dynamic> food) {
    try {
      // Get basic food info
      final id = food['food_id'] as String? ?? '';
      final name = food['food_name'] as String? ?? '';
      final brand = food['brand_name'] as String? ?? '';
      final foodType = food['food_type'] as String? ?? '';

      // Default values
      int calories = 0;
      double protein = 0.0;
      double fat = 0.0;
      double carbs = 0.0;
      double? sugar;
      double? fiber;
      double? sodium;
      String servingSize = '100g';
      String category = foodType.isNotEmpty ? foodType : 'API Foods';

      if (food['food_description'] != null) {
        // Parse description for simple nutrition (used in search results)
        final description = food['food_description'] as String;
        debugPrint('FatSecret: Parsing description: $description');

        // More flexible regex patterns that handle various formats
        final caloriesMatch =
            RegExp(r'(\d+)\s*(?:kcal|calories?)', caseSensitive: false)
                .firstMatch(description);
        final proteinMatch = RegExp(r'(?:protein|p):\s*([\d.]+)\s*(?:g|grams?)',
                caseSensitive: false)
            .firstMatch(description);
        final fatMatch = RegExp(r'(?:fat|f):\s*([\d.]+)\s*(?:g|grams?)',
                caseSensitive: false)
            .firstMatch(description);
        final carbsMatch = RegExp(
                r'(?:carbs|carbohydrate|c):\s*([\d.]+)\s*(?:g|grams?)',
                caseSensitive: false)
            .firstMatch(description);

        if (caloriesMatch != null) {
          calories = int.tryParse(caloriesMatch.group(1) ?? '') ?? 0;
          debugPrint('FatSecret: Parsed calories: $calories');
        }

        if (proteinMatch != null) {
          protein = double.tryParse(proteinMatch.group(1) ?? '') ?? 0.0;
          debugPrint('FatSecret: Parsed protein: $protein');
        }

        if (fatMatch != null) {
          fat = double.tryParse(fatMatch.group(1) ?? '') ?? 0.0;
          debugPrint('FatSecret: Parsed fat: $fat');
        }

        if (carbsMatch != null) {
          carbs = double.tryParse(carbsMatch.group(1) ?? '') ?? 0.0;
          debugPrint('FatSecret: Parsed carbs: $carbs');
        }

        // Try to extract serving size from description
        final servingMatch = RegExp(r'Per ([\w\s]+) -').firstMatch(description);
        if (servingMatch != null) {
          servingSize = servingMatch.group(1) ?? '100g';
        }
      }

      // For detailed food information (from food.get)
      if (food['servings'] != null && food['servings']['serving'] != null) {
        var serving = food['servings']['serving'];

        // Handle case where servings is a list
        if (serving is List) {
          serving = serving.first; // Use default serving
        }

        // Extract serving size
        final servingAmount = double.tryParse(
                serving['metric_serving_amount']?.toString() ?? '') ??
            0.0;
        final servingUnit = serving['metric_serving_unit'] as String? ?? 'g';
        servingSize = '$servingAmount$servingUnit';

        // Extract full nutrition data
        calories = int.tryParse(serving['calories']?.toString() ?? '') ?? 0;
        protein = double.tryParse(serving['protein']?.toString() ?? '') ?? 0.0;
        fat = double.tryParse(serving['fat']?.toString() ?? '') ?? 0.0;
        carbs =
            double.tryParse(serving['carbohydrate']?.toString() ?? '') ?? 0.0;
        fiber = double.tryParse(serving['fiber']?.toString() ?? '');
        sugar = double.tryParse(serving['sugar']?.toString() ?? '');
        sodium = double.tryParse(serving['sodium']?.toString() ?? '');
      }

      return FoodItem(
        id: id,
        userId: '', // API foods don't have a user ID
        name: name,
        brand: brand,
        servingSize: servingSize,
        description: food['food_description'] as String?,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        sugar: sugar,
        fiber: fiber,
        sodium: sodium,
        isCustom: false,
        source: 'fatsecret',
        category: category,
      );
    } catch (e) {
      debugPrint('Error parsing food item: $e');
      return FoodItem(
        id: '',
        userId: '',
        name: 'Unknown Food',
        servingSize: 'serving',
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
        source: 'fatsecret',
      );
    }
  }
}
