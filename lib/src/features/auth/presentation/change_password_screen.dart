import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common_widgets/app_scaffold.dart';
import '../application/auth_controller.dart';

/// Screen for changing user password in-app
class ChangePasswordScreen extends ConsumerStatefulWidget {
  /// Constructor
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Focus nodes for managing keyboard navigation
  final _currentPasswordFocusNode = FocusNode();
  final _newPasswordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _isLoading = false;
  String? _errorMessage;
  bool _hideCurrentPassword = true;
  bool _hideNewPassword = true;
  bool _hideConfirmPassword = true;

  // Password strength variables
  double _passwordStrength = 0.0;
  String _passwordStrengthText = 'Password Strength';
  Color _passwordStrengthColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_updatePasswordStrength);

    // Set the initial focus to the current password field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_currentPasswordFocusNode);
    });
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();

    _currentPasswordFocusNode.dispose();
    _newPasswordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();

    super.dispose();
  }

  /// Updates the password strength indicator based on the new password
  void _updatePasswordStrength() {
    final password = _newPasswordController.text;

    if (password.isEmpty) {
      setState(() {
        _passwordStrength = 0.0;
        _passwordStrengthText = 'Password Strength';
        _passwordStrengthColor = Colors.grey;
      });
      return;
    }

    // Calculate password strength
    double strength = 0;

    // Length check (up to 0.3)
    if (password.length >= 8)
      strength += 0.3;
    else if (password.length >= 6) strength += 0.15;

    // Character variety checks (each worth 0.175 = 0.7 total)
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.175; // uppercase
    if (password.contains(RegExp(r'[a-z]'))) strength += 0.175; // lowercase
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.175; // digits
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')))
      strength += 0.175; // special chars

    // Set UI elements based on strength
    Color strengthColor;
    String strengthText;

    if (strength < 0.3) {
      strengthColor = Colors.red;
      strengthText = 'Very Weak';
    } else if (strength < 0.5) {
      strengthColor = Colors.orange;
      strengthText = 'Weak';
    } else if (strength < 0.7) {
      strengthColor = Colors.yellow.shade800;
      strengthText = 'Medium';
    } else if (strength < 0.9) {
      strengthColor = Colors.lightGreen;
      strengthText = 'Strong';
    } else {
      strengthColor = Colors.green;
      strengthText = 'Very Strong';
    }

    setState(() {
      _passwordStrength = strength;
      _passwordStrengthText = strengthText;
      _passwordStrengthColor = strengthColor;
    });

    // Announce password strength to screen readers
    final String announcement =
        'Password strength is $_passwordStrengthText, ${(_passwordStrength * 100).toInt()} percent.';
    SemanticsService.announce(announcement, TextDirection.ltr);
  }

  /// Validates the password strength
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }

    if (_passwordStrength < 0.5) {
      return 'Password is too weak. Add uppercase, numbers, or special characters.';
    }

    return null;
  }

  /// Validates that passwords match
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != _newPasswordController.text) {
      return 'Passwords do not match';
    }

    return null;
  }

  Future<void> _changePassword() async {
    // Clear any previous error messages
    setState(() => _errorMessage = null);

    // Validate the form
    if (!_formKey.currentState!.validate()) {
      // Announce validation failed to screen readers
      SemanticsService.announce(
        'Form validation failed. Please correct the errors and try again.',
        TextDirection.ltr,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(authControllerProvider).changePassword(
            currentPassword: _currentPasswordController.text,
            newPassword: _newPasswordController.text,
          );

      if (mounted) {
        // Show success dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Password Changed'),
            content: const Text(
              'Your password has been changed successfully. '
              'You will need to sign in again with your new password.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Navigate to sign in screen after signing out
                  context.go('/sign-in');
                },
                child: const Text('OK'),
              ),
            ],
            semanticLabel:
                'Password changed successfully. You need to sign in again with your new password.',
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Handle specific error cases
        String errorMessage;

        if (e.toString().contains('Current password is incorrect')) {
          errorMessage = 'Current password is incorrect';
        } else if (e.toString().contains('weak-password')) {
          errorMessage = 'New password is too weak';
        } else if (e.toString().contains('requires-recent-login')) {
          errorMessage = 'Please sign in again before changing your password';
        } else {
          errorMessage = 'An error occurred. Please try again';
        }

        setState(() {
          _errorMessage = errorMessage;
        });

        // Announce error to screen readers
        SemanticsService.announce(errorMessage, TextDirection.ltr);

        // Show error in a snackbar for immediate feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Theme.of(context).colorScheme.onError,
              onPressed: _changePassword,
            ),
            duration: const Duration(
                seconds: 8), // Extended duration for accessibility
          ),
        );

        // Set focus back to the problematic field if applicable
        if (errorMessage == 'Current password is incorrect') {
          FocusScope.of(context).requestFocus(_currentPasswordFocusNode);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Change Password',
      showBackButton: true,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  label: 'Change Password Section',
                  header: true,
                  child: const Icon(
                    Icons.lock,
                    size: 64,
                    color: Colors.blue,
                    semanticLabel: 'Lock icon',
                  ),
                ),
                const SizedBox(height: 24),
                Semantics(
                  header: true,
                  child: Text(
                    'Change Your Password',
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                Semantics(
                  label: 'Password Requirements',
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Password Requirements:',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          _buildRequirementItem(
                            'At least 8 characters long',
                            icon: Icons.check_circle,
                          ),
                          _buildRequirementItem(
                            'Include uppercase and lowercase letters',
                            icon: Icons.check_circle,
                          ),
                          _buildRequirementItem(
                            'Include at least one number',
                            icon: Icons.check_circle,
                          ),
                          _buildRequirementItem(
                            'Include at least one special character (!@#\$%^&*)',
                            icon: Icons.check_circle,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Current password field
                Semantics(
                  label: 'Current Password Field',
                  hint: 'Enter your current password',
                  textField: true,
                  onTapHint: 'Enter your current password',
                  child: TextFormField(
                    controller: _currentPasswordController,
                    focusNode: _currentPasswordFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      hintText: 'Enter your current password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: ExcludeSemantics(
                        child: IconButton(
                          icon: Icon(
                            _hideCurrentPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          tooltip: _hideCurrentPassword
                              ? 'Show password'
                              : 'Hide password',
                          onPressed: () {
                            setState(() {
                              _hideCurrentPassword = !_hideCurrentPassword;
                            });
                          },
                        ),
                      ),
                      border: const OutlineInputBorder(),
                      errorText: _errorMessage,
                    ),
                    obscureText: _hideCurrentPassword,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) {
                      FocusScope.of(context)
                          .requestFocus(_newPasswordFocusNode);
                    },
                    enabled: !_isLoading,
                  ),
                ),
                const SizedBox(height: 24),

                // New password field
                Semantics(
                  label: 'New Password Field',
                  hint: 'Enter your new password',
                  textField: true,
                  onTapHint: 'Enter your new password',
                  child: TextFormField(
                    controller: _newPasswordController,
                    focusNode: _newPasswordFocusNode,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      hintText: 'Enter your new password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: ExcludeSemantics(
                        child: IconButton(
                          icon: Icon(
                            _hideNewPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          tooltip: _hideNewPassword
                              ? 'Show password'
                              : 'Hide password',
                          onPressed: () {
                            setState(() {
                              _hideNewPassword = !_hideNewPassword;
                            });
                          },
                        ),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    obscureText: _hideNewPassword,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) {
                      FocusScope.of(context)
                          .requestFocus(_confirmPasswordFocusNode);
                    },
                    validator: _validatePassword,
                    enabled: !_isLoading,
                  ),
                ),
                const SizedBox(height: 8),

                // Password strength indicator
                Semantics(
                  label: 'Password Strength Indicator',
                  value:
                      '$_passwordStrengthText, ${(_passwordStrength * 100).toInt()} percent',
                  excludeSemantics: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _passwordStrengthText,
                            style: TextStyle(
                              color: _passwordStrengthColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${(_passwordStrength * 100).toInt()}%',
                            style: TextStyle(
                              color: _passwordStrengthColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: _passwordStrength,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            _passwordStrengthColor),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                        semanticsLabel:
                            'Password strength: $_passwordStrengthText',
                        semanticsValue:
                            '${(_passwordStrength * 100).toInt()} percent',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Confirm password field
                Semantics(
                  label: 'Confirm New Password Field',
                  hint: 'Confirm your new password',
                  textField: true,
                  onTapHint: 'Confirm your new password',
                  child: TextFormField(
                    controller: _confirmPasswordController,
                    focusNode: _confirmPasswordFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      hintText: 'Confirm your new password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: ExcludeSemantics(
                        child: IconButton(
                          icon: Icon(
                            _hideConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          tooltip: _hideConfirmPassword
                              ? 'Show password'
                              : 'Hide password',
                          onPressed: () {
                            setState(() {
                              _hideConfirmPassword = !_hideConfirmPassword;
                            });
                          },
                        ),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    obscureText: _hideConfirmPassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _changePassword(),
                    validator: _validateConfirmPassword,
                    enabled: !_isLoading,
                  ),
                ),
                const SizedBox(height: 32),

                // Submit button
                Semantics(
                  button: true,
                  enabled: !_isLoading,
                  label: _isLoading
                      ? 'Changing password...'
                      : 'Change password button',
                  onTapHint: 'Submits form to change your password',
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _changePassword,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      disabledBackgroundColor:
                          theme.colorScheme.primary.withOpacity(0.6),
                      disabledForegroundColor:
                          theme.colorScheme.onPrimary.withOpacity(0.8),
                      minimumSize: const Size(
                          double.infinity, 50), // Larger touch target
                    ),
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Changing Password...',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                            ],
                          )
                        : const Text('Change Password'),
                  ),
                ),
                const SizedBox(height: 16),

                // Cancel button
                Semantics(
                  button: true,
                  enabled: !_isLoading,
                  label: 'Cancel button',
                  onTapHint:
                      'Cancels password change and returns to previous screen',
                  child: TextButton(
                    onPressed: _isLoading ? null : () => context.pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(
                          double.infinity, 50), // Larger touch target
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequirementItem(String text, {required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: MergeSemantics(
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text),
            ),
          ],
        ),
      ),
    );
  }
}
