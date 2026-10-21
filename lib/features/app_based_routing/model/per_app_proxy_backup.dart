import 'package:freezed_annotation/freezed_annotation.dart';

part 'per_app_proxy_backup.freezed.dart';
part 'per_app_proxy_backup.g.dart';

@freezed
abstract class PerAppProxyBackup with _$PerAppProxyBackup {
  const factory PerAppProxyBackup({
    @Default(PerAppProxyBackupMode()) PerAppProxyBackupMode include,
    @Default(PerAppProxyBackupMode()) PerAppProxyBackupMode exclude,
  }) = _PerAppProxyBackup;

  factory PerAppProxyBackup.fromJson(Map<String, Object?> json) => _$PerAppProxyBackupFromJson(json);
}

@freezed
abstract class PerAppProxyBackupMode with _$PerAppProxyBackupMode {
  const factory PerAppProxyBackupMode({@Default([]) List<String> selected, @Default([]) List<String> deselected}) =
      _PerAppProxyBackupMode;

  factory PerAppProxyBackupMode.fromJson(Map<String, Object?> json) => _$PerAppProxyBackupModeFromJson(json);
}
