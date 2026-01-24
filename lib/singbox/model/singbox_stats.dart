import 'package:freezed_annotation/freezed_annotation.dart';

part 'singbox_stats.freezed.dart';
part 'singbox_stats.g.dart';

@freezed
class SingboxStats with _$SingboxStats {
  const SingboxStats._();

  @JsonSerializable(fieldRename: FieldRename.kebab)
  const factory SingboxStats({
    required int connectionsIn,
    required int connectionsOut,
    required int uplink,
    required int downlink,
    required int uplinkTotal,
    required int downlinkTotal,
  }) = _SingboxStats;

  factory SingboxStats.fromJson(Map<String, dynamic> json) => _$SingboxStatsFromJson(json);
}
