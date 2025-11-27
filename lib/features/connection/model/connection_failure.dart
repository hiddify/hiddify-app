import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/failures.dart';

part 'connection_failure.freezed.dart';

@freezed
sealed class ConnectionFailure with _$ConnectionFailure, Failure {
  const ConnectionFailure._();

  @With<UnexpectedFailure>()
  const factory ConnectionFailure.unexpected([
    Object? error,
    StackTrace? stackTrace,
  ]) = UnexpectedConnectionFailure;

  @With<ExpectedMeasuredFailure>()
  const factory ConnectionFailure.missingVpnPermission([String? message]) =
      MissingVpnPermission;

  @With<ExpectedMeasuredFailure>()
  const factory ConnectionFailure.missingNotificationPermission([
    String? message,
  ]) = MissingNotificationPermission;

  @With<ExpectedMeasuredFailure>()
  const factory ConnectionFailure.missingPrivilege() = MissingPrivilege;

  @With<ExpectedMeasuredFailure>()
  const factory ConnectionFailure.missingGeoAssets() = MissingGeoAssets;

  @With<ExpectedMeasuredFailure>()
  const factory ConnectionFailure.invalidConfigOption([String? message]) =
      InvalidConfigOption;

  @With<ExpectedMeasuredFailure>()
  const factory ConnectionFailure.invalidConfig([String? message]) =
      InvalidConfig;

  @override
  ({String type, String? message}) present(TranslationsEn t) {
    return switch (this) {
      UnexpectedConnectionFailure() => (
        type: t.failure.connectivity.unexpected,
        message: null,
      ),
      MissingVpnPermission(:final message) => (
        type: t.failure.connectivity.missingVpnPermission,
        message: message,
      ),
      MissingNotificationPermission(:final message) => (
        type: t.failure.connectivity.missingNotificationPermission,
        message: message,
      ),
      MissingPrivilege() => (
        type: t.failure.singbox.missingPrivilege,
        message: t.failure.singbox.missingPrivilegeMsg,
      ),
      MissingGeoAssets() => (
        type: t.failure.singbox.missingGeoAssets,
        message: t.failure.singbox.missingGeoAssetsMsg,
      ),
      InvalidConfigOption(:final message) => (
        type: t.failure.singbox.invalidConfigOptions,
        message: message,
      ),
      InvalidConfig(:final message) => (
        type: t.failure.singbox.invalidConfig,
        message: message,
      ),
    };
  }
}
