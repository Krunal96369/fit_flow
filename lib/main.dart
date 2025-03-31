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
import 'src/data/repositories/repository_providers.dart';
import 'src/features/nutrition/domain/food_repository.dart';
import 'src/services/notification_service.dart';

// Removed flutter_local_notifications import as it's now encapsulated in the service

void main() async {
  // Ensure widgets are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // DEBUGGING: Print startup information
  debugPrint('==============================================================');
  debugPrint('FitFlow App Starting');
  debugPrint('==============================================================');

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
      // Force the providers to be initialized
      baseFoodRepositoryProvider,
      nutritionRepositoryProvider,
      authRepositoryProvider,
    ],
  );

  // Pre-initialize repositories and verify they're loaded correctly
  final foodRepo = container.read(baseFoodRepositoryProvider);
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
    const ProviderScope(
      // Override any test/dev providers with the real implementations
      overrides: [
        // Use the real repository providers from src/data/repositories/repository_providers.dart
        // This ensures the entire app uses the Firebase implementations, not the mocks
      ],
      child: FitFlowApp(),
    ),
  );
}
