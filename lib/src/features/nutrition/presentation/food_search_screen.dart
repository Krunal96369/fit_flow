import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common_widgets/app_scaffold.dart';
import '../../../features/auth/application/auth_controller.dart';
import '../../../services/barcode_scanner_service.dart';
import '../application/food_controller.dart';
import '../domain/food_item.dart';

/// Screen for searching food items in the nutrition database
///
/// Provides functionality to search by text and barcode, and displays
/// recent/favorite foods when no search is active.
class FoodSearchScreen extends ConsumerStatefulWidget {
  /// Date for which the food will be added to the nutrition log
  final DateTime date;

  /// Creates a new food search screen
  ///
  /// [date] The date for which the food entry will be recorded
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

  /// Loads the user's recent and favorite foods
  ///
  /// This method is called on initialization and fetches the user's
  /// recently used and favorite food items from the repository
  Future<void> _loadInitialData() async {
    try {
      final user = ref.read(authStateProvider).value;
      final userId = user?.uid;

      if (userId == null) {
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

      try {
        List<FoodItem> recentFoods = [];
        List<FoodItem> favoriteFoods = [];

        try {
          recentFoods =
              await ref.read(foodControllerProvider).getRecentFoods(userId);
        } catch (recentError) {
          // Silently handle error loading recent foods
        }

        try {
          favoriteFoods =
              await ref.read(foodControllerProvider).getFavoriteFoods(userId);
        } catch (favoriteError) {
          // Silently handle error loading favorite foods
        }

        if (mounted) {
          setState(() {
            _recentFoods = recentFoods;
            _favoriteFoods = favoriteFoods;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = 'Error loading data: ${e.toString()}';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Unexpected error: ${e.toString()}';
        });
      }
    }
  }

  /// Performs a food search with the given query
  ///
  /// [query] The search term to use for finding food items
  void _performSearch(String query) {
    try {
      if (query.trim().isEmpty) {
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

      _debounce.run(() async {
        try {
          final results = await ref
              .read(foodControllerProvider)
              .searchFoodByName(query.trim());

          if (mounted) {
            setState(() {
              _searchResults = results;
              _isLoading = false;
              _error =
                  results.isEmpty ? 'No foods found matching "$query"' : null;
            });
          }
        } catch (e) {
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
          }
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Unexpected error: ${e.toString()}';
        });
      }
    }
  }

  /// Handles changes to the search text field
  ///
  /// [text] The current text in the search field
  void _onSearchTextChanged(String text) {
    if (text.isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
        _error = null;
      });
    }
  }

  /// Selects a food item and navigates to the add nutrition screen
  ///
  /// [food] The food item to add to the nutrition log
  void _selectFood(FoodItem food) {
    try {
      final user = ref.read(authStateProvider).value;
      final userId = user?.uid;

      if (userId != null && food.id.isNotEmpty) {
        // Mark as recently used, but don't wait for it to complete
        // and handle errors silently to avoid blocking the navigation
        ref
            .read(foodControllerProvider)
            .markFoodAsRecentlyUsed(userId, food.id)
            .catchError((error) {
          // Silently log the error but allow navigation to continue
          debugPrint(
              'Error marking food as recently used: ${error.toString()}');
          return null; // Return null to satisfy the Future
        });
      }

      // Navigate to add nutrition entry screen with selected food
      context.go(
        '/nutrition/add?date=${widget.date.toIso8601String()}',
        extra: food,
      );
    } catch (e) {
      // Log the error but still navigate
      debugPrint('Error in _selectFood: ${e.toString()}');
      context.go(
        '/nutrition/add?date=${widget.date.toIso8601String()}',
        extra: food,
      );
    }
  }

  /// Builds the search bar with barcode scanner button
  ///
  /// @returns A widget containing the search field and barcode button
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

  /// Builds a food item card for display in lists
  ///
  /// [food] The food item to display
  /// @returns A widget card displaying the food item's details
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

                          // Nutrition information
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

  /// Builds a nutrient chip for displaying macronutrient information
  ///
  /// [label] The nutrient label (e.g., "P" for protein)
  /// [value] The nutrient value with unit (e.g., "20g")
  /// [lightModeBackground] Background color in light mode
  /// [lightModeText] Text color in light mode
  /// @returns A styled container displaying the nutrient information
  Widget _buildNutrientChip(String label, String value,
      Color lightModeBackground, Color lightModeText) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = colorScheme.brightness == Brightness.dark;

    Color chipBackground;
    Color chipText;
    Color borderColor;

    if (isDarkMode) {
      // In dark mode, use more subtle, darker colors
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

  /// Builds the empty search state UI
  ///
  /// @returns A widget displaying message when no search results are found
  Widget _buildEmptySearchState() {
    final colorScheme = Theme.of(context).colorScheme;

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

  /// Builds the error state UI
  ///
  /// @returns A widget displaying error message when search fails
  Widget _buildErrorState() {
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

  /// Builds the loading state UI
  ///
  /// @returns A widget displaying loading indicator during search
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

  /// Scans a barcode and searches for matching food items
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

      // Handle null or empty barcode (user cancelled scan)
      if (barcode == null || barcode.isEmpty) {
        if (mounted) {
          setState(() {
            _isScanningBarcode = false;
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
          } else if (e.toString().contains('unauthenticated') ||
              e.toString().contains('authentication')) {
            _error = 'Authentication issue. Please log out and log in again.';
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

  /// Builds the main widget
  ///
  /// @returns The composed screen widget
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Food Search',
      body: FocusScope(
        child: Column(
          children: [
            // Search bar at the top
            _buildSearchBar(),

            // Main content area
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

  /// Builds the food list based on current state
  ///
  /// @returns A widget displaying either search results or suggested foods
  Widget _buildFoodList() {
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

  /// Builds the initial suggestions UI with recent and favorite foods
  ///
  /// @returns A widget displaying recent and favorite foods or an empty state
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
///
/// Delays execution of the provided action to avoid excessive API calls
/// during rapid user input like typing in a search field
class Debouncer {
  /// The delay in milliseconds before executing the action
  final int milliseconds;

  /// The timer that tracks the delay
  Timer? _timer;

  /// Creates a new debouncer with the specified delay
  ///
  /// [milliseconds] The delay before executing the action
  Debouncer({required this.milliseconds});

  /// Runs the provided action after the delay, canceling any pending action
  ///
  /// [action] The callback to execute after the delay
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}
