/// Represents a nutrition/food entry in the user's food log
class NutritionEntry {
  /// Unique ID for this entry
  final String id;

  /// User ID this entry belongs to
  final String userId;

  /// Name of the food
  final String name;

  /// When this food was consumed
  final DateTime consumedAt;

  /// Total calories in this entry (computed from nutrition values and serving size)
  final int calories;

  /// Protein content in grams
  final double protein;

  /// Carbohydrate content in grams
  final double carbs;

  /// Fat content in grams
  final double fat;

  /// Description of the serving size (e.g., "100g", "1 cup")
  final String servingSize;

  /// Number of servings consumed
  final double servings;

  /// Optional additional notes about this entry
  final String? notes;

  /// Type of meal (e.g., Breakfast, Lunch, Dinner, Snack)
  final String mealType;

  /// Whether this entry has been synced with the server
  final bool isSynced;

  /// Tags for categorizing entries (optional)
  final List<String> tags;

  /// Constructor
  NutritionEntry({
    required this.id,
    required this.userId,
    required this.name,
    required this.consumedAt,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.servingSize,
    required this.servings,
    this.notes,
    required this.mealType,
    this.isSynced = true,
    List<String>? tags,
  }) : tags = tags ?? [];

  /// Create a copy of this entry with given fields replaced with new values
  NutritionEntry copyWith({
    String? id,
    String? userId,
    String? name,
    DateTime? consumedAt,
    int? calories,
    double? protein,
    double? carbs,
    double? fat,
    String? servingSize,
    double? servings,
    String? notes,
    String? mealType,
    bool? isSynced,
    List<String>? tags,
  }) {
    return NutritionEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      consumedAt: consumedAt ?? this.consumedAt,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      servingSize: servingSize ?? this.servingSize,
      servings: servings ?? this.servings,
      notes: notes ?? this.notes,
      mealType: mealType ?? this.mealType,
      isSynced: isSynced ?? this.isSynced,
      tags: tags ?? this.tags,
    );
  }

  /// Convert entry to a map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'consumedAt': consumedAt.millisecondsSinceEpoch,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'servingSize': servingSize,
      'servings': servings,
      'notes': notes,
      'mealType': mealType,
      'isSynced': isSynced,
      'tags': tags,
    };
  }

  /// Create an entry from a map
  factory NutritionEntry.fromMap(Map<String, dynamic> map) {
    return NutritionEntry(
      id: map['id'],
      userId: map['userId'],
      name: map['name'],
      consumedAt: DateTime.fromMillisecondsSinceEpoch(map['consumedAt']),
      calories: map['calories'],
      protein: map['protein'].toDouble(),
      carbs: map['carbs'].toDouble(),
      fat: map['fat'].toDouble(),
      servingSize: map['servingSize'],
      servings: map['servings'].toDouble(),
      notes: map['notes'],
      mealType: map['mealType'] ?? 'Other',
      isSynced: map['isSynced'] ?? true,
      tags: List<String>.from(map['tags'] ?? []),
    );
  }
}
