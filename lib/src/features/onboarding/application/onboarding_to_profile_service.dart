import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/application/profile_controller.dart';
import '../../profile/domain/user_profile.dart';

/// Provider for the OnboardingToProfileService
final onboardingToProfileServiceProvider =
    Provider<OnboardingToProfileService>((ref) {
  final profileController = ref.watch(profileControllerProvider);
  return OnboardingToProfileService(
    profileController: profileController,
    auth: FirebaseAuth.instance,
  );
});

/// Service for saving onboarding data to user profile in Firebase
class OnboardingToProfileService {
  final ProfileController _profileController;
  final FirebaseAuth _auth;

  /// Constructor
  OnboardingToProfileService({
    required ProfileController profileController,
    required FirebaseAuth auth,
  })  : _profileController = profileController,
        _auth = auth;

  /// Save profile data from onboarding
  Future<void> saveProfileData({
    String? displayName,
    String? gender,
    DateTime? dateOfBirth,
    double? height,
    double? weight,
    String? heightUnit,
    String? weightUnit,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('Cannot save profile: No authenticated user');
        return;
      }

      final userId = user.uid;

      // Get existing profile or create a new one if it doesn't exist
      UserProfile? existingProfile =
          await _profileController.getUserProfile(userId);

      existingProfile ??= UserProfile.fromFirebaseUser(
        userId,
        user.email ?? '',
        displayName: user.displayName,
      );

      // Convert height and weight to metric system for storage if necessary
      double? heightInCm = height;
      double? weightInKg = weight;

      if (height != null && heightUnit == 'ft') {
        // Convert feet to cm (1 foot = 30.48 cm)
        heightInCm = height * 30.48;
      }

      if (weight != null && weightUnit == 'lb') {
        // Convert pounds to kg (1 pound = 0.453592 kg)
        weightInKg = weight * 0.453592;
      }

      // Update with onboarding data
      final updatedProfile = existingProfile.copyWith(
        displayName: displayName ?? existingProfile.displayName,
        gender: gender,
        dateOfBirth: dateOfBirth,
        height: heightInCm, // Always store in cm
        weight: weightInKg, // Always store in kg
        lastUpdated: DateTime.now(),
      );

      // Save to Firebase
      await _profileController.saveUserProfile(updatedProfile);
      debugPrint('Successfully saved onboarding profile data to Firebase');
    } catch (e) {
      debugPrint('Error saving onboarding profile data: $e');
    }
  }

  /// Save fitness goals data from onboarding
  Future<void> saveFitnessGoals({
    String? primaryGoal,
    int? workoutsPerWeek,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('Cannot save fitness goals: No authenticated user');
        return;
      }

      final userId = user.uid;

      // Get existing profile
      UserProfile? profile = await _profileController.getUserProfile(userId);

      if (profile == null) {
        debugPrint('Cannot save fitness goals: Profile not found');
        return;
      }

      // Create or update preferences with fitness goals
      final Map<String, dynamic> currentPreferences = profile.preferences ?? {};
      final Map<String, dynamic> fitnessPreferences =
          currentPreferences['fitness'] as Map<String, dynamic>? ?? {};

      fitnessPreferences['primaryGoal'] = primaryGoal;
      fitnessPreferences['workoutsPerWeek'] = workoutsPerWeek;

      currentPreferences['fitness'] = fitnessPreferences;

      // Update profile with new preferences
      final updatedProfile = profile.copyWith(
        preferences: currentPreferences,
        lastUpdated: DateTime.now(),
      );

      // Save to Firebase
      await _profileController.saveUserProfile(updatedProfile);
      debugPrint('Successfully saved fitness goals to Firebase');
    } catch (e) {
      debugPrint('Error saving fitness goals: $e');
    }
  }
}
