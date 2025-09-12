import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/failures.dart';

part 'settings_failure.freezed.dart';

@freezed
sealed class SettingsFailure with _$SettingsFailure, Failure {
  const SettingsFailure._();

  @With<UnexpectedFailure>()
  const factory SettingsFailure.unexpected([
    Object? error,
    StackTrace? stackTrace,
  ]) = SettingsUnexpectedFailure;

  @override
  ({String type, String? message}) present(Translations t) {
    return switch (this) {
      SettingsUnexpectedFailure() => (
          type: t.failure.unexpected,
          message: null,
        ),
    };
  }
}
