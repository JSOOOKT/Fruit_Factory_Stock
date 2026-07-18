import 'package:fruit_factory_stock/features/auth/data/datasources/auth_datasource.dart';
import 'package:fruit_factory_stock/features/auth/data/models/auth_request.dart';
import 'package:fruit_factory_stock/features/auth/data/models/auth_response.dart';
import 'package:fruit_factory_stock/shared/models/user.dart';

class InMemoryAuthRemoteDataSource implements AuthRemoteDataSource {
  static final Map<String, _StoredAuthUser> _usersByEmail = <String, _StoredAuthUser>{};
  static AuthResponse? _currentSession;

  @override
  Future<AuthResponse> signUp(SignUpRequest request) async {
    if (!request.passwordsMatch) {
      throw StateError('Passwords do not match');
    }

    final now = DateTime.now();
    final user = User(
      uid: 'demo-${request.email.hashCode.abs()}',
      name: request.name,
      email: request.email,
      role: request.role,
      preferredLanguage: request.preferredLanguage,
      active: true,
      createdAt: now,
      updatedAt: now,
    );

    final response = AuthResponse(user: user, token: 'demo-token-${user.uid}');
    _usersByEmail[request.email.toLowerCase()] = _StoredAuthUser(
      password: request.password,
      response: response,
    );
    _currentSession = response;
    return response;
  }

  @override
  Future<AuthResponse> signIn(LoginRequest request) async {
    final existing = _usersByEmail[request.email.toLowerCase()];
    if (existing != null) {
      _currentSession = existing.response;
      return existing.response;
    }

    final now = DateTime.now();
    final user = User(
      uid: 'demo-${request.email.hashCode.abs()}',
      name: 'Demo User',
      email: request.email,
      role: 'recorder',
      preferredLanguage: 'en',
      active: true,
      createdAt: now,
      updatedAt: now,
    );
    final response = AuthResponse(user: user, token: 'demo-token-${user.uid}');
    _usersByEmail[request.email.toLowerCase()] = _StoredAuthUser(
      password: request.password,
      response: response,
    );
    _currentSession = response;
    return response;
  }

  @override
  Future<void> signOut() async {
    _currentSession = null;
  }

  @override
  Future<void> resetPassword(ResetPasswordRequest request) async {
    // Demo mode: no-op.
  }

  @override
  Future<AuthResponse?> getCurrentUser() async {
    return _currentSession;
  }

  @override
  Future<void> verifyEmail() async {
    // Demo mode: no-op.
  }

  @override
  Future<void> updateUserProfile({
    required String userId,
    required String name,
    required String preferredLanguage,
  }) async {
    final current = _currentSession;
    if (current == null || current.user.uid != userId) {
      return;
    }

    final updatedUser = current.user.copyWith(
      name: name,
      preferredLanguage: preferredLanguage,
      updatedAt: DateTime.now(),
    );
    _currentSession = current.copyWith(user: updatedUser);
  }
}

class InMemoryAuthLocalDataSource implements AuthLocalDataSource {
  AuthResponse? _cachedUser;
  String? _token;

  @override
  Future<void> saveToken(String token) async {
    _token = token;
  }

  @override
  Future<String?> getToken() async {
    return _token;
  }

  @override
  Future<void> removeToken() async {
    _token = null;
  }

  @override
  Future<void> saveUser(AuthResponse response) async {
    _cachedUser = response;
    _token = response.token;
  }

  @override
  Future<AuthResponse?> getCachedUser() async {
    return _cachedUser;
  }

  @override
  Future<void> clearCache() async {
    _cachedUser = null;
    _token = null;
  }

  @override
  Future<bool> isLoggedIn() async {
    return _token != null && _token!.isNotEmpty;
  }
}

class _StoredAuthUser {
  _StoredAuthUser({required this.password, required this.response});

  final String password;
  final AuthResponse response;
}