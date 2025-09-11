import 'package:fpdart/fpdart.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:rxdart/rxdart.dart';

mixin ExceptionHandler implements LoggerMixin {
  TaskEither<F, R> exceptionHandler<F, R>(
    Future<Either<F, R>> Function() run,
    F Function(Object error, StackTrace stackTrace) onError,
  ) {
    return TaskEither(
      () async {
        try {
          return await run();
        } catch (error, stackTrace) {
          return Left(onError(error, stackTrace));
        }
      },
    );
  }
}

extension StreamExceptionHandler<R extends Object?> on Stream<R> {
  Stream<Either<F, R>> handleExceptions<F>(
    F Function(Object error, StackTrace stackTrace) onError,
  ) {
    return map(right<F, R>).onErrorReturnWith(
      (error, stackTrace) {
        return Left(onError(error, stackTrace));
      },
    );
  }
}

extension TaskEitherExceptionHandler<F, R> on TaskEither<F, R> {
  TaskEither<F, R> handleExceptions(
    F Function(Object error, StackTrace stackTrace) onError,
  ) {
    return TaskEither(
      () async {
        try {
          return await run();
        } catch (error, stackTrace) {
          return Left(onError(error, stackTrace));
        }
      },
    );
  }
}
