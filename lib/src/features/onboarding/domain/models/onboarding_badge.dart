/// Represents a badge that can be earned during the onboarding process
class OnboardingBadge {
  /// Unique identifier for the badge
  final String id;

  /// Name of the badge
  final String name;

  /// Description of what the badge represents
  final String description;

  /// Path to the image asset for the badge
  final String imagePath;

  /// Level or tier of the badge (higher is better)
  final int tier;

  /// Points value of the badge
  final int pointsValue;

  /// Requirements to earn this badge
  final List<String> requirements;

  /// Whether the badge is currently unlocked
  final bool isUnlocked;

  /// Date when the badge was earned
  final DateTime? earnedAt;

  /// Constructor
  const OnboardingBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.imagePath,
    this.tier = 1,
    this.pointsValue = 50,
    this.requirements = const [],
    this.isUnlocked = false,
    this.earnedAt,
  });

  /// Create a copy of this badge with updated properties
  OnboardingBadge copyWith({
    String? id,
    String? name,
    String? description,
    String? imagePath,
    int? tier,
    int? pointsValue,
    List<String>? requirements,
    bool? isUnlocked,
    DateTime? earnedAt,
  }) {
    return OnboardingBadge(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      tier: tier ?? this.tier,
      pointsValue: pointsValue ?? this.pointsValue,
      requirements: requirements ?? this.requirements,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      earnedAt: earnedAt ?? this.earnedAt,
    );
  }

  /// Creates an unlocked version of this badge
  OnboardingBadge unlock() {
    return copyWith(
      isUnlocked: true,
      earnedAt: DateTime.now(),
    );
  }
}
