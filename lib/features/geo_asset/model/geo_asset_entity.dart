import 'package:freezed_annotation/freezed_annotation.dart';

part 'geo_asset_entity.freezed.dart';

enum GeoAssetType { geoip, geosite }

typedef GeoAssetWithFileSize = (GeoAssetEntity geoAsset, int? size);

@freezed
sealed class GeoAssetEntity with _$GeoAssetEntity {
  const GeoAssetEntity._();

  const factory GeoAssetEntity({
    required String id,
    required String name,
    required GeoAssetType type,
    required bool active,
    required String providerName,
    String? version,
    DateTime? lastCheck,
  }) = _GeoAssetEntity;

  String get fileName => name;

  String get repositoryUrl => "https://api.github.com/repos/$providerName/releases/latest";
}
