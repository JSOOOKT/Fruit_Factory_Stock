abstract class Failure {
  final String message;
  final StackTrace? stackTrace;

  Failure({required this.message, this.stackTrace});

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  ServerFailure({required String message, StackTrace? stackTrace})
      : super(message: message, stackTrace: stackTrace);
}

class CacheFailure extends Failure {
  CacheFailure({required String message, StackTrace? stackTrace})
      : super(message: message, stackTrace: stackTrace);
}

class FirebaseFailure extends Failure {
  final String? code;

  FirebaseFailure({required String message, this.code, StackTrace? stackTrace})
      : super(message: message, stackTrace: stackTrace);
}

class AuthFailure extends Failure {
  AuthFailure({required String message, StackTrace? stackTrace})
      : super(message: message, stackTrace: stackTrace);
}

class ValidationFailure extends Failure {
  final Map<String, String> fieldErrors;

  ValidationFailure({
    required String message,
    required this.fieldErrors,
    StackTrace? stackTrace,
  }) : super(message: message, stackTrace: stackTrace);
}

class NotFoundFailure extends Failure {
  NotFoundFailure({required String message, StackTrace? stackTrace})
      : super(message: message, stackTrace: stackTrace);
}

class NetworkFailure extends Failure {
  NetworkFailure({required String message, StackTrace? stackTrace})
      : super(message: message, stackTrace: stackTrace);
}

class UnknownFailure extends Failure {
  UnknownFailure({required String message, StackTrace? stackTrace})
      : super(message: message, stackTrace: stackTrace);
}

typedef Either<L, R> = Future<Result<L, R>>;

sealed class Result<FailureType, SuccessType> {
  const Result();

  factory Result.success(SuccessType data) => ResultSuccess._(data);
  factory Result.failure(FailureType error) => ResultFailure._(error);

  R fold<R>(
    R Function(FailureType error) onFailure,
    R Function(SuccessType data) onSuccess,
  ) {
    if (this is ResultSuccess<FailureType, SuccessType>) {
      return onSuccess((this as ResultSuccess<FailureType, SuccessType>).data);
    } else {
      return onFailure((this as ResultFailure<FailureType, SuccessType>).error);
    }
  }

  Future<R> foldAsync<R>(
    Future<R> Function(FailureType error) onFailure,
    Future<R> Function(SuccessType data) onSuccess,
  ) async {
    if (this is ResultSuccess<FailureType, SuccessType>) {
      return onSuccess((this as ResultSuccess<FailureType, SuccessType>).data);
    } else {
      return onFailure((this as ResultFailure<FailureType, SuccessType>).error);
    }
  }
}

final class ResultSuccess<FailureType, SuccessType>
    extends Result<FailureType, SuccessType> {
  final SuccessType data;

  const ResultSuccess._(this.data);
}

final class ResultFailure<FailureType, SuccessType>
    extends Result<FailureType, SuccessType> {
  final FailureType error;

  const ResultFailure._(this.error);
}
