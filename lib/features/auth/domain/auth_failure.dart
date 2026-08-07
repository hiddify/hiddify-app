import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/failures.dart';

part 'auth_failure.freezed.dart';

@freezed
sealed class AuthFailure with _$AuthFailure, Failure {
  const AuthFailure._();

  @With<UnexpectedFailure>()
  const factory AuthFailure.unexpected([Object? error, StackTrace? stackTrace]) = AuthUnexpectedFailure;

  const factory AuthFailure.notConfigured() = AuthNotConfiguredFailure;

  const factory AuthFailure.invalidToken() = AuthInvalidTokenFailure;

  @With<ExpectedFailure>()
  const factory AuthFailure.accountBlocked() = AuthAccountBlockedFailure;

  @With<ExpectedFailure>()
  const factory AuthFailure.rateLimited() = AuthRateLimitedFailure;

  const factory AuthFailure.sessionExpired() = AuthSessionExpiredFailure;

  @override
  ({String type, String? message}) present(TranslationsEn t) {
    return switch (this) {
      AuthUnexpectedFailure() => (type: t.errors.auth.unexpected, message: null),
      AuthNotConfiguredFailure() => (type: t.errors.auth.notConfigured, message: null),
      AuthInvalidTokenFailure() => (type: t.errors.auth.invalidToken, message: null),
      AuthAccountBlockedFailure() => (type: t.errors.auth.accountBlocked, message: null),
      AuthRateLimitedFailure() => (type: t.errors.auth.rateLimited, message: null),
      AuthSessionExpiredFailure() => (type: t.errors.auth.sessionExpired, message: null),
    };
  }
}