import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/failures.dart';

part 'profile_failure.freezed.dart';

@freezed
sealed class ProfileFailure with _$ProfileFailure, Failure {
  const ProfileFailure._();

  @With<UnexpectedFailure>()
  const factory ProfileFailure.unexpected([
    Object? error,
    StackTrace? stackTrace,
  ]) = ProfileUnexpectedFailure;

  const factory ProfileFailure.notFound() = ProfileNotFoundFailure;

  @With<ExpectedFailure>()
  const factory ProfileFailure.invalidUrl() = ProfileInvalidUrlFailure;

  @With<ExpectedFailure>()
  const factory ProfileFailure.invalidConfig([String? message]) =
      ProfileInvalidConfigFailure;

  @override
  ({String type, String? message}) present(Translations t) {
    return switch (this) {
      ProfileUnexpectedFailure() => (
          type: t.failure.profiles.unexpected,
          message: null,
        ),
      ProfileNotFoundFailure() => (
          type: t.failure.profiles.notFound,
          message: null
        ),
      ProfileInvalidUrlFailure() => (
          type: t.failure.profiles.invalidUrl,
          message: null,
        ),
      ProfileInvalidConfigFailure(:final message) => (
          type: t.failure.profiles.invalidConfig,
          message: message
        ),
    };
  }
}
