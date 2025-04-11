import 'package:flutter/material.dart';

// App Info
const String kAppName = 'FitFlow';

// Locales
const Locale kDefaultLocale = Locale('en');
const List<Locale> kSupportedLocales = [kDefaultLocale];

/// Constants used throughout the app
class AppConstants {
  /// App name
  static const String appName = 'FitFlow';

  /// Default goals
  static const int defaultCalorieGoal = 2000;
  static const double defaultProteinGoal = 125;
  static const double defaultCarbsGoal = 250;
  static const double defaultFatGoal = 55;
  static const int defaultWaterGoal = 2500; // milliliters

  /// Firebase collections
  static const String userProfilesCollection = 'users';
  static const String workoutsCollection = 'workouts';
  static const String exercisesCollection = 'exercises';
  static const String nutritionEntriesCollection = 'nutrition_entries';
  static const String nutritionGoalsCollection = 'nutrition_goals';
  static const String favoriteExercisesCollection = 'favorite_exercises';
  static const String foodItemsCollection = 'food_items';

  /// Hive boxes
  static const String preferencesBox = 'preferences';
  static const String workoutDataBox = 'workoutData';
  static const String nutritionEntriesBox = 'nutrition_entries';
  static const String nutritionSummariesBox = 'nutrition_summaries';
  static const String nutritionGoalsBox = 'nutrition_goals';
  static const String foodsBox = 'foods';
  static const String favoriteFoodsBox = 'favorite_foods';
  static const String recentFoodsBox = 'recent_foods';

  /// Theme preferences keys
  static const String themeModeKey = 'themeMode';

  /// Onboarding preferences keys
  static const String onboardingCompletedKey = 'onboardingCompleted';
}
