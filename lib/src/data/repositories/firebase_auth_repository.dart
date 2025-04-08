import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

import '../../features/auth/domain/auth_repository.dart';
import '../../features/auth/domain/models/auth_credentials.dart';

/// Firebase implementation of the [AuthRepository].
/// Handles authentication using the FirebaseAuth SDK.
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  /// Creates a [FirebaseAuthRepository].
  /// Requires a [FirebaseAuth] instance.
  FirebaseAuthRepository(this._firebaseAuth, {FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  Future<void> signInWithCredentials(SignInCredentials credentials) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: credentials.email,
        password: credentials.password,
      );
    } on FirebaseAuthException catch (e) {
      // TODO: Consider mapping FirebaseAuthException codes to custom domain exceptions
      // e.g., 'user-not-found', 'wrong-password' -> InvalidCredentialsException
      debugPrint('FirebaseAuthException during sign in: ${e.code}');
      rethrow; // Rethrow the original exception for now
    } catch (e) {
      debugPrint('Unexpected error during sign in: $e');
      rethrow; // Rethrow unexpected errors
    }
  }

  @override
  Future<void> createUserWithCredentials(SignUpCredentials credentials) async {
    try {
      // Create the Firebase Auth user
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: credentials.email,
        password: credentials.password,
      );

      // Try to get the current user's ID directly from the credential
      final userId = userCredential.user?.uid;

      if (userId != null) {
        try {
          // Create user document in Firestore with default values
          // This is a separate try-catch to avoid failing the entire sign-up
          await _createUserDocument(userId, credentials.email);
        } catch (e) {
          // Log but don't rethrow - we still want the auth account to be created
          debugPrint('Error creating user document in Firestore: $e');
        }
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during sign up: ${e.code}');
      rethrow; // Rethrow the original exception for now
    } catch (e) {
      debugPrint('Unexpected error during sign up: $e');
      rethrow; // Rethrow unexpected errors
    }
  }

  /// Creates a user document in Firestore with default values
  Future<void> _createUserDocument(String userId, String email) async {
    try {
      // Check if user document already exists
      final userDocRef = _firestore.collection('users').doc(userId);
      final userDoc = await userDocRef.get();

      if (!userDoc.exists) {
        // Create user document with default values
        await userDocRef.set({
          'userId': userId,
          'email': email,
          'displayName':
              email.split('@')[0], // Use part of email as initial display name
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'isAdmin': false,
          'preferences': {
            'theme': 'system',
            'notifications': true,
          },
        });

        // Create default nutrition goals for the user
        await userDocRef.collection('nutrition_goals').doc(userId).set({
          'userId': userId,
          'calorieGoal': 2000,
          'proteinGoal': 150,
          'carbsGoal': 200,
          'fatGoal': 65,
          'waterGoal': 2000,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        debugPrint('User document created successfully for user: $userId');
      } else {
        debugPrint('User document already exists for user: $userId');
      }
    } catch (e) {
      debugPrint('Error creating user document: $e');
      // We don't rethrow here to prevent blocking account creation if Firestore fails
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      debugPrint('Error during sign out: $e');
      rethrow; // Rethrow unexpected errors
    }
  }
}
