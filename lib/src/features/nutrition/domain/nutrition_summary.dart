/// Represents a nutritional summary for a given day
class DailyNutritionSummary {
  /// The date this summary represents
  final DateTime date;

  /// Total calories consumed
  final int totalCalories;

  /// Total protein consumed in grams
  final double totalProtein;

  /// Total carbs consumed in grams
  final double totalCarbs;

  /// Total fat consumed in grams
  final double totalFat;

  /// Current calorie goal for the user
  final int calorieGoal;

  /// Current protein goal in grams
  final double proteinGoal;

  /// Current carbs goal in grams
  final double carbsGoal;

  /// Current fat goal in grams
  final double fatGoal;

  /// Water intake in milliliters
  final int waterIntake;

  /// Water intake goal in milliliters
  final int waterGoal;

  /// Number of entries logged on this day
  final int entryCount;

  DailyNutritionSummary({
    required this.date,
    this.totalCalories = 0,
    this.totalProtein = 0,
    this.totalCarbs = 0,
    this.totalFat = 0,
    required this.calorieGoal,
    required this.proteinGoal,
    required this.carbsGoal,
    required this.fatGoal,
    this.waterIntake = 0,
    required this.waterGoal,
    this.entryCount = 0,
  });

  /// Calculate remaining calories for the day
  int get remainingCalories => calorieGoal - totalCalories;

  /// Calculate remaining protein for the day
  double get remainingProtein => proteinGoal - totalProtein;

  /// Calculate remaining carbs for the day
  double get remainingCarbs => carbsGoal - totalCarbs;

  /// Calculate remaining fat for the day
  double get remainingFat => fatGoal - totalFat;

  /// Calculate remaining water for the day
  int get remainingWater => waterGoal - waterIntake;

  /// Calculate calorie progress percentage (capped at 100%)
  double get calorieProgress => (totalCalories / calorieGoal).clamp(0.0, 1.0);

  /// Calculate protein progress percentage (capped at 100%)
  double get proteinProgress => (totalProtein / proteinGoal).clamp(0.0, 1.0);

  /// Calculate carbs progress percentage (capped at 100%)
  double get carbsProgress => (totalCarbs / carbsGoal).clamp(0.0, 1.0);

  /// Calculate fat progress percentage (capped at 100%)
  double get fatProgress => (totalFat / fatGoal).clamp(0.0, 1.0);

  /// Calculate water progress percentage (capped at 100%)
  double get waterProgress => (waterIntake / waterGoal).clamp(0.0, 1.0);

  /// Create a copy of this summary with given fields replaced with new values
  DailyNutritionSummary copyWith({
    DateTime? date,
    int? totalCalories,
    double? totalProtein,
    double? totalCarbs,
    double? totalFat,
    int? calorieGoal,
    double? proteinGoal,
    double? carbsGoal,
    double? fatGoal,
    int? waterIntake,
    int? waterGoal,
    int? entryCount,
  }) {
    return DailyNutritionSummary(
      date: date ?? this.date,
      totalCalories: totalCalories ?? this.totalCalories,
      totalProtein: totalProtein ?? this.totalProtein,
      totalCarbs: totalCarbs ?? this.totalCarbs,
      totalFat: totalFat ?? this.totalFat,
      calorieGoal: calorieGoal ?? this.calorieGoal,
      proteinGoal: proteinGoal ?? this.proteinGoal,
      carbsGoal: carbsGoal ?? this.carbsGoal,
      fatGoal: fatGoal ?? this.fatGoal,
      waterIntake: waterIntake ?? this.waterIntake,
      waterGoal: waterGoal ?? this.waterGoal,
      entryCount: entryCount ?? this.entryCount,
    );
  }

  /// Convert summary to a map for storage
  Map<String, dynamic> toMap() {
    return {
      'date': date.millisecondsSinceEpoch,
      'totalCalories': totalCalories,
      'totalProtein': totalProtein,
      'totalCarbs': totalCarbs,
      'totalFat': totalFat,
      'calorieGoal': calorieGoal,
      'proteinGoal': proteinGoal,
      'carbsGoal': carbsGoal,
      'fatGoal': fatGoal,
      'waterIntake': waterIntake,
      'waterGoal': waterGoal,
      'entryCount': entryCount,
    };
  }

  /// Create a summary from a map
  factory DailyNutritionSummary.fromMap(Map<String, dynamic> map) {
    return DailyNutritionSummary(
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      totalCalories: map['totalCalories'] ?? 0,
      totalProtein: map['totalProtein'] ?? 0.0,
      totalCarbs: map['totalCarbs'] ?? 0.0,
      totalFat: map['totalFat'] ?? 0.0,
      calorieGoal: map['calorieGoal'] ?? 2000,
      proteinGoal: map['proteinGoal'] ?? 50.0,
      carbsGoal: map['carbsGoal'] ?? 250.0,
      fatGoal: map['fatGoal'] ?? 70.0,
      waterIntake: map['waterIntake'] ?? 0,
      waterGoal: map['waterGoal'] ?? 2000,
      entryCount: map['entryCount'] ?? 0,
    );
  }
}

/// Represents user's nutritional goals and preferences
class NutritionGoals {
  /// Daily calorie goal
  final int calorieGoal;

  /// Daily protein goal in grams
  final double proteinGoal;

  /// Daily carbohydrate goal in grams
  final double carbsGoal;

  /// Daily fat goal in grams
  final double fatGoal;

  /// Daily water goal in milliliters
  final int waterGoal;

  /// User ID these goals belong to
  final String userId;

  /// When these goals were last updated
  final DateTime lastUpdated;

  /// Macronutrient distribution (protein/carbs/fat percentages)
  final MacroDistribution macroDistribution;

  NutritionGoals({
    required this.calorieGoal,
    required this.proteinGoal,
    required this.carbsGoal,
    required this.fatGoal,
    required this.waterGoal,
    required this.userId,
    DateTime? lastUpdated,
    MacroDistribution? macroDistribution,
  }) : lastUpdated = lastUpdated ?? DateTime.now(),
       macroDistribution = macroDistribution ?? MacroDistribution();

  /// Create a copy of these goals with given fields replaced with new values
  NutritionGoals copyWith({
    int? calorieGoal,
    double? proteinGoal,
    double? carbsGoal,
    double? fatGoal,
    int? waterGoal,
    String? userId,
    DateTime? lastUpdated,
    MacroDistribution? macroDistribution,
  }) {
    return NutritionGoals(
      calorieGoal: calorieGoal ?? this.calorieGoal,
      proteinGoal: proteinGoal ?? this.proteinGoal,
      carbsGoal: carbsGoal ?? this.carbsGoal,
      fatGoal: fatGoal ?? this.fatGoal,
      waterGoal: waterGoal ?? this.waterGoal,
      userId: userId ?? this.userId,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      macroDistribution: macroDistribution ?? this.macroDistribution,
    );
  }

  /// Convert goals to a map for storage
  Map<String, dynamic> toMap() {
    return {
      'calorieGoal': calorieGoal,
      'proteinGoal': proteinGoal,
      'carbsGoal': carbsGoal,
      'fatGoal': fatGoal,
      'waterGoal': waterGoal,
      'userId': userId,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      'macroDistribution': macroDistribution.toMap(),
    };
  }

  /// Create goals from a map
  factory NutritionGoals.fromMap(Map<String, dynamic> map) {
    return NutritionGoals(
      calorieGoal: map['calorieGoal'] ?? 2000,
      proteinGoal: map['proteinGoal'] ?? 50.0,
      carbsGoal: map['carbsGoal'] ?? 250.0,
      fatGoal: map['fatGoal'] ?? 70.0,
      waterGoal: map['waterGoal'] ?? 2000,
      userId: map['userId'],
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(
        map['lastUpdated'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      macroDistribution:
          map['macroDistribution'] != null
              ? MacroDistribution.fromMap(map['macroDistribution'])
              : MacroDistribution(),
    );
  }
}

/// Represents the distribution of macronutrients in the diet
class MacroDistribution {
  /// Percentage of calories from protein (0-100)
  final int proteinPercentage;

  /// Percentage of calories from carbohydrates (0-100)
  final int carbsPercentage;

  /// Percentage of calories from fat (0-100)
  final int fatPercentage;

  MacroDistribution({
    this.proteinPercentage = 25,
    this.carbsPercentage = 50,
    this.fatPercentage = 25,
  });

  /// Validate that percentages add up to 100
  bool get isValid =>
      proteinPercentage + carbsPercentage + fatPercentage == 100;

  /// Create a copy with given fields replaced with new values
  MacroDistribution copyWith({
    int? proteinPercentage,
    int? carbsPercentage,
    int? fatPercentage,
  }) {
    return MacroDistribution(
      proteinPercentage: proteinPercentage ?? this.proteinPercentage,
      carbsPercentage: carbsPercentage ?? this.carbsPercentage,
      fatPercentage: fatPercentage ?? this.fatPercentage,
    );
  }

  /// Convert to a map for storage
  Map<String, dynamic> toMap() {
    return {
      'proteinPercentage': proteinPercentage,
      'carbsPercentage': carbsPercentage,
      'fatPercentage': fatPercentage,
    };
  }

  /// Create from a map
  factory MacroDistribution.fromMap(Map<String, dynamic> map) {
    return MacroDistribution(
      proteinPercentage: map['proteinPercentage'] ?? 25,
      carbsPercentage: map['carbsPercentage'] ?? 50,
      fatPercentage: map['fatPercentage'] ?? 25,
    );
  }
}
