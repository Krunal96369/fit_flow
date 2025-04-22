import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common_widgets/error_dialog.dart';
import '../../../services/error/error_service.dart';
import '../../../services/theme/custom_colors.dart';
import '../../auth/application/auth_controller.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _confirmDeleteTyped = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // Get CustomColors with fallback
  CustomColors? _getCustomColors() {
    final theme = Theme.of(context);
    return theme.extension<CustomColors>();
  }

  // Get danger color with fallback
  Color _getDangerColor() {
    final customColors = _getCustomColors();
    return customColors?.danger ?? Colors.red;
  }

  // Get onDanger color with fallback
  Color _getOnDangerColor() {
    final customColors = _getCustomColors();
    return customColors?.onDanger ?? Colors.white;
  }

  // Get success color with fallback
  Color _getSuccessColor() {
    final customColors = _getCustomColors();
    return customColors?.success ?? Colors.green;
  }

  Future<void> _deleteAccount() async {
    // Validate inputs
    final password = _passwordController.text.trim();
    final confirmText = _confirmController.text.trim();

    if (password.isEmpty) {
      _showSnackbar('Please enter your password', false);
      return;
    }

    if (confirmText != 'DELETE') {
      _showSnackbar('Please type DELETE to confirm account deletion', false);
      return;
    }

    // Show final confirmation dialog
    final confirmed = await _showConfirmationDialog();
    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authController = ref.read(authControllerProvider);
      final success = await authController.deleteAccount(password);

      if (!mounted) return;

      if (success) {
        _showSnackbar('Account successfully deleted', true);

        // Navigate back to login screen after a short delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            context.go('/sign-in');
          }
        });
      } else {
        _showSnackbar(
            'Failed to delete account. Please check your password and try again.',
            false);
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (errorContext) => ErrorDialog(
            errorType: ErrorType.authentication,
            technicalMessage: e.toString(),
            onRetry: _deleteAccount,
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

  Future<bool> _showConfirmationDialog() async {
    final theme = Theme.of(context);
    final dangerColor = _getDangerColor();
    final onDangerColor = _getOnDangerColor();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Semantics(
          header: true,
          child: Text(
            'Permanently Delete Account?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: dangerColor,
            ),
          ),
        ),
        content: Semantics(
          label: 'Warning about permanent account deletion',
          child: const Text(
              'This action cannot be undone. All your data will be permanently deleted.\n\n'
              'Are you absolutely sure you want to delete your account?'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          Semantics(
            button: true,
            label: 'Confirm permanent account deletion',
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: dangerColor,
                foregroundColor: onDangerColor,
              ),
              child: const Text('Yes, Delete My Account'),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _showSnackbar(String message, bool isSuccess) {
    final theme = Theme.of(context);
    final successColor = _getSuccessColor();
    final dangerColor = _getDangerColor();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? successColor : dangerColor,
        duration:
            isSuccess ? const Duration(seconds: 2) : const Duration(seconds: 4),
      ),
    );
  }

  void _updateDeleteConfirmation(String value) {
    setState(() {
      _confirmDeleteTyped = value.trim() == 'DELETE';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dangerColor = _getDangerColor();
    final onDangerColor = _getOnDangerColor();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delete Account'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: theme.colorScheme.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Delete Your Account',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              label: 'Warning about account deletion consequences',
              child: const Text(
                'This action is permanent and cannot be undone. If you delete your account:',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              label: 'Warning points about data deletion',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWarningPoint(
                    icon: Icons.person_off,
                    text:
                        'Your profile information will be permanently deleted',
                  ),
                  _buildWarningPoint(
                    icon: Icons.fitness_center_outlined,
                    text:
                        'All your workout history will be permanently deleted',
                  ),
                  _buildWarningPoint(
                    icon: Icons.restaurant,
                    text: 'All your nutrition data will be permanently deleted',
                  ),
                  _buildWarningPoint(
                    icon: Icons.favorite_border,
                    text: 'Your health data will be permanently deleted',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            Text(
              'Confirm Account Deletion',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'To delete your account, enter your password and type DELETE in the confirmation field.',
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Your Password',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              obscureText: _obscurePassword,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmController,
              decoration: const InputDecoration(
                labelText: 'Type DELETE to confirm',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.delete_forever),
                helperText: 'Type the word DELETE in all capital letters',
              ),
              onChanged: _updateDeleteConfirmation,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (_confirmDeleteTyped && !_isLoading) {
                  _deleteAccount();
                }
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: Semantics(
                label: 'Permanently delete my account',
                button: true,
                enabled: !_isLoading && _confirmDeleteTyped,
                child: ElevatedButton(
                  onPressed: _isLoading || !_confirmDeleteTyped
                      ? null
                      : _deleteAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dangerColor,
                    foregroundColor: onDangerColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    disabledBackgroundColor: dangerColor.withOpacity(0.3),
                    disabledForegroundColor: onDangerColor.withOpacity(0.5),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: onDangerColor,
                          ),
                        )
                      : const Text(
                          'Delete My Account Permanently',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningPoint({
    required IconData icon,
    required String text,
  }) {
    final theme = Theme.of(context);
    final dangerColor = _getDangerColor();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: dangerColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
