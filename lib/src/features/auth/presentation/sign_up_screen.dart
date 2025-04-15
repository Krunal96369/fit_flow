import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';

import '../application/auth_controller.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isEmailSignup = true;
  bool _isOtpSent = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _verificationId;

  // Animation controller for transitions
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Track full phone number with country code
  String _fullPhoneNumber = '';

  @override
  void initState() {
    super.initState();

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _signUpWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showSnackbar(
        message: 'Please fill all fields',
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

    // Check password length
    if (password.length < 6) {
      _showSnackbar(
        message: 'Password must be at least 6 characters',
        icon: Icons.error_outline,
        isSuccess: false,
      );
      return;
    }

    if (password != confirmPassword) {
      _showSnackbar(
        message: 'Passwords do not match',
        icon: Icons.error_outline,
        isSuccess: false,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref
          .read(authControllerProvider)
          .createUserWithEmailAndPassword(email: email, password: password);

      if (mounted) {
        _showSnackbar(
          message: 'Account created successfully!',
          icon: Icons.check_circle,
          isSuccess: true,
        );
        // Will auto-redirect to dashboard due to auth state change
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage = 'Account creation failed';

        // Provide more user-friendly error messages
        if (e.code == 'email-already-in-use') {
          errorMessage = 'This email is already registered';
        } else if (e.code == 'weak-password') {
          errorMessage = 'This password is too weak';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'Invalid email format';
        } else if (e.code == 'operation-not-allowed') {
          errorMessage = 'Email/password accounts are not enabled';
        } else if (e.message != null) {
          errorMessage = e.message!;
        }

        _showSnackbar(
          message: errorMessage,
          icon: Icons.error_outline,
          isSuccess: false,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar(
          message: 'Error: ${e.toString()}',
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

  Future<void> _sendOtp() async {
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
                if (mounted) {
                  _showSnackbar(
                    message: 'Account created successfully!',
                    icon: Icons.check_circle,
                    isSuccess: true,
                  );
                }
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

  Future<void> _verifyOtp() async {
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

      if (mounted) {
        _showSnackbar(
          message: 'Account created successfully!',
          icon: Icons.check_circle,
          isSuccess: true,
        );
        // Will auto-redirect to dashboard due to auth state change
      }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
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
                      color: theme.colorScheme.primary.withOpacity(0.1),
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
                  'Join FitFlow',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create an account to start your fitness journey',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 32),

                // Toggle between Email and Phone signup
                _buildToggleButtons(),
                const SizedBox(height: 24),

                // Conditional UI based on signup method
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isEmailSignup
                      ? _buildEmailForm()
                      : _isOtpSent
                          ? _buildOtpForm()
                          : _buildPhoneForm(),
                ),

                const SizedBox(height: 24),
                // Already have an account? Sign In link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
                      style: TextStyle(
                        color:
                            theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        context.pushReplacement('/sign-in');
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: Text(
                        "Sign In",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
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
      selected: {_isEmailSignup},
      onSelectionChanged: (Set<bool> newSelection) {
        setState(() {
          _isEmailSignup = newSelection.first;
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
    final theme = Theme.of(context);

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
            fillColor: theme.cardColor,
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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
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
            helperText: 'At least 6 characters',
            filled: true,
            fillColor: theme.cardColor,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmPasswordController,
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility
                    : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
            filled: true,
            fillColor: theme.cardColor,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
          obscureText: _obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _signUpWithEmail(),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _signUpWithEmail,
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
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Sign Up'),
        ),
      ],
    );
  }

  Widget _buildOtpForm() {
    final theme = Theme.of(context);

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
            fillColor: theme.cardColor,
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
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Verify & Create Account'),
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
    final theme = Theme.of(context);

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
            fillColor: theme.cardColor,
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
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Send OTP'),
        ),
      ],
    );
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
}
