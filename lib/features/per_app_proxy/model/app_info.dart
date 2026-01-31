import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_info.freezed.dart';
part 'app_info.g.dart';

@freezed
sealed class AppInfo with _$AppInfo {
  const factory AppInfo({
    required String name,
    @JsonKey(name: 'package') required String packageName,
    required bool system,
  }) = _AppInfo;

  factory AppInfo.fromJson(Map<String, dynamic> json) =>
      _$AppInfoFromJson(json);
}
