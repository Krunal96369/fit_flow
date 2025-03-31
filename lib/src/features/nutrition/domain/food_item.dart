import 'package:uuid/uuid.dart';

/// Represents a food item with nutritional information
class FoodItem {
  /// Unique identifier
  final String id;

  /// User ID who created the item (if custom)
  final String userId;

  /// Name of the food
  final String name;

  /// Barcode of the product (if available)
  final String? barcode;

  /// Description or additional details
  final String? description;

  /// Serving size (e.g., "1 cup", "100g")
  final String servingSize;

  /// Whether this is a custom food created by the user
  final bool isCustom;

  /// Category of the food (e.g., "Fruits", "Dairy")
  final String category;

  /// Brand of the food (if applicable)
  final String? brand;

  /// Calories per serving
  final int calories;

  /// Protein content in grams per serving
  final double protein;

  /// Carbohydrate content in grams per serving
  final double carbs;

  /// Fat content in grams per serving
  final double fat;

  /// Sugar content in grams per serving
  final double? sugar;

  /// Fiber content in grams per serving
  final double? fiber;

  /// Sodium content in milligrams per serving
  final double? sodium;

  /// Timestamp when the food was created or added to the database
  final DateTime? createdAt;

  /// Optional image URL for the food
  final String? imageUrl;

  /// Nutritional data source (FDA, USDA, user, etc.)
  final String? source;

  /// Whether this food is marked as a favorite
  final bool isFavorite;

  /// Constructor
  FoodItem({
    String? id,
    required this.userId,
    required this.name,
    this.barcode,
    this.description,
    required this.servingSize,
    this.isCustom = false,
    String? category,
    this.brand,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.sugar,
    this.fiber,
    this.sodium,
    this.createdAt,
    this.imageUrl,
    this.source,
    this.isFavorite = false,
  }) : id = id ?? const Uuid().v4(),
       category = category ?? 'Uncategorized';

  /// Create a copy of this food item with given fields replaced with new values
  FoodItem copyWith({
    String? id,
    String? userId,
    String? name,
    String? barcode,
    String? description,
    String? servingSize,
    bool? isCustom,
    String? category,
    String? brand,
    int? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? sugar,
    double? fiber,
    double? sodium,
    DateTime? createdAt,
    String? imageUrl,
    String? source,
    bool? isFavorite,
  }) {
    return FoodItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      description: description ?? this.description,
      servingSize: servingSize ?? this.servingSize,
      isCustom: isCustom ?? this.isCustom,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      sugar: sugar ?? this.sugar,
      fiber: fiber ?? this.fiber,
      sodium: sodium ?? this.sodium,
      createdAt: createdAt ?? this.createdAt,
      imageUrl: imageUrl ?? this.imageUrl,
      source: source ?? this.source,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  /// Convert to a map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'barcode': barcode,
      'description': description,
      'servingSize': servingSize,
      'isCustom': isCustom,
      'category': category,
      'brand': brand,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'sugar': sugar,
      'fiber': fiber,
      'sodium': sodium,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'imageUrl': imageUrl,
      'source': source,
      'isFavorite': isFavorite,
    };
  }

  /// Create from a map
  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'],
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      barcode: map['barcode'],
      description: map['description'],
      servingSize: map['servingSize'] ?? '',
      isCustom: map['isCustom'] ?? false,
      category: map['category'] ?? 'Uncategorized',
      brand: map['brand'],
      calories: map['calories'] ?? 0,
      protein: map['protein'] ?? 0.0,
      carbs: map['carbs'] ?? 0.0,
      fat: map['fat'] ?? 0.0,
      sugar: map['sugar'],
      fiber: map['fiber'],
      sodium: map['sodium'],
      createdAt:
          map['createdAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
              : null,
      imageUrl: map['imageUrl'],
      source: map['source'],
      isFavorite: map['isFavorite'] ?? false,
    );
  }
}
