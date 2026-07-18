// lib/core/error/failure.dart
abstract class Failure {
  final String message;
  final StackTrace? stackTrace;

  Failure(this.message, [this.stackTrace]);

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  ServerFailure(String message, [StackTrace? stackTrace])
      : super(message, stackTrace);
}

class CacheFailure extends Failure {
  CacheFailure(String message, [StackTrace? stackTrace])
      : super(message, stackTrace);
}

class FirebaseFailure extends Failure {
  final String? code;

  FirebaseFailure(String message, [this.code, StackTrace? stackTrace])
      : super(message, stackTrace);
}

class AuthFailure extends Failure {
  AuthFailure(String message, [StackTrace? stackTrace])
      : super(message, stackTrace);
}

class ValidationFailure extends Failure {
  final Map<String, String> fieldErrors;

  ValidationFailure({
    required String message,
    this.fieldErrors = const {},
    StackTrace? stackTrace,
  }) : super(message, stackTrace);
}

class NotFoundFailure extends Failure {
  NotFoundFailure(String message, [StackTrace? stackTrace])
      : super(message, stackTrace);
}

class NetworkFailure extends Failure {
  NetworkFailure(String message, [StackTrace? stackTrace])
      : super(message, stackTrace);
}

class UnknownFailure extends Failure {
  UnknownFailure(String message, [StackTrace? stackTrace])
      : super(message, stackTrace);
}

// Simple Result class without complex generics
sealed class Result<T> {
  const Result();

  factory Result.success(T data) = Success;
  factory Result.failure(Failure error) = Failure;

  R fold<R>(
    R Function(Failure error) onFailure,
    R Function(T data) onSuccess,
  );
}

final class Success<T> extends Result<T> {
  final T data;

  const Success(this.data);
}

final class FailureResult<T> extends Result<T> {
  final Failure error;

  const FailureResult(this.error);
}