// lib/features/auth/presentation/providers/auth_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fruit_factory_stock/features/auth/data/datasources/auth_datasource.dart';
import 'package:fruit_factory_stock/features/auth/data/datasources/firebase_auth_remote_datasource.dart';
import 'package:fruit_factory_stock/features/auth/data/datasources/shared_preferences_auth_local_datasource.dart';
import 'package:fruit_factory_stock/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:fruit_factory_stock/features/auth/data/models/auth_response.dart';
import 'package:fruit_factory_stock/features/auth/data/models/auth_request.dart';
import 'package:fruit_factory_stock/shared/models/user.dart';

// Firebase providers
final firebaseAuthProvider = Provider<fb.FirebaseAuth>((ref) {
  return fb.FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// SharedPreferences provider
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

// DataSource providers
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);
  return FirebaseAuthRemoteDataSource(auth: auth, firestore: firestore);
});

final authLocalDataSourceProvider = FutureProvider<AuthLocalDataSource>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return SharedPreferencesAuthLocalDataSource(prefs: prefs);
});

// Repository provider
final authRepositoryProvider = FutureProvider<AuthRepository>((ref) async {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  final localDataSource = await ref.watch(authLocalDataSourceProvider.future);
  return AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
  );
});

// Auth State Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository? _repository;

  AuthNotifier(this._repository) : super(const AuthState.initial());

  Future<void> signUp(SignUpRequest request) async {
    if (_repository == null) return;
    state = const AuthState.loading();
    final result = await _repository!.signUp(request);
    
    result.fold(
      (failure) {
        state = AuthState.error(message: failure.message);
      },
      (response) {
        state = AuthState.authenticated(
          user: response.user,
          token: response.token,
        );
      },
    );
  }

  Future<void> signIn(LoginRequest request) async {
    if (_repository == null) return;
    state = const AuthState.loading();
    final result = await _repository!.signIn(request);
    
    result.fold(
      (failure) {
        state = AuthState.error(message: failure.message);
      },
      (response) {
        state = AuthState.authenticated(
          user: response.user,
          token: response.token,
        );
      },
    );
  }

  Future<void> signOut() async {
    if (_repository == null) return;
    state = const AuthState.loading();
    final result = await _repository!.signOut();
    
    result.fold(
      (failure) {
        state = AuthState.error(message: failure.message);
      },
      (_) {
        state = const AuthState.unauthenticated(message: 'Signed out successfully');
      },
    );
  }

  Future<void> resetPassword(ResetPasswordRequest request) async {
    if (_repository == null) return;
    state = const AuthState.loading();
    final result = await _repository!.resetPassword(request);
    
    result.fold(
      (failure) {
        state = AuthState.error(message: failure.message);
      },
      (_) {
        state = const AuthState.unauthenticated(
          message: 'Password reset email sent. Please check your inbox.',
        );
      },
    );
  }

  Future<void> getCurrentUser() async {
    if (_repository == null) return;
    state = const AuthState.loading();
    final result = await _repository!.getCurrentUser();
    
    result.fold(
      (failure) {
        state = const AuthState.unauthenticated(message: null);
      },
      (response) {
        if (response != null) {
          state = AuthState.authenticated(
            user: response.user,
            token: response.token,
          );
        } else {
          state = const AuthState.unauthenticated(message: null);
        }
      },
    );
  }

  Future<void> updateUserProfile({
    required String userId,
    required String name,
    required String preferredLanguage,
  }) async {
    if (_repository == null || state is! AuthAuthenticated) return;

    final result = await _repository!.updateUserProfile(
      userId: userId,
      name: name,
      preferredLanguage: preferredLanguage,
    );

    result.fold(
      (failure) {
        state = AuthState.error(message: failure.message);
      },
      (_) {
        final currentState = state as AuthAuthenticated;
        final updatedUser = currentState.user.copyWith(
          name: name,
          preferredLanguage: preferredLanguage,
        );
        state = AuthState.authenticated(
          user: updatedUser,
          token: currentState.token,
        );
      },
    );
  }

  void clearError() {
    if (state is AuthError) {
      state = const AuthState.initial();
    }
  }
}

// Auth State provider
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repoAsync = ref.watch(authRepositoryProvider);
  return repoAsync.when(
    data: (repo) => AuthNotifier(repo),
    error: (_, __) => AuthNotifier(null),
    loading: () => AuthNotifier(null),
  );
});

// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.maybeMap(
    authenticated: (state) => state.user,
    orElse: () => null,
  );
});

// Auth token provider
final authTokenProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.maybeMap(
    authenticated: (state) => state.token,
    orElse: () => null,
  );
});

// Check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.isAuthenticated;
});

// Check if loading
final isLoadingProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.isLoading;
});