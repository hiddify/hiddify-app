import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/failures.dart';

part 'proxy_failure.freezed.dart';

@freezed
sealed class ProxyFailure with _$ProxyFailure, Failure {
  const ProxyFailure._();

  @With<UnexpectedFailure>()
  const factory ProxyFailure.unexpected([
    Object? error,
    StackTrace? stackTrace,
  ]) = ProxyUnexpectedFailure;

  @With<ExpectedFailure>()
  const factory ProxyFailure.serviceNotRunning() = ServiceNotRunning;

  @With<ExpectedFailure>()
  const factory ProxyFailure.unknownIp() = UnknownIp;

  @With<ExpectedMeasuredFailure>()
  const factory ProxyFailure.unableToRetrieveIp([
    Object? error,
    StackTrace? stackTrace,
  ]) = UnableToRetrieveIp;

  @override
  ({String type, String? message}) present(Translations t) {
    return switch (this) {
      ProxyUnexpectedFailure() => (
          type: t.failure.unexpected,
          message: null,
        ),
      ServiceNotRunning() => (
          type: t.failure.singbox.serviceNotRunning,
          message: null,
        ),
      UnknownIp() => (type: t.general.unknown, message: null),
      UnableToRetrieveIp() => (
          type: t.failure.unexpected,
          message: null,
        ),
    };
  }
}
