import 'macro_distribution.dart';

/// Represents a user's nutrition goals
class NutritionGoals {
  /// User ID that these goals belong to
  final String userId;

  /// Daily calorie goal
  final int calorieGoal;

  /// Daily protein goal in grams
  final double proteinGoal;

  /// Daily carbs goal in grams
  final double carbsGoal;

  /// Daily fat goal in grams
  final double fatGoal;

  /// Daily water intake goal in milliliters
  final int waterGoal;

  /// When these goals were last updated
  final DateTime lastUpdated;

  /// Macronutrient distribution (protein/carbs/fat percentages)
  final MacroDistribution macroDistribution;

  /// Constructor
  NutritionGoals({
    required this.userId,
    required this.calorieGoal,
    required this.proteinGoal,
    required this.carbsGoal,
    required this.fatGoal,
    required this.waterGoal,
    DateTime? lastUpdated,
    MacroDistribution? macroDistribution,
  })  : lastUpdated = lastUpdated ?? DateTime.now(),
        macroDistribution = macroDistribution ?? MacroDistribution();

  /// Create a copy of this object with some fields replaced
  NutritionGoals copyWith({
    String? userId,
    int? calorieGoal,
    double? proteinGoal,
    double? carbsGoal,
    double? fatGoal,
    int? waterGoal,
    DateTime? lastUpdated,
    MacroDistribution? macroDistribution,
  }) {
    return NutritionGoals(
      userId: userId ?? this.userId,
      calorieGoal: calorieGoal ?? this.calorieGoal,
      proteinGoal: proteinGoal ?? this.proteinGoal,
      carbsGoal: carbsGoal ?? this.carbsGoal,
      fatGoal: fatGoal ?? this.fatGoal,
      waterGoal: waterGoal ?? this.waterGoal,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      macroDistribution: macroDistribution ?? this.macroDistribution,
    );
  }

  /// Convert to map for database storage
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'calorieGoal': calorieGoal,
      'proteinGoal': proteinGoal,
      'carbsGoal': carbsGoal,
      'fatGoal': fatGoal,
      'waterGoal': waterGoal,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      'macroDistribution': macroDistribution.toMap(),
    };
  }

  /// Create nutrition goals from a map
  factory NutritionGoals.fromMap(Map<String, dynamic> map) {
    return NutritionGoals(
      userId: map['userId'] ?? '',
      calorieGoal: map['calorieGoal'] ?? 2000,
      proteinGoal: map['proteinGoal'] ?? 125.0,
      carbsGoal: map['carbsGoal'] ?? 250.0,
      fatGoal: map['fatGoal'] ?? 55.0,
      waterGoal: map['waterGoal'] ?? 2500,
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(
        map['lastUpdated'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      macroDistribution: map['macroDistribution'] != null
          ? MacroDistribution.fromMap(
              map['macroDistribution'] as Map<String, dynamic>)
          : MacroDistribution(),
    );
  }
}
