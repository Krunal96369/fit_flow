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

// Removed flutter_local_notifications import as it's now encapsulated in the service

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
