import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'firebase_options.dart';
import 'src/app.dart';
// Import specific repository implementations
import 'src/data/repositories/firebase_food_repository.dart';
// Import the repo providers that have the real implementations
import 'src/data/repositories/repository_providers.dart' as repos;
// Import domain interfaces
import 'src/features/nutrition/domain/nutrition_repository.dart' as domain;
import 'src/services/notification_service.dart';
import 'src/services/secure_storage/secure_storage_service.dart';

void main() async {
  // Ensure widgets are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Hive
  await Hive.initFlutter();

  // Register adapters for Hive
  // Note: No custom adapters needed as we're using Maps

  // Open Hive boxes
  await Hive.openBox<Map>('nutrition_entries');
  await Hive.openBox<Map>('nutrition_summaries');
  await Hive.openBox<Map>('nutrition_goals');
  await Hive.openBox<Map>('foods');
  await Hive.openBox<Map>('favorite_foods');
  await Hive.openBox<Map>('recent_foods');

  // Load remote config defaults and fetch values
  final remoteConfig = FirebaseRemoteConfig.instance;
  await remoteConfig.setConfigSettings(
    RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 12),
    ),
  );
  await remoteConfig.setDefaults({
    'fatsecret_api_key': '',
    'fatsecret_api_secret': '',
  });
  await remoteConfig.fetchAndActivate();

  // Create ProviderContainer to access providers outside the widget tree
  // Including overrides to ensure proper initialization
  final container = ProviderContainer(
    overrides: [
      // No overrides needed here, just accessing the providers
    ],
  );

  // Initialize SecureStorageService
  final secureStorage = container.read(secureStorageProvider);
  // Run a comprehensive test of secure storage
  await _testSecureStorage(secureStorage);

  // Pre-initialize repositories and verify they're loaded correctly
  final foodRepo = container.read(repos.foodRepositoryProvider);
  debugPrint('==============================================================');
  debugPrint('REPOSITORY DEBUG: Food Repository Type: ${foodRepo.runtimeType}');
  debugPrint(
      'REPOSITORY DEBUG: Is Firebase implementation: ${foodRepo is FirebaseFoodRepository}');
  debugPrint('==============================================================');

  // Initialize NotificationService
  final notificationService = container.read(notificationServiceProvider);
  await notificationService.initialize();

  // Wrap the app in ProviderScope to provide the repositories to the widget tree
  runApp(
    ProviderScope(
      // Explicitly override the mock nutrition repository with the real one
      overrides: [
        // This fixes the issue where the nutrition dashboard is using the mock repository
        domain.nutritionRepositoryProvider
            .overrideWithProvider(repos.nutritionRepositoryProvider),
      ],
      child: const FitFlowApp(),
    ),
  );
}

/// Test function to verify the secure storage is working correctly at startup
Future<void> _testSecureStorage(SecureStorageService secureStorage) async {
  try {
    debugPrint('SECURE STORAGE TEST: Starting diagnostic test...');

    // Test data
    const testKey = 'diagnostic_test_key';
    final testValue = 'test_value_${DateTime.now().toIso8601String()}';

    // Test setting a value
    debugPrint('SECURE STORAGE TEST: Setting test data');
    final setSuccess = await secureStorage.setSecureData(testKey, testValue);
    debugPrint('SECURE STORAGE TEST: Set success: $setSuccess');

    // Test retrieving the value
    final retrievedValue = await secureStorage.getSecureData(testKey);
    debugPrint(
        'SECURE STORAGE TEST: Retrieved value exists: ${retrievedValue != null}');

    // Test that values match
    final matches = retrievedValue == testValue;
    debugPrint('SECURE STORAGE TEST: Values match: $matches');

    // Test containsKey
    final hasKey = await secureStorage.containsKey(testKey);
    debugPrint('SECURE STORAGE TEST: Contains key: $hasKey');

    // Test secure credential keys
    final hasEmailKey = await secureStorage.containsKey('auth_email');
    final hasPasswordKey = await secureStorage.containsKey('auth_password');
    final hasBiometricEnabledKey =
        await secureStorage.containsKey('biometric_enabled');

    debugPrint('SECURE STORAGE TEST: Has email key: $hasEmailKey');
    debugPrint('SECURE STORAGE TEST: Has password key: $hasPasswordKey');
    debugPrint(
        'SECURE STORAGE TEST: Has biometric enabled key: $hasBiometricEnabledKey');

    // Report overall status
    if (setSuccess && matches && hasKey) {
      debugPrint(
          'SECURE STORAGE TEST: PASSED ✅ - Storage functioning correctly');
    } else {
      debugPrint(
          'SECURE STORAGE TEST: FAILED ❌ - Storage not working properly');
    }

    debugPrint(
        '==============================================================');
  } catch (e) {
    debugPrint('SECURE STORAGE TEST: Error during diagnostic test: $e');
  }
}
