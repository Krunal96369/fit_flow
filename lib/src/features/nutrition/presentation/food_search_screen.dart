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

  // Enhanced search bar with barcode scanner
  Widget _buildSearchBar() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = colorScheme.brightness == Brightness.dark;

    // Use theme-appropriate colors
    final backgroundColor =
        isDarkMode ? colorScheme.surfaceContainerHighest : colorScheme.surface;
    final borderColor = isDarkMode
        ? colorScheme.outline.withOpacity(0.3)
        : colorScheme.outline.withOpacity(0.1);
    final iconColor = colorScheme.onSurfaceVariant;
    final hintTextColor = colorScheme.onSurfaceVariant.withOpacity(0.7);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'Search foods...',
                  hintStyle: TextStyle(
                    color: hintTextColor,
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: iconColor,
                    semanticLabel: 'Search',
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: iconColor),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchTextChanged('');
                          },
                          tooltip: 'Clear search',
                        )
                      : null,
                ),
                onChanged: _onSearchTextChanged,
                onSubmitted: _performSearch,
                textInputAction: TextInputAction.search,
                // Enhanced accessibility
                keyboardType: TextInputType.text,
                autofocus: false,
                enableSuggestions: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          MergeSemantics(
            child: Semantics(
              label: 'Scan barcode for food lookup',
              hint: 'Double tap to scan a product barcode',
              button: true,
              enabled: !_isScanningBarcode,
              child: Material(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(30),
                elevation: 2,
                child: InkWell(
                  onTap: _isScanningBarcode ? null : _scanBarcode,
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    width: 50,
                    height: 50,
                    child: _isScanningBarcode
                        ? Semantics(
                            label: 'Scanning barcode',
                            child: const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.qr_code_scanner,
                            color: colorScheme.onPrimary,
                            size: 26,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodItem(FoodItem food) {
    try {
      final colorScheme = Theme.of(context).colorScheme;
      final isDarkMode = colorScheme.brightness == Brightness.dark;

      // Use theme-aware colors
      final cardColor = isDarkMode
          ? colorScheme.surfaceContainerHighest.withOpacity(0.4)
          : colorScheme.surface;
      final borderColor = isDarkMode
          ? colorScheme.outline.withOpacity(0.3)
          : colorScheme.outline.withOpacity(0.05);
      final imageBackgroundColor =
          isDarkMode ? Colors.grey[800] : Colors.grey[200];
      final placeholderIconColor =
          isDarkMode ? Colors.grey[400] : Colors.grey[600];

      // Format nutritional information for accessibility
      final String accessibilityDescription =
          '${food.name}. ${food.brand != null && food.brand!.isNotEmpty ? 'Brand: ${food.brand}. ' : ''}${food.calories} calories, ${food.protein} grams protein, ${food.carbs} grams carbs, ${food.fat} grams fat. Serving size: ${food.servingSize}. Double tap to select.';

      return Card(
        elevation: 1.5,
        shadowColor: Colors.black.withOpacity(isDarkMode ? 0.4 : 0.1),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor),
        ),
        child: MergeSemantics(
          child: Semantics(
            label: accessibilityDescription,
            button: true,
            enabled: true,
            excludeSemantics: true,
            child: InkWell(
              onTap: () => _selectFood(food),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Food image or placeholder with semantic label
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 70,
                        height: 70,
                        child:
                            food.imageUrl != null && food.imageUrl!.isNotEmpty
                                ? Image.network(
                                    food.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, _, __) => Container(
                                      color: imageBackgroundColor,
                                      child: Icon(
                                        Icons.fastfood,
                                        size: 30,
                                        color: placeholderIconColor,
                                      ),
                                    ),
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        color: imageBackgroundColor,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    (loadingProgress
                                                            .expectedTotalBytes ??
                                                        1)
                                                : null,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    color: imageBackgroundColor,
                                    child: Icon(
                                      Icons.fastfood,
                                      size: 30,
                                      color: placeholderIconColor,
                                    ),
                                  ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Food details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Food name
                          Text(
                            food.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          // Brand info if available
                          if (food.brand != null && food.brand!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              food.brand!,
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],

                          const SizedBox(height: 8),

                          // Nutrition information with better contrast colors
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _buildNutrientChip(
                                'Kcal',
                                '${food.calories}',
                                Colors.orange[100]!,
                                Colors.orange[900]!,
                              ),
                              _buildNutrientChip(
                                'P',
                                '${food.protein}g',
                                Colors.red[100]!,
                                Colors.red[900]!,
                              ),
                              _buildNutrientChip(
                                'C',
                                '${food.carbs}g',
                                Colors.blue[100]!,
                                Colors.blue[900]!,
                              ),
                              _buildNutrientChip(
                                'F',
                                '${food.fat}g',
                                Colors.green[100]!,
                                Colors.green[900]!,
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          // Serving size
                          Text(
                            food.servingSize,
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Add button with semantic label
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.add_circle,
                        color: colorScheme.primary,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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

  /// Helper to build a nutrient chip
  Widget _buildNutrientChip(String label, String value,
      Color lightModeBackground, Color lightModeText) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = colorScheme.brightness == Brightness.dark;

    Color chipBackground;
    Color chipText;
    Color borderColor;

    if (isDarkMode) {
      // In dark mode, use more subtle, darker colors
      // Use a uniform dark background (one level up from surface)
      chipBackground = colorScheme.surfaceContainerHighest;

      // Use different color for the border based on nutrient type
      switch (label) {
        case 'Kcal':
          borderColor = const Color(0xFF705D36); // Subtle orange
          chipText = const Color(0xFFE6C58E); // Soft gold
          break;
        case 'P':
          borderColor = const Color(0xFF7A4343); // Subtle red
          chipText = const Color(0xFFE6A090); // Soft salmon
          break;
        case 'C':
          borderColor = const Color(0xFF325573); // Subtle blue
          chipText = const Color(0xFFB1D0E0); // Soft blue
          break;
        case 'F':
          borderColor = const Color(0xFF385547); // Subtle green
          chipText = const Color(0xFFA9D3BC); // Soft green
          break;
        default:
          borderColor = colorScheme.outline;
          chipText = colorScheme.onSurface;
      }
    } else {
      // In light mode, keep the original design
      chipBackground = lightModeBackground;
      chipText = lightModeText;
      borderColor = lightModeText.withOpacity(0.3);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: chipBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: isDarkMode ? 1.0 : 0.7),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: chipText,
        ),
      ),
    );
  }

  Widget _buildEmptySearchState() {
    debugPrint('UI: Building empty search state');
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = colorScheme.brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off,
                size: 70,
                color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                semanticLabel: 'No search results found',
              ),
              const SizedBox(height: 20),
              Text(
                'No foods found matching "${_searchController.text}"',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Try a different search term or create a custom food item',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () {
                  context.go(
                      '/nutrition/add?date=${widget.date.toIso8601String()}');
                },
                icon: const Icon(Icons.add),
                label: const Text('Create Custom Food'),
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    debugPrint('UI: Building error state - error: $_error');
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 60, color: colorScheme.error.withOpacity(0.7)),
              const SizedBox(height: 20),
              Text(
                _error ?? 'An error occurred',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
              if (_error?.contains('FatSecret API credentials') ?? false) ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    context.go(
                        '/nutrition/add?date=${widget.date.toIso8601String()}');
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create Custom Food'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Searching for foods...',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  /// Search for food items by barcode
  Future<void> _scanBarcode() async {
    setState(() {
      _isScanningBarcode = true;
      _error = null;
    });

    debugPrint('====== BARCODE SCANNING START ======');

    try {
      // Get the barcode scanner service
      final barcodeScannerService = ref.read(barcodeScannerServiceProvider);
      debugPrint(
          'UI: Got barcode scanner service: ${barcodeScannerService.runtimeType}');

      // Scan the barcode
      debugPrint('UI: Starting barcode scan...');

      // Use the actual barcode scanner instead of hardcoded barcode
      final String? barcode = await barcodeScannerService.scanProductBarcode();

      // Handle null or empty barcode (user cancelled scan)
      if (barcode == null || barcode.isEmpty) {
        debugPrint('UI: Barcode scan cancelled or returned null/empty value');
        if (mounted) {
          setState(() {
            _isScanningBarcode = false;
          });
        }
        return;
      }

      // Log detailed barcode information
      debugPrint('UI: Barcode scan successful');
      debugPrint('UI: Barcode value: "$barcode"');
      debugPrint('UI: Barcode length: ${barcode.length}');
      debugPrint('UI: Barcode type: ${_getBarcodeType(barcode)}');

      // Check if barcode contains only digits
      final isNumeric = RegExp(r'^\d+$').hasMatch(barcode);
      debugPrint('UI: Barcode is numeric only: $isNumeric');

      if (!isNumeric) {
        debugPrint(
            'UI: WARNING - Barcode contains non-numeric characters which will be removed');
      }

      // Log the expected GTIN-13 format to verify conversion logic
      final expectedGtin13 = _getExpectedGtin13(barcode);
      debugPrint(
          'UI: Expected GTIN-13 format (based on FatSecret docs): $expectedGtin13');

      // Trace the barcode through the conversion chain
      _traceBarcodeThroughServicesDebug(barcode);

      // Search for food by barcode using FoodController
      debugPrint(
          'UI: Calling FoodController.searchByBarcode with barcode: $barcode');
      final foodItems =
          await ref.read(foodControllerProvider).searchByBarcode(barcode);
      debugPrint('UI: FoodController.searchByBarcode returned: $foodItems');

      // If a food item was found, select it
      if (foodItems != null) {
        debugPrint('UI: Food item found, selecting it: ${foodItems.name}');
        if (mounted) {
          // Instead of directly navigating to add screen, show the food in search results
          setState(() {
            _hasSearched = true;
            _searchResults = [foodItems];
            _isLoading = false;
            _error = null;
          });
          // Show a snackbar to indicate success
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Found: ${foodItems.name}'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              action: SnackBarAction(
                label: 'Add',
                onPressed: () => _selectFood(foodItems),
              ),
            ),
          );
        }
      } else if (mounted) {
        // Show message if no food found
        debugPrint('UI: No food found for barcode: $barcode');
        setState(() {
          _error =
              'No food found with this barcode. Try searching by name or create a custom food.';
        });
      }
    } catch (e) {
      debugPrint('UI: ERROR in _scanBarcode: $e');
      debugPrint('UI: Error type: ${e.runtimeType}');

      if (mounted) {
        setState(() {
          if (e.toString().contains('FatSecret API credentials not set') ||
              e.toString().contains('fatsecret_api_key')) {
            _error =
                'Online food database is currently unavailable. Try searching by name instead.';
            debugPrint('UI: FatSecret API credentials error');
          } else if (e.toString().contains('permission') ||
              e.toString().contains('camera')) {
            _error =
                'Camera permission is required to scan barcodes. Please enable it in your device settings.';
            debugPrint('UI: Camera permission error');
          } else if (e.toString().contains('internet') ||
              e.toString().contains('connection') ||
              e.toString().contains('timeout')) {
            _error =
                'No internet connection. Check your connection and try again.';
            debugPrint('UI: Connection error');
          } else if (e.toString().contains('unauthenticated') ||
              e.toString().contains('authentication')) {
            _error = 'Authentication issue. Please log out and log in again.';
            debugPrint('UI: Authentication error');
          } else {
            _error = 'Error scanning barcode: ${e.toString()}';
            debugPrint('UI: General error: $_error');
          }
        });
      }
    } finally {
      debugPrint('====== BARCODE SCANNING END ======');
      if (mounted) {
        setState(() {
          _isScanningBarcode = false;
        });
      }
    }
  }

  /// Helper method to determine the expected GTIN-13 format based on FatSecret docs
  String _getExpectedGtin13(String barcode) {
    // Remove any non-digit characters
    final cleanBarcode = barcode.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanBarcode.isEmpty) {
      return 'Invalid barcode (empty after cleaning)';
    }

    // Handle UPC-E (8 digits with leading 0)
    if (cleanBarcode.length == 8 && cleanBarcode.startsWith('0')) {
      // This would require conversion to UPC-A first according to standard algorithm
      return 'UPC-E requires conversion to UPC-A first, then adding leading 0';
    }

    // Handle EAN-8 (8 digits without leading 0)
    if (cleanBarcode.length == 8 && !cleanBarcode.startsWith('0')) {
      return '00000$cleanBarcode'; // Add 5 leading zeros
    }

    // Handle UPC-A (12 digits)
    if (cleanBarcode.length == 12) {
      return '0$cleanBarcode'; // Add 1 leading zero
    }

    // Handle EAN-13 (already 13 digits)
    if (cleanBarcode.length == 13) {
      return cleanBarcode; // Already in correct format
    }

    // Other unusual cases
    return cleanBarcode.padLeft(13, '0'); // Pad to 13 digits
  }

  /// Helper method to determine barcode type based on length
  String _getBarcodeType(String barcode) {
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

  /// Helper method to trace barcode through various service normalizations
  void _traceBarcodeThroughServicesDebug(String barcode) {
    if (barcode.isEmpty) {
      debugPrint('UI DEBUG TRACE: Empty barcode provided');
      return;
    }

    // Step 1: Clean the barcode (digits only)
    final cleanBarcode = barcode.replaceAll(RegExp(r'[^\d]'), '');
    debugPrint(
        'UI DEBUG TRACE: Step 1 - Clean barcode (digits only): "$cleanBarcode"');

    // Step 2: Normalize based on barcode type
    String normalizedBarcode = cleanBarcode;

    // Handle UPC-E (8 digits with leading 0)
    if (cleanBarcode.length == 8 && cleanBarcode.startsWith('0')) {
      debugPrint('UI DEBUG TRACE: Step 2a - Detected UPC-E format');
      // Convert UPC-E to UPC-A using simplified algorithm for tracing
      String upcA = cleanBarcode;

      // Get the last digit for the conversion rule
      final lastDigit = cleanBarcode[7];

      if (lastDigit == '0' || lastDigit == '1' || lastDigit == '2') {
        upcA =
            '${cleanBarcode.substring(0, 3)}${cleanBarcode[7]}0000${cleanBarcode.substring(3, 6)}${cleanBarcode[7]}';
      } else if (lastDigit == '3') {
        upcA =
            '${cleanBarcode.substring(0, 4)}00000${cleanBarcode.substring(4, 6)}${cleanBarcode[7]}';
      } else if (lastDigit == '4') {
        upcA =
            '${cleanBarcode.substring(0, 5)}00000${cleanBarcode.substring(5, 6)}${cleanBarcode[7]}';
      } else {
        upcA = '${cleanBarcode.substring(0, 6)}0000${cleanBarcode[7]}';
      }
      debugPrint('UI DEBUG TRACE: Step 2b - Converted to UPC-A: "$upcA"');

      // Convert UPC-A to GTIN-13
      normalizedBarcode = '0$upcA';
      debugPrint(
          'UI DEBUG TRACE: Step 2c - GTIN-13 from UPC-E: "$normalizedBarcode"');
    }
    // Handle EAN-8 (8 digits without leading 0)
    else if (cleanBarcode.length == 8 && !cleanBarcode.startsWith('0')) {
      debugPrint('UI DEBUG TRACE: Step 2 - Detected EAN-8 format');
      normalizedBarcode = '00000$cleanBarcode';
      debugPrint(
          'UI DEBUG TRACE: Step 2 - GTIN-13 from EAN-8: "$normalizedBarcode"');
    }
    // Handle UPC-A (12 digits)
    else if (cleanBarcode.length == 12) {
      debugPrint('UI DEBUG TRACE: Step 2 - Detected UPC-A format');
      normalizedBarcode = '0$cleanBarcode';
      debugPrint(
          'UI DEBUG TRACE: Step 2 - GTIN-13 from UPC-A: "$normalizedBarcode"');
    }
    // Handle EAN-13 (already 13 digits)
    else if (cleanBarcode.length == 13) {
      debugPrint('UI DEBUG TRACE: Step 2 - Already in GTIN-13 format');
    }
    // Handle other cases
    else {
      debugPrint(
          'UI DEBUG TRACE: Step 2 - Unusual barcode length (${cleanBarcode.length})');
      normalizedBarcode = cleanBarcode.padLeft(13, '0');
      debugPrint(
          'UI DEBUG TRACE: Step 2 - Padded to GTIN-13: "$normalizedBarcode"');
    }

    debugPrint(
        'UI DEBUG TRACE: Final normalized barcode: "$normalizedBarcode"');
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Food Search',
      body: FocusScope(
        child: Column(
          children: [
            // Extracted search bar to a separate method
            _buildSearchBar(),

            // Rest of the existing content
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: _isLoading
                    ? _buildLoadingState()
                    : _error != null
                        ? _buildErrorState()
                        : _hasSearched && _searchResults.isEmpty
                            ? _buildEmptySearchState()
                            : _buildFoodList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodList() {
    debugPrint('UI: Building food list - count: ${_searchResults.length}');

    // If we have an active search, show search results
    if (_hasSearched) {
      return ListView.builder(
        itemCount: _searchResults.length,
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        itemBuilder: (context, index) => _buildFoodItem(_searchResults[index]),
      );
    }
    // Otherwise show recent and favorite foods
    else {
      return _buildInitialSuggestions();
    }
  }

  Widget _buildInitialSuggestions() {
    try {
      final colorScheme = Theme.of(context).colorScheme;
      final textColor = colorScheme.onSurface;

      if (_recentFoods.isEmpty && _favoriteFoods.isEmpty && !_isLoading) {
        // Show placeholder when no suggestions available
        return Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.food_bank_outlined,
                    size: 80,
                    color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Start by searching for foods',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Use the search bar above or scan a barcode',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () {
                      context.go(
                        '/nutrition/add?date=${widget.date.toIso8601String()}',
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Custom Food'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // Show recent and favorite foods in a scrollable list with card design
      return ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          if (_recentFoods.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              child: Row(
                children: [
                  Icon(Icons.history, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Recently Used Foods',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
            ...List.generate(
              _recentFoods.length > 5 ? 5 : _recentFoods.length,
              (index) => _buildFoodItem(_recentFoods[index]),
            ),
          ],
          if (_favoriteFoods.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              child: Row(
                children: [
                  Icon(Icons.favorite, color: colorScheme.error),
                  const SizedBox(width: 8),
                  Text(
                    'Favorite Foods',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
            ...List.generate(
              _favoriteFoods.length > 5 ? 5 : _favoriteFoods.length,
              (index) => _buildFoodItem(_favoriteFoods[index]),
            ),
          ],
          // Add a bit of padding at the bottom and a custom food button
          const SizedBox(height: 16),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: FilledButton.icon(
              onPressed: () {
                context.go(
                  '/nutrition/add?date=${widget.date.toIso8601String()}',
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Custom Food'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    } catch (e) {
      debugPrint('Error building initial suggestions: $e');
      // Fallback widget in case of errors
      final colorScheme = Theme.of(context).colorScheme;

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: colorScheme.error.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load suggestions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Error: ${e.toString()}',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
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
