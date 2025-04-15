import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for the BiometricService
final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricServiceImpl();
});

/// Service that handles biometric authentication (fingerprint, face ID)
abstract class BiometricService {
  /// Check if the device supports biometric authentication
  Future<bool> isBiometricsAvailable();

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics();

  /// Authenticate user with biometrics
  Future<bool> authenticate({
    required String localizedReason,
    bool useErrorDialogs = true,
  });

  /// Check if biometric authentication is enabled by user preference
  Future<bool> isBiometricsEnabled();

  /// Enable or disable biometric authentication in user preferences
  Future<void> setBiometricsEnabled(bool enabled);
}

/// Implementation of BiometricService that uses local_auth package
class BiometricServiceImpl implements BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();
  static const String _biometricEnabledKey = 'biometrics_enabled';

  @override
  Future<bool> isBiometricsAvailable() async {
    try {
      final canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final canAuthenticate = await _auth.isDeviceSupported();
      return canAuthenticateWithBiometrics && canAuthenticate;
    } on PlatformException catch (e) {
      debugPrint('Error checking biometrics availability: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Unexpected error checking biometrics: $e');
      return false;
    }
  }

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      debugPrint('Error getting available biometrics: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('Unexpected error getting biometrics: $e');
      return [];
    }
  }

  @override
  Future<bool> authenticate({
    required String localizedReason,
    bool useErrorDialogs = true,
  }) async {
    try {
      // First check if biometrics are available
      final biometricsAvailable = await isBiometricsAvailable();
      if (!biometricsAvailable) {
        return false;
      }

      return await _auth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: useErrorDialogs,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('Error authenticating: ${e.message}');
      // Handle specific error cases
      if (e.code == auth_error.notAvailable) {
        debugPrint('Biometrics not available on this device');
      } else if (e.code == auth_error.notEnrolled) {
        debugPrint('No biometrics enrolled on this device');
      } else if (e.code == auth_error.lockedOut) {
        debugPrint('Biometrics locked out due to too many attempts');
      } else if (e.code == auth_error.permanentlyLockedOut) {
        debugPrint('Biometrics permanently locked out');
      }
      return false;
    } catch (e) {
      debugPrint('Unexpected error during authentication: $e');
      return false;
    }
  }

  @override
  Future<bool> isBiometricsEnabled() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      // Default to false if not set
      return preferences.getBool(_biometricEnabledKey) ?? false;
    } catch (e) {
      debugPrint('Error reading biometrics preference: $e');
      return false;
    }
  }

  @override
  Future<void> setBiometricsEnabled(bool enabled) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_biometricEnabledKey, enabled);
    } catch (e) {
      debugPrint('Error saving biometrics preference: $e');
    }
  }
}
