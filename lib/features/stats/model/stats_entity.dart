import 'package:freezed_annotation/freezed_annotation.dart';

part 'stats_entity.freezed.dart';

@freezed
class StatsEntity with _$StatsEntity {
  const StatsEntity._();

  const factory StatsEntity({
    required int uplink,
    required int downlink,
    required int uplinkTotal,
    required int downlinkTotal,
  }) = _StatsEntity;

  factory StatsEntity.empty() => const StatsEntity(uplink: 0, downlink: 0, uplinkTotal: 0, downlinkTotal: 0);
}
