import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/failures.dart';

part 'log_failure.freezed.dart';

@freezed
sealed class LogFailure with _$LogFailure, Failure {
  const LogFailure._();

  @With<UnexpectedFailure>()
  const factory LogFailure.unexpected([Object? error, StackTrace? stackTrace]) = LogUnexpectedFailure;

  @override
  ({String type, String? message}) present(TranslationsEn t) {
    return switch (this) {
      LogUnexpectedFailure() => (type: t.errors.unexpected, message: null),
    };
  }
}
