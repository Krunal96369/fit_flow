import '../../domain/models/difficulty.dart';
import '../../domain/models/equipment.dart';
import '../../domain/models/exercise.dart';
import '../../domain/models/movement_pattern.dart';
import '../../domain/models/muscle.dart';
import '../../domain/repositories/exercise_repository.dart';

/// An in-memory implementation of the ExerciseRepository for testing and development.
///
/// Simulates fetching data from a hardcoded list with a slight delay.
class InMemoryExerciseRepository implements ExerciseRepository {
  // Simulate network delay
  final Duration _delay = const Duration(milliseconds: 500);

  // Hardcoded list of exercises
  static final List<Exercise> _exercises = [
    const Exercise(
      id: 'ex001',
      name: 'Barbell Bench Press',
      primaryMuscle: Muscle.chest,
      secondaryMuscles: [Muscle.shoulders, Muscle.triceps],
      description:
          'Lie on a flat bench, lower the barbell to the mid-chest, and press it back up.',
      difficulty: Difficulty.intermediate,
      equipmentNeeded: [Equipment.barbell, Equipment.bench],
      movementPattern: MovementPattern.push,
      isCompoundMovement: true,
      properForm:
          'Lie on a flat bench with feet firmly planted on the ground. Grip the barbell slightly wider than shoulder width. Lower the bar to mid-chest, keeping elbows at about a 45-degree angle to your body. Press the bar upward until arms are fully extended.',
      commonMistakes:
          'Bouncing the bar off the chest, arching the back excessively, feet up in the air, inconsistent bar path.',
      alternativeExercises: [
        'Dumbbell Bench Press',
        'Push-up',
        'Machine Chest Press'
      ],
      equipmentVariations: [
        'Barbell',
        'Dumbbell',
        'Smith Machine',
        'Resistance Band'
      ],
      muscleGroupImageUrl: 'assets/images/muscle_groups/chest.png',
      imageUrl: 'assets/images/exercises/barbell_bench_press.jpg',
      videoUrl: 'https://example.com/videos/barbell_bench_press.mp4',
      instructions:
          '1. Lie on the bench with feet flat on the floor\n2. Grip the barbell with hands slightly wider than shoulder-width\n3. Unrack the barbell and position it over your chest\n4. Lower the barbell to your mid-chest\n5. Push the barbell back up to the starting position\n6. Repeat for desired reps',
      calories: 150,
    ),
    const Exercise(
      id: 'ex002',
      name: 'Barbell Squat',
      primaryMuscle: Muscle.quads,
      secondaryMuscles: [
        Muscle.glutes,
        Muscle.hamstrings,
        Muscle.calves,
        Muscle.lowerBack
      ],
      description:
          'Place the barbell on your upper back, squat down until your thighs are parallel to the floor, and stand back up.',
      difficulty: Difficulty.intermediate,
      equipmentNeeded: [Equipment.barbell, Equipment.other],
      movementPattern: MovementPattern.squat,
      isCompoundMovement: true,
      properForm:
          'Stand with feet shoulder-width apart, barbell resting on upper back (not neck). Keeping chest up and back straight, push hips back and bend knees to lower until thighs are parallel to floor. Drive through heels to return to standing.',
      commonMistakes:
          'Knees caving inward, rounding the back, not reaching proper depth, heels coming off the floor, looking down.',
      alternativeExercises: ['Front Squat', 'Goblet Squat', 'Leg Press'],
      equipmentVariations: ['Barbell', 'Dumbbell', 'Kettlebell', 'Body Weight'],
      muscleGroupImageUrl: 'assets/images/muscle_groups/legs.png',
      imageUrl: 'assets/images/exercises/barbell_squat.jpg',
      videoUrl: 'https://example.com/videos/barbell_squat.mp4',
      instructions:
          '1. Position barbell on upper back\n2. Set feet shoulder-width apart\n3. Brace core and maintain neutral spine\n4. Bend knees and push hips back\n5. Lower until thighs are parallel to floor\n6. Push through heels to stand up\n7. Repeat for desired reps',
      calories: 200,
    ),
    const Exercise(
      id: 'ex003',
      name: 'Deadlift',
      primaryMuscle: Muscle.lowerBack,
      secondaryMuscles: [
        Muscle.glutes,
        Muscle.hamstrings,
        Muscle.quads,
        Muscle.traps,
        Muscle.lats
      ],
      description:
          'Lift the barbell from the floor by extending your hips and knees until you are standing upright.',
      difficulty: Difficulty.advanced,
      equipmentNeeded: [Equipment.barbell],
      movementPattern: MovementPattern.hinge,
      isCompoundMovement: true,
      properForm:
          'Stand with feet hip-width apart, barbell over mid-foot. Hinge at hips to grip bar with hands shoulder-width apart. Keep back flat and chest up, engage core, and pull the bar up by driving through the heels and extending the hips and knees until standing upright.',
      commonMistakes:
          'Rounding the lower back, starting with hips too low, jerking the weight off the floor, hyperextending at the top, looking up too high.',
      alternativeExercises: [
        'Romanian Deadlift',
        'Trap Bar Deadlift',
        'Sumo Deadlift'
      ],
      equipmentVariations: ['Barbell', 'Trap Bar', 'Dumbbell', 'Kettlebell'],
      muscleGroupImageUrl: 'assets/images/muscle_groups/posterior_chain.png',
      imageUrl: 'assets/images/exercises/deadlift.jpg',
      videoUrl: 'https://example.com/videos/deadlift.mp4',
      instructions:
          '1. Stand with feet hip-width apart, barbell over mid-foot\n2. Hinge at hips to grab the bar, shoulder-width grip\n3. Lower hips, flat back, chest up\n4. Drive through heels while maintaining back position\n5. Extend hips and knees to stand up\n6. Return weight to floor by hinging at hips\n7. Repeat for desired reps',
      calories: 250,
    ),
    const Exercise(
      id: 'ex004',
      name: 'Overhead Press',
      primaryMuscle: Muscle.shoulders,
      secondaryMuscles: [Muscle.triceps, Muscle.traps],
      description:
          'Press the barbell overhead from your shoulders until your arms are fully extended.',
      difficulty: Difficulty.intermediate,
      equipmentNeeded: [Equipment.barbell],
      movementPattern: MovementPattern.push,
      isCompoundMovement: true,
      properForm:
          'Start with barbell at shoulder height, hands just outside shoulders. Feet hip-width apart, core braced. Press bar directly overhead, moving head slightly backward as bar passes face. Fully extend arms overhead, bar aligned with mid-foot. Lower bar back to shoulders with control.',
      commonMistakes:
          'Arching the lower back, pressing the bar in front of the body instead of straight up, not fully engaging the core, incomplete lockout overhead.',
      alternativeExercises: [
        'Dumbbell Shoulder Press',
        'Seated Military Press',
        'Kettlebell Press'
      ],
      equipmentVariations: ['Barbell', 'Dumbbell', 'Kettlebell', 'Machine'],
      muscleGroupImageUrl: 'assets/images/muscle_groups/shoulders.png',
      imageUrl: 'assets/images/exercises/overhead_press.jpg',
      videoUrl: 'https://example.com/videos/overhead_press.mp4',
      instructions:
          '1. Start with barbell at shoulder level\n2. Grip bar with hands just outside shoulders\n3. Brace core and glutes\n4. Press bar directly overhead\n5. Fully lock out arms at the top\n6. Lower bar back to shoulders with control\n7. Repeat for desired reps',
      calories: 130,
    ),
    const Exercise(
      id: 'ex005',
      name: 'Pull Up',
      primaryMuscle: Muscle.lats,
      secondaryMuscles: [Muscle.biceps, Muscle.upperBack],
      description:
          'Hang from a pull-up bar and pull your body up until your chin is over the bar.',
      difficulty: Difficulty.advanced,
      equipmentNeeded: [Equipment.pullUpBar],
      movementPattern: MovementPattern.pull,
      isCompoundMovement: true,
      properForm:
          'Hang from pull-up bar with hands slightly wider than shoulder-width, palms facing away. Start from a dead hang with arms fully extended. Pull body up by driving elbows down and back until chin clears the bar. Lower with control to starting position.',
      commonMistakes:
          'Using momentum (kipping), incomplete range of motion, excessive body swinging, not engaging the lats properly.',
      alternativeExercises: [
        'Assisted Pull-up',
        'Lat Pulldown',
        'Negative Pull-ups'
      ],
      equipmentVariations: [
        'Bar',
        'Assisted Machine',
        'Resistance Bands',
        'Gymnastic Rings'
      ],
      muscleGroupImageUrl: 'assets/images/muscle_groups/back.png',
      imageUrl: 'assets/images/exercises/pull_up.jpg',
      videoUrl: 'https://example.com/videos/pull_up.mp4',
      instructions:
          '1. Grip pull-up bar with hands wider than shoulders\n2. Hang with arms fully extended\n3. Engage core and pull shoulders down and back\n4. Pull up until chin is above the bar\n5. Lower with control to starting position\n6. Repeat for desired reps',
      calories: 100,
    ),
    const Exercise(
      id: 'ex006',
      name: 'Dumbbell Bicep Curl',
      primaryMuscle: Muscle.biceps,
      secondaryMuscles: [Muscle.forearms],
      description:
          'Curl dumbbells towards your shoulders, keeping your elbows tucked in.',
      difficulty: Difficulty.beginner,
      equipmentNeeded: [Equipment.dumbbells],
      movementPattern: MovementPattern.pull,
      isCompoundMovement: false,
      properForm:
          'Stand with feet shoulder-width apart, dumbbells in hands, palms facing forward. Keep elbows close to torso and stationary throughout the movement. Curl weights toward shoulders by flexing at the elbow. Squeeze biceps at the top, then lower with control to starting position.',
      commonMistakes:
          'Swinging the weight, moving the elbows forward, not maintaining proper posture, lifting too heavy.',
      alternativeExercises: ['Hammer Curl', 'Barbell Curl', 'Cable Curl'],
      equipmentVariations: [
        'Dumbbells',
        'Barbell',
        'EZ Bar',
        'Cables',
        'Resistance Bands'
      ],
      muscleGroupImageUrl: 'assets/images/muscle_groups/arms.png',
      imageUrl: 'assets/images/exercises/bicep_curl.jpg',
      videoUrl: 'https://example.com/videos/bicep_curl.mp4',
      instructions:
          '1. Stand with dumbbells at sides, palms forward\n2. Keep upper arms stationary against sides\n3. Curl dumbbells up toward shoulders\n4. Squeeze biceps at the top\n5. Lower with control to starting position\n6. Repeat for desired reps',
      calories: 70,
    ),
    const Exercise(
      id: 'ex007',
      name: 'Plank',
      primaryMuscle: Muscle.abs,
      secondaryMuscles: [Muscle.shoulders, Muscle.lowerBack],
      description:
          'Hold a prone position with body weight on forearms and toes.',
      difficulty: Difficulty.beginner,
      equipmentNeeded: [],
      movementPattern: MovementPattern.isometric,
      isCompoundMovement: false,
      properForm:
          'Start in a prone position, resting on forearms with elbows under shoulders. Extend legs with toes on the floor. Lift body to create a straight line from head to heels. Keep core engaged, back flat, and neck neutral. Hold this position.',
      commonMistakes:
          'Sagging hips, raised buttocks, holding breath, looking up or down, improper shoulder position.',
      alternativeExercises: ['Side Plank', 'Bird Dog', 'Dead Bug'],
      equipmentVariations: ['Floor', 'Stability Ball', 'TRX', 'BOSU Ball'],
      muscleGroupImageUrl: 'assets/images/muscle_groups/core.png',
      imageUrl: 'assets/images/exercises/plank.jpg',
      videoUrl: 'https://example.com/videos/plank.mp4',
      instructions:
          '1. Start in a prone position on forearms\n2. Elbows directly beneath shoulders\n3. Extend legs with toes on floor\n4. Lift body to create straight line from head to heels\n5. Engage core and glutes\n6. Keep shoulders down and back\n7. Hold position for prescribed time',
      calories: 40,
    ),
    const Exercise(
      id: 'ex008',
      name: 'Romanian Deadlift',
      primaryMuscle: Muscle.hamstrings,
      secondaryMuscles: [Muscle.glutes, Muscle.lowerBack],
      description:
          'Hinge at the hips while keeping legs mostly straight to lower weight and then stand back up.',
      difficulty: Difficulty.intermediate,
      equipmentNeeded: [Equipment.barbell],
      movementPattern: MovementPattern.hinge,
      isCompoundMovement: true,
      properForm:
          'Start standing with barbell at hip level. Initiate movement by pushing hips backward while maintaining a slight bend in knees. Lower barbell by hinging at hips, keeping back flat and bar close to legs. Feel stretch in hamstrings, then drive hips forward to return to standing.',
      commonMistakes:
          'Rounding the back, bending knees too much, letting bar drift away from legs, not hinging properly at hips.',
      alternativeExercises: [
        'Single-Leg RDL',
        'Good Morning',
        'Kettlebell RDL'
      ],
      equipmentVariations: ['Barbell', 'Dumbbell', 'Kettlebell', 'Trap Bar'],
      muscleGroupImageUrl: 'assets/images/muscle_groups/hamstrings.png',
      imageUrl: 'assets/images/exercises/romanian_deadlift.jpg',
      videoUrl: 'https://example.com/videos/romanian_deadlift.mp4',
      instructions:
          '1. Stand with feet hip-width apart, holding barbell\n2. Slight bend in knees throughout movement\n3. Hinge at hips, pushing buttocks backward\n4. Keep back flat and bar close to legs\n5. Lower until feeling stretch in hamstrings\n6. Drive hips forward to stand up\n7. Repeat for desired reps',
      calories: 150,
    ),
  ];

  /// Gets all exercises from the repository.
  @override
  Future<List<Exercise>> getAllExercises() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    return _exercises;
  }

  /// Gets a single exercise by ID.
  @override
  Future<Exercise?> getExerciseById(String id) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      return _exercises.firstWhere((exercise) => exercise.id == id);
    } catch (e) {
      // Return null if not found
      return null;
    }
  }

  /// Gets all exercises for a specific muscle.
  @override
  Future<List<Exercise>> getExercisesByMuscle(String muscleId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 700));

    try {
      // Parse the muscleId to Muscle enum
      final muscle = Muscle.values.firstWhere(
        (m) =>
            m.toString() == muscleId ||
            m.toString() == 'Muscle.$muscleId' ||
            m.name.toLowerCase() == muscleId.toLowerCase(),
        orElse: () => throw Exception('Invalid muscle ID: $muscleId'),
      );

      return _exercises
          .where((exercise) =>
              exercise.primaryMuscle == muscle ||
              (exercise.secondaryMuscles?.contains(muscle) ?? false))
          .toList();
    } catch (e) {
      print('Error in getExercisesByMuscle: $e');
      return [];
    }
  }

  /// Adds a new exercise to the repository.
  @override
  Future<Exercise> addExercise(Exercise exercise) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));

    // Check if the exercise already exists
    final exists = _exercises.any((e) => e.id == exercise.id);
    if (exists) {
      throw Exception('Exercise with ID ${exercise.id} already exists');
    }

    // Create a new ID if one isn't provided
    final newExercise = exercise.id.isEmpty
        ? exercise.copyWith(id: 'ex${_exercises.length + 1}')
        : exercise;

    _exercises.add(newExercise);
    return newExercise;
  }

  /// Updates an existing exercise in the repository.
  @override
  Future<Exercise> updateExercise(Exercise exercise) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));

    final index = _exercises.indexWhere((e) => e.id == exercise.id);
    if (index == -1) {
      throw Exception('Exercise with ID ${exercise.id} not found');
    }

    _exercises[index] = exercise;
    return exercise;
  }

  /// Deletes an exercise from the repository.
  @override
  Future<bool> deleteExercise(String id) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    final initialLength = _exercises.length;
    _exercises.removeWhere((e) => e.id == id);

    return _exercises.length < initialLength;
  }

  /// Searches for exercises that match the given term.
  @override
  Future<List<Exercise>> searchExercises(String searchTerm) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 700));

    if (searchTerm.isEmpty) {
      return [];
    }

    final term = searchTerm.toLowerCase();
    return _exercises
        .where((exercise) =>
            exercise.name.toLowerCase().contains(term) ||
            (exercise.description?.toLowerCase().contains(term) ?? false) ||
            exercise.primaryMuscle.name.toLowerCase().contains(term) ||
            (exercise.secondaryMuscles?.any(
                    (muscle) => muscle.name.toLowerCase().contains(term)) ??
                false) ||
            (exercise.equipmentNeeded?.any((equipment) =>
                    equipment.name.toLowerCase().contains(term)) ??
                false))
        .toList();
  }

  /// Toggles whether an exercise is a favorite.
  @override
  Future<void> toggleFavorite(String id, bool isFavorite) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    final index = _exercises.indexWhere((e) => e.id == id);
    if (index == -1) {
      throw Exception('Exercise with ID $id not found');
    }

    final exercise = _exercises[index];
    _exercises[index] = exercise.copyWith(isFavorite: isFavorite);
  }

  /// Gets all favorite exercises.
  @override
  Future<List<Exercise>> getFavoriteExercises() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 700));

    return _exercises
        .where((exercise) => exercise.isFavorite ?? false)
        .toList();
  }

  // Added for backward compatibility with dependent code
  Future<List<Exercise>> fetchExercises() async {
    return getAllExercises();
  }

  // Added for backward compatibility with dependent code
  Future<Exercise?> fetchExerciseById(String id) async {
    return getExerciseById(id);
  }

  @override
  Future<List<Exercise>> getExercisesByEquipment(Equipment equipment) async {
    await Future.delayed(_delay);
    return _exercises
        .where((exercise) =>
            exercise.equipmentNeeded?.contains(equipment) ?? false)
        .toList();
  }

  // Add method to search exercises by difficulty
  Future<List<Exercise>> getExercisesByDifficulty(Difficulty difficulty) async {
    await Future.delayed(_delay);
    return _exercises
        .where((exercise) => exercise.difficulty == difficulty)
        .toList();
  }

  // Add method to search exercises by movement pattern
  Future<List<Exercise>> getExercisesByMovementPattern(
      MovementPattern pattern) async {
    await Future.delayed(_delay);
    return _exercises
        .where((exercise) => exercise.movementPattern == pattern)
        .toList();
  }

  // Add method to filter exercises by compound vs isolation movements
  Future<List<Exercise>> getExercisesByType(bool isCompound) async {
    await Future.delayed(_delay);
    return _exercises
        .where((exercise) => exercise.isCompoundMovement == isCompound)
        .toList();
  }
}
