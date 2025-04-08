/// Represents the distribution of macronutrients in the diet
class MacroDistribution {
  /// Percentage of calories from protein (0-100)
  final int proteinPercentage;

  /// Percentage of calories from carbohydrates (0-100)
  final int carbsPercentage;

  /// Percentage of calories from fat (0-100)
  final int fatPercentage;

  MacroDistribution({
    this.proteinPercentage = 30,
    this.carbsPercentage = 40,
    this.fatPercentage = 30,
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
      proteinPercentage: map['proteinPercentage'] ?? 30,
      carbsPercentage: map['carbsPercentage'] ?? 40,
      fatPercentage: map['fatPercentage'] ?? 30,
    );
  }
}
