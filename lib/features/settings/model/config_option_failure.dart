import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/failures.dart';

part 'config_option_failure.freezed.dart';

@freezed
sealed class ConfigOptionFailure with _$ConfigOptionFailure, Failure {
  const ConfigOptionFailure._();

  @With<UnexpectedFailure>()
  const factory ConfigOptionFailure.unexpected([
    Object? error,
    StackTrace? stackTrace,
  ]) = ConfigOptionUnexpectedFailure;

  @With<ExpectedFailure>()
  const factory ConfigOptionFailure.missingWarp() = MissingWarpConfigFailure;

  @override
  ({String type, String? message}) present(TranslationsEn t) {
    return switch (this) {
      ConfigOptionUnexpectedFailure() => (
          type: t.failure.unexpected,
          message: null,
        ),
      MissingWarpConfigFailure() => (
          type: t.config.missingWarpConfig,
          message: null,
        ),
    };
  }
}
