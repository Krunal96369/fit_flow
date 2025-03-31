import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';

import '../../../common_widgets/accessible_button.dart';
import '../../../common_widgets/error_dialog.dart';
import '../../../services/error/error_service.dart';
import '../application/auth_controller.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isEmailLogin = true;
  bool _isOtpSent = false;
  String? _verificationId;

  // Track full phone number with country code
  String _fullPhoneNumber = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _signInWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref
          .read(authControllerProvider)
          .signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => ErrorDialog(
            errorType: ErrorType.authentication,
            technicalMessage: e.toString(),
            onRetry: _signInWithEmail,
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

  void _sendOtp() async {
    if (_fullPhoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number')),
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
              setState(() {
                _isLoading = true;
              });

              try {
                await ref
                    .read(authControllerProvider)
                    .signInWithCredential(credential);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Auto-verification failed: ${e.toString()}',
                      ),
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
            },
            verificationFailed: (FirebaseAuthException e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Verification failed: ${e.message}')),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('OTP sent to your phone')),
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
        showDialog(
          context: context,
          builder: (context) => ErrorDialog(
            errorType: ErrorType.authentication,
            technicalMessage: e.toString(),
            onRetry: _sendOtp,
          ),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter the OTP')));
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
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => ErrorDialog(
            errorType: ErrorType.authentication,
            technicalMessage: e.toString(),
            onRetry: _verifyOtp,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // App Logo/Branding
              Icon(
                Icons.fitness_center,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 32),
              const Text(
                'Welcome to FitFlow',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),

              // Toggle between Email and Phone login
              SegmentedButton<bool>(
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
              ),
              const SizedBox(height: 24),

              // Conditional UI based on login method
              if (_isEmailLogin) ...[
                // Email login fields
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _signInWithEmail(),
                ),
                const SizedBox(height: 24),
                AccessibleButton(
                  onPressed: _isLoading ? null : _signInWithEmail,
                  semanticLabel: 'Sign in with email and password',
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign In'),
                ),
              ] else if (!_isOtpSent) ...[
                // Phone number input with country code
                IntlPhoneField(
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                    counterText: '',
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
                AccessibleButton(
                  onPressed: _isLoading ? null : _sendOtp,
                  semanticLabel: 'Send verification code to your phone',
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send OTP'),
                ),
              ] else ...[
                // OTP verification
                TextField(
                  controller: _otpController,
                  decoration: const InputDecoration(
                    labelText: 'OTP Code',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.security),
                    hintText: '6-digit code',
                  ),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  maxLength: 6,
                  onSubmitted: (_) => _verifyOtp(),
                ),
                const SizedBox(height: 24),
                AccessibleButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  semanticLabel: 'Verify OTP and sign in',
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Verify & Sign In'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _isOtpSent = false;
                          });
                        },
                  child: const Text('Change Phone Number'),
                ),
              ],

              const SizedBox(height: 24),
              // Don't have an account? Sign Up link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Don\'t have an account?'),
                  TextButton(
                    onPressed: () {
                      context.push('/sign-up');
                    },
                    child: const Text('Sign Up'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
