import 'package:fruit_factory_stock/core/error/failure.dart';
import 'package:fruit_factory_stock/features/auth/data/datasources/auth_datasource.dart';
import 'package:fruit_factory_stock/features/auth/data/models/auth_request.dart';
import 'package:fruit_factory_stock/features/auth/data/models/auth_response.dart';

abstract class AuthRepository {
  Future<Result<Failure, AuthResponse>> signUp(SignUpRequest request);
  Future<Result<Failure, AuthResponse>> signIn(LoginRequest request);
  Future<Result<Failure, void>> signOut();
  Future<Result<Failure, void>> resetPassword(ResetPasswordRequest request);
  Future<Result<Failure, AuthResponse>> getCurrentUser();
  Future<Result<Failure, void>> updateUserProfile({
    required String userId,
    required String name,
    required String preferredLanguage,
  });
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  @override
  Future<Result<Failure, AuthResponse>> signUp(SignUpRequest request) async {
    try {
      final response = await _remoteDataSource.signUp(request);
      await _localDataSource.saveUser(response);
      return Result.success(response);
    } catch (e) {
      return Result.failure(_mapException(e));
    }
  }

  @override
  Future<Result<Failure, AuthResponse>> signIn(LoginRequest request) async {
    try {
      final response = await _remoteDataSource.signIn(request);
      await _localDataSource.saveUser(response);
      return Result.success(response);
    } catch (e) {
      return Result.failure(_mapException(e));
    }
  }

  @override
  Future<Result<Failure, void>> signOut() async {
    try {
      await _remoteDataSource.signOut();
      await _localDataSource.clearCache();
      return Result.success(null);
    } catch (e) {
      return Result.failure(_mapException(e));
    }
  }

  @override
  Future<Result<Failure, void>> resetPassword(ResetPasswordRequest request) async {
    try {
      await _remoteDataSource.resetPassword(request);
      return Result.success(null);
    } catch (e) {
      return Result.failure(_mapException(e));
    }
  }

  @override
  Future<Result<Failure, AuthResponse>> getCurrentUser() async {
    try {
      // Try to get from remote first
      final response = await _remoteDataSource.getCurrentUser();
      if (response != null) {
        await _localDataSource.saveUser(response);
        return Result.success(response);
      }

      // Fall back to cached user
      final cachedResponse = await _localDataSource.getCachedUser();
      if (cachedResponse != null) {
        return Result.success(cachedResponse);
      }

      return Result.failure(
        NotFoundFailure('User not found'),
      );
    } catch (e) {
      return Result.failure(_mapException(e));
    }
  }

  @override
  Future<Result<Failure, void>> updateUserProfile({
    required String userId,
    required String name,
    required String preferredLanguage,
  }) async {
    try {
      await _remoteDataSource.updateUserProfile(
        userId: userId,
        name: name,
        preferredLanguage: preferredLanguage,
      );
      return Result.success(null);
    } catch (e) {
      return Result.failure(_mapException(e));
    }
  }

  Failure _mapException(Object exception) {
    if (exception is Failure) {
      return exception;
    }
    return UnknownFailure(exception.toString());
  }
}
