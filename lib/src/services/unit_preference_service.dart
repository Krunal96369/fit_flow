import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

// --- Enums ---
/// Represents the unit system to use for measurements
enum UnitSystem {
  /// Metric system (kg, cm, etc.)
  metric,

  /// Imperial system (lb, ft, etc.)
  imperial,
}

// --- Constants ---
const String _kUnitSystemKey = 'unit_system';
const String _kPreferencesBox = 'preferences';

// --- Providers ---

/// Provider for the current unit system
final unitSystemProvider =
    StateNotifierProvider<UnitSystemNotifier, UnitSystem>((
  ref,
) {
  return UnitSystemNotifier();
});

// --- Notifier ---

/// Manages the application's [UnitSystem] state.
class UnitSystemNotifier extends StateNotifier<UnitSystem> {
  /// Creates a [UnitSystemNotifier] and loads the saved unit system.
  UnitSystemNotifier() : super(UnitSystem.metric) {
    _loadUnitSystem();
  }

  /// Loads the saved unit system from local storage.
  Future<void> _loadUnitSystem() async {
    try {
      final Box<dynamic> box = await Hive.openBox<dynamic>(_kPreferencesBox);
      final String? savedUnitSystem = box.get(_kUnitSystemKey) as String?;
      if (savedUnitSystem != null) {
        state = _unitSystemFromString(savedUnitSystem);
      }
    } catch (e) {
      // Handle potential Hive errors
      debugPrint('Error loading unit system from Hive: $e');
      // Keep default state (UnitSystem.metric)
    }
  }

  /// Sets the application's unit system and saves it locally.
  Future<void> setUnitSystem(UnitSystem unitSystem) async {
    if (state == unitSystem) return; // Avoid unnecessary updates and writes

    state = unitSystem;
    try {
      final Box<dynamic> box = await Hive.openBox<dynamic>(_kPreferencesBox);
      await box.put(_kUnitSystemKey, unitSystem.toString());
    } catch (e) {
      // Handle potential Hive errors
      debugPrint('Error saving unit system to Hive: $e');
    }
  }

  /// Converts a string representation back to a [UnitSystem].
  UnitSystem _unitSystemFromString(String unitSystemString) =>
      UnitSystem.values.firstWhere(
        (system) => system.toString() == unitSystemString,
        orElse: () => UnitSystem.metric, // Default to metric if parsing fails
      );
}

// --- Utility Extension ---

/// Extension on [UnitSystem] to provide conversion methods
extension UnitSystemExtension on UnitSystem {
  /// Convert height from the current unit system to centimeters
  double heightToCm(double value) {
    if (this == UnitSystem.imperial) {
      // Convert feet and inches (assumed as decimal) to cm
      // 1 foot = 30.48 cm
      return value * 30.48;
    }
    return value; // Already in cm
  }

  /// Convert height from centimeters to the current unit system
  double heightFromCm(double cm) {
    if (this == UnitSystem.imperial) {
      // Convert cm to feet
      // 1 cm = 0.0328084 feet
      return cm * 0.0328084;
    }
    return cm; // Keep as cm
  }

  /// Convert weight from the current unit system to kilograms
  double weightToKg(double value) {
    if (this == UnitSystem.imperial) {
      // Convert pounds to kg
      // 1 pound = 0.453592 kg
      return value * 0.453592;
    }
    return value; // Already in kg
  }

  /// Convert weight from kilograms to the current unit system
  double weightFromKg(double kg) {
    if (this == UnitSystem.imperial) {
      // Convert kg to pounds
      // 1 kg = 2.20462 pounds
      return kg * 2.20462;
    }
    return kg; // Keep as kg
  }

  /// Get the label for height units
  String get heightLabel => this == UnitSystem.metric ? 'cm' : 'ft';

  /// Get the label for weight units
  String get weightLabel => this == UnitSystem.metric ? 'kg' : 'lb';
}
