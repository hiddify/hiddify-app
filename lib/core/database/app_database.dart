import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:hiddify/core/database/app_database.steps.dart';
import 'package:hiddify/core/database/converters/duration_converter.dart';
import 'package:hiddify/core/database/tables/database_tables.dart';
import 'package:hiddify/features/geo_asset/model/geo_asset_entity.dart';
import 'package:hiddify/features/per_app_proxy/model/per_app_proxy_mode.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/utils/custom_loggers.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [ProfileEntries, GeoAssetEntries, AppProxyEntries])
class AppDatabase extends _$AppDatabase with InfraLogger {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 5;

  static QueryExecutor _openConnection() {
    return LazyDatabase(
      () => driftDatabase(
        name: "db",
        web: DriftWebOptions(
          sqlite3Wasm: Uri.parse('sqlite3.wasm'),
          driftWorker: Uri.parse('drift_worker.js'),
        ),
      ),
    );
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // await _prePopulateGeoAssets();
      },
      onUpgrade: stepByStep(
        // add type column to profile entries table
        // make url column nullable
        from1To2: (m, schema) async {
          await m.alterTable(
            TableMigration(
              schema.profileEntries,
              columnTransformer: {
                schema.profileEntries.type: const Constant<String>("remote"),
              },
              newColumns: [schema.profileEntries.type],
            ),
          );
        },
        from2To3: (m, schema) async {
          await m.createTable(schema.geoAssetEntries);
          // await _prePopulateGeoAssets();
        },
        from3To4: (m, schema) async {
          await m.addColumn(schema.profileEntries, schema.profileEntries.testUrl);
        },
        from4To5: (m, schema) async {
          // await m.renameColumn(
          //   schema.profileEntries,
          //   'test_url',
          //   schema.profileEntries.localOverride,
          // );
          await m.createTable(schema.appProxyEntries);
        },
      ),
      beforeOpen: (details) async {
        // if (kDebugMode) {
        // await validateDatabaseSchema();
        // }
      },
    );
  }

  // Future<void> _prePopulateGeoAssets() async {
  //   loggy.debug("populating default geo assets");
  //   await transaction(() async {
  //     final geoAssets = defaultGeoAssets.map((e) => e.toEntry());
  //     for (final geoAsset in geoAssets) {
  //       await into(geoAssetEntries)
  //           .insert(geoAsset, mode: InsertMode.insertOrIgnore);
  //     }
  //   });
  // }
}
