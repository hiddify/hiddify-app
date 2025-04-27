import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_local_override.freezed.dart';
part 'profile_local_override.g.dart';

@freezed
abstract class ProfileLocalOverride with _$ProfileLocalOverride {
  const factory ProfileLocalOverride({
    String? name,
    bool? enableWarp,
    bool? enableFragment,
  }) = _ProfileLocalOverride;

  //json key for this model
  static const key = 'local-override';

  factory ProfileLocalOverride.fromJson(Map<String, Object?> json) => _$ProfileLocalOverrideFromJson(json);
}
