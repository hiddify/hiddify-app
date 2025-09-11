import 'package:drift/drift.dart';
import 'package:hiddify/core/database/app_database.dart';
import 'package:hiddify/features/geo_asset/model/geo_asset_entity.dart';

extension GeoAssetEntityMapper on GeoAssetEntity {
  GeoAssetEntriesCompanion toEntry() {
    return GeoAssetEntriesCompanion.insert(
      id: id,
      type: type,
      active: active,
      name: name,
      providerName: providerName,
      version: Value(version),
      lastCheck: Value(lastCheck),
    );
  }
}

extension GeoAssetEntryMapper on GeoAssetEntry {
  GeoAssetEntity toEntity() {
    return GeoAssetEntity(
      id: id,
      name: name,
      type: type,
      active: active,
      providerName: providerName,
      version: version,
      lastCheck: lastCheck,
    );
  }
}
