import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'user_profile.dart';

/// Repository interface for handling user profile operations
abstract class ProfileRepository {
  /// Get a user profile by ID
  Future<UserProfile?> getUserProfile(String userId);

  /// Get a stream of user profile updates
  Stream<UserProfile?> getUserProfileStream(String userId);

  /// Save or update a user profile
  Future<void> saveUserProfile(UserProfile profile);

  /// Update user profile photo URL
  Future<void> updateProfilePhoto(String userId, String photoUrl);

  /// Delete a user profile
  Future<void> deleteUserProfile(String userId);
}

/// Provider for the profile repository
/// This will be overridden in repository_providers.dart with the actual implementation
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  throw UnimplementedError(
    'profileRepositoryProvider has not been overridden. '
    'Make sure to override this in repository_providers.dart',
  );
});
