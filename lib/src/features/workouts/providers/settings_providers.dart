import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/weight_unit.dart';

/// Provider for the user's preferred weight unit.
///
/// Defaults to kg. In a real app, this would likely read from
/// user preferences (e.g., SharedPreferences).
final preferredWeightUnitProvider = StateProvider<WeightUnit>((ref) {
  // TODO: Load from actual user preferences
  return WeightUnit.lbs;
});
