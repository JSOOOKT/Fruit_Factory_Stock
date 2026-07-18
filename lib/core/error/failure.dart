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

  ValidationFailure(String message, this.fieldErrors, [StackTrace? stackTrace])
      : super(message, stackTrace);
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

typedef Either<L, R> = Future<Result<L, R>>;

sealed class Result<Failure, Success> {
  const Result();

  factory Result.success(Success data) => Success._(data);
  factory Result.failure(Failure error) => Failure._(error);

  R fold<R>(
    R Function(Failure error) onFailure,
    R Function(Success data) onSuccess,
  ) {
    if (this is Success<Failure, Success>) {
      return onSuccess((this as Success<Failure, Success>).data);
    } else {
      return onFailure((this as Failure<Failure, Success>).error);
    }
  }

  Future<R> foldAsync<R>(
    Future<R> Function(Failure error) onFailure,
    Future<R> Function(Success data) onSuccess,
  ) async {
    if (this is Success<Failure, Success>) {
      return onSuccess((this as Success<Failure, Success>).data);
    } else {
      return onFailure((this as Failure<Failure, Success>).error);
    }
  }
}

final class Success<Failure, Success> extends Result<Failure, Success> {
  final Success data;

  const Success._(this.data);
}

final class Failure<Failure, Success> extends Result<Failure, Success> {
  final Failure error;

  const Failure._(this.error);
}
