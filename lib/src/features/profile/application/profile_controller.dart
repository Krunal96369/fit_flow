import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/repository_providers.dart' as repo_providers;
import '../domain/profile_repository.dart';
import '../domain/user_profile.dart';

/// Provider for the current user's profile stream
final userProfileStreamProvider =
    StreamProvider.autoDispose<UserProfile?>((ref) {
  final auth = FirebaseAuth.instance;
  final userId = auth.currentUser?.uid;
  final profileController = ref.watch(profileControllerProvider);

  if (userId == null) {
    return Stream.value(null);
  }

  return profileController.getUserProfileStream(userId);
});

/// Provider for the current user's profile (future)
final userProfileProvider =
    FutureProvider.autoDispose<UserProfile?>((ref) async {
  final auth = FirebaseAuth.instance;
  final userId = auth.currentUser?.uid;
  final profileController = ref.watch(profileControllerProvider);

  if (userId == null) {
    return null;
  }

  return profileController.getUserProfile(userId);
});

/// Provider for the profile controller
final profileControllerProvider = Provider<ProfileController>((ref) {
  final profileRepository = ref.watch(repo_providers.profileRepositoryProvider);
  return ProfileController(profileRepository);
});

/// Controller for managing user profiles
class ProfileController {
  final ProfileRepository _profileRepository;

  /// Constructor
  ProfileController(this._profileRepository);

  /// Get a user profile by ID
  Future<UserProfile?> getUserProfile(String userId) {
    return _profileRepository.getUserProfile(userId);
  }

  /// Get a stream of user profile updates
  Stream<UserProfile?> getUserProfileStream(String userId) {
    return _profileRepository.getUserProfileStream(userId);
  }

  /// Save or update a user profile
  Future<void> saveUserProfile(UserProfile profile) {
    return _profileRepository.saveUserProfile(profile);
  }

  /// Update user profile photo URL
  Future<void> updateProfilePhoto(String userId, String photoUrl) {
    return _profileRepository.updateProfilePhoto(userId, photoUrl);
  }

  /// Update user profile information
  Future<void> updateUserProfile({
    required String userId,
    String? displayName,
    String? firstName,
    String? lastName,
    double? height,
    double? weight,
    DateTime? dateOfBirth,
    String? gender,
  }) async {
    final currentProfile = await _profileRepository.getUserProfile(userId);

    if (currentProfile == null) {
      throw Exception('User profile not found');
    }

    final updatedProfile = currentProfile.copyWith(
      displayName: displayName,
      firstName: firstName,
      lastName: lastName,
      height: height,
      weight: weight,
      dateOfBirth: dateOfBirth,
      gender: gender,
    );

    return _profileRepository.saveUserProfile(updatedProfile);
  }

  /// Delete a user profile
  Future<void> deleteUserProfile(String userId) {
    return _profileRepository.deleteUserProfile(userId);
  }
}
