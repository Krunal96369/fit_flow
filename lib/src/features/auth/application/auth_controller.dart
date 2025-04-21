import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../../data/repositories/firebase_auth_repository.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../services/biometric/biometric_service.dart' as bio_service;
import '../../onboarding/application/onboarding_controller.dart';
import '../domain/auth_repository.dart';
import '../domain/models/auth_credentials.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Provider for the AuthController
final authControllerProvider = Provider<AuthController>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final biometricService = ref.watch(bio_service.biometricServiceProvider);
  return AuthController(
      FirebaseAuth.instance, authRepository, ref, biometricService);
});

class AuthController {
  final FirebaseAuth _auth;
  final AuthRepository _authRepository;
  final Ref _ref;
  final bio_service.BiometricService _biometricService;

  AuthController(
      this._auth, this._authRepository, this._ref, this._biometricService);

  /// Sign in with email and password
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _authRepository.signInWithCredentials(
      SignInCredentials(email: email, password: password),
    );
  }

  /// Create user with email and password
  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _authRepository.createUserWithCredentials(
      SignUpCredentials(email: email, password: password),
    );

    /// Reset onboarding status for new users
    await _ref.read(onboardingCompletedProvider.notifier).resetOnboarding();
  }

  /// Sign in with credential
  Future<void> signInWithCredential(AuthCredential credential) async {
    await _auth.signInWithCredential(credential);
  }

  /// Verify phone number
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(PhoneAuthCredential) verificationCompleted,
    required void Function(FirebaseAuthException) verificationFailed,
    required void Function(String, int?) codeSent,
    required void Function(String) codeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  /// Sign out current user
  Future<void> signOut() async {
    await _authRepository.signOut();
  }

  /// Send password reset email
  Future<void> resetPassword(String email) async {
    await _authRepository.resetPassword(email);
  }

  /// Change password for authenticated user
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _authRepository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  /// Get current authenticated user
  User? get currentUser => _auth.currentUser;

  /// Check if biometric authentication is available on the device
  Future<bool> isBiometricsAvailable() async {
    return _biometricService.isBiometricsAvailable();
  }

  /// Get available biometric types (e.g. fingerprint, face)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    return _biometricService.getAvailableBiometrics();
  }

  Future<bool> enableBiometricAuth({
    required String email,
    required String password,
  }) async {
    return _authRepository.enableBiometricAuth(
      SignInCredentials(email: email, password: password),
    );
  }

  Future<bool> enableBiometricAuthForCurrentUser() async {
    return _authRepository.enableBiometricAuth(SignInCredentials.empty());
  }

  /// Disable biometric authentication for the current user
  Future<bool> disableBiometricAuth() async {
    return _authRepository.disableBiometricAuth();
  }

  /// Check if biometric authentication is enabled for the current user
  Future<bool> isBiometricAuthEnabled() async {
    return _authRepository.isBiometricAuthEnabled();
  }

  /// Check if credentials are stored for the current user
  Future<bool> hasStoredCredentials() async {
    return (_authRepository as FirebaseAuthRepository).hasStoredCredentials();
  }

  /// Sign in with biometric authentication
  Future<bool> signInWithBiometrics() async {
    return _authRepository.signInWithBiometrics();
  }
}
