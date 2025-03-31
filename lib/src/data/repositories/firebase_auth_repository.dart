import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

import '../../features/auth/domain/auth_repository.dart';
import '../../features/auth/domain/models/auth_credentials.dart';

/// Firebase implementation of the [AuthRepository].
/// Handles authentication using the FirebaseAuth SDK.
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth;

  /// Creates a [FirebaseAuthRepository].
  /// Requires a [FirebaseAuth] instance.
  const FirebaseAuthRepository(this._firebaseAuth);

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
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: credentials.email,
        password: credentials.password,
      );
      // TODO: Add logic here to create user profile in Firestore if needed
    } on FirebaseAuthException catch (e) {
      // TODO: Consider mapping FirebaseAuthException codes to custom domain exceptions
      // e.g., 'email-already-in-use' -> EmailInUseException
      debugPrint('FirebaseAuthException during sign up: ${e.code}');
      rethrow; // Rethrow the original exception for now
    } catch (e) {
      debugPrint('Unexpected error during sign up: $e');
      rethrow; // Rethrow unexpected errors
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
