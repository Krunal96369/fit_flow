import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../features/auth/domain/auth_repository.dart';
import '../../features/nutrition/domain/food_repository.dart';
import '../../features/nutrition/domain/nutrition_repository.dart';
import '../../features/profile/domain/profile_repository.dart';
import '../../services/biometric/biometric_service.dart';
import '../../services/secure_storage/secure_storage_service.dart';
import '../services/cloud_functions_service.dart';
import '../services/fatsecret_service.dart';
import 'firebase_auth_repository.dart';
import 'firebase_food_repository.dart';
import 'firebase_nutrition_repository.dart';
import 'firebase_profile_repository.dart';

// Firebase instances
final _firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final _firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final _firebaseFunctionsProvider = Provider<FirebaseFunctions>((ref) {
  return FirebaseFunctions.instance;
});

// Remote Config provider
final _remoteConfigProvider = Provider<FirebaseRemoteConfig>((ref) {
  return FirebaseRemoteConfig.instance;
});

// Connectivity provider
final _connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

// Hive box providers
final _nutritionEntriesBoxProvider = Provider<Box<Map>>((ref) {
  return Hive.box<Map>('nutrition_entries');
});

final _nutritionSummariesBoxProvider = Provider<Box<Map>>((ref) {
  return Hive.box<Map>('nutrition_summaries');
});

final _nutritionGoalsBoxProvider = Provider<Box<Map>>((ref) {
  return Hive.box<Map>('nutrition_goals');
});

final _foodsBoxProvider = Provider<Box<Map>>((ref) {
  return Hive.box<Map>('foods');
});

final _favoriteFoodsBoxProvider = Provider<Box<Map>>((ref) {
  return Hive.box<Map>('favorite_foods');
});

final _recentFoodsBoxProvider = Provider<Box<Map>>((ref) {
  return Hive.box<Map>('recent_foods');
});

// FatSecret API provider
final _fatSecretServiceProvider = Provider<FatSecretService>((ref) {
  final remoteConfig = ref.watch(_remoteConfigProvider);

  // Create the service
  final service = FatSecretService(
    remoteConfig: remoteConfig,
  );

  // The initialize method will be called by the repository when needed
  // We don't call it here to avoid initialization errors affecting the entire app

  return service;
});

// Cloud Functions Service provider
final cloudFunctionsServiceProvider = Provider<CloudFunctionsService>((ref) {
  final functions = ref.watch(_firebaseFunctionsProvider);
  return CloudFunctionsService(functions: functions);
});

// Biometric Service provider
final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricServiceImpl();
});

// Secure Storage Service provider
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageServiceImpl();
});

// Repository providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository(
    ref.watch(_firebaseAuthProvider),
    firestore: ref.watch(_firestoreProvider),
    biometricService: ref.watch(biometricServiceProvider),
    secureStorage: ref.watch(secureStorageProvider),
  );
});

/// Provides the stream of Firebase Auth state changes.
/// Emits the current User? object when the auth state changes.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges();
});

/// Provides the UID of the currently authenticated user.
/// Returns null if the user is not logged in.
final currentUserIdProvider = Provider<String?>((ref) {
  // Watch the auth state stream
  debugPrint('--- Reading currentUserIdProvider ---'); // Log when read
  final authState = ref.watch(authStateChangesProvider);
  // Return the user's UID if logged in, otherwise null
  final user = authState.value; // Get the User? object
  // Log the user object and its UID
  debugPrint('--- currentUserIdProvider: authState.value = $user ---');
  debugPrint('--- currentUserIdProvider: returning uid = ${user?.uid} ---');
  return user?.uid;
});

final nutritionRepositoryProvider = Provider<NutritionRepository>((ref) {
  return FirebaseNutritionRepository(
    firestore: ref.watch(_firestoreProvider),
    entriesBox: ref.watch(_nutritionEntriesBoxProvider),
    summariesBox: ref.watch(_nutritionSummariesBoxProvider),
    goalsBox: ref.watch(_nutritionGoalsBoxProvider),
    connectivity: ref.watch(_connectivityProvider),
  );
});

final foodRepositoryProvider = Provider<FoodRepository>((ref) {
  return FirebaseFoodRepository(
    firestore: ref.watch(_firestoreProvider),
    foodsBox: ref.watch(_foodsBoxProvider),
    favoritesBox: ref.watch(_favoriteFoodsBoxProvider),
    recentFoodsBox: ref.watch(_recentFoodsBoxProvider),
    connectivity: ref.watch(_connectivityProvider),
    fatSecretService: ref.watch(_fatSecretServiceProvider),
    cloudFunctionsService: ref.watch(cloudFunctionsServiceProvider),
  );
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return FirebaseProfileRepository(
    firestore: ref.watch(_firestoreProvider),
    auth: ref.watch(_firebaseAuthProvider),
  );
});
