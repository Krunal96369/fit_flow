import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/local_storage_service.dart';
import '../data/local_onboarding_repository.dart';
import '../domain/models/onboarding_badge.dart';
import '../domain/models/onboarding_progress.dart';
import '../domain/models/onboarding_step.dart';
import '../domain/repositories/onboarding_repository.dart';

// Provider for the onboarding repository
final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return LocalOnboardingRepository();
});

// Provider for onboarding steps
final onboardingStepsProvider = FutureProvider<List<OnboardingStep>>((ref) {
  final repository = ref.watch(onboardingRepositoryProvider);
  return repository.getOnboardingSteps();
});

// Provider for available badges
final onboardingBadgesProvider = FutureProvider<List<OnboardingBadge>>((ref) {
  final repository = ref.watch(onboardingRepositoryProvider);
  return repository.getAvailableBadges();
});

// Provider for onboarding progress
final onboardingProgressProvider = FutureProvider<OnboardingProgress?>((ref) {
  final repository = ref.watch(onboardingRepositoryProvider);
  return repository.getOnboardingProgress();
});

// Provider for whether onboarding is completed
final onboardingCompletedProvider =
    StateNotifierProvider<OnboardingCompletedNotifier, bool>((ref) {
  final localStorageService = ref.watch(localStorageServiceProvider);
  final repository = ref.watch(onboardingRepositoryProvider);
  return OnboardingCompletedNotifier(localStorageService, repository);
});

// Provider for the current step index
final currentStepIndexProvider = StateProvider<int>((ref) => 0);

// Main onboarding controller provider
final onboardingControllerProvider = StateNotifierProvider<OnboardingController,
    AsyncValue<OnboardingProgress?>>(
  (ref) {
    final repository = ref.watch(onboardingRepositoryProvider);
    return OnboardingController(repository, ref);
  },
);

// Notifier for onboarding completion status
class OnboardingCompletedNotifier extends StateNotifier<bool> {
  final LocalStorageService _localStorageService;
  final OnboardingRepository _repository;
  static const String _onboardingKey = 'onboarding_completed';

  OnboardingCompletedNotifier(this._localStorageService, this._repository)
      : super(false) {
    _loadOnboardingStatus();
  }

  Future<void> _loadOnboardingStatus() async {
    final completed = await _repository.isOnboardingCompleted();
    state = completed;
  }

  Future<void> completeOnboarding() async {
    state = true;
    await _repository.completeOnboarding();
  }

  Future<void> resetOnboarding() async {
    state = false;
    await _repository.resetOnboarding();
  }
}

// Onboarding controller
class OnboardingController
    extends StateNotifier<AsyncValue<OnboardingProgress?>> {
  final OnboardingRepository _repository;
  final Ref _ref;

  OnboardingController(this._repository, this._ref)
      : super(const AsyncValue.loading()) {
    _loadOnboardingProgress();
  }

  Future<void> _loadOnboardingProgress() async {
    try {
      state = const AsyncValue.loading();
      final progress = await _repository.getOnboardingProgress();
      state = AsyncValue.data(progress);

      // Set current step index
      if (progress != null) {
        final steps = await _repository.getOnboardingSteps();
        final currentStepIndex = steps.indexWhere(
          (step) => step.id == progress.currentStepId,
        );
        if (currentStepIndex >= 0) {
          _ref.read(currentStepIndexProvider.notifier).state = currentStepIndex;
        }
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> goToNextStep() async {
    try {
      // Get current progress
      if (state.value == null) {
        await _loadOnboardingProgress();
        return;
      }

      // Get all steps
      final steps = await _repository.getOnboardingSteps();

      // Find current step and the next step
      final currentStepIndex = _ref.read(currentStepIndexProvider);
      final nextStepIndex = currentStepIndex + 1;

      // Check if there is a next step
      if (nextStepIndex >= steps.length) {
        // If we're at the last step, complete onboarding
        await completeOnboarding();
        return;
      }

      final currentStep = steps[currentStepIndex];
      final nextStep = steps[nextStepIndex];

      // Mark the current step as completed and update progress
      final updatedProgress = state.value!.completeStep(
        stepId: currentStep.id,
        nextStepId: nextStep.id,
        earnedBadge: await _getBadgeForStep(currentStep.id),
      );

      // Save the updated progress
      await _repository.saveOnboardingProgress(updatedProgress);

      // Update state
      state = AsyncValue.data(updatedProgress);

      // Update current step index
      _ref.read(currentStepIndexProvider.notifier).state = nextStepIndex;
    } catch (e, stack) {
      debugPrint('Error going to next step: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  Future<OnboardingBadge?> _getBadgeForStep(String stepId) async {
    // Get all badges
    final badges = await _repository.getAvailableBadges();

    // Map step IDs to badge IDs
    final Map<String, String> stepToBadgeMap = {
      'welcome': 'welcome_explorer',
      'profile_setup': 'profile_pioneer',
      'goal_setting': 'goal_setter',
      'feature_tour': 'feature_explorer',
      'permissions': 'permission_grantor',
      'completion': 'journey_beginner',
    };

    // Get the corresponding badge if any
    final badgeId = stepToBadgeMap[stepId];
    if (badgeId != null) {
      try {
        return badges.firstWhere(
          (badge) => badge.id == badgeId,
        );
      } catch (_) {
        // Badge not found, return null
        return null;
      }
    }

    return null;
  }

  Future<void> completeOnboarding() async {
    await _ref.read(onboardingCompletedProvider.notifier).completeOnboarding();
  }

  Future<void> resetOnboarding() async {
    await _ref.read(onboardingCompletedProvider.notifier).resetOnboarding();
    await _loadOnboardingProgress();
  }
}
