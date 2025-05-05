/// Enum representing units of weight.
enum WeightUnit {
  kg,
  lbs;

  /// Returns the display string for the unit.
  String get displayName {
    switch (this) {
      case WeightUnit.kg:
        return 'kg';
      case WeightUnit.lbs:
        return 'lbs';
    }
  }
}
