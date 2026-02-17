import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/failures.dart';
import 'package:hiddify/features/settings/model/config_option_failure.dart';

part 'connection_failure.freezed.dart';

@freezed
sealed class ConnectionFailure with _$ConnectionFailure, Failure {
  const ConnectionFailure._();

  @With<UnexpectedFailure>()
  const factory ConnectionFailure.unexpected([Object? error, StackTrace? stackTrace]) = UnexpectedConnectionFailure;

  @With<ExpectedMeasuredFailure>()
  const factory ConnectionFailure.missingVpnPermission([String? message]) = MissingVpnPermission;

  @With<ExpectedMeasuredFailure>()
  const factory ConnectionFailure.missingNotificationPermission([String? message]) = MissingNotificationPermission;

  @With<ExpectedMeasuredFailure>()
  const factory ConnectionFailure.missingPrivilege() = MissingPrivilege;

  @With<ExpectedMeasuredFailure>()
  const factory ConnectionFailure.invalidConfigOption([String? message, ConfigOptionFailure? configOptionFailure]) =
      InvalidConfigOption;

  @With<ExpectedMeasuredFailure>()
  const factory ConnectionFailure.invalidConfig([String? message]) = InvalidConfig;

  @With<ExpectedMeasuredFailure>()
  const factory ConnectionFailure.backgroundCoreNotAvailable([String? message]) = BackgroundCoreNotAvailable;

  @With<ExpectedMeasuredFailure>()
  const factory ConnectionFailure.missiingWarpLicense() = MissingWarpLicense;

  @override
  ({String type, String? message}) present(TranslationsEn t) {
    return switch (this) {
      UnexpectedConnectionFailure(:final error) when error != null => (
        type: t.errors.connectivity.unexpected,
        message: "$error",
      ),
      UnexpectedConnectionFailure() => (type: t.errors.connectivity.unexpected, message: null),
      MissingVpnPermission(:final message) => (type: t.errors.connectivity.missingVpnPermission, message: message),
      MissingNotificationPermission(:final message) => (
        type: t.errors.connectivity.missingNotificationPermission,
        message: message,
      ),
      MissingPrivilege() => (type: t.errors.singbox.missingPrivilege, message: t.errors.singbox.missingPrivilegeMsg),
      InvalidConfigOption(:final message, :final configOptionFailure) =>
        configOptionFailure?.present(t) ?? (type: t.errors.singbox.invalidConfigOptions, message: message),
      InvalidConfig(:final message) => (type: t.errors.singbox.invalidConfig, message: message),
      BackgroundCoreNotAvailable(:final message) => (type: t.errors.connectivity.core, message: message),
      MissingWarpLicense() => (type: t.errors.warp.missingLicense, message: t.errors.warp.missingLicenseMsg),
    };
  }
}
