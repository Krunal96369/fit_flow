/// Represents the type of onboarding step
enum OnboardingStepType {
  welcome,
  profile,
  goals,
  featureTour,
  permissions,
  completion,
}

/// Represents a single step in the onboarding process
class OnboardingStep {
  /// Unique identifier for the step
  final String id;

  /// Title of the step
  final String title;

  /// Description of what the step involves
  final String description;

  /// The order of this step in the sequence
  final int order;

  /// Path to the icon representing this step
  final String? iconPath;

  /// Whether this step is required to complete onboarding
  final bool isRequired;

  /// Points awarded for completing this step
  final int pointsValue;

  /// Constructor
  const OnboardingStep({
    required this.id,
    required this.title,
    required this.description,
    required this.order,
    this.iconPath,
    this.isRequired = true,
    this.pointsValue = 10,
  });

  /// Create a copy with updated properties
  OnboardingStep copyWith({
    String? id,
    String? title,
    String? description,
    int? order,
    String? iconPath,
    bool? isRequired,
    int? pointsValue,
  }) {
    return OnboardingStep(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      order: order ?? this.order,
      iconPath: iconPath ?? this.iconPath,
      isRequired: isRequired ?? this.isRequired,
      pointsValue: pointsValue ?? this.pointsValue,
    );
  }
}
