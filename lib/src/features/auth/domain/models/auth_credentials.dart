/// Data class representing credentials for signing in.
/// Encapsulates email and password.
class SignInCredentials {
  final String email;
  final String password;

  const SignInCredentials({
    required this.email,
    required this.password,
  });

  /// Creates empty credentials to use when the user is already logged in
  factory SignInCredentials.empty() {
    return const SignInCredentials(email: '', password: '');
  }

  // Optional: Add validation logic here if needed,
  // or use a package like Freezed for more robust data classes.
}

/// Data class representing credentials for signing up.
/// Encapsulates email and password.
class SignUpCredentials {
  final String email;
  final String password;

  const SignUpCredentials({
    required this.email,
    required this.password,
  });

  // Optional: Add validation logic here if needed.
}
