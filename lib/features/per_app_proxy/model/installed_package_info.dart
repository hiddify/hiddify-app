import 'package:freezed_annotation/freezed_annotation.dart';

part 'installed_package_info.freezed.dart';
part 'installed_package_info.g.dart';

@freezed
abstract class InstalledPackageInfo with _$InstalledPackageInfo {
  @JsonSerializable(fieldRename: FieldRename.kebab)
  const factory InstalledPackageInfo({
    required String packageName,
    required String name,
    required bool isSystemApp,
  }) = _InstalledPackageInfo;

  factory InstalledPackageInfo.fromJson(Map<String, dynamic> json) =>
      _$InstalledPackageInfoFromJson(json);
}
