import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageServiceImpl();
});

abstract class LocalStorageService {
  Future<T?> getData<T>(String boxName, String key);
  Future<void> saveData<T>(String boxName, String key, T data);
  Future<void> deleteData(String boxName, String key);
  Future<List<T>> getAllData<T>(String boxName);
}

class LocalStorageServiceImpl implements LocalStorageService {
  @override
  Future<T?> getData<T>(String boxName, String key) async {
    final box = await Hive.openBox<dynamic>(boxName);
    return box.get(key) as T?;
  }

  @override
  Future<void> saveData<T>(String boxName, String key, T data) async {
    final box = await Hive.openBox<dynamic>(boxName);
    await box.put(key, data);
  }

  @override
  Future<void> deleteData(String boxName, String key) async {
    final box = await Hive.openBox<dynamic>(boxName);
    await box.delete(key);
  }

  @override
  Future<List<T>> getAllData<T>(String boxName) async {
    final box = await Hive.openBox<dynamic>(boxName);
    return box.values.cast<T>().toList();
  }

  // Helper method to save a list of objects where each has a unique ID
  Future<void> saveMapData<T>(
    String boxName,
    String key,
    Map<String, T> data,
  ) async {
    final box = await Hive.openBox<dynamic>(boxName);
    await box.put(key, data);
  }

  // Helper method to save a collection with a timestamp for sync status
  Future<void> saveWithTimestamp<T>(String boxName, String key, T data) async {
    final box = await Hive.openBox<dynamic>(boxName);
    final entry = {
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
      'synced': false,
    };
    await box.put(key, entry);
  }

  // Mark an item as synced
  Future<void> markAsSynced(String boxName, String key) async {
    final box = await Hive.openBox<dynamic>(boxName);
    final data = box.get(key);
    if (data != null && data is Map) {
      final updatedData = Map<String, dynamic>.from(data);
      updatedData['synced'] = true;
      await box.put(key, updatedData);
    }
  }

  // Get all unsynced items
  Future<Map<String, dynamic>> getUnsyncedItems(String boxName) async {
    final box = await Hive.openBox<dynamic>(boxName);
    final result = <String, dynamic>{};

    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map && value['synced'] == false) {
        result[key.toString()] = value['data'];
      }
    }

    return result;
  }
}

/// Keys used for storing data in shared preferences
class PreferenceKeys {
  /// The key for onboarding completion status
  static const String onboardingCompleted = 'onboarding_completed';

  /// The key for theme mode
  static const String themeMode = 'theme_mode';

  /// Key for permissions already requested
  static const String permissionsRequested = 'permissions_requested';
}
