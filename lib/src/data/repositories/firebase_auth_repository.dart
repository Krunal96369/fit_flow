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

      if (currentUser != null &&
          credentials.email.isEmpty &&
          credentials.password.isEmpty) {
        debugPrint('enableBiometricAuth: Using current user credentials');
        // User is already logged in and we're enabling biometrics from settings
        // without re-entering credentials - use stored credentials
        email = currentUser.email ?? '';

        // Check if we already have a stored password for this user
        final storedPassword = await _secureStorage.getSecureData(_passwordKey);

        if (email.isEmpty) {
          debugPrint('Cannot enable biometrics: user has no email');
          return false;
        }

        if (storedPassword == null) {
          debugPrint('Cannot enable biometrics: no stored password for user');
          return false;
        }

        password = storedPassword;
        debugPrint(
            'enableBiometricAuth: Using stored password for current user: $email');

        // Use the stored credentials without verification since user is already logged in
      } else {
        // User provided specific credentials to use
        email = credentials.email;
        password = credentials.password;
        debugPrint(
            'enableBiometricAuth: Using provided credentials for: $email');

        // Only try to verify if user is not already logged in with these credentials
        if (currentUser == null || currentUser.email != email) {
          try {
            debugPrint(
                'enableBiometricAuth: Verifying credentials before storing');
            // Verify the credentials before storing
            await _firebaseAuth.signInWithEmailAndPassword(
              email: email,
              password: password,
            );
            debugPrint(
                'enableBiometricAuth: Credentials verified successfully');
          } catch (e) {
            debugPrint('Failed to verify credentials: $e');
            return false;
          }
        } else {
          debugPrint(
              'enableBiometricAuth: Skipping verification as user is already logged in');
        }
      }

      // Store the credentials securely
      debugPrint('enableBiometricAuth: Storing email: $email');
      final emailSaved = await _secureStorage.setSecureData(
        _emailKey,
        email,
      );
      debugPrint('enableBiometricAuth: Email saved: $emailSaved');

      debugPrint('enableBiometricAuth: Storing password');
      final passwordSaved = await _secureStorage.setSecureData(
        _passwordKey,
        password,
      );
      debugPrint('enableBiometricAuth: Password saved: $passwordSaved');

      // Mark biometrics as enabled
      if (emailSaved && passwordSaved) {
        debugPrint('enableBiometricAuth: Setting biometrics enabled flag');
        final flagSaved =
            await _secureStorage.setSecureData(_biometricEnabledKey, 'true');
        debugPrint('enableBiometricAuth: Flag saved: $flagSaved');

        await _biometricService.setBiometricsEnabled(true);
        debugPrint('Biometric authentication enabled successfully');

        // Let's test storage immediately to make sure we can retrieve what we just stored
        final test = await hasStoredCredentials();
        debugPrint('enableBiometricAuth: Immediate verification check: $test');

        return true;
      } else {
        // If either save failed, clean up
        debugPrint('Failed to save credentials securely');
        await _secureStorage.deleteSecureData(_emailKey);
        await _secureStorage.deleteSecureData(_passwordKey);
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
