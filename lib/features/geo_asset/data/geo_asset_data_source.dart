import 'package:drift/drift.dart';
import 'package:hiddify/core/database/app_database.dart';
import 'package:hiddify/core/database/tables/database_tables.dart';
import 'package:hiddify/features/geo_asset/model/geo_asset_entity.dart';
import 'package:hiddify/utils/custom_loggers.dart';

part 'geo_asset_data_source.g.dart';

abstract interface class GeoAssetDataSource {
  Future<void> insert(GeoAssetEntriesCompanion entry);
  Future<GeoAssetEntry?> getActiveAssetByType(GeoAssetType type);
  Stream<List<GeoAssetEntry>> watchAll();
  Future<void> patch(String id, GeoAssetEntriesCompanion entry);
}

@DriftAccessor(tables: [GeoAssetEntries])
class GeoAssetsDao extends DatabaseAccessor<AppDatabase>
    with _$GeoAssetsDaoMixin, InfraLogger
    implements GeoAssetDataSource {
  GeoAssetsDao(super.db);

  @override
  Future<void> insert(GeoAssetEntriesCompanion entry) async {
    await into(geoAssetEntries).insert(entry);
  }

  @override
  Future<GeoAssetEntry?> getActiveAssetByType(GeoAssetType type) {
    return (geoAssetEntries.select()
          ..where((tbl) => tbl.active.equals(true))
          ..where((tbl) => tbl.type.equalsValue(type))
          ..limit(1))
        .getSingleOrNull();
  }

  @override
  Stream<List<GeoAssetEntry>> watchAll() {
    return geoAssetEntries.select().watch();
  }

  @override
  Future<void> patch(String id, GeoAssetEntriesCompanion entry) async {
    await transaction(() async {
      if (entry.active.present && entry.active.value) {
        final baseEntry = await (select(
          geoAssetEntries,
        )..where((tbl) => tbl.id.equals(id))).getSingle();
        await (update(geoAssetEntries)
              ..where((tbl) => tbl.active.equals(true))
              ..where((tbl) => tbl.type.equalsValue(baseEntry.type)))
            .write(const GeoAssetEntriesCompanion(active: Value(false)));
      }
      await (update(
        geoAssetEntries,
      )..where((tbl) => tbl.id.equals(id))).write(entry);
    });
  }
}
