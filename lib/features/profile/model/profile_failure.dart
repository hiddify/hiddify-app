import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/failures.dart';
import 'package:hiddify/features/settings/model/config_option_failure.dart';

part 'profile_failure.freezed.dart';

@freezed
sealed class ProfileFailure with _$ProfileFailure, Failure {
  const ProfileFailure._();

  @With<UnexpectedFailure>()
  const factory ProfileFailure.unexpected([Object? error, StackTrace? stackTrace]) = ProfileUnexpectedFailure;

  const factory ProfileFailure.notFound() = ProfileNotFoundFailure;

  @With<ExpectedFailure>()
  const factory ProfileFailure.invalidUrl([String? message]) = ProfileInvalidUrlFailure;

  @With<ExpectedFailure>()
  const factory ProfileFailure.invalidConfig([String? message, ConfigOptionFailure? configOptionFailure]) =
      ProfileInvalidConfigFailure;

  @With<ExpectedFailure>()
  const factory ProfileFailure.cancelByUser([String? message]) = ProfileCancelByUserFailure;

  @override
  ({String type, String? message}) present(TranslationsEn t) {
    return switch (this) {
      ProfileUnexpectedFailure() => (type: t.errors.profiles.unexpected, message: null),
      ProfileNotFoundFailure() => (type: t.errors.profiles.notFound, message: null),
      ProfileInvalidUrlFailure(:final message) => (type: t.errors.profiles.invalidUrl, message: message),
      ProfileInvalidConfigFailure(:final message, :final configOptionFailure) =>
        configOptionFailure?.present(t) ?? (type: t.errors.profiles.invalidConfig, message: message),
      ProfileCancelByUserFailure(:final message) => (type: t.errors.profiles.canceledByUser, message: message),
    };
  }
}
