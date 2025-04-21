import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../domain/models/onboarding_badge.dart';
import '../domain/models/onboarding_progress.dart';
import '../domain/models/onboarding_step.dart';
import '../domain/repositories/onboarding_repository.dart';

/// Local implementation of the [OnboardingRepository] for storing onboarding data
class LocalOnboardingRepository implements OnboardingRepository {
  // Storage keys
  static const String _onboardingBox = 'onboarding';
  static const String _progressKey = 'progress';
  static const String _completedKey = 'completed';
  static const String _badgesKey = 'badges';

  /// Constructor
  LocalOnboardingRepository();

  @override
  Future<List<OnboardingStep>> getOnboardingSteps() async {
    // Return predefined onboarding steps
    return [
      const OnboardingStep(
        id: 'welcome',
        title: 'Welcome to FitFlow',
        description:
            'Your personalized fitness companion for tracking workouts, nutrition, and health data.',
        order: 1,
        pointsValue: 10,
      ),
      const OnboardingStep(
        id: 'profile_setup',
        title: 'Create Your Profile',
        description:
            'Set up your profile with basic information to get personalized recommendations.',
        order: 2,
        pointsValue: 20,
      ),
      const OnboardingStep(
        id: 'goal_setting',
        title: 'Set Your Goals',
        description:
            'Define your fitness goals to help us customize your experience.',
        order: 3,
        pointsValue: 30,
      ),
      const OnboardingStep(
        id: 'feature_tour',
        title: 'Explore Features',
        description:
            'Discover the key features that will help you on your fitness journey.',
        order: 4,
        pointsValue: 20,
      ),
      const OnboardingStep(
        id: 'permissions',
        title: 'App Permissions',
        description:
            'Grant necessary permissions for the best experience with health tracking.',
        order: 5,
        pointsValue: 20,
      ),
      const OnboardingStep(
        id: 'completion',
        title: 'Ready to Go!',
        description:
            'Your account is set up and you\'re ready to start your fitness journey!',
        order: 6,
        pointsValue: 50,
      ),
    ];
  }

  @override
  Future<List<OnboardingBadge>> getAvailableBadges() async {
    // Return predefined badges
    return [
      OnboardingBadge(
        id: 'welcome_explorer',
        name: 'Welcome Explorer',
        description: 'Completed the app introduction',
        imagePath: 'assets/badges/welcome_explorer.png',
        pointsValue: 10,
        tier: 1,
      ),
      OnboardingBadge(
        id: 'profile_pioneer',
        name: 'Profile Pioneer',
        description: 'Set up your fitness profile',
        imagePath: 'assets/badges/profile_pioneer.png',
        pointsValue: 20,
        tier: 1,
      ),
      OnboardingBadge(
        id: 'goal_setter',
        name: 'Goal Setter',
        description: 'Defined your fitness goals',
        imagePath: 'assets/badges/goal_setter.png',
        pointsValue: 30,
        tier: 2,
      ),
      OnboardingBadge(
        id: 'feature_explorer',
        name: 'Feature Explorer',
        description: 'Explored the app\'s key features',
        imagePath: 'assets/badges/feature_explorer.png',
        pointsValue: 20,
        tier: 1,
      ),
      OnboardingBadge(
        id: 'permission_grantor',
        name: 'Permission Grantor',
        description: 'Enabled necessary app permissions',
        imagePath: 'assets/badges/permission_grantor.png',
        pointsValue: 20,
        tier: 1,
      ),
      OnboardingBadge(
        id: 'journey_beginner',
        name: 'Journey Beginner',
        description: 'Completed the entire onboarding process',
        imagePath: 'assets/badges/journey_beginner.png',
        pointsValue: 50,
        tier: 3,
      ),
    ];
  }

  @override
  Future<OnboardingProgress?> getOnboardingProgress() async {
    try {
      final box = await Hive.openBox<dynamic>(_onboardingBox);
      final Map<dynamic, dynamic>? progressData = box.get(_progressKey);

      if (progressData == null) {
        // Initialize with first step if no progress exists
        final steps = await getOnboardingSteps();

        if (steps.isNotEmpty) {
          final initialProgress = OnboardingProgress.initial(
            initialStepId: steps.first.id,
            totalSteps: steps.length,
          );

          // Save initial progress
          await saveOnboardingProgress(initialProgress);

          return initialProgress;
        }
        return null;
      }

      // Create a progress object from saved data
      try {
        final currentStepId =
            progressData['currentStepId'] as String? ?? 'welcome';
        final List<dynamic> completedStepIds =
            progressData['completedStepIds'] ?? [];
        final completedStepsCount =
            progressData['completedStepsCount'] as int? ?? 0;
        final totalStepsCount = progressData['totalStepsCount'] as int? ?? 6;
        final isComplete = progressData['isComplete'] as bool? ?? false;
        final totalPoints = progressData['totalPoints'] as int? ?? 0;
        final startedAt = progressData['startedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                progressData['startedAt'] as int)
            : DateTime.now();
        final completedAt = progressData['completedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                progressData['completedAt'] as int)
            : null;

        return OnboardingProgress(
          currentStepId: currentStepId,
          completedStepIds: List<String>.from(completedStepIds),
          completedStepsCount: completedStepsCount,
          totalStepsCount: totalStepsCount,
          isComplete: isComplete,
          earnedBadges: [], // For now, simplify by using empty list
          totalPoints: totalPoints,
          startedAt: startedAt,
          completedAt: completedAt,
        );
      } catch (e) {
        debugPrint('Error parsing saved progress: $e');
        // Fall back to fresh progress if parsing fails
        final steps = await getOnboardingSteps();
        return OnboardingProgress.initial(
          initialStepId: steps.first.id,
          totalSteps: steps.length,
        );
      }
    } catch (e) {
      debugPrint('Error getting onboarding progress: $e');
      return null;
    }
  }

  @override
  Future<void> saveOnboardingProgress(OnboardingProgress progress) async {
    try {
      final box = await Hive.openBox<dynamic>(_onboardingBox);

      // Extract badge IDs from badge objects
      final List<String> earnedBadgeIds =
          progress.earnedBadges.map((badge) => badge.id).toList();

      // Convert progress to a storable format
      Map<String, dynamic> progressData = {
        'currentStepId': progress.currentStepId,
        'completedStepIds': progress.completedStepIds,
        'completedStepsCount': progress.completedStepsCount,
        'totalStepsCount': progress.totalStepsCount,
        'isComplete': progress.isComplete,
        'totalPoints': progress.totalPoints,
        'startedAt': progress.startedAt.millisecondsSinceEpoch,
        'completedAt': progress.completedAt?.millisecondsSinceEpoch,
        'earnedBadgeIds': earnedBadgeIds,
      };

      await box.put(_progressKey, progressData);
      debugPrint(
          'Saved onboarding progress: step=${progress.currentStepId}, completed=${progress.completedStepsCount}/${progress.totalStepsCount}');
    } catch (e) {
      debugPrint('Error saving onboarding progress: $e');
    }
  }

  @override
  Future<void> unlockBadge(String badgeId) async {
    try {
      // Get current progress
      final progress = await getOnboardingProgress();
      if (progress == null) return;

      // Get badge to unlock
      final badges = await getAvailableBadges();
      final badge = badges.firstWhere(
        (b) => b.id == badgeId,
        orElse: () => throw Exception('Badge not found'),
      );

      // Get next step
      final steps = await getOnboardingSteps();
      final nextStep = steps.firstWhere(
        (s) => s.id == progress.currentStepId,
        orElse: () => steps.first,
      );

      // Update progress with new badge
      final updatedProgress = progress.completeStep(
        stepId: progress.currentStepId,
        nextStepId: nextStep.id,
        earnedBadge: badge,
      );

      // Save updated progress
      await saveOnboardingProgress(updatedProgress);
    } catch (e) {
      debugPrint('Error unlocking badge: $e');
    }
  }

  @override
  Future<bool> isOnboardingCompleted() async {
    try {
      final box = await Hive.openBox<dynamic>(_onboardingBox);
      return box.get(_completedKey, defaultValue: false) as bool;
    } catch (e) {
      debugPrint('Error checking onboarding completion: $e');
      return false;
    }
  }

  @override
  Future<void> completeOnboarding() async {
    try {
      final box = await Hive.openBox<dynamic>(_onboardingBox);
      await box.put(_completedKey, true);
    } catch (e) {
      debugPrint('Error completing onboarding: $e');
    }
  }

  @override
  Future<void> resetOnboarding() async {
    try {
      final box = await Hive.openBox<dynamic>(_onboardingBox);
      await box.put(_completedKey, false);

      // Also reset progress
      await box.delete(_progressKey);
    } catch (e) {
      debugPrint('Error resetting onboarding: $e');
    }
  }
}
