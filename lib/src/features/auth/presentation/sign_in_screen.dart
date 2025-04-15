import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';

import '../application/auth_controller.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isEmailLogin = true;
  bool _isOtpSent = false;
  bool _isBiometricsAvailable = false;
  bool _obscurePassword = true;
  String? _verificationId;

  // Animation controller for transitions
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Track full phone number with country code
  String _fullPhoneNumber = '';

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _animationController.forward();
  }

  Future<void> _checkBiometricAvailability() async {
    if (!mounted) return;

    final authController = ref.read(authControllerProvider);
    final isBiometricsAvailable = await authController.isBiometricsAvailable();
    final isBiometricAuthEnabled =
        await authController.isBiometricAuthEnabled();

    if (mounted) {
      setState(() {
        _isBiometricsAvailable =
            isBiometricsAvailable && isBiometricAuthEnabled;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _signInWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Validate input
    if (email.isEmpty || password.isEmpty) {
      _showSnackbar(
        message: 'Please enter email and password',
        icon: Icons.error_outline,
        isSuccess: false,
      );
      return;
    }

    // Check for valid email format
    final bool isValidEmail = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
    if (!isValidEmail) {
      _showSnackbar(
        message: 'Please enter a valid email address',
        icon: Icons.error_outline,
        isSuccess: false,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Login with provided credentials
      await ref.read(authControllerProvider).signInWithEmailAndPassword(
            email: email,
            password: password,
          );

      // Save credentials for later biometric use without enabling biometrics yet
      final authController = ref.read(authControllerProvider);

      // Store the credentials but don't enable biometrics yet
      await authController.enableBiometricAuth(
        email: email,
        password: password,
      );

      // Check if biometrics are already enabled to show the biometric login option
      final isBiometricsAvailable =
          await authController.isBiometricsAvailable();

      if (isBiometricsAvailable) {
        // Check if biometrics are already enabled
        final isBiometricAuthEnabled =
            await authController.isBiometricAuthEnabled();
        if (isBiometricAuthEnabled) {
          // Update UI to show biometric option
          if (mounted) {
            setState(() {
              _isBiometricsAvailable = true;
            });
          }
        }
      }

      // Show success message briefly before navigation happens
      _showSnackbar(
        message: 'Sign in successful!',
        icon: Icons.check_circle,
        isSuccess: true,
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage = 'Authentication failed';

        // Provide more user-friendly error messages
        if (e.code == 'user-not-found') {
          errorMessage = 'No account found with this email';
        } else if (e.code == 'wrong-password') {
          errorMessage = 'Incorrect password, please try again';
        } else if (e.code == 'invalid-credential') {
          errorMessage = 'Invalid credentials, please try again';
        } else if (e.code == 'user-disabled') {
          errorMessage = 'This account has been disabled';
        } else if (e.code == 'too-many-requests') {
          errorMessage = 'Too many attempts, please try again later';
        } else if (e.code == 'network-request-failed') {
          errorMessage = 'Network error, please check your connection';
        }

        _showSnackbar(
          message: errorMessage,
          icon: Icons.error_outline,
          isSuccess: false,
        );

        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar(
          message: 'Error: ${e.toString()}',
          icon: Icons.error_outline,
          isSuccess: false,
        );

        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _signInWithBiometrics() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Show prompt to explain biometric authentication
      _showSnackbar(
        message: 'Scan your fingerprint/face to sign in',
        icon: Icons.fingerprint,
        isSuccess: true,
      );

      final success =
          await ref.read(authControllerProvider).signInWithBiometrics();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (!success) {
          _showSnackbar(
            message: 'Biometric authentication failed',
            icon: Icons.error_outline,
            isSuccess: false,
          );
        } else {
          // Show success message briefly before navigation happens
          _showSnackbar(
            message: 'Sign in successful!',
            icon: Icons.check_circle,
            isSuccess: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        String errorMessage = 'Biometric authentication failed';

        // Handle specific biometric error cases
        if (e.toString().contains('NotAvailable')) {
          errorMessage = 'Biometrics not available on this device';
        } else if (e.toString().contains('NotEnrolled')) {
          errorMessage = 'No biometrics enrolled on your device';
        } else if (e.toString().contains('LockedOut')) {
          errorMessage = 'Biometrics locked out due to too many attempts';
        } else if (e.toString().contains('PermanentlyLockedOut')) {
          errorMessage = 'Biometrics permanently locked out';
        }

        _showSnackbar(
          message: errorMessage,
          icon: Icons.error_outline,
          isSuccess: false,
        );
      }
    }
  }

  // Helper method to show themed snackbar messages
  void _showSnackbar({
    required String message,
    required IconData icon,
    required bool isSuccess,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isSuccess ? Colors.green.shade700 : Colors.red.shade700,
        duration: isSuccess ? Duration(seconds: 1) : Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App Logo/Branding
                Hero(
                  tag: 'app_logo',
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.fitness_center,
                      size: 80,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome to FitFlow',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to track your fitness journey',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color
                        ?.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 32),
                _buildToggleButtons(),
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isEmailLogin
                      ? _buildEmailForm()
                      : _isOtpSent
                          ? _buildOtpForm()
                          : _buildPhoneForm(),
                ),
                const SizedBox(height: 20),
                if (_isBiometricsAvailable) ...[
                  Divider(
                      height: 40,
                      color: theme.dividerColor.withValues(alpha: 0.5)),
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _signInWithBiometrics,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Sign in with biometrics'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: theme.colorScheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?",
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color
                            ?.withValues(alpha: 0.7),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        context.go('/sign-up');
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: Text(
                        "Sign Up",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButtons() {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment<bool>(
          value: true,
          label: Text('Email'),
          icon: Icon(Icons.email),
        ),
        ButtonSegment<bool>(
          value: false,
          label: Text('Phone'),
          icon: Icon(Icons.phone),
        ),
      ],
      selected: {_isEmailLogin},
      onSelectionChanged: (Set<bool> newSelection) {
        setState(() {
          _isEmailLogin = newSelection.first;
          _isOtpSent = false;
        });
      },
      style: ButtonStyle(
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailForm() {
    return Column(
      key: const ValueKey('email_form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: const Icon(Icons.email),
            filled: true,
            fillColor: Theme.of(context).cardColor,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autocorrect: false,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: 'Enter your password',
            prefixIcon: const Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Theme.of(context).cardColor,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _signInWithEmail(),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              final router = GoRouter.of(context);
              router.push('/reset-password?source=signin');
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Forgot Password?'),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _signInWithEmail,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Sign In'),
        ),
      ],
    );
  }

  Widget _buildOtpForm() {
    return Column(
      key: const ValueKey('otp_form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _otpController,
          decoration: InputDecoration(
            labelText: 'OTP Code',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: const Icon(Icons.security),
            hintText: '6-digit code',
            filled: true,
            fillColor: Theme.of(context).cardColor,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          maxLength: 6,
          onSubmitted: (_) => _verifyOtp(),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _verifyOtp,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Verify & Sign In'),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: _isLoading
              ? null
              : () {
                  setState(() {
                    _isOtpSent = false;
                  });
                },
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('Change Phone Number'),
          style: TextButton.styleFrom(
            alignment: Alignment.center,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneForm() {
    return Column(
      key: const ValueKey('phone_form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntlPhoneField(
          decoration: InputDecoration(
            labelText: 'Phone Number',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            counterText: '',
            filled: true,
            fillColor: Theme.of(context).cardColor,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
          initialCountryCode: 'US',
          disableLengthCheck: false,
          invalidNumberMessage: 'Invalid phone number',
          dropdownIconPosition: IconPosition.trailing,
          flagsButtonPadding: const EdgeInsets.all(8),
          onChanged: (PhoneNumber number) {
            // Save complete number with country code
            _fullPhoneNumber = number.completeNumber;
          },
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _sendOtp,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Send OTP'),
        ),
      ],
    );
  }

  void _sendOtp() async {
    if (_fullPhoneNumber.isEmpty) {
      _showSnackbar(
        message: 'Please enter your phone number',
        icon: Icons.error_outline,
        isSuccess: false,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authControllerProvider).verifyPhoneNumber(
            phoneNumber: _fullPhoneNumber,
            verificationCompleted: (PhoneAuthCredential credential) async {
              // Auto-verification completed (Android only)
              _showSnackbar(
                message: 'Verification completed automatically',
                icon: Icons.check_circle,
                isSuccess: true,
              );

              setState(() {
                _isLoading = true;
              });

              try {
                await ref
                    .read(authControllerProvider)
                    .signInWithCredential(credential);

                // Show success briefly before navigation
                _showSnackbar(
                  message: 'Sign in successful!',
                  icon: Icons.check_circle,
                  isSuccess: true,
                );
              } catch (e) {
                if (mounted) {
                  _showSnackbar(
                    message: 'Auto-verification failed: ${e.toString()}',
                    icon: Icons.error_outline,
                    isSuccess: false,
                  );
                }
              } finally {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              }
            },
            verificationFailed: (FirebaseAuthException e) {
              String errorMessage = 'Verification failed';

              // Handle common error cases
              if (e.code == 'invalid-phone-number') {
                errorMessage = 'Invalid phone number format';
              } else if (e.code == 'too-many-requests') {
                errorMessage = 'Too many attempts, try again later';
              } else if (e.code == 'quota-exceeded') {
                errorMessage = 'Service temporarily unavailable';
              } else if (e.message != null) {
                errorMessage = e.message!;
              }

              _showSnackbar(
                message: errorMessage,
                icon: Icons.error_outline,
                isSuccess: false,
              );
              setState(() {
                _isLoading = false;
              });
            },
            codeSent: (String verificationId, int? resendToken) {
              setState(() {
                _verificationId = verificationId;
                _isOtpSent = true;
                _isLoading = false;
              });
              _showSnackbar(
                message: 'OTP sent to your phone',
                icon: Icons.message,
                isSuccess: true,
              );
            },
            codeAutoRetrievalTimeout: (String verificationId) {
              setState(() {
                _verificationId = verificationId;
              });
            },
          );
    } catch (e) {
      if (mounted) {
        _showSnackbar(
          message: 'Error sending OTP: ${e.toString()}',
          icon: Icons.error_outline,
          isSuccess: false,
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _verifyOtp() async {
    final otp = _otpController.text.trim();

    if (otp.isEmpty) {
      _showSnackbar(
        message: 'Please enter the OTP',
        icon: Icons.error_outline,
        isSuccess: false,
      );
      return;
    }

    if (otp.length < 6) {
      _showSnackbar(
        message: 'OTP must be 6 digits',
        icon: Icons.error_outline,
        isSuccess: false,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      await ref.read(authControllerProvider).signInWithCredential(credential);

      // Show success message briefly before navigation happens
      _showSnackbar(
        message: 'Sign in successful!',
        icon: Icons.check_circle,
        isSuccess: true,
      );
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Verification failed';

        if (e is FirebaseAuthException) {
          if (e.code == 'invalid-verification-code') {
            errorMessage = 'Invalid OTP code, please try again';
          } else if (e.code == 'session-expired') {
            errorMessage = 'OTP session expired. Please request a new code';
          } else if (e.message != null) {
            errorMessage = e.message!;
          }
        }

        _showSnackbar(
          message: errorMessage,
          icon: Icons.error_outline,
          isSuccess: false,
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
