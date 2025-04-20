/// Defines the different muscle groups that can be targeted by exercises.
enum Muscle {
  chest,
  back,
  shoulders,
  biceps,
  triceps,
  forearms,
  abs,
  quads,
  hamstrings,
  calves,
  glutes,
  traps,
  lats,
  obliques,
  lowerBack,
  upperBack,
  fullBody;

  /// Returns a display-friendly name for the muscle group
  String get displayName {
    switch (this) {
      case Muscle.chest:
        return 'Chest';
      case Muscle.back:
        return 'Back';
      case Muscle.shoulders:
        return 'Shoulders';
      case Muscle.biceps:
        return 'Biceps';
      case Muscle.triceps:
        return 'Triceps';
      case Muscle.forearms:
        return 'Forearms';
      case Muscle.abs:
        return 'Abs';
      case Muscle.quads:
        return 'Quadriceps';
      case Muscle.hamstrings:
        return 'Hamstrings';
      case Muscle.calves:
        return 'Calves';
      case Muscle.glutes:
        return 'Glutes';
      case Muscle.traps:
        return 'Trapezius';
      case Muscle.lats:
        return 'Latissimus Dorsi';
      case Muscle.obliques:
        return 'Obliques';
      case Muscle.lowerBack:
        return 'Lower Back';
      case Muscle.upperBack:
        return 'Upper Back';
      case Muscle.fullBody:
        return 'Full Body';
    }
  }
}
