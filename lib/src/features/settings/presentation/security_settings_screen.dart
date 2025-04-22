import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common_widgets/error_dialog.dart';
import '../../../services/error/error_service.dart';
import '../../../services/secure_storage/secure_storage_service.dart';
import '../../auth/application/auth_controller.dart';

class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  ConsumerState<SecuritySettingsScreen> createState() =>
      _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState
    extends ConsumerState<SecuritySettingsScreen> {
  bool _isLoading = false;
  bool _isBiometricsAvailable = false;
  bool _isBiometricsEnabled = false;
  bool _hasStoredCredentials = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricSettings();
  }

  Future<void> _loadBiometricSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authController = ref.read(authControllerProvider);

      // Test secure storage - This is temporary and should be removed after verifying it works
      await _testSecureStorage();

      final isBiometricsAvailable =
          await authController.isBiometricsAvailable();
      final isBiometricsEnabled = await authController.isBiometricAuthEnabled();
      final hasStoredCredentials = await authController.hasStoredCredentials();

      if (mounted) {
        setState(() {
          _isBiometricsAvailable = isBiometricsAvailable;
          _isBiometricsEnabled = isBiometricsEnabled;
          _hasStoredCredentials = hasStoredCredentials;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showDialog(
          context: context,
          builder: (errorContext) => ErrorDialog(
            errorType: ErrorType.authentication,
            technicalMessage: e.toString(),
          ),
        );
      }
    }
  }

  // Test function to verify the secure storage is working
  Future<void> _testSecureStorage() async {
    try {
      // Import directly to avoid circular dependency
      final secureStorage = ref.read(secureStorageProvider);

      // Test setting a value
      final testKey = 'test_key';
      final testValue = 'test_value_${DateTime.now().toIso8601String()}';

      debugPrint('Test: Setting secure data: $testKey = $testValue');
      final setSuccess = await secureStorage.setSecureData(testKey, testValue);
      debugPrint('Test: Set result: $setSuccess');

      // Test retrieving the value
      final retrievedValue = await secureStorage.getSecureData(testKey);
      debugPrint('Test: Retrieved value: $retrievedValue');

      // Test that it matches
      final matches = retrievedValue == testValue;
      debugPrint('Test: Values match: $matches');

      // Test containsKey
      final hasKey = await secureStorage.containsKey(testKey);
      debugPrint('Test: Contains key: $hasKey');

      // Don't delete the test key so we can verify persistence
      // await secureStorage.deleteSecureData(testKey);
    } catch (e) {
      debugPrint('Test: Error testing secure storage: $e');
    }
  }

  Future<void> _toggleBiometrics(bool value) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authController = ref.read(authControllerProvider);

      if (value) {
        // Try to enable biometrics

        // First check if user is logged in
        final currentUser = authController.currentUser;
        final bool isLoggedIn =
            currentUser != null && currentUser.email != null;

        if (!isLoggedIn) {
          // User is not logged in - show error
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'You must be logged in to enable biometric authentication')),
          );
          return;
        }

        // Check if credentials are already stored
        final hasStoredCredentials =
            await authController.hasStoredCredentials();

        if (hasStoredCredentials) {
          // If we already have credentials stored, use them to enable biometrics
          final success =
              await authController.enableBiometricAuthForCurrentUser();

          if (success) {
            setState(() {
              _isBiometricsEnabled = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Biometric authentication enabled')),
            );
          } else {
            // If enabling fails, show dialog to collect credentials
            await _showBiometricEnableDialog();
          }
        } else {
          // No stored credentials, show dialog to collect them
          await _showBiometricEnableDialog();
        }

        // Reload settings to ensure UI is updated correctly
        await _loadBiometricSettings();
      } else {
        // Disable biometric auth
        final success = await authController.disableBiometricAuth();

        if (mounted) {
          if (success) {
            setState(() {
              _isBiometricsEnabled = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Biometric authentication disabled')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Failed to disable biometric authentication')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (errorContext) => ErrorDialog(
            errorType: ErrorType.authentication,
            technicalMessage: e.toString(),
            onRetry: () => _toggleBiometrics(value),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showBiometricEnableDialog() async {
    if (!mounted) return;

    // Create controllers here but don't dispose them immediately in the then() callback
    // The controllers need to remain valid until the dialog is fully closed
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    try {
      await showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Enable Biometric Authentication'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Enter your credentials to enable biometric authentication',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final email = emailController.text.trim();
                final password = passwordController.text.trim();

                if (email.isEmpty || password.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter email and password')),
                  );
                  return;
                }

                // Return the credentials instead of starting async operation here
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Enable'),
            ),
          ],
        ),
      );

      // Now proceed with the async operation outside the dialog
      if (mounted) {
        final email = emailController.text.trim();
        final password = passwordController.text.trim();

        if (email.isNotEmpty && password.isNotEmpty) {
          try {
            setState(() {
              _isLoading = true;
            });

            final authController = ref.read(authControllerProvider);
            final success = await authController.enableBiometricAuth(
              email: email,
              password: password,
            );

            if (mounted) {
              if (success) {
                setState(() {
                  _isBiometricsEnabled = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Biometric authentication enabled')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Failed to enable biometric authentication')),
                );
              }
            }
          } catch (e) {
            if (mounted) {
              showDialog(
                context: context,
                builder: (errorContext) => ErrorDialog(
                  errorType: ErrorType.authentication,
                  technicalMessage: e.toString(),
                  onRetry: () => _toggleBiometrics(true),
                ),
              );
            }
          } finally {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          }
        }
      }
    } finally {
      // Always dispose controllers when done with the entire operation
      emailController.dispose();
      passwordController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Settings'),
      ),
      body: _isLoading &&
              (_isBiometricsAvailable == false && _isBiometricsEnabled == false)
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Authentication',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      // Password change option - now navigates to the dedicated change password screen
                      ListTile(
                        title: const Text('Change Password'),
                        leading: const Icon(Icons.password),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/change-password'),
                      ),
                      const Divider(),
                      ListTile(
                        title: const Text('Delete Account'),
                        subtitle: const Text(
                            'Permanently delete your account and all data'),
                        leading:
                            const Icon(Icons.delete_forever, color: Colors.red),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/delete-account'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Text(
                      'Biometric Authentication',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_hasStoredCredentials && !_isBiometricsEnabled)
                      Tooltip(
                        message: 'Your credentials are securely stored',
                        child: Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Colors.blue,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Use Biometric Authentication'),
                        subtitle: Text(_isBiometricsAvailable
                            ? 'Sign in with fingerprint or face recognition'
                            : 'Biometric authentication not available on this device'),
                        value: _isBiometricsEnabled,
                        onChanged: _isBiometricsAvailable
                            ? (value) => _toggleBiometrics(value)
                            : null,
                        secondary: const Icon(Icons.fingerprint),
                      ),
                      if (_isBiometricsAvailable && _isBiometricsEnabled) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            'Biometric authentication is enabled. You can sign in using your fingerprint or face recognition without entering your email and password.',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                      if (_isBiometricsAvailable &&
                          !_isBiometricsEnabled &&
                          _hasStoredCredentials) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            'Your credentials are securely stored. You can enable biometric authentication to sign in quickly.',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
