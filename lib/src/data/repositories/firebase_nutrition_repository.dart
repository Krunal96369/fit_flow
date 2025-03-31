import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../features/nutrition/domain/nutrition_entry.dart';
import '../../features/nutrition/domain/nutrition_repository.dart';
import '../../features/nutrition/domain/nutrition_summary.dart';

/// Firebase implementation of the [NutritionRepository] with Hive caching for offline support
class FirebaseNutritionRepository implements NutritionRepository {
  final FirebaseFirestore _firestore;
  final Box<Map> _entriesBox;
  final Box<Map> _summariesBox;
  final Box<Map> _goalsBox;
  final Connectivity _connectivity;
  StreamSubscription? _connectivitySubscription;

  /// Key prefixes for Hive storage
  static const String _entryPrefix = 'entry_';
  static const String _dailySummaryPrefix = 'summary_';
  static const String _goalsPrefix = 'goals_';

  /// Firebase collection names
  static const String _entriesCollection = 'nutrition_entries';
  static const String _summariesCollection = 'nutrition_summaries';
  static const String _goalsCollection = 'nutrition_goals';

  /// Creates a [FirebaseNutritionRepository].
  FirebaseNutritionRepository({
    required FirebaseFirestore firestore,
    required Box<Map> entriesBox,
    required Box<Map> summariesBox,
    required Box<Map> goalsBox,
    required Connectivity connectivity,
  }) : _firestore = firestore,
       _entriesBox = entriesBox,
       _summariesBox = summariesBox,
       _goalsBox = goalsBox,
       _connectivity = connectivity {
    _initConnectivityListener();
  }

  void _initConnectivityListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      result,
    ) {
      if (result != ConnectivityResult.none) {
        syncOfflineData();
      }
    });
  }

  /// Synchronizes cached offline data with Firestore when internet connection is restored
  Future<void> syncOfflineData() async {
    try {
      // Sync unsynchronized entries
      final unsyncedEntries =
          _entriesBox.keys
              .where(
                (key) => key.toString().startsWith('${_entryPrefix}unsynced_'),
              )
              .toList();

      for (final key in unsyncedEntries) {
        final Map? entryMap = _entriesBox.get(key);
        if (entryMap != null) {
          final entry = NutritionEntry.fromMap(
            Map<String, dynamic>.from(entryMap),
          );
          await _saveEntryToFirestore(entry);

          // Delete the unsynced entry and store as synced
          await _entriesBox.delete(key);
          await _entriesBox.put('$_entryPrefix${entry.id}', entry.toMap());
        }
      }

      // Sync goals data
      final unsyncedGoals =
          _goalsBox.keys
              .where(
                (key) => key.toString().startsWith('${_goalsPrefix}unsynced_'),
              )
              .toList();

      for (final key in unsyncedGoals) {
        final Map? goalMap = _goalsBox.get(key);
        if (goalMap != null) {
          final userId = key.toString().split('_').last;
          final goals = NutritionGoals.fromMap(
            Map<String, dynamic>.from(goalMap),
          );
          await _saveGoalsToFirestore(goals);

          // Delete the unsynced goals and store as synced
          await _goalsBox.delete(key);
          await _goalsBox.put('$_goalsPrefix$userId', goals.toMap());
        }
      }
    } catch (e) {
      debugPrint('Error syncing offline data: $e');
    }
  }

  Future<bool> _isConnected() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  @override
  Future<NutritionEntry> addEntry(NutritionEntry entry) async {
    try {
      final isConnected = await _isConnected();

      if (isConnected) {
        await _saveEntryToFirestore(entry);
        await _entriesBox.put('$_entryPrefix${entry.id}', entry.toMap());
      } else {
        // Store as unsynced in local cache
        await _entriesBox.put(
          '${_entryPrefix}unsynced_${entry.id}',
          entry.toMap(),
        );
      }

      // Update the daily summary locally after adding an entry
      await _updateDailySummaryAfterEntryChange(entry);

      return entry;
    } catch (e) {
      debugPrint('Error adding nutrition entry: $e');
      rethrow;
    }
  }

  Future<void> _saveEntryToFirestore(NutritionEntry entry) async {
    await _firestore
        .collection(_entriesCollection)
        .doc(entry.id)
        .set(entry.toMap());
  }

  @override
  Future<NutritionEntry> updateEntry(NutritionEntry entry) async {
    try {
      final isConnected = await _isConnected();

      if (isConnected) {
        await _firestore
            .collection(_entriesCollection)
            .doc(entry.id)
            .update(entry.toMap());
        await _entriesBox.put('$_entryPrefix${entry.id}', entry.toMap());
      } else {
        // Store as unsynced in local cache
        await _entriesBox.put(
          '${_entryPrefix}unsynced_${entry.id}',
          entry.toMap(),
        );
      }

      // Update the daily summary after updating an entry
      await _updateDailySummaryAfterEntryChange(entry);

      return entry;
    } catch (e) {
      debugPrint('Error updating nutrition entry: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteEntry(String entryId) async {
    try {
      // Get the entry first to update summary after deletion
      final entry = await getEntryById(entryId);
      if (entry == null) return;

      final isConnected = await _isConnected();

      if (isConnected) {
        await _firestore.collection(_entriesCollection).doc(entryId).delete();
      }

      // Remove from local cache
      await _entriesBox.delete('$_entryPrefix$entryId');
      await _entriesBox.delete('${_entryPrefix}unsynced_$entryId');

      // Update the daily summary after deleting an entry
      await _updateDailySummaryAfterEntryChange(entry, isDelete: true);
    } catch (e) {
      debugPrint('Error deleting nutrition entry: $e');
      rethrow;
    }
  }

  @override
  Future<List<NutritionEntry>> getEntriesForDate(
    String userId,
    DateTime date,
  ) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Try to fetch from Firestore first if connected
      final isConnected = await _isConnected();
      List<NutritionEntry> entries = [];

      if (isConnected) {
        final querySnapshot =
            await _firestore
                .collection(_entriesCollection)
                .where('userId', isEqualTo: userId)
                .where(
                  'consumedAt',
                  isGreaterThanOrEqualTo: startOfDay.millisecondsSinceEpoch,
                )
                .where(
                  'consumedAt',
                  isLessThan: endOfDay.millisecondsSinceEpoch,
                )
                .get();

        entries =
            querySnapshot.docs
                .map((doc) => NutritionEntry.fromMap(doc.data()))
                .toList();

        // Update local cache
        for (final entry in entries) {
          await _entriesBox.put('$_entryPrefix${entry.id}', entry.toMap());
        }
      } else {
        // Fetch from local cache
        final localEntries =
            _entriesBox.values
                .map(
                  (map) =>
                      NutritionEntry.fromMap(Map<String, dynamic>.from(map)),
                )
                .where(
                  (entry) =>
                      entry.userId == userId &&
                      entry.consumedAt.isAfter(startOfDay) &&
                      entry.consumedAt.isBefore(endOfDay),
                )
                .toList();

        entries = localEntries;
      }

      return entries;
    } catch (e) {
      debugPrint('Error getting entries for date: $e');
      return [];
    }
  }

  @override
  Future<NutritionEntry?> getEntryById(String entryId) async {
    try {
      // Try local cache first
      final cachedData =
          _entriesBox.get('$_entryPrefix$entryId') ??
          _entriesBox.get('${_entryPrefix}unsynced_$entryId');

      if (cachedData != null) {
        return NutritionEntry.fromMap(Map<String, dynamic>.from(cachedData));
      }

      // If not in cache and connected, try Firestore
      final isConnected = await _isConnected();
      if (isConnected) {
        final doc =
            await _firestore.collection(_entriesCollection).doc(entryId).get();

        if (doc.exists) {
          final entry = NutritionEntry.fromMap(doc.data()!);
          // Update cache
          await _entriesBox.put('$_entryPrefix${entry.id}', entry.toMap());
          return entry;
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error getting entry by ID: $e');
      return null;
    }
  }

  @override
  Future<DailyNutritionSummary> getDailySummary(
    String userId,
    DateTime date,
  ) async {
    try {
      final dateKey = '${date.year}-${date.month}-${date.day}';
      final summaryId = '$userId-$dateKey';

      // Try local cache first
      final cachedData = _summariesBox.get('$_dailySummaryPrefix$summaryId');

      if (cachedData != null) {
        return DailyNutritionSummary.fromMap(
          Map<String, dynamic>.from(cachedData),
        );
      }

      // If not in cache, try Firestore if connected
      final isConnected = await _isConnected();
      if (isConnected) {
        final doc =
            await _firestore
                .collection(_summariesCollection)
                .doc(summaryId)
                .get();

        if (doc.exists) {
          final summary = DailyNutritionSummary.fromMap(doc.data()!);
          // Update cache
          await _summariesBox.put(
            '$_dailySummaryPrefix$summaryId',
            summary.toMap(),
          );
          return summary;
        }
      }

      // If neither cache nor Firestore has the summary, calculate it from entries
      return _calculateDailySummary(userId, date);
    } catch (e) {
      debugPrint('Error getting daily summary: $e');
      // Return default summary with 0 values
      final goals = await getUserNutritionGoals(userId);
      return DailyNutritionSummary(
        date: date,
        calorieGoal: goals.calorieGoal,
        proteinGoal: goals.proteinGoal,
        carbsGoal: goals.carbsGoal,
        fatGoal: goals.fatGoal,
        waterGoal: goals.waterGoal,
      );
    }
  }

  Future<DailyNutritionSummary> _calculateDailySummary(
    String userId,
    DateTime date,
  ) async {
    try {
      final entries = await getEntriesForDate(userId, date);
      final goals = await getUserNutritionGoals(userId);

      int totalCalories = 0;
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;
      int waterIntake = 0;

      for (final entry in entries) {
        totalCalories += entry.calories;
        totalProtein += entry.protein;
        totalCarbs += entry.carbs;
        totalFat += entry.fat;
      }

      final summary = DailyNutritionSummary(
        date: date,
        totalCalories: totalCalories,
        totalProtein: totalProtein,
        totalCarbs: totalCarbs,
        totalFat: totalFat,
        calorieGoal: goals.calorieGoal,
        proteinGoal: goals.proteinGoal,
        carbsGoal: goals.carbsGoal,
        fatGoal: goals.fatGoal,
        waterIntake: waterIntake,
        waterGoal: goals.waterGoal,
        entryCount: entries.length,
      );

      // Save to local cache
      final dateKey = '${date.year}-${date.month}-${date.day}';
      final summaryId = '$userId-$dateKey';
      await _summariesBox.put(
        '$_dailySummaryPrefix$summaryId',
        summary.toMap(),
      );

      // If connected, save to Firestore
      final isConnected = await _isConnected();
      if (isConnected) {
        await _firestore
            .collection(_summariesCollection)
            .doc(summaryId)
            .set(summary.toMap());
      }

      return summary;
    } catch (e) {
      debugPrint('Error calculating daily summary: $e');
      rethrow;
    }
  }

  Future<void> _updateDailySummaryAfterEntryChange(
    NutritionEntry entry, {
    bool isDelete = false,
  }) async {
    try {
      final date = DateTime(
        entry.consumedAt.year,
        entry.consumedAt.month,
        entry.consumedAt.day,
      );

      // Recalculate summary completely to ensure consistency
      await _calculateDailySummary(entry.userId, date);
    } catch (e) {
      debugPrint('Error updating daily summary after entry change: $e');
    }
  }

  @override
  Future<List<DailyNutritionSummary>> getDailySummariesForRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final List<DailyNutritionSummary> summaries = [];

      // Create a list of dates within the range
      for (
        var date = startDate;
        date.isBefore(endDate.add(const Duration(days: 1)));
        date = date.add(const Duration(days: 1))
      ) {
        final summary = await getDailySummary(userId, date);
        summaries.add(summary);
      }

      return summaries;
    } catch (e) {
      debugPrint('Error getting daily summaries for range: $e');
      return [];
    }
  }

  @override
  Future<NutritionGoals> getUserNutritionGoals(String userId) async {
    try {
      // Try local cache first
      final cachedData =
          _goalsBox.get('$_goalsPrefix$userId') ??
          _goalsBox.get('${_goalsPrefix}unsynced_$userId');

      if (cachedData != null) {
        return NutritionGoals.fromMap(Map<String, dynamic>.from(cachedData));
      }

      // If not in cache and connected, try Firestore
      final isConnected = await _isConnected();
      if (isConnected) {
        final doc =
            await _firestore.collection(_goalsCollection).doc(userId).get();

        if (doc.exists) {
          final goals = NutritionGoals.fromMap(doc.data()!);
          // Update cache
          await _goalsBox.put('$_goalsPrefix$userId', goals.toMap());
          return goals;
        }
      }

      // If no goals found, return default goals
      return _createDefaultNutritionGoals(userId);
    } catch (e) {
      debugPrint('Error getting user nutrition goals: $e');
      // Return default goals in case of error
      return _createDefaultNutritionGoals(userId);
    }
  }

  NutritionGoals _createDefaultNutritionGoals(String userId) {
    return NutritionGoals(
      userId: userId,
      calorieGoal: 2000,
      proteinGoal: 50,
      carbsGoal: 250,
      fatGoal: 70,
      waterGoal: 2000, // 2 liters in ml
    );
  }

  @override
  Future<NutritionGoals> updateNutritionGoals(NutritionGoals goals) async {
    try {
      final isConnected = await _isConnected();

      if (isConnected) {
        await _saveGoalsToFirestore(goals);
        await _goalsBox.put('$_goalsPrefix${goals.userId}', goals.toMap());
      } else {
        // Store as unsynced in local cache
        await _goalsBox.put(
          '${_goalsPrefix}unsynced_${goals.userId}',
          goals.toMap(),
        );
      }

      return goals;
    } catch (e) {
      debugPrint('Error updating nutrition goals: $e');
      rethrow;
    }
  }

  Future<void> _saveGoalsToFirestore(NutritionGoals goals) async {
    await _firestore
        .collection(_goalsCollection)
        .doc(goals.userId)
        .set(goals.toMap());
  }

  @override
  Future<void> logWaterIntake(String userId, DateTime date, int amount) async {
    try {
      final summary = await getDailySummary(userId, date);

      // Update the summary with the new water intake
      final updatedSummary = summary.copyWith(
        waterIntake: summary.waterIntake + amount,
      );

      // Save the updated summary
      final dateKey = '${date.year}-${date.month}-${date.day}';
      final summaryId = '$userId-$dateKey';

      await _summariesBox.put(
        '$_dailySummaryPrefix$summaryId',
        updatedSummary.toMap(),
      );

      // If connected, update Firestore
      final isConnected = await _isConnected();
      if (isConnected) {
        await _firestore
            .collection(_summariesCollection)
            .doc(summaryId)
            .set(updatedSummary.toMap());
      }
    } catch (e) {
      debugPrint('Error logging water intake: $e');
      rethrow;
    }
  }

  @override
  Future<int> getWaterIntake(String userId, DateTime date) async {
    try {
      final summary = await getDailySummary(userId, date);
      return summary.waterIntake;
    } catch (e) {
      debugPrint('Error getting water intake: $e');
      return 0;
    }
  }

  @override
  Future<List<NutritionEntry>> getEntriesForDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final startOfRange = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      );
      final endOfRange = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
      ).add(const Duration(days: 1));

      // Try to fetch from Firestore first if connected
      final isConnected = await _isConnected();
      List<NutritionEntry> entries = [];

      if (isConnected) {
        final querySnapshot =
            await _firestore
                .collection(_entriesCollection)
                .where('userId', isEqualTo: userId)
                .where(
                  'consumedAt',
                  isGreaterThanOrEqualTo: startOfRange.millisecondsSinceEpoch,
                )
                .where(
                  'consumedAt',
                  isLessThan: endOfRange.millisecondsSinceEpoch,
                )
                .get();

        entries =
            querySnapshot.docs
                .map((doc) => NutritionEntry.fromMap(doc.data()))
                .toList();

        // Update local cache
        for (final entry in entries) {
          await _entriesBox.put('$_entryPrefix${entry.id}', entry.toMap());
        }
      } else {
        // Fetch from local cache
        final localEntries =
            _entriesBox.values
                .map(
                  (map) =>
                      NutritionEntry.fromMap(Map<String, dynamic>.from(map)),
                )
                .where(
                  (entry) =>
                      entry.userId == userId &&
                      entry.consumedAt.isAfter(
                        startOfRange.subtract(const Duration(seconds: 1)),
                      ) &&
                      entry.consumedAt.isBefore(endOfRange),
                )
                .toList();

        entries = localEntries;
      }

      return entries;
    } catch (e) {
      debugPrint('Error getting entries for date range: $e');
      return [];
    }
  }

  @override
  Future<NutritionGoals> getNutritionGoals(String userId) async {
    try {
      final isConnected = await _isConnected();

      // Try to fetch from local cache first
      final cachedGoals = _goalsBox.get('$_goalsPrefix$userId');
      if (cachedGoals != null) {
        return NutritionGoals.fromMap(Map<String, dynamic>.from(cachedGoals));
      }

      if (isConnected) {
        final doc =
            await _firestore.collection(_goalsCollection).doc(userId).get();

        if (doc.exists && doc.data() != null) {
          final goals = NutritionGoals.fromMap(doc.data()!);

          // Cache the goals locally
          await _goalsBox.put('$_goalsPrefix$userId', goals.toMap());

          return goals;
        }
      }

      // If no goals exist yet, create default goals
      final defaultGoals = NutritionGoals(
        userId: userId,
        calorieGoal: 2000,
        proteinGoal: 125.0,
        carbsGoal: 250.0,
        fatGoal: 55.0,
        waterGoal: 2500, // 2.5 liters in ml
      );

      // Save default goals
      await saveNutritionGoals(defaultGoals);

      return defaultGoals;
    } catch (e) {
      debugPrint('Error getting nutrition goals: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveNutritionGoals(NutritionGoals goals) async {
    try {
      final isConnected = await _isConnected();

      if (isConnected) {
        await _saveGoalsToFirestore(goals);
        // Cache the goals locally
        await _goalsBox.put('$_goalsPrefix${goals.userId}', goals.toMap());
      } else {
        // Store as unsynced in local cache
        await _goalsBox.put(
          '${_goalsPrefix}unsynced_${goals.userId}',
          goals.toMap(),
        );
      }
    } catch (e) {
      debugPrint('Error saving nutrition goals: $e');
      rethrow;
    }
  }

  /// Dispose of any resources
  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
