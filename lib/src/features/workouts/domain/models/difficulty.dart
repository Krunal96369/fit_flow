/// Defines the difficulty levels for exercises.
enum Difficulty {
  beginner,
  intermediate,
  advanced;

  /// Returns a display-friendly name for the difficulty level
  String get displayName {
    switch (this) {
      case Difficulty.beginner:
        return 'Beginner';
      case Difficulty.intermediate:
        return 'Intermediate';
      case Difficulty.advanced:
        return 'Advanced';
    }
  }
}
