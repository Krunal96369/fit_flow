import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

import '../../features/auth/domain/auth_repository.dart';
import '../../features/auth/domain/models/auth_credentials.dart';
import '../../services/biometric/biometric_service.dart';
import '../../services/secure_storage/secure_storage_service.dart';

/// Firebase implementation of the [AuthRepository].
/// Handles authentication using the FirebaseAuth SDK.
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final BiometricService _biometricService;
  final SecureStorageService _secureStorage;

  // Keys for secure storage
  static const String _emailKey = 'auth_email';
  static const String _passwordKey = 'auth_password';
  static const String _biometricEnabledKey = 'biometric_enabled';

  /// Creates a [FirebaseAuthRepository].
  /// Requires a [FirebaseAuth] instance.
  FirebaseAuthRepository(
    this._firebaseAuth, {
    required BiometricService biometricService,
    required SecureStorageService secureStorage,
    FirebaseFirestore? firestore,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _biometricService = biometricService,
        _secureStorage = secureStorage {
    // Print the secure storage service type during initialization to verify we're using the right implementation
    debugPrint(
        'FirebaseAuthRepository: Using secure storage implementation: ${_secureStorage.runtimeType}');
  }

  @override
  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  Future<void> signInWithCredentials(SignInCredentials credentials) async {
    try {
      debugPrint('Signing in with credentials for: ${credentials.email}');
      await _firebaseAuth.signInWithEmailAndPassword(
        email: credentials.email,
        password: credentials.password,
      );
      debugPrint(
          'Successfully signed in with credentials for: ${credentials.email}');
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

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      debugPrint('Error during sign out: $e');
      rethrow; // Rethrow unexpected errors
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during password reset: ${e.code}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error during password reset: $e');
      rethrow;
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // Get the current user
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user');
      }

      // Get auth credentials for the current user email and password
      final email = user.email;
      if (email == null) {
        throw Exception('User has no email');
      }

      // Re-authenticate to verify current password
      final credentials = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credentials);

      // Update the password
      await user.updatePassword(newPassword);

      // If biometric auth is enabled, update the stored password
      final biometricsEnabled = await isBiometricAuthEnabled();
      if (biometricsEnabled) {
        await _secureStorage.setSecureData(_passwordKey, newPassword);
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during change password: ${e.code}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error during change password: $e');
      rethrow;
    }
  }

  /// Store user credentials securely without enabling biometrics
  @override
  Future<bool> storeCredentials({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('storeCredentials: Storing email: $email');

      // Store the credentials securely
      final emailSaved = await _secureStorage.setSecureData(
        _emailKey,
        email,
      );

      final passwordSaved = await _secureStorage.setSecureData(
        _passwordKey,
        password,
      );

      return emailSaved && passwordSaved;
    } catch (e) {
      debugPrint('Error storing credentials: $e');
      return false;
    }
  }

  @override
  Future<bool> enableBiometricAuth(SignInCredentials credentials) async {
    try {
      debugPrint(
          'enableBiometricAuth: Starting with email: ${credentials.email.isNotEmpty ? credentials.email : "empty"}');
      // First check if the device supports biometrics
      final biometricsAvailable =
          await _biometricService.isBiometricsAvailable();
      if (!biometricsAvailable) {
        debugPrint('Biometrics not available on this device');
        return false;
      }

      // Check if we have a current user already logged in
      final currentUser = _firebaseAuth.currentUser;
      String email;
      String password;

      // If credentials are empty, try to use stored credentials for the current user
      if (credentials.email.isEmpty && credentials.password.isEmpty) {
        debugPrint('enableBiometricAuth: Trying to use stored credentials');

        if (currentUser == null) {
          debugPrint('Cannot enable biometrics: no logged in user');
          return false;
        }

        email = currentUser.email ?? '';
        if (email.isEmpty) {
          debugPrint('Cannot enable biometrics: user has no email');
          return false;
        }

        // Check if we already have stored credentials
        final storedEmail = await _secureStorage.getSecureData(_emailKey);
        final storedPassword = await _secureStorage.getSecureData(_passwordKey);

        if (storedEmail == null || storedPassword == null) {
          debugPrint('Cannot enable biometrics: no stored credentials');
          return false;
        }

        // Use the stored credentials
        password = storedPassword;
        debugPrint(
            'enableBiometricAuth: Using stored credentials for current user');
      } else {
        // Use the provided credentials
        email = credentials.email;
        password = credentials.password;

        // Verify the credentials if user is not already logged in with these credentials
        if (currentUser == null || currentUser.email != email) {
          try {
            debugPrint('enableBiometricAuth: Verifying provided credentials');
            await _firebaseAuth.signInWithEmailAndPassword(
              email: email,
              password: password,
            );
          } catch (e) {
            debugPrint('Failed to verify credentials: $e');
            return false;
          }
        }

        // Store the credentials if not already stored
        await storeCredentials(email: email, password: password);
      }

      // Set the biometrics enabled flag
      debugPrint('enableBiometricAuth: Setting biometrics enabled flag');
      final flagSaved =
          await _secureStorage.setSecureData(_biometricEnabledKey, 'true');

      if (flagSaved) {
        await _biometricService.setBiometricsEnabled(true);
        debugPrint('Biometric authentication enabled successfully');
        return true;
      } else {
        debugPrint('Failed to save biometrics enabled flag');
        return false;
      }
    } catch (e) {
      debugPrint('Error enabling biometric auth: $e');
      return false;
    }
  }

  @override
  Future<bool> disableBiometricAuth() async {
    try {
      // Delete the stored credentials
      await _secureStorage.deleteSecureData(_emailKey);
      await _secureStorage.deleteSecureData(_passwordKey);
      await _secureStorage.deleteSecureData(_biometricEnabledKey);
      return true;
    } catch (e) {
      debugPrint('Error disabling biometric auth: $e');
      return false;
    }
  }

  @override
  Future<bool> isBiometricAuthEnabled() async {
    try {
      final value = await _secureStorage.getSecureData(_biometricEnabledKey);
      return value == 'true';
    } catch (e) {
      debugPrint('Error checking if biometric auth is enabled: $e');
      return false;
    }
  }

  /// Check if credentials are already stored for the current user
  Future<bool> hasStoredCredentials() async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null || currentUser.email == null) {
        debugPrint('HasStoredCredentials: No current user or email is null');
        return false;
      }

      final storedEmail = await _secureStorage.getSecureData(_emailKey);
      final storedPassword = await _secureStorage.getSecureData(_passwordKey);

      // If we have a current user and stored credentials don't match the current user,
      // but we have valid stored credentials, update the stored email to match the current user
      if (storedEmail != currentUser.email && storedPassword != null) {
        debugPrint(
            'HasStoredCredentials: Updating stored email to match current user');
        await _secureStorage.setSecureData(_emailKey, currentUser.email!);
        return true;
      }

      return storedEmail == currentUser.email && storedPassword != null;
    } catch (e) {
      debugPrint('Error checking for stored credentials: $e');
      return false;
    }
  }

  @override
  Future<bool> signInWithBiometrics() async {
    try {
      // First check if biometric auth is enabled
      final enabled = await isBiometricAuthEnabled();
      if (!enabled) {
        debugPrint('Biometric auth not enabled for this user');
        return false;
      }

      // Authenticate with biometrics
      final authenticated = await _biometricService.authenticate(
        localizedReason: 'Authenticate to access FitFlow',
      );

      if (!authenticated) {
        debugPrint('Biometric authentication failed');
        return false;
      }

      // Retrieve stored credentials
      final email = await _secureStorage.getSecureData(_emailKey);
      final password = await _secureStorage.getSecureData(_passwordKey);

      if (email == null || password == null) {
        debugPrint('Stored credentials not found');
        return false;
      }

      // Sign in with the stored credentials
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during biometric sign in: ${e.code}');
      return false;
    } catch (e) {
      debugPrint('Error during biometric sign in: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteAccount(String password) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        debugPrint('Cannot delete account: No authenticated user');
        return false;
      }

      final email = user.email;
      if (email == null) {
        debugPrint('Cannot delete account: User has no email');
        return false;
      }

      final userId = user.uid;

      // Re-authenticate the user for security
      debugPrint('Re-authenticating user before account deletion');
      final credentials = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      await user.reauthenticateWithCredential(credentials);

      // Delete user data from Firestore
      debugPrint('Deleting user data from Firestore');
      await _deleteUserData(userId);

      // Delete any stored biometric credentials
      debugPrint('Deleting stored biometric credentials');
      await disableBiometricAuth();

      // Delete the user account from Firebase Auth
      debugPrint('Deleting user account');
      await user.delete();

      debugPrint('Account successfully deleted');
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during account deletion: ${e.code}');
      if (e.code == 'requires-recent-login') {
        debugPrint('User needs to re-authenticate before deletion');
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting account: $e');
      return false;
    }
  }

  /// Deletes all user data from Firestore
  Future<void> _deleteUserData(String userId) async {
    try {
      // Delete user profile
      final userProfileRef = _firestore.collection('user_profiles').doc(userId);
      await userProfileRef.delete();

      // Get user document reference
      final userDocRef = _firestore.collection('users').doc(userId);

      // Delete user's nutrition entries
      final entriesCollection = userDocRef.collection('nutrition_entries');
      await _deleteCollection(entriesCollection);

      // Delete user's nutrition goals
      final goalsCollection = userDocRef.collection('nutrition_goals');
      await _deleteCollection(goalsCollection);

      // Delete user's workout data
      final workoutsCollection = userDocRef.collection('workouts');
      await _deleteCollection(workoutsCollection);

      // Delete user's food favorites and recent foods
      final favoritesCollection = userDocRef.collection('food_favorites');
      await _deleteCollection(favoritesCollection);

      final recentFoodsCollection = userDocRef.collection('recent_foods');
      await _deleteCollection(recentFoodsCollection);

      // Finally delete the main user document
      await userDocRef.delete();

      debugPrint('All user data deleted from Firestore');
    } catch (e) {
      debugPrint('Error deleting user data: $e');
      // Don't rethrow to ensure account deletion completes even if data deletion fails
    }
  }

  /// Helper method to delete a collection
  Future<void> _deleteCollection(CollectionReference collection) async {
    final batchSize = 100;
    var query = collection.limit(batchSize);

    var deleted = 0;

    while (true) {
      final snapshot = await query.get();
      final size = snapshot.size;

      if (size == 0) {
        break;
      }

      // Delete documents in a batch
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      deleted += size;

      if (size < batchSize) {
        break;
      }
    }

    debugPrint('Deleted $deleted documents from collection ${collection.path}');
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
}
