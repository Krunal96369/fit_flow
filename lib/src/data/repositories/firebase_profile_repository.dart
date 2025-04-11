import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../features/profile/domain/profile_repository.dart';
import '../../features/profile/domain/user_profile.dart';

/// Firebase implementation of the [ProfileRepository]
class FirebaseProfileRepository implements ProfileRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// The collection name for users
  static const String _usersCollection = 'users';

  /// Constructor
  FirebaseProfileRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  @override
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc =
          await _firestore.collection(_usersCollection).doc(userId).get();

      if (doc.exists && doc.data() != null) {
        return UserProfile.fromMap(doc.data()!);
      }

      // If profile doesn't exist yet, create a default one from Firebase user
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null && firebaseUser.uid == userId) {
        final defaultProfile = UserProfile.fromFirebaseUser(
          userId,
          firebaseUser.email ?? '',
          displayName: firebaseUser.displayName,
        );

        // Save the default profile
        await saveUserProfile(defaultProfile);
        return defaultProfile;
      }

      return null;
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  @override
  Stream<UserProfile?> getUserProfileStream(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserProfile.fromMap(doc.data()!);
      }
      return null;
    });
  }

  @override
  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      await _firestore.collection(_usersCollection).doc(profile.id).set(
            profile.copyWith(lastUpdated: DateTime.now()).toMap(),
            SetOptions(merge: true),
          );

      // Update display name in Firebase Auth if it has changed
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null &&
          firebaseUser.uid == profile.id &&
          firebaseUser.displayName != profile.displayName) {
        await firebaseUser.updateDisplayName(profile.displayName);
      }
    } catch (e) {
      debugPrint('Error saving user profile: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateProfilePhoto(String userId, String photoUrl) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).update({
        'photoUrl': photoUrl,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Update photo URL in Firebase Auth
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null && firebaseUser.uid == userId) {
        await firebaseUser.updatePhotoURL(photoUrl);
      }
    } catch (e) {
      debugPrint('Error updating profile photo: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteUserProfile(String userId) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).delete();
    } catch (e) {
      debugPrint('Error deleting user profile: $e');
      rethrow;
    }
  }
}
