import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../features/nutrition/domain/food_item.dart';
import '../../features/nutrition/domain/food_repository.dart';
import '../services/cloud_functions_service.dart';
import '../services/fatsecret_service.dart';

/// Firebase implementation of the [FoodRepository] with Hive caching and FatSecret API integration
class FirebaseFoodRepository implements FoodRepository {
  final FirebaseFirestore _firestore;
  final Box<Map> _foodsBox;
  final Box<Map> _favoritesBox;
  final Box<Map> _recentFoodsBox;
  final Connectivity _connectivity;
  final FatSecretService _fatSecretService;
  final CloudFunctionsService _cloudFunctionsService;
  StreamSubscription? _connectivitySubscription;
  bool _isFatSecretInitialized = false;

  /// Key prefixes for Hive storage
  static const String _foodPrefix = 'food_';
  static const String _userFoodPrefix = 'user_food_';
  static const String _favoritePrefix = 'favorite_';
  static const String _recentPrefix = 'recent_';

  /// Firebase collection names
  static const String _foodsCollection = 'foods';
  static const String _favoritesCollection = 'food_favorites';
  static const String _recentFoodsCollection = 'recent_foods';

  /// TTL for cached search results in minutes
  static const int _searchCacheTtl = 60; // 1 hour cache

  /// Rate limiting for API calls
  DateTime? _lastApiCallTime;
  static const Duration _apiCallThrottle = Duration(milliseconds: 500);

  /// Check if we can make an API call (rate limiting)
  bool _canMakeApiCall() {
    if (_lastApiCallTime == null) {
      _lastApiCallTime = DateTime.now();
      return true;
    }

    final now = DateTime.now();
    final timeSinceLastCall = now.difference(_lastApiCallTime!);

    if (timeSinceLastCall >= _apiCallThrottle) {
      _lastApiCallTime = now;
      return true;
    }

    return false;
  }

  /// Creates a [FirebaseFoodRepository].
  FirebaseFoodRepository({
    required FirebaseFirestore firestore,
    required Box<Map> foodsBox,
    required Box<Map> favoritesBox,
    required Box<Map> recentFoodsBox,
    required Connectivity connectivity,
    required FatSecretService fatSecretService,
    required CloudFunctionsService cloudFunctionsService,
  })  : _firestore = firestore,
        _foodsBox = foodsBox,
        _favoritesBox = favoritesBox,
        _recentFoodsBox = recentFoodsBox,
        _connectivity = connectivity,
        _fatSecretService = fatSecretService,
        _cloudFunctionsService = cloudFunctionsService {
    _initConnectivityListener();
    // Initialize FatSecret service
    Future.microtask(() => _fatSecretService.initialize());
  }

  void _initConnectivityListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      result,
    ) {
      if (result != ConnectivityResult.none) {
        syncOfflineData();
      }
    });
  }

  /// Synchronizes cached offline data with Firestore when internet connection is restored
  Future<void> syncOfflineData() async {
    try {
      // Sync unsynchronized custom foods
      final unsyncedFoods = _foodsBox.keys
          .where(
            (key) => key.toString().startsWith('${_userFoodPrefix}unsynced_'),
          )
          .toList();

      for (final key in unsyncedFoods) {
        final Map? foodMap = _foodsBox.get(key);
        if (foodMap != null) {
          final food = FoodItem.fromMap(Map<String, dynamic>.from(foodMap));
          await _saveFoodToFirestore(food);

          // Delete the unsynced food and store as synced
          await _foodsBox.delete(key);
          await _foodsBox.put('$_userFoodPrefix${food.id}', food.toMap());
        }
      }
    } catch (e) {
      debugPrint('Error syncing offline food data: $e');
    }
  }

  /// Check if device is connected to the internet
  Future<bool> _isConnected() async {
    try {
      debugPrint('NETWORK DEBUG: Checking network connectivity...');

      // Force connectivity to true to ensure Cloud Functions are called
      debugPrint('NETWORK DEBUG: Forcing connectivity to TRUE for testing');
      return true;
    } catch (e) {
      debugPrint('NETWORK DEBUG: Error checking connectivity: $e');
      // Default to true for testing
      return true;
    }
  }

  /// Initialize the FatSecret service
  Future<bool> _initializeFatSecretService() async {
    try {
      if (!_isFatSecretInitialized) {
        _isFatSecretInitialized = await _fatSecretService.initialize();
      }
      return _isFatSecretInitialized;
    } catch (e) {
      debugPrint('Error initializing FatSecret service: $e');
      _isFatSecretInitialized = false;
      return false;
    }
  }

  @override
  Future<List<FoodItem>> searchFoodByName(
    String query, {
    int limit = 20,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      debugPrint('======================================================');
      debugPrint(
          'REPOSITORY DEBUG: Starting searchFoodByName with query: "$query"');

      // Check network connection - but force to true for testing
      const isConnected = true; // Force connected
      debugPrint(
          'REPOSITORY DEBUG: Internet connection forced to: $isConnected');

      // Results container
      List<FoodItem> results = [];

      // ALWAYS try Cloud Functions first (highest priority)
      try {
        debugPrint('======================================================');
        debugPrint('CLOUD FUNCTIONS DEBUG: Attempting Cloud Functions search with V3 API');

        // Remove rate limiting for testing
        debugPrint(
            'CLOUD FUNCTIONS DEBUG: Bypassing rate limiting for testing');

        // ADD BREAKPOINT HERE to confirm this is called
        debugPrint('CRITICAL BREAKPOINT: About to call Cloud Functions V3');
        final cloudFunctionsFoods = await _cloudFunctionsService.searchFoods(
          query,
          maxResults: limit,
          pageNumber: 0,
          includeFoodImages: true,
          includeFoodAttributes: true,
          includeSubCategories: true,
        );

        debugPrint(
            'CLOUD FUNCTIONS DEBUG: Received ${cloudFunctionsFoods.length} results from Cloud Functions V3');

        // Add results directly - don't filter for Cloud Functions priority
        results.addAll(cloudFunctionsFoods);

        // Cache results
        for (final food in cloudFunctionsFoods) {
          await _foodsBox.put(_getKeyForFood(food), food.toMap());
        }

        debugPrint(
            'REPOSITORY DEBUG: Found ${results.length} results from Cloud Functions V3, returning');
        return results;
      } catch (e, stackTrace) {
        debugPrint('CRITICAL ERROR: Cloud Functions V3 call failed: $e');
        debugPrint(
            'REPOSITORY DEBUG: Entered catch block for Cloud Functions V3 failure.');
        debugPrint('Stack trace: $stackTrace');
      }

      // If Cloud Functions failed, try FatSecret directly
      if (results.isEmpty) {
        debugPrint(
            'REPOSITORY DEBUG: Cloud Functions failed or returned empty, trying direct API...');
        try {
          final isInitialized = await _initializeFatSecretService();
          if (isInitialized) {
            debugPrint('REPOSITORY DEBUG: Trying direct FatSecret API call');
            final apiResults =
                await _fatSecretService.searchFoods(query, maxResults: limit);
            results.addAll(apiResults);

            // Cache results
            for (final food in apiResults) {
              await _foodsBox.put(_getKeyForFood(food), food.toMap());
            }

            if (results.isNotEmpty) {
              debugPrint(
                  'REPOSITORY DEBUG: Found ${results.length} results from direct API call');
              return results;
            }
          }
        } catch (e) {
          debugPrint('REPOSITORY DEBUG: Direct API call failed: $e');
        }
      }

      // If still no results, try local cache
      if (results.isEmpty) {
        debugPrint(
            'REPOSITORY DEBUG: Direct API failed or returned empty, trying local cache...');
        try {
          debugPrint(
              'REPOSITORY DEBUG: Searching local database as last resort');

          final localFoods = _foodsBox.values
              .map((map) => FoodItem.fromMap(Map<String, dynamic>.from(map)))
              .where(
                (food) => food.name.toLowerCase().contains(query.toLowerCase()),
              )
              .take(limit)
              .toList();

          debugPrint(
              'REPOSITORY DEBUG: Found ${localFoods.length} results in local database');
          results.addAll(localFoods);
        } catch (e) {
          debugPrint('REPOSITORY DEBUG: Error searching local foods: $e');
        }
      }

      // If still empty, try Firestore
      if (results.isEmpty) {
        try {
          debugPrint('FIRESTORE DEBUG: Searching Firestore as final attempt');
          final querySnapshot = await _firestore
              .collection(_foodsCollection)
              .where('name', isGreaterThanOrEqualTo: query)
              .where('name', isLessThanOrEqualTo: '$query\uf8ff')
              .limit(limit)
              .get();

          debugPrint(
              'FIRESTORE DEBUG: Found ${querySnapshot.docs.length} results in Firestore');

          final firebaseFoods = querySnapshot.docs
              .map((doc) => FoodItem.fromMap(doc.data()))
              .toList();

          results.addAll(firebaseFoods);

          // Cache results
          for (final food in firebaseFoods) {
            await _foodsBox.put(_getKeyForFood(food), food.toMap());
          }
        } catch (e) {
          debugPrint('FIRESTORE DEBUG: Error searching Firestore: $e');
        }
      }

      debugPrint('REPOSITORY DEBUG: Returning ${results.length} total results');
      debugPrint('======================================================');
      return results;
    } catch (e) {
      debugPrint('CRITICAL ERROR in searchFoodByName: $e');
      debugPrint('======================================================');
      rethrow; // Let the controller see the actual error
    }
  }

  @override
  Future<List<FoodItem>> searchFoodByBarcode(String barcode) async {
    try {
      // First check if we have internet connection
      final isConnected = await _isConnected();

      // Check if the barcode is already cached locally
      final cachedResults = _foodsBox.keys
          .where((key) => key.toString().contains(barcode))
          .map((key) => _foodsBox.get(key))
          .map(
            (data) => data != null
                ? FoodItem.fromMap(Map<String, dynamic>.from(data))
                : null,
          )
          .whereType<FoodItem>()
          .toList();

      // If we have cached results and no connection, return them
      if (cachedResults.isNotEmpty && !isConnected) {
        return cachedResults;
      }

      // If we have a connection, try to fetch using Cloud Functions
      if (isConnected) {
        try {
          debugPrint('REPOSITORY DEBUG: Searching barcode using improved Cloud Function');

          // Search using Firebase Cloud Functions with dedicated barcode endpoint
          final apiResults =
              await _cloudFunctionsService.searchFoodsByBarcode(barcode);

          // Cache the results locally
          for (final food in apiResults) {
            await _foodsBox.put('food_${food.id}', food.toMap());
          }

          if (apiResults.isNotEmpty) {
            debugPrint('REPOSITORY DEBUG: Found ${apiResults.length} results for barcode via Cloud Functions');
            return apiResults;
          } else {
            debugPrint('REPOSITORY DEBUG: No results found for barcode via Cloud Functions');
          }
        } catch (e) {
          debugPrint(
              'Error searching food by barcode using Cloud Functions: $e');
          // Fall back to direct API search if Cloud Functions fail
          try {
            // Try to initialize the FatSecret service
            final isInitialized = await _initializeFatSecretService();

            // If initialization was successful, search for the barcode
            if (isInitialized) {
              final apiResults = await _fatSecretService.searchFoodsByBarcode(
                barcode,
              );

              // Cache the results locally
              for (final food in apiResults) {
                await _foodsBox.put('food_${food.id}', food.toMap());
              }

              if (apiResults.isNotEmpty) {
                return apiResults;
              }
            } else {
              debugPrint(
                'FatSecret service not initialized, skipping barcode search',
              );
            }
          } catch (e) {
            debugPrint('Error searching food by barcode from API: $e');
            // Continue to use cached results or Firestore
          }
        }
      }

      // If API search failed or returned no results, try Firestore
      if (isConnected) {
        try {
          final QuerySnapshot querySnapshot = await _firestore
              .collection('foods')
              .where('barcode', isEqualTo: barcode)
              .limit(5)
              .get();

          final List<FoodItem> results = querySnapshot.docs
              .map(
                (doc) => FoodItem.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList();

          // Cache the results locally
          for (final food in results) {
            await _foodsBox.put('food_${food.id}', food.toMap());
          }

          if (results.isNotEmpty) {
            return results;
          }
        } catch (e) {
          debugPrint('Error searching food by barcode from Firestore: $e');
          // Fall back to cached results if Firestore fails
        }
      }

      // If we still have no results but have cached items, return those
      if (cachedResults.isNotEmpty) {
        return cachedResults;
      }

      // No results found
      return [];
    } catch (e) {
      debugPrint('Error in searchFoodByBarcode: $e');
      return [];
    }
  }

  String _getKeyForFood(FoodItem food) {
    // Use different prefixes for user foods vs. API foods
    return '$_userFoodPrefix${food.id}';
  }

  @override
  Future<FoodItem?> getFoodById(String id) async {
    try {
      // Try local cache first
      final userFoodKey = '$_userFoodPrefix$id';
      final apiDataKey = '$_foodPrefix$id';
      final cachedUserFood = _foodsBox.get(userFoodKey);
      final cachedApiFood = _foodsBox.get(apiDataKey);

      if (cachedUserFood != null) {
        return FoodItem.fromMap(Map<String, dynamic>.from(cachedUserFood));
      }

      if (cachedApiFood != null) {
        return FoodItem.fromMap(Map<String, dynamic>.from(cachedApiFood));
      }

      // If not in cache and connected, try Firestore
      final isConnected = await _isConnected();
      if (isConnected) {
        final doc = await _firestore.collection(_foodsCollection).doc(id).get();

        if (doc.exists) {
          final food = FoodItem.fromMap(doc.data()!);
          // Update cache
          await _foodsBox.put(_getKeyForFood(food), food.toMap());
          return food;
        }

        // If not in Firestore, try Cloud Functions
        try {
          final food = await _cloudFunctionsService.getFoodById(id);
          if (food != null) {
            // Update cache
            await _foodsBox.put(_getKeyForFood(food), food.toMap());
            return food;
          }
        } catch (e) {
          debugPrint('Error getting food by ID from Cloud Functions: $e');
          // Fall back to direct API if Cloud Functions fail
          return await _fatSecretService.getFoodById(id);
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error getting food by ID: $e');
      return null;
    }
  }

  @override
  Future<List<FoodItem>> getRecentFoods(String userId, {int limit = 10}) async {
    try {
      final isConnected = await _isConnected();
      List<FoodItem> recentFoods = [];

      if (isConnected) {
        final querySnapshot = await _firestore
            .collection(_recentFoodsCollection)
            .where('userId', isEqualTo: userId)
            .orderBy('lastUsed', descending: true)
            .limit(limit)
            .get();

        // Get the food IDs from recent foods
        final foodIds = querySnapshot.docs
            .map((doc) => doc.data()['foodId'] as String)
            .toList();

        // Fetch each food item
        for (final foodId in foodIds) {
          final food = await getFoodById(foodId);
          if (food != null) {
            recentFoods.add(food);
          }
        }
      } else {
        // Get from local cache
        final recentFoodIds = _recentFoodsBox.values
            .map((map) => Map<String, dynamic>.from(map))
            .where((data) => data['userId'] == userId)
            .toList()
          ..sort(
            (a, b) => (b['lastUsed'] as int).compareTo(a['lastUsed'] as int),
          );

        // Limit results
        final limitedIds = recentFoodIds
            .take(limit)
            .map((data) => data['foodId'] as String)
            .toList();

        // Fetch each food item from cache
        for (final foodId in limitedIds) {
          final userFoodKey = '$_userFoodPrefix$foodId';
          final apiDataKey = '$_foodPrefix$foodId';

          final cachedUserFood = _foodsBox.get(userFoodKey);
          final cachedApiFood = _foodsBox.get(apiDataKey);

          if (cachedUserFood != null) {
            recentFoods.add(
              FoodItem.fromMap(Map<String, dynamic>.from(cachedUserFood)),
            );
          } else if (cachedApiFood != null) {
            recentFoods.add(
              FoodItem.fromMap(Map<String, dynamic>.from(cachedApiFood)),
            );
          }
        }
      }

      return recentFoods;
    } catch (e) {
      debugPrint('Error getting recent foods: $e');
      return [];
    }
  }

  @override
  Future<FoodItem> addCustomFood(FoodItem food) async {
    try {
      final foodWithId = food.copyWith(createdAt: DateTime.now());

      final isConnected = await _isConnected();

      if (isConnected) {
        await _saveFoodToFirestore(foodWithId);
        await _foodsBox.put(
          '$_userFoodPrefix${foodWithId.id}',
          foodWithId.toMap(),
        );
      } else {
        // Store as unsynced in local cache
        await _foodsBox.put(
          '${_userFoodPrefix}unsynced_${foodWithId.id}',
          foodWithId.toMap(),
        );
      }

      return foodWithId;
    } catch (e) {
      debugPrint('Error adding custom food: $e');
      rethrow;
    }
  }

  Future<void> _saveFoodToFirestore(FoodItem food) async {
    final foodData = food.toMap();
    // Ensure createdBy is set to the user's ID for custom foods
    if (food.isCustom) {
      foodData['createdBy'] = food.userId;
    }
    await _firestore.collection(_foodsCollection).doc(food.id).set(foodData);
  }

  @override
  Future<FoodItem> updateCustomFood(FoodItem food) async {
    try {
      final isConnected = await _isConnected();

      if (isConnected) {
        await _firestore
            .collection(_foodsCollection)
            .doc(food.id)
            .update(food.toMap());
        await _foodsBox.put('$_userFoodPrefix${food.id}', food.toMap());
      } else {
        // Store as unsynced in local cache
        await _foodsBox.put(
          '${_userFoodPrefix}unsynced_${food.id}',
          food.toMap(),
        );
      }

      return food;
    } catch (e) {
      debugPrint('Error updating custom food: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteCustomFood(String foodId) async {
    try {
      final isConnected = await _isConnected();

      if (isConnected) {
        await _firestore.collection(_foodsCollection).doc(foodId).delete();
      }

      // Remove from local cache
      await _foodsBox.delete('$_userFoodPrefix$foodId');
      await _foodsBox.delete('${_userFoodPrefix}unsynced_$foodId');
    } catch (e) {
      debugPrint('Error deleting custom food: $e');
      rethrow;
    }
  }

  @override
  Future<List<String>> getFoodCategories() async {
    // Return a predefined list of common food categories
    return [
      'Breakfast',
      'Lunch',
      'Dinner',
      'Snacks',
      'Beverages',
      'Fruits',
      'Vegetables',
      'Dairy',
      'Meat',
      'Grains',
      'Desserts',
      'Fast Food',
      'Common',
    ];
  }

  @override
  Future<List<FoodItem>> getFoodsByCategory(
    String category, {
    int limit = 20,
  }) async {
    try {
      final isConnected = await _isConnected();
      List<FoodItem> results = [];

      if (isConnected) {
        final querySnapshot = await _firestore
            .collection(_foodsCollection)
            .where('category', isEqualTo: category)
            .limit(limit)
            .get();

        final foods = querySnapshot.docs
            .map((doc) => FoodItem.fromMap(doc.data()))
            .toList();

        results.addAll(foods);

        // Update local cache
        for (final food in foods) {
          await _foodsBox.put(_getKeyForFood(food), food.toMap());
        }
      } else {
        // Get from local cache
        final localFoods = _foodsBox.values
            .map((map) => FoodItem.fromMap(Map<String, dynamic>.from(map)))
            .where((food) => food.category == category)
            .take(limit)
            .toList();

        results.addAll(localFoods);
      }

      return results;
    } catch (e) {
      debugPrint('Error getting foods by category: $e');
      return [];
    }
  }

  @override
  Future<List<FoodItem>> getFavoriteFoods(String userId) async {
    try {
      final isConnected = await _isConnected();
      List<FoodItem> favoriteFoods = [];

      if (isConnected) {
        final querySnapshot = await _firestore
            .collection(_favoritesCollection)
            .where('userId', isEqualTo: userId)
            .get();

        // Get the food IDs from favorites
        final foodIds = querySnapshot.docs
            .map((doc) => doc.data()['foodId'] as String)
            .toList();

        // Fetch each food item
        for (final foodId in foodIds) {
          final food = await getFoodById(foodId);
          if (food != null) {
            favoriteFoods.add(food);
          }
        }
      } else {
        // Get from local cache
        final favoriteKeys = _favoritesBox.keys
            .where(
              (key) => key.toString().startsWith('$_favoritePrefix${userId}_'),
            )
            .toList();

        // Get the food IDs from the keys
        final foodIds =
            favoriteKeys.map((key) => key.toString().split('_').last).toList();

        // Fetch each food item
        for (final foodId in foodIds) {
          final userFoodKey = '$_userFoodPrefix$foodId';
          final apiDataKey = '$_foodPrefix$foodId';

          final cachedUserFood = _foodsBox.get(userFoodKey);
          final cachedApiFood = _foodsBox.get(apiDataKey);

          if (cachedUserFood != null) {
            favoriteFoods.add(
              FoodItem.fromMap(Map<String, dynamic>.from(cachedUserFood)),
            );
          } else if (cachedApiFood != null) {
            favoriteFoods.add(
              FoodItem.fromMap(Map<String, dynamic>.from(cachedApiFood)),
            );
          }
        }
      }

      return favoriteFoods;
    } catch (e) {
      debugPrint('Error getting favorite foods: $e');
      return [];
    }
  }

  @override
  Future<void> addToFavorites(String userId, String foodId) async {
    try {
      final docId = '${userId}_$foodId';
      final data = {
        'userId': userId,
        'foodId': foodId,
        'addedAt': DateTime.now().millisecondsSinceEpoch,
      };

      final isConnected = await _isConnected();

      if (isConnected) {
        await _firestore.collection(_favoritesCollection).doc(docId).set(data);
      }

      // Update local cache
      await _favoritesBox.put('$_favoritePrefix$docId', data);
    } catch (e) {
      debugPrint('Error adding to favorites: $e');
      rethrow;
    }
  }

  @override
  Future<void> removeFromFavorites(String userId, String foodId) async {
    try {
      final docId = '${userId}_$foodId';

      final isConnected = await _isConnected();

      if (isConnected) {
        await _firestore.collection(_favoritesCollection).doc(docId).delete();
      }

      // Remove from local cache
      await _favoritesBox.delete('$_favoritePrefix$docId');
    } catch (e) {
      debugPrint('Error removing from favorites: $e');
      rethrow;
    }
  }

  @override
  Future<void> markFoodAsRecentlyUsed(String userId, String foodId) async {
    try {
      final docId = '${userId}_$foodId';
      final data = {
        'userId': userId,
        'foodId': foodId,
        'lastUsed': DateTime.now().millisecondsSinceEpoch,
      };

      final isConnected = await _isConnected();

      if (isConnected) {
        await _firestore
            .collection(_recentFoodsCollection)
            .doc(docId)
            .set(data);
      }

      // Update local cache
      await _recentFoodsBox.put('$_recentPrefix$docId', data);
    } catch (e) {
      debugPrint('Error marking food as recently used: $e');
      rethrow;
    }
  }

  /// Get commonly used foods for new users
  Future<List<FoodItem>> getCommonFoods() async {
    try {
      return await getFoodsByCategory('Common', limit: 20);
    } catch (e) {
      debugPrint('Error getting common foods: $e');
      return [];
    }
  }

  @override
  Future<List<FoodItem>> getCustomFoods(String userId) async {
    try {
      final isConnected = await _isConnected();

      // If we have a connection, try to fetch from Firestore
      if (isConnected) {
        try {
          final QuerySnapshot querySnapshot = await _firestore
              .collection('foods')
              .where('userId', isEqualTo: userId)
              .where('isCustom', isEqualTo: true)
              .get();

          final List<FoodItem> results = querySnapshot.docs
              .map(
                (doc) => FoodItem.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList();

          // Cache the results locally
          for (final food in results) {
            await _foodsBox.put('food_${food.id}', food.toMap());
          }

          return results;
        } catch (e) {
          debugPrint('Error fetching custom foods from Firestore: $e');
          // Fall back to cached items
        }
      }

      // If offline or Firestore failed, try to fetch from cache
      final cachedResults = _foodsBox.values
          .map((data) => FoodItem.fromMap(Map<String, dynamic>.from(data)))
          .where((food) => food.userId == userId && food.isCustom)
          .toList();

      return cachedResults;
    } catch (e) {
      debugPrint('Error in getCustomFoods: $e');
      return [];
    }
  }

  /// Dispose of any resources
  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
