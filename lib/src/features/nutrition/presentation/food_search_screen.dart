import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common_widgets/app_scaffold.dart';
import '../../../features/auth/application/auth_controller.dart';
import '../../../services/barcode_scanner_service.dart';
import '../application/food_controller.dart';
import '../domain/food_item.dart';

/// Screen for searching food items in the database
class FoodSearchScreen extends ConsumerStatefulWidget {
  /// Date for which the food will be added
  final DateTime date;

  /// Constructor
  const FoodSearchScreen({super.key, required this.date});

  @override
  ConsumerState<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends ConsumerState<FoodSearchScreen> {
  final _searchController = TextEditingController();
  final _debounce = Debouncer(milliseconds: 200);

  List<FoodItem> _searchResults = [];
  List<FoodItem> _recentFoods = [];
  List<FoodItem> _favoriteFoods = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _error;
  bool _isScanningBarcode = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce._timer?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      debugPrint('UI: Starting initial data load');
      final user = ref.read(authStateProvider).value;
      final userId = user?.uid;

      if (userId == null) {
        debugPrint('UI: No user ID found, showing sign in message');
        setState(() {
          _isLoading = false;
          _error = 'Please sign in to view your food items';
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _error = null;
      });
      debugPrint('UI: Set loading state for initial data load');

      try {
        List<FoodItem> recentFoods = [];
        List<FoodItem> favoriteFoods = [];

        try {
          debugPrint('UI: Loading recent foods');
          recentFoods =
              await ref.read(foodControllerProvider).getRecentFoods(userId);
          debugPrint('UI: Loaded ${recentFoods.length} recent foods');
        } catch (recentError) {
          debugPrint('UI: Error loading recent foods: $recentError');
        }

        try {
          debugPrint('UI: Loading favorite foods');
          favoriteFoods =
              await ref.read(foodControllerProvider).getFavoriteFoods(userId);
          debugPrint('UI: Loaded ${favoriteFoods.length} favorite foods');
        } catch (favoriteError) {
          debugPrint('UI: Error loading favorite foods: $favoriteError');
        }

        if (mounted) {
          setState(() {
            _recentFoods = recentFoods;
            _favoriteFoods = favoriteFoods;
            _isLoading = false;
          });
          debugPrint(
              'UI: Updated state with initial data - recent: ${_recentFoods.length}, favorites: ${_favoriteFoods.length}');
        }
      } catch (e) {
        debugPrint('UI: Error in initial data load: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = 'Error loading data: ${e.toString()}';
          });
        }
      }
    } catch (e) {
      debugPrint('UI: Critical error in initial data load: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Unexpected error: ${e.toString()}';
        });
      }
    }
  }

  void _performSearch(String query) {
    try {
      debugPrint('======================================================');
      debugPrint('UI: Starting search with query: "$query"');
      debugPrint(
          'UI: Current state - isLoading: $_isLoading, hasSearched: $_hasSearched, error: $_error');
      debugPrint('UI: Current search results count: ${_searchResults.length}');

      if (query.trim().isEmpty) {
        debugPrint('UI: Empty query, clearing results');
        setState(() {
          _searchResults = [];
          _hasSearched = false;
          _error = null;
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _hasSearched = true;
        _error = null;
      });
      debugPrint(
          'UI: Set loading state - isLoading: $_isLoading, hasSearched: $_hasSearched');

      _debounce.run(() async {
        try {
          debugPrint(
              'UI: Debounce complete, executing search for: ${query.trim()}');
          final results = await ref
              .read(foodControllerProvider)
              .searchFoodByName(query.trim());
          debugPrint('UI: Search complete, received ${results.length} results');

          if (mounted) {
            setState(() {
              _searchResults = results;
              _isLoading = false;
              _error =
                  results.isEmpty ? 'No foods found matching "$query"' : null;
            });
            debugPrint(
                'UI: Updated state - isLoading: $_isLoading, results: ${_searchResults.length}, error: $_error');
          }
        } catch (e) {
          debugPrint('UI: Error during search: $e');
          if (mounted) {
            setState(() {
              _isLoading = false;
              if (e.toString().contains('FatSecret API credentials not set') ||
                  e.toString().contains('fatsecret_api_key')) {
                _error =
                    'Online food database is currently unavailable. You can still use your recent or favorite foods, or create custom foods.';
              } else if (e.toString().contains('UnimplementedError')) {
                _error =
                    'Search functionality is still being set up. Please use recent foods or create custom foods for now.';
              } else if (e.toString().contains('internet') ||
                  e.toString().contains('connection') ||
                  e.toString().contains('timeout')) {
                _error =
                    'No internet connection. Check your connection and try again, or use your recent foods.';
              } else if (e.toString().contains('Cloud Function')) {
                _error =
                    'Error calling Cloud Functions: ${e.toString()}. This is likely a server-side issue.';
              } else {
                _error = 'Error searching foods: ${e.toString()}';
              }
            });
            debugPrint('UI: Updated error state - error: $_error');
          }
        }
      });
      debugPrint('======================================================');
    } catch (e) {
      debugPrint('UI: Critical error in _performSearch: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Unexpected error: ${e.toString()}';
        });
      }
    }
  }

  void _onSearchTextChanged(String text) {
    if (text.isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
        _error = null;
      });
    }
  }

  void _selectFood(FoodItem food) {
    try {
      final user = ref.read(authStateProvider).value;
      final userId = user?.uid;

      if (userId != null && food.id.isNotEmpty) {
        // Mark as recently used
        ref
            .read(foodControllerProvider)
            .markFoodAsRecentlyUsed(userId, food.id);
      }

      // Navigate to add nutrition entry screen with selected food
      context.go(
        '/nutrition/add?date=${widget.date.toIso8601String()}',
        extra: food,
      );
    } catch (e) {
      debugPrint('Error selecting food: $e');
      // Still navigate even if marking as recent fails
      context.go(
        '/nutrition/add?date=${widget.date.toIso8601String()}',
        extra: food,
      );
    }
  }

  Widget _buildFoodItem(FoodItem food) {
    try {
      debugPrint('UI: Building food item: ${food.name} ');
      return ListTile(
        title: Text(food.name),
        subtitle: Text(
          '${food.calories} kcal | ${food.protein}g P | ${food.carbs}g C | ${food.fat}g F | ${food.servingSize}',
        ),
        trailing: const Icon(Icons.add_circle_outline),
        onTap: () => _selectFood(food),
      );
    } catch (e) {
      debugPrint('UI: Error building food item: $e');
      return ListTile(
        title: const Text('Food Item'),
        subtitle: const Text('Details not available'),
        trailing: const Icon(Icons.error_outline, color: Colors.red),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error displaying this food item'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      );
    }
  }

  Widget _buildErrorState() {
    debugPrint('UI: Building error state - error: $_error');
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _error ?? 'An error occurred',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: Colors.grey[700]),
              ),
              if (_error?.contains('FatSecret API credentials') ?? false) ...[
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () {
                    context.go(
                        '/nutrition/add?date=${widget.date.toIso8601String()}');
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create Custom Food'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySearchState() {
    debugPrint('UI: Building empty search state');
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No foods found matching "${_searchController.text}"',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Try a different search term or create a custom food',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  context.go(
                      '/nutrition/add?date=${widget.date.toIso8601String()}');
                },
                icon: const Icon(Icons.add),
                label: const Text('Create Custom Food'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Search for food items by barcode
  Future<void> _scanBarcode() async {
    setState(() {
      _isScanningBarcode = true;
      _error = null;
    });

    try {
      // Get the barcode scanner service
      final barcodeScannerService = ref.read(barcodeScannerServiceProvider);

      // Scan the barcode
      final String? barcode = await barcodeScannerService.scanProductBarcode();

      // If scanning was canceled or failed
      if (barcode == null) {
        if (mounted) {
          setState(() {
            _error = 'Barcode scanning was canceled.';
          });
        }
        return;
      }

      // Search for food by barcode using FoodController
      final foodItems =
          await ref.read(foodControllerProvider).searchByBarcode(barcode);

      // If a food item was found, select it
      if (foodItems != null) {
        if (mounted) {
          _selectFood(foodItems);
        }
      } else if (mounted) {
        // Show message if no food found
        setState(() {
          _error =
              'No food found with this barcode. Try searching by name or create a custom food.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (e.toString().contains('FatSecret API credentials not set') ||
              e.toString().contains('fatsecret_api_key')) {
            _error =
                'Online food database is currently unavailable. Try searching by name instead.';
          } else if (e.toString().contains('permission') ||
              e.toString().contains('camera')) {
            _error =
                'Camera permission is required to scan barcodes. Please enable it in your device settings.';
          } else if (e.toString().contains('internet') ||
              e.toString().contains('connection') ||
              e.toString().contains('timeout')) {
            _error =
                'No internet connection. Check your connection and try again.';
          } else {
            _error = 'Error scanning barcode: ${e.toString()}';
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanningBarcode = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      final List<Widget> appBarActions = [
        // Add barcode scan button in app bar
        IconButton(
          icon: _isScanningBarcode
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.qr_code_scanner),
          onPressed: _isScanningBarcode ? null : _scanBarcode,
          tooltip: 'Scan barcode',
        ),
      ];

      return AppScaffold(
        title: 'Search Foods',
        actions: appBarActions,
        showBackButton: true,
        showBottomNavigation: false,
        body: SafeArea(
          child: Column(
            children: [
              // Search Box Area - Not expanded, takes minimum required height
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Updated search bar with search button
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Search for foods',
                        hintText: 'e.g., banana, chicken breast, etc.',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_searchController.text.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchTextChanged('');
                                },
                              ),
                            IconButton(
                              icon: const Icon(Icons.search),
                              onPressed: () {
                                // Trigger search when button is pressed
                                if (_searchController.text.isNotEmpty) {
                                  _performSearch(_searchController.text);
                                }
                              },
                            ),
                          ],
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.search,
                      onChanged: _onSearchTextChanged,
                      // Execute search when user presses enter/search
                      onSubmitted: _performSearch,
                    ),

                    // Add barcode scan button below search
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _isScanningBarcode ? null : _scanBarcode,
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Scan Barcode'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ],
                ),
              ),

              // Results Area - Expanded to fill remaining space
              Expanded(
                child: _buildResultsArea(),
              ),

              // Bottom action button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.go(
                      '/nutrition/add?date=${widget.date.toIso8601String()}',
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create Custom Food'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      // Error fallback
      debugPrint('Error in food search build: $e');
      return Scaffold(
        appBar: AppBar(
          title: const Text('Search Foods'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Something went wrong',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Error: ${e.toString()}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  // Helper method to build the appropriate results widget
  Widget _buildResultsArea() {
    if (_isLoading) {
      return _buildLoadingState();
    } else if (_error != null) {
      return _buildErrorState();
    } else if (_searchController.text.isNotEmpty && _searchResults.isEmpty) {
      return _buildEmptySearchState();
    } else if (_searchController.text.isNotEmpty) {
      return _buildSearchResults();
    } else {
      return _buildInitialSuggestions();
    }
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildSearchResults() {
    debugPrint('UI: Building search results - count: ${_searchResults.length}');
    debugPrint(
        'UI: Search results: ${_searchResults.map((e) => e).join(', ')}');
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        debugPrint(
            'UI: Building food item at index $index: ${_searchResults[index].name}');
        return _buildFoodItem(_searchResults[index]);
      },
      padding: const EdgeInsets.symmetric(vertical: 8.0),
    );
  }

  Widget _buildInitialSuggestions() {
    try {
      if (_recentFoods.isEmpty && _favoriteFoods.isEmpty && !_isLoading) {
        // Show placeholder when no suggestions available
        return const Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.food_bank_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Start by searching for foods',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Use the search bar above or scan a barcode',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }

      // Show recent and favorite foods in a scrollable list
      return ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          if (_recentFoods.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              child: Text(
                'Recently Used Foods',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ...List.generate(
              _recentFoods.length > 5 ? 5 : _recentFoods.length,
              (index) => _buildFoodItem(_recentFoods[index]),
            ),
          ],
          if (_favoriteFoods.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              child: Text(
                'Favorite Foods',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ...List.generate(
              _favoriteFoods.length > 5 ? 5 : _favoriteFoods.length,
              (index) => _buildFoodItem(_favoriteFoods[index]),
            ),
          ],
        ],
      );
    } catch (e) {
      debugPrint('Error building initial suggestions: $e');
      // Fallback widget in case of errors
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Unable to load suggestions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Error: ${e.toString()}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
  }
}

/// Utility class for debouncing API calls
class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}
