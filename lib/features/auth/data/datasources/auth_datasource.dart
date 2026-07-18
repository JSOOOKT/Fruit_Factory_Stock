import 'package:fruit_factory_stock/core/error/failure.dart';
import 'package:fruit_factory_stock/features/auth/data/models/auth_request.dart';
import 'package:fruit_factory_stock/features/auth/data/models/auth_response.dart';

abstract class AuthRemoteDataSource {
  /// Sign up with email and password
  Future<AuthResponse> signUp(SignUpRequest request);

  /// Sign in with email and password
  Future<AuthResponse> signIn(LoginRequest request);

  /// Sign out current user
  Future<void> signOut();

  /// Reset password for email
  Future<void> resetPassword(ResetPasswordRequest request);

  /// Get current user data
  Future<AuthResponse?> getCurrentUser();

  /// Verify email
  Future<void> verifyEmail();

  /// Update user profile
  Future<void> updateUserProfile({
    required String userId,
    required String name,
    required String preferredLanguage,
  });
}

abstract class AuthLocalDataSource {
  /// Save auth token locally
  Future<void> saveToken(String token);

  /// Get saved token
  Future<String?> getToken();

  /// Remove token
  Future<void> removeToken();

  /// Save user data locally
  Future<void> saveUser(AuthResponse response);

  /// Get cached user
  Future<AuthResponse?> getCachedUser();

  /// Clear cache
  Future<void> clearCache();

  /// Check if user is logged in
  Future<bool> isLoggedIn();
}
