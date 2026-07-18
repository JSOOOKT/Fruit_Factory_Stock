class AuthValidators {
  // Email validation
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email is required';
    }

    const emailPattern =
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    final regex = RegExp(emailPattern);

    if (!regex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  // Password validation
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }

    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }

    if (password.length > 128) {
      return 'Password is too long';
    }

    // Optional: Check for password strength
    if (!_isPasswordStrong(password)) {
      return 'Password must contain letters and numbers';
    }

    return null;
  }

  // Password confirmation validation
  static String? validatePasswordConfirmation(
    String? password,
    String? passwordConfirmation,
  ) {
    if (passwordConfirmation == null || passwordConfirmation.isEmpty) {
      return 'Please confirm your password';
    }

    if (password != passwordConfirmation) {
      return 'Passwords do not match';
    }

    return null;
  }

  // Name validation
  static String? validateName(String? name) {
    if (name == null || name.isEmpty) {
      return 'Name is required';
    }

    if (name.length < 2) {
      return 'Name must be at least 2 characters';
    }

    if (name.length > 100) {
      return 'Name is too long';
    }

    return null;
  }

  // Helper to check password strength
  static bool _isPasswordStrong(String password) {
    final hasLetters = RegExp(r'[a-zA-Z]').hasMatch(password);
    final hasNumbers = RegExp(r'[0-9]').hasMatch(password);
    return hasLetters && hasNumbers;
  }
}
