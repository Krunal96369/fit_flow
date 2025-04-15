import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:rxdart/rxdart.dart';

import '../../features/nutrition/domain/nutrition_entry.dart';
import '../../features/nutrition/domain/nutrition_goals.dart';
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
  })  : _firestore = firestore,
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
      // The result type is a single ConnectivityResult, not a list
      if (result != ConnectivityResult.none) {
        syncOfflineData();
      }
    });
  }

  /// Synchronizes cached offline data with Firestore when internet connection is restored
  Future<void> syncOfflineData() async {
    try {
      if (await _isConnected()) {
        // Sync unsynchronized entries
        final unsyncedEntries = _entriesBox.keys
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

        // Sync unsynchronized goals
        final unsyncedGoals = _goalsBox.keys
            .where(
              (key) => key.toString().startsWith('${_goalsPrefix}unsynced_'),
            )
            .toList();

        for (final key in unsyncedGoals) {
          final Map? goalsMap = _goalsBox.get(key);
          if (goalsMap != null) {
            final goals = NutritionGoals.fromMap(
              Map<String, dynamic>.from(goalsMap),
            );
            await _getUserGoalsDoc(goals.userId).set(goals.toMap());

            // Delete the unsynced goals and store as synced
            await _goalsBox.delete(key);
            await _goalsBox.put('$_goalsPrefix${goals.userId}', goals.toMap());
          }
        }

        // Update local summaries with server data
        final summaryKeys = _summariesBox.keys.toList();
        for (final key in summaryKeys) {
          final keyStr = key.toString();
          if (keyStr.startsWith(_dailySummaryPrefix)) {
            final summaryId = keyStr.substring(_dailySummaryPrefix.length);
            final userId = summaryId.split('-')[0];
            final doc = await _getUserSummaryDoc(userId, summaryId).get();
            if (doc.exists) {
              final data = doc.data() as Map<String, dynamic>;
              await _summariesBox.put(key, data);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error syncing offline data: $e');
    }
  }

  Future<bool> _isConnected() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // Helper method to ensure date keys are formatted consistently with two-digit months and days
  String _formatDateKey(DateTime date) {
    // Format as YYYY-MM-DD with leading zeros for month and day
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  @override
  Future<NutritionEntry> addEntry(NutritionEntry entry) async {
    try {
      debugPrint(
          'NUTRITION REPO: Adding entry: ${entry.name} for user: ${entry.userId}');

      // Add a dateKey field to help with queries
      final date = DateTime(
        entry.consumedAt.year,
        entry.consumedAt.month,
        entry.consumedAt.day,
      );
      final dateKey = _formatDateKey(date);

      // Create an entry map with the dateKey added
      final entryMap = entry.toMap();
      entryMap['dateKey'] = dateKey;

      final isConnected = await _isConnected();

      if (isConnected) {
        // 1. Create the users collection and document if it doesn't exist
        final userDocRef = _firestore.collection('users').doc(entry.userId);
        await userDocRef.set({
          'lastActive': DateTime.now().millisecondsSinceEpoch,
          'hasNutritionData': true,
        }, SetOptions(merge: true));

        // 2. Save entry to Firestore
        debugPrint(
            'NUTRITION REPO: Saving entry to Firestore: ${_getUserEntryDoc(entry.userId, entry.id).path}');
        await _getUserEntryDoc(entry.userId, entry.id).set(entryMap);

        // 3. Store in local cache
        await _entriesBox.put('$_entryPrefix${entry.id}', entryMap);

        // 4. Make sure nutrition goals exist
        await getNutritionGoals(entry.userId);

        // 5. Update the summary document
        final summaryId = '${entry.userId}-$dateKey';
        final summaryDocRef = _getUserSummaryDoc(entry.userId, summaryId);

        // Check if summary document exists
        final summaryDoc = await summaryDocRef.get();
        if (!summaryDoc.exists) {
          debugPrint(
              'NUTRITION REPO: Creating new summary document for date: $dateKey');
          // If it doesn't exist, calculate a new summary
          await _calculateDailySummary(entry.userId, date);
        } else {
          // If it exists, update it with the new entry
          debugPrint(
              'NUTRITION REPO: Updating existing summary document for date: $dateKey');
          await _updateDailySummaryAfterEntryChange(entry);
        }
      } else {
        // Store as unsynced in local cache
        await _entriesBox.put(
          '${_entryPrefix}unsynced_${entry.id}',
          entryMap,
        );

        // Try to update the summary in local cache
        await _updateDailySummaryAfterEntryChange(entry);
      }

      debugPrint('NUTRITION REPO: Entry added successfully: ${entry.id}');
      return entry;
    } catch (e) {
      debugPrint('NUTRITION REPO: Error adding nutrition entry: $e');
      rethrow;
    }
  }

  Future<void> _saveEntryToFirestore(NutritionEntry entry) async {
    await _getUserEntryDoc(entry.userId, entry.id).set(entry.toMap());
  }

  @override
  Future<NutritionEntry> updateEntry(NutritionEntry entry) async {
    try {
      debugPrint(
          'NUTRITION REPO: Updating entry: ${entry.name} for user: ${entry.userId}');

      // Ensure dateKey field is present
      final date = DateTime(
        entry.consumedAt.year,
        entry.consumedAt.month,
        entry.consumedAt.day,
      );
      final dateKey = _formatDateKey(date);

      final entryMap = entry.toMap();
      entryMap['dateKey'] = dateKey;

      final isConnected = await _isConnected();

      if (isConnected) {
        // Ensure user document exists
        final userDocRef = _firestore.collection('users').doc(entry.userId);
        await userDocRef.set({
          'lastActive': DateTime.now().millisecondsSinceEpoch,
          'hasNutritionData': true,
        }, SetOptions(merge: true));

        // Check if entry exists
        final entryDocRef = _getUserEntryDoc(entry.userId, entry.id);
        final entryDoc = await entryDocRef.get();

        if (!entryDoc.exists) {
          // Create entry if it doesn't exist
          debugPrint(
              'NUTRITION REPO: Entry does not exist, creating new entry: ${entry.id}');
          await entryDocRef.set(entryMap);
        } else {
          // Update existing entry
          debugPrint('NUTRITION REPO: Updating existing entry: ${entry.id}');
          await entryDocRef.update(entryMap);
        }

        // Update local cache
        await _entriesBox.put('$_entryPrefix${entry.id}', entryMap);

        // Update summary
        final summaryId = '${entry.userId}-$dateKey';
        final summaryDocRef = _getUserSummaryDoc(entry.userId, summaryId);

        final summaryDoc = await summaryDocRef.get();
        if (!summaryDoc.exists) {
          // Create summary if it doesn't exist
          debugPrint(
              'NUTRITION REPO: Summary does not exist, calculating new summary');
          await _calculateDailySummary(entry.userId, date);
        } else {
          // Update existing summary
          debugPrint(
              'NUTRITION REPO: Updating existing summary with entry changes');
          await _updateDailySummaryAfterEntryChange(entry);
        }
      } else {
        // Store as unsynced in local cache
        await _entriesBox.put(
          '${_entryPrefix}unsynced_${entry.id}',
          entryMap,
        );

        // Try to update local summary
        await _updateDailySummaryAfterEntryChange(entry);
      }

      debugPrint('NUTRITION REPO: Entry updated successfully: ${entry.id}');
      return entry;
    } catch (e) {
      debugPrint('NUTRITION REPO: Error updating nutrition entry: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteEntry(String entryId) async {
    try {
      debugPrint('NUTRITION REPO: Deleting entry: $entryId');

      // Get the entry first to update summary after deletion
      final entry = await getEntryById(entryId);
      if (entry == null) {
        debugPrint('NUTRITION REPO: Entry not found, nothing to delete');
        return;
      }

      final date = DateTime(
        entry.consumedAt.year,
        entry.consumedAt.month,
        entry.consumedAt.day,
      );
      final dateKey = _formatDateKey(date);
      final userId = entry.userId;

      final isConnected = await _isConnected();

      if (isConnected) {
        // Delete from Firestore
        await _getUserEntryDoc(userId, entryId).delete();
        debugPrint('NUTRITION REPO: Entry deleted from Firestore');

        // Update summary document
        final summaryId = '$userId-$dateKey';
        final summaryDocRef = _getUserSummaryDoc(userId, summaryId);

        final summaryDoc = await summaryDocRef.get();
        if (summaryDoc.exists) {
          debugPrint('NUTRITION REPO: Updating summary after deletion');
          await _updateDailySummaryAfterEntryChange(entry, isDelete: true);
        }
      }

      // Remove from local cache
      await _entriesBox.delete('$_entryPrefix$entryId');
      await _entriesBox.delete('${_entryPrefix}unsynced_$entryId');
      debugPrint('NUTRITION REPO: Entry removed from local cache');

      if (!isConnected) {
        // If offline, still try to update the local summary
        await _updateDailySummaryAfterEntryChange(entry, isDelete: true);
      }

      debugPrint('NUTRITION REPO: Entry deleted successfully');
    } catch (e) {
      debugPrint('NUTRITION REPO: Error deleting nutrition entry: $e');
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
        final querySnapshot = await _getUserEntriesQuery(userId)
            .where('consumedAt',
                isGreaterThanOrEqualTo: startOfDay.millisecondsSinceEpoch)
            .where('consumedAt', isLessThan: endOfDay.millisecondsSinceEpoch)
            .get();

        entries = querySnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return NutritionEntry.fromMap(data);
        }).toList();

        // Update local cache
        for (final entry in entries) {
          await _entriesBox.put('$_entryPrefix${entry.id}', entry.toMap());
        }
      } else {
        // Fetch from local cache
        final localEntries = _entriesBox.values
            .map(
              (map) => NutritionEntry.fromMap(Map<String, dynamic>.from(map)),
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

  Future<NutritionEntry?> getEntryById(String entryId) async {
    try {
      // Try local cache first
      final cachedData = _entriesBox.get('$_entryPrefix$entryId') ??
          _entriesBox.get('${_entryPrefix}unsynced_$entryId');

      if (cachedData != null) {
        return NutritionEntry.fromMap(Map<String, dynamic>.from(cachedData));
      }

      // If not in cache and connected, try Firestore
      final isConnected = await _isConnected();
      if (isConnected) {
        // Extract userId from entryId if possible, or use a default
        final userId =
            entryId.contains('_') ? entryId.split('_').first : 'unknown';

        final doc = await _getUserEntryDoc(userId, entryId).get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final entry = NutritionEntry.fromMap(data);
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
    debugPrint(
        'NUTRITION REPO: Getting daily summary for user: $userId on date: $date');
    try {
      final dateKey = _formatDateKey(date);
      final summaryId = '$userId-$dateKey';

      // Try local cache first
      final cachedData = _summariesBox.get('$_dailySummaryPrefix$summaryId');

      if (cachedData != null) {
        debugPrint('NUTRITION REPO: Found summary in local cache');
        return DailyNutritionSummary.fromMap(
          Map<String, dynamic>.from(cachedData),
        );
      }

      // If not in cache, try Firestore if connected
      final isConnected = await _isConnected();
      debugPrint('NUTRITION REPO: Connected to network: $isConnected');
      if (isConnected) {
        final docRef = _getUserSummaryDoc(userId, summaryId);
        debugPrint(
            'NUTRITION REPO: Checking Firestore document at path: ${docRef.path}');
        final doc = await docRef.get();

        if (doc.exists) {
          debugPrint('NUTRITION REPO: Found summary in Firestore');
          final data = doc.data() as Map<String, dynamic>;
          final summary = DailyNutritionSummary.fromMap(data);
          // Update cache
          await _summariesBox.put(
            '$_dailySummaryPrefix$summaryId',
            summary.toMap(),
          );
          return summary;
        } else {
          debugPrint('NUTRITION REPO: Summary not found in Firestore');
        }
      }

      // If neither cache nor Firestore has the summary, calculate it from entries
      debugPrint('NUTRITION REPO: Calculating summary from entries');
      return _calculateDailySummary(userId, date);
    } catch (e) {
      debugPrint('NUTRITION REPO: Error getting daily summary: $e');
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

  Future<void> _saveSummaryToFirestore(
    String userId,
    DailyNutritionSummary summary,
  ) async {
    final dateKey = _formatDateKey(summary.date);
    final summaryId = '$userId-$dateKey';
    await _getUserSummaryDoc(userId, summaryId).set(summary.toMap());
  }

  Future<DailyNutritionSummary> _calculateDailySummary(
    String userId,
    DateTime date,
  ) async {
    try {
      final entries = await getEntriesForDate(userId, date);
      final goals = await getNutritionGoals(userId);

      int totalCalories = 0;
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;

      // Try to get existing water intake from current summary
      int waterIntake = 0;
      try {
        final dateKey = _formatDateKey(date);
        final summaryId = '$userId-$dateKey';
        final cachedData = _summariesBox.get('$_dailySummaryPrefix$summaryId');

        if (cachedData != null) {
          final existingSummary = DailyNutritionSummary.fromMap(
            Map<String, dynamic>.from(cachedData),
          );
          waterIntake = existingSummary.waterIntake;
          debugPrint(
              'NUTRITION REPO: Preserving existing water intake: $waterIntake ml');
        } else if (await _isConnected()) {
          final doc = await _getUserSummaryDoc(userId, summaryId).get();
          if (doc.exists && doc.data() != null) {
            final data = doc.data() as Map<String, dynamic>;
            final existingSummary = DailyNutritionSummary.fromMap(data);
            waterIntake = existingSummary.waterIntake;
            debugPrint(
                'NUTRITION REPO: Found water intake from Firestore: $waterIntake ml');
          }
        }
      } catch (e) {
        debugPrint('NUTRITION REPO: Error getting existing water intake: $e');
      }

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
        waterIntake: waterIntake, // Use preserved water intake value
        waterGoal: goals.waterGoal,
        entryCount: entries.length,
      );

      // Save to local cache
      final dateKey = _formatDateKey(date);
      final summaryId = '$userId-$dateKey';
      await _summariesBox.put(
        '$_dailySummaryPrefix$summaryId',
        summary.toMap(),
      );

      // If connected, save to Firestore
      final isConnected = await _isConnected();
      if (isConnected) {
        await _saveSummaryToFirestore(userId, summary);
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
      for (var date = startDate;
          date.isBefore(endDate.add(const Duration(days: 1)));
          date = date.add(const Duration(days: 1))) {
        final summary = await getDailySummary(userId, date);
        summaries.add(summary);
      }

      return summaries;
    } catch (e) {
      debugPrint('Error getting daily summaries for range: $e');
      return [];
    }
  }

  Future<NutritionGoals> getUserNutritionGoals(String userId) async {
    try {
      // Try local cache first
      final cachedData = _goalsBox.get('$_goalsPrefix$userId') ??
          _goalsBox.get('${_goalsPrefix}unsynced_$userId');

      if (cachedData != null) {
        return NutritionGoals.fromMap(Map<String, dynamic>.from(cachedData));
      }

      // If not in cache and connected, try Firestore
      final isConnected = await _isConnected();
      if (isConnected) {
        final doc = await _firestore
            .collection('users')
            .doc(userId)
            .collection(_goalsCollection)
            .doc(userId)
            .get();

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
  Future<void> saveNutritionGoals(NutritionGoals goals) async {
    try {
      final isConnected = await _isConnected();

      if (isConnected) {
        // Ensure user document exists
        final userDocRef = _firestore.collection('users').doc(goals.userId);
        await userDocRef.set({
          'lastActive': DateTime.now().millisecondsSinceEpoch,
          'hasNutritionData': true,
        }, SetOptions(merge: true));

        // Save nutrition goals
        await _getUserGoalsDoc(goals.userId).set(goals.toMap());
      }

      // Update local cache regardless of connection
      await _goalsBox.put('$_goalsPrefix${goals.userId}', goals.toMap());

      // Update all summaries for today with new goals
      try {
        final today = DateTime.now();
        final normalizedDate = DateTime(today.year, today.month, today.day);
        // dateKey not used directly since we pass normalizedDate to getDailySummary
        // final dateKey = _formatDateKey(normalizedDate);

        // Check if summary exists for today
        final summary = await getDailySummary(goals.userId, normalizedDate);

        // Create an updated summary with new goals
        final updatedSummary = DailyNutritionSummary(
          date: summary.date,
          totalCalories: summary.totalCalories,
          totalProtein: summary.totalProtein,
          totalCarbs: summary.totalCarbs,
          totalFat: summary.totalFat,
          calorieGoal: goals.calorieGoal,
          proteinGoal: goals.proteinGoal,
          carbsGoal: goals.carbsGoal,
          fatGoal: goals.fatGoal,
          waterIntake: summary.waterIntake,
          waterGoal: goals.waterGoal,
          entryCount: summary.entryCount,
        );

        // Save updated summary
        await _saveSummary(goals.userId, updatedSummary);
      } catch (e) {
        // Ignore errors updating summary
        debugPrint(
            'Warning: Could not update today\'s summary with new goals: $e');
      }
    } catch (e) {
      debugPrint('Error saving nutrition goals: $e');
      rethrow;
    }
  }

  @override
  Future<int> getWaterIntake(String userId, DateTime date) async {
    debugPrint(
        'NUTRITION REPO: Getting water intake for user: $userId on date: $date');
    try {
      final summary = await getDailySummary(userId, date);
      debugPrint(
          'NUTRITION REPO: Water intake from summary: ${summary.waterIntake} ml');
      return summary.waterIntake;
    } catch (e) {
      debugPrint('NUTRITION REPO: Error getting water intake: $e');
      return 0;
    }
  }

  @override
  Future<void> logWaterIntake(
    String userId,
    DateTime date,
    int amount,
  ) async {
    try {
      // Normalize the date
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final dateKey = _formatDateKey(normalizedDate);
      final summaryId = '$userId-$dateKey';

      // First, get the current summary
      DailyNutritionSummary summary;
      try {
        summary = await getDailySummary(userId, normalizedDate);
      } catch (e) {
        // If there's an error getting the summary, create a new one
        final goals = await getNutritionGoals(userId);
        summary = DailyNutritionSummary(
          date: normalizedDate,
          calorieGoal: goals.calorieGoal,
          proteinGoal: goals.proteinGoal,
          carbsGoal: goals.carbsGoal,
          fatGoal: goals.fatGoal,
          waterGoal: goals.waterGoal,
        );
      }

      // Create an updated summary with new water intake
      final updatedSummary = DailyNutritionSummary(
        date: summary.date,
        totalCalories: summary.totalCalories,
        totalProtein: summary.totalProtein,
        totalCarbs: summary.totalCarbs,
        totalFat: summary.totalFat,
        calorieGoal: summary.calorieGoal,
        proteinGoal: summary.proteinGoal,
        carbsGoal: summary.carbsGoal,
        fatGoal: summary.fatGoal,
        waterIntake: summary.waterIntake + amount,
        waterGoal: summary.waterGoal,
        entryCount: summary.entryCount,
      );

      // Save to local cache
      await _summariesBox.put(
        '$_dailySummaryPrefix$summaryId',
        updatedSummary.toMap(),
      );

      // If connected, save to Firestore
      final isConnected = await _isConnected();
      if (isConnected) {
        // Ensure user document exists
        final userDocRef = _firestore.collection('users').doc(userId);
        await userDocRef.set({
          'lastActive': DateTime.now().millisecondsSinceEpoch,
          'hasNutritionData': true,
        }, SetOptions(merge: true));

        // Update the summary document
        await _getUserSummaryDoc(userId, summaryId).set(updatedSummary.toMap());
      }

      debugPrint(
          'NUTRITION REPO: Water intake logged: $amount ml, total: ${updatedSummary.waterIntake} ml');
    } catch (e) {
      debugPrint('NUTRITION REPO: Error logging water intake: $e');
      rethrow;
    }
  }

  // Helper to save a summary to both cache and Firestore if connected
  Future<void> _saveSummary(
      String userId, DailyNutritionSummary summary) async {
    try {
      // Save to local cache
      final dateKey = _formatDateKey(summary.date);
      final summaryId = '$userId-$dateKey';
      await _summariesBox.put(
        '$_dailySummaryPrefix$summaryId',
        summary.toMap(),
      );

      // If connected, update Firestore
      final isConnected = await _isConnected();
      if (isConnected) {
        await _saveSummaryToFirestore(userId, summary);
      }
    } catch (e) {
      debugPrint('NUTRITION REPO: Error saving summary: $e');
      rethrow;
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
        final querySnapshot = await _getUserEntriesQuery(userId)
            .where('consumedAt',
                isGreaterThanOrEqualTo: startOfRange.millisecondsSinceEpoch)
            .where('consumedAt', isLessThan: endOfRange.millisecondsSinceEpoch)
            .get();

        entries = querySnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return NutritionEntry.fromMap(data);
        }).toList();

        // Update local cache
        for (final entry in entries) {
          await _entriesBox.put('$_entryPrefix${entry.id}', entry.toMap());
        }
      } else {
        // Fetch from local cache
        final localEntries = _entriesBox.values
            .map(
              (map) => NutritionEntry.fromMap(Map<String, dynamic>.from(map)),
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
        final doc = await _getUserGoalsDoc(userId).get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data() as Map<String, dynamic>;
          final goals = NutritionGoals.fromMap(data);

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
        waterGoal: 2500,
      );

      // Save default goals to both cache and Firestore if connected
      await _goalsBox.put('$_goalsPrefix$userId', defaultGoals.toMap());

      if (isConnected) {
        await _getUserGoalsDoc(userId).set(defaultGoals.toMap());
      }

      return defaultGoals;
    } catch (e) {
      debugPrint('Error getting nutrition goals: $e');

      // Return default goals in case of error
      return NutritionGoals(
        userId: userId,
        calorieGoal: 2000,
        proteinGoal: 125.0,
        carbsGoal: 250.0,
        fatGoal: 55.0,
        waterGoal: 2500,
      );
    }
  }

  /// Dispose of any resources
  void dispose() {
    _connectivitySubscription?.cancel();
  }

  /// Gets a reference to a user's nutrition entry
  DocumentReference _getUserEntryDoc(String userId, String entryId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection(_entriesCollection)
        .doc(entryId);
  }

  /// Gets a reference to a user's nutrition summary
  DocumentReference _getUserSummaryDoc(String userId, String summaryId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection(_summariesCollection)
        .doc(summaryId);
  }

  /// Gets a reference to a user's nutrition goals
  DocumentReference _getUserGoalsDoc(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection(_goalsCollection)
        .doc(userId);
  }

  /// Gets a query reference to a user's nutrition entries
  Query _getUserEntriesQuery(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection(_entriesCollection);
  }

  /// Gets a query reference to a user's nutrition summaries
  // Keeping this method for future use but commenting it out since it's currently unused
  // Query _getUserSummariesQuery(String userId) {
  //   return _firestore
  //       .collection('users')
  //       .doc(userId)
  //       .collection(_summariesCollection);
  // }

  @override
  Stream<DailyNutritionSummary> getDailySummaryStream(
      String userId, DateTime date) {
    debugPrint(
        'NUTRITION REPO: Setting up stream for daily summary - user: $userId, date: $date');

    try {
      final dateKey = _formatDateKey(date);
      debugPrint('NUTRITION REPO: Using dateKey: $dateKey for summary');
      final summaryId = '$userId-$dateKey';

      // First, set up a stream for the summary document
      final summaryStream =
          _getUserSummaryDoc(userId, summaryId).snapshots().map((snapshot) {
        debugPrint('NUTRITION STREAM: Summary document updated');
        if (snapshot.exists && snapshot.data() != null) {
          try {
            final data = snapshot.data() as Map<String, dynamic>;
            return DailyNutritionSummary.fromMap(data);
          } catch (e) {
            debugPrint('NUTRITION STREAM: Error parsing summary: $e');
            return null;
          }
        } else {
          debugPrint('NUTRITION STREAM: Summary does not exist yet');
          return null;
        }
      });

      // Also listen to entries for this day to calculate a summary if needed
      final entriesStream = _getUserEntriesQuery(userId)
          .where('dateKey', isEqualTo: dateKey)
          .snapshots()
          .map((snapshot) {
        debugPrint(
            'NUTRITION STREAM: Entries updated, count: ${snapshot.docs.length}');
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return NutritionEntry.fromMap(data);
        }).toList();
      });

      // First try to use any existing valid summary
      final existingSummaryStream = summaryStream
          .where((summary) => summary != null)
          .map((summary) => summary!)
          .asBroadcastStream();

      // If no summary exists, calculate it from entries
      final calculatedSummaryStream = entriesStream
          .asyncMap(
              (entries) => _calculateSummaryFromEntries(userId, date, entries))
          .asBroadcastStream();

      // Merge both streams, preferring existing summaries when available
      return MergeStream([existingSummaryStream, calculatedSummaryStream]);
    } catch (e) {
      debugPrint('NUTRITION REPO: Error setting up daily summary stream: $e');
      // Return a default summary in case of error
      return Stream.value(DailyNutritionSummary(
        date: date,
        calorieGoal: 2000,
        proteinGoal: 150,
        carbsGoal: 250,
        fatGoal: 70,
        waterGoal: 2000,
      ));
    }
  }

  // Helper to calculate a summary from entries
  Future<DailyNutritionSummary> _calculateSummaryFromEntries(
      String userId, DateTime date, List<NutritionEntry> entries) async {
    debugPrint(
        'NUTRITION STREAM: Calculating summary from ${entries.length} entries');

    // Get the user's goals
    NutritionGoals goals;
    try {
      goals = await getUserNutritionGoals(userId);
    } catch (e) {
      debugPrint('NUTRITION STREAM: Error getting goals: $e');
      // Use default goals if there's an error
      goals = NutritionGoals(
        userId: userId,
        calorieGoal: 2000,
        proteinGoal: 150,
        carbsGoal: 250,
        fatGoal: 70,
        waterGoal: 2000,
      );
    }

    // Calculate summary values
    int totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    // Try to get existing water intake from current summary
    int waterIntake = 0;
    try {
      final dateKey = _formatDateKey(date);
      final summaryId = '$userId-$dateKey';
      final cachedData = _summariesBox.get('$_dailySummaryPrefix$summaryId');

      if (cachedData != null) {
        final existingSummary = DailyNutritionSummary.fromMap(
          Map<String, dynamic>.from(cachedData),
        );
        waterIntake = existingSummary.waterIntake;
        debugPrint(
            'NUTRITION STREAM: Preserving existing water intake: $waterIntake ml');
      } else if (await _isConnected()) {
        final doc = await _getUserSummaryDoc(userId, summaryId).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data() as Map<String, dynamic>;
          final existingSummary = DailyNutritionSummary.fromMap(data);
          waterIntake = existingSummary.waterIntake;
          debugPrint(
              'NUTRITION STREAM: Found water intake from Firestore: $waterIntake ml');
        }
      }
    } catch (e) {
      debugPrint('NUTRITION STREAM: Error getting existing water intake: $e');
    }

    for (final entry in entries) {
      totalCalories += entry.calories;
      totalProtein += entry.protein;
      totalCarbs += entry.carbs;
      totalFat += entry.fat;
    }

    // Create a new summary
    final calculatedSummary = DailyNutritionSummary(
      date: date,
      totalCalories: totalCalories,
      totalProtein: totalProtein,
      totalCarbs: totalCarbs,
      totalFat: totalFat,
      waterIntake: waterIntake, // Use preserved water intake value
      calorieGoal: goals.calorieGoal,
      proteinGoal: goals.proteinGoal,
      carbsGoal: goals.carbsGoal,
      fatGoal: goals.fatGoal,
      waterGoal: goals.waterGoal,
      entryCount: entries.length,
    );

    // Save this calculated summary to cache and Firestore
    _saveSummary(userId, calculatedSummary).catchError((e) {
      debugPrint('NUTRITION STREAM: Error saving calculated summary: $e');
    });

    return calculatedSummary;
  }

  @override
  Stream<List<NutritionEntry>> getEntriesForDateStream(
      String userId, DateTime date) {
    debugPrint(
        'NUTRITION REPO: Setting up stream for entries - user: $userId, date: $date');
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      // Note: We're using dateKey-based query rather than timestamp range
      // final endOfDay = startOfDay.add(const Duration(days: 1));
      final dateKey = _formatDateKey(startOfDay);

      debugPrint('NUTRITION REPO: Using dateKey: $dateKey for query');

      // Try first with dateKey which is more reliable
      return _getUserEntriesQuery(userId)
          .where('dateKey', isEqualTo: dateKey)
          .orderBy('consumedAt', descending: true)
          .snapshots()
          .map((snapshot) {
        debugPrint(
            'NUTRITION STREAM: Entries updated (stream), count: ${snapshot.docs.length}');
        final entries = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return NutritionEntry.fromMap(data);
        }).toList();
        // Update local cache asynchronously
        _updateEntriesCache(entries);
        return entries;
      });
    } catch (e) {
      debugPrint('NUTRITION REPO: Error setting up entries stream: $e');
      return Stream.value([]); // Return empty list on error
    }
  }

  // Helper to update local cache with fetched entries
  Future<void> _updateEntriesCache(List<NutritionEntry> entries) async {
    for (final entry in entries) {
      await _entriesBox.put('$_entryPrefix${entry.id}', entry.toMap());
    }
  }
}
