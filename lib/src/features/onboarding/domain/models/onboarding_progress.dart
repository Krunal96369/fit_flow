import '../models/onboarding_badge.dart';

/// Represents the user's progress through the onboarding process
class OnboardingProgress {
  /// List of completed onboarding steps
  final List<String> completedStepIds;

  /// Current onboarding step ID
  final String currentStepId;

  /// Total number of completed steps
  final int completedStepsCount;

  /// Total number of steps in the onboarding process
  final int totalStepsCount;

  /// Whether the onboarding process is complete
  final bool isComplete;

  /// Badges earned during onboarding
  final List<OnboardingBadge> earnedBadges;

  /// Total points earned during onboarding
  final int totalPoints;

  /// Timestamp when onboarding was started
  final DateTime startedAt;

  /// Timestamp when onboarding was completed (null if not completed)
  final DateTime? completedAt;

  /// Constructor
  const OnboardingProgress({
    required this.completedStepIds,
    required this.currentStepId,
    required this.completedStepsCount,
    required this.totalStepsCount,
    required this.isComplete,
    required this.earnedBadges,
    required this.totalPoints,
    required this.startedAt,
    this.completedAt,
  });

  /// Initial state with no progress
  factory OnboardingProgress.initial({
    required String initialStepId,
    required int totalSteps,
  }) {
    return OnboardingProgress(
      completedStepIds: [],
      currentStepId: initialStepId,
      completedStepsCount: 0,
      totalStepsCount: totalSteps,
      isComplete: false,
      earnedBadges: [],
      totalPoints: 0,
      startedAt: DateTime.now(),
      completedAt: null,
    );
  }

  /// Create a copy with updated properties
  OnboardingProgress copyWith({
    List<String>? completedStepIds,
    String? currentStepId,
    int? completedStepsCount,
    int? totalStepsCount,
    bool? isComplete,
    List<OnboardingBadge>? earnedBadges,
    int? totalPoints,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return OnboardingProgress(
      completedStepIds: completedStepIds ?? this.completedStepIds,
      currentStepId: currentStepId ?? this.currentStepId,
      completedStepsCount: completedStepsCount ?? this.completedStepsCount,
      totalStepsCount: totalStepsCount ?? this.totalStepsCount,
      isComplete: isComplete ?? this.isComplete,
      earnedBadges: earnedBadges ?? this.earnedBadges,
      totalPoints: totalPoints ?? this.totalPoints,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// Mark a step as completed and update progress
  OnboardingProgress completeStep({
    required String stepId,
    required String nextStepId,
    OnboardingBadge? earnedBadge,
  }) {
    final updatedCompletedSteps = List<String>.from(completedStepIds)
      ..add(stepId);
    final updatedCompletedCount = completedStepsCount + 1;
    final updatedIsComplete = updatedCompletedCount >= totalStepsCount;

    List<OnboardingBadge> updatedBadges =
        List<OnboardingBadge>.from(earnedBadges);
    int updatedPoints = totalPoints;

    if (earnedBadge != null) {
      updatedBadges.add(earnedBadge.unlock());
      updatedPoints += earnedBadge.pointsValue;
    }

    return copyWith(
      completedStepIds: updatedCompletedSteps,
      currentStepId: nextStepId,
      completedStepsCount: updatedCompletedCount,
      isComplete: updatedIsComplete,
      earnedBadges: updatedBadges,
      totalPoints: updatedPoints,
      completedAt: updatedIsComplete ? DateTime.now() : null,
    );
  }

  /// Get completion percentage (0.0 to 1.0)
  double get completionPercentage =>
      totalStepsCount > 0 ? completedStepsCount / totalStepsCount : 0.0;
}
