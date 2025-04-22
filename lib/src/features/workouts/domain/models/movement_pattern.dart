/// Defines the different movement patterns for exercises.
enum MovementPattern {
  push,
  pull,
  squat,
  hinge,
  lunge,
  rotation,
  carry,
  isometric;

  /// Returns a display-friendly name for the movement pattern
  String get displayName {
    switch (this) {
      case MovementPattern.push:
        return 'Push';
      case MovementPattern.pull:
        return 'Pull';
      case MovementPattern.squat:
        return 'Squat';
      case MovementPattern.hinge:
        return 'Hinge';
      case MovementPattern.lunge:
        return 'Lunge';
      case MovementPattern.rotation:
        return 'Rotation';
      case MovementPattern.carry:
        return 'Carry';
      case MovementPattern.isometric:
        return 'Isometric';
    }
  }
}
