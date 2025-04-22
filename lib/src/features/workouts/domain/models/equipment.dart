/// Defines different types of equipment that may be needed for exercises.
enum Equipment {
  noEquipment,
  dumbbells,
  barbell,
  kettlebell,
  resistanceBands,
  cable,
  machine,
  medicineBall,
  foam,
  bench,
  pullUpBar,
  dipBars,
  swissBall,
  rings,
  trx,
  rope,
  box,
  other;

  /// Returns a display-friendly name for the equipment
  String get displayName {
    switch (this) {
      case Equipment.noEquipment:
        return 'No Equipment';
      case Equipment.dumbbells:
        return 'Dumbbells';
      case Equipment.barbell:
        return 'Barbell';
      case Equipment.kettlebell:
        return 'Kettlebell';
      case Equipment.resistanceBands:
        return 'Resistance Bands';
      case Equipment.cable:
        return 'Cable';
      case Equipment.machine:
        return 'Machine';
      case Equipment.medicineBall:
        return 'Medicine Ball';
      case Equipment.foam:
        return 'Foam Roller';
      case Equipment.bench:
        return 'Bench';
      case Equipment.pullUpBar:
        return 'Pull-Up Bar';
      case Equipment.dipBars:
        return 'Dip Bars';
      case Equipment.swissBall:
        return 'Swiss Ball';
      case Equipment.rings:
        return 'Gymnastic Rings';
      case Equipment.trx:
        return 'TRX/Suspension Trainer';
      case Equipment.rope:
        return 'Battle Rope';
      case Equipment.box:
        return 'Plyo Box';
      case Equipment.other:
        return 'Other';
    }
  }
}
