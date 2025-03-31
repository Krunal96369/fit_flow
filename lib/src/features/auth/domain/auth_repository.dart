import 'package:firebase_auth/firebase_auth.dart'; // For User type

import 'models/auth_credentials.dart';

/// Abstract interface for authentication operations.
/// Defines the contract for interacting with authentication services.
abstract class AuthRepository {
  /// Stream of authentication state changes. Emits the current [User] or null.
  Stream<User?> authStateChanges();

  /// Returns the currently signed-in user, or null if none.
  User? get currentUser;

  /// Signs in a user with the provided email and password credentials.
  /// Throws specific exceptions on failure (e.g., InvalidCredentialsException).
  Future<void> signInWithCredentials(SignInCredentials credentials);

  /// Creates a new user account with the provided email and password credentials.
  /// Throws specific exceptions on failure (e.g., EmailInUseException).
  Future<void> createUserWithCredentials(SignUpCredentials credentials);

  /// Signs out the current user.
  Future<void> signOut();
}
