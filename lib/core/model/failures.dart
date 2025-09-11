import 'package:dio/dio.dart';
import 'package:hiddify/core/localization/translations.dart';

typedef PresentableError = ({String type, String? message});

mixin Failure {
  ({String type, String? message}) present(Translations t);
}

/// failures that are not expected to happen but depending on [error] type might not be relevant (eg network errors)
mixin UnexpectedFailure {
  Object? get error;
  StackTrace? get stackTrace;
}

/// failures that are expected to happen and should be handled by the app
/// and should be logged, eg missing permissions
mixin ExpectedMeasuredFailure {}

/// failures ignored by analytics service etc.
mixin ExpectedFailure {}

extension ErrorPresenter on Translations {
  PresentableError errorToPair(Object error) => switch (error) {
        UnexpectedFailure(error: final nestedErr?) => errorToPair(nestedErr),
        Failure() => error.present(this),
        DioException() => error.present(this),
        _ => (type: failure.unexpected, message: error.toString()),
      };

  PresentableError presentError(
    Object error, {
    String? action,
  }) {
    final pair = errorToPair(error);
    if (action == null) return pair;
    return (
      type: action,
      message: pair.type + (pair.message == null ? "" : "\n${pair.message!}"),
    );
  }

  String presentShortError(
    Object error, {
    String? action,
  }) {
    final pair = errorToPair(error);
    if (action == null) return pair.type;
    return "$action: ${pair.type}";
  }
}

extension DioExceptionPresenter on DioException {
  PresentableError present(Translations t) => switch (type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout =>
          (type: t.failure.connection.timeout, message: null),
        DioExceptionType.badCertificate => (
            type: t.failure.connection.badCertificate,
            message: message,
          ),
        DioExceptionType.badResponse => (
            type: t.failure.connection.badResponse,
            message: message,
          ),
        DioExceptionType.connectionError => (
            type: t.failure.connection.connectionError,
            message: message,
          ),
        _ => (type: t.failure.connection.unexpected, message: message),
      };
}
