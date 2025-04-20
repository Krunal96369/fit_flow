import '../models/onboarding_badge.dart';
import '../models/onboarding_progress.dart';
import '../models/onboarding_step.dart';

/// Repository interface for onboarding data
abstract class OnboardingRepository {
  /// Get the list of onboarding steps
  Future<List<OnboardingStep>> getOnboardingSteps();

  /// Get available badges for onboarding
  Future<List<OnboardingBadge>> getAvailableBadges();

  /// Get the current onboarding progress
  Future<OnboardingProgress?> getOnboardingProgress();

  /// Save the onboarding progress
  Future<void> saveOnboardingProgress(OnboardingProgress progress);

  /// Mark a specific badge as unlocked
  Future<void> unlockBadge(String badgeId);

  /// Check if onboarding is completed
  Future<bool> isOnboardingCompleted();

  /// Mark onboarding as completed
  Future<void> completeOnboarding();

  /// Reset onboarding progress
  Future<void> resetOnboarding();
}
