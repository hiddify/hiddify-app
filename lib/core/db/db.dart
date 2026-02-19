import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:hiddify/core/db/converters/duration_converter.dart';
import 'package:hiddify/core/db/db.steps.dart';
import 'package:hiddify/core/directories/directories_provider.dart';
import 'package:hiddify/features/per_app_proxy/model/per_app_proxy_mode.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/utils/custom_loggers.dart';

part 'db.g.dart';

@DriftDatabase(tables: [ProfileEntries, AppProxyEntries])
class Db extends _$Db with InfraLogger {
  Db([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 5;

  static QueryExecutor _openConnection() {
    return LazyDatabase(
      () => driftDatabase(
        name: "db",
        native: const DriftNativeOptions(databaseDirectory: AppDirectories.getDatabaseDirectory),
        web: DriftWebOptions(sqlite3Wasm: Uri.parse('sqlite3.wasm'), driftWorker: Uri.parse('drift_worker.js')),
      ),
    );
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: stepByStep(
        from1To2: (m, schema) async {
          await m.alterTable(
            TableMigration(
              schema.profileEntries,
              columnTransformer: {schema.profileEntries.type: const Constant<String>("remote")},
              newColumns: [schema.profileEntries.type],
            ),
          );
        },
        from2To3: (m, schema) async {
          await m.createTable(schema.geoAssetEntries);
        },
        from3To4: (m, schema) async {
          await m.addColumn(schema.profileEntries, schema.profileEntries.testUrl);
        },
        from4To5: (m, schema) async {
          await m.deleteTable('geo_asset_entries');
          await m.renameColumn(schema.profileEntries, 'test_url', schema.profileEntries.profileOverride);
          await m.addColumn(schema.profileEntries, schema.profileEntries.userOverride);
          await m.addColumn(schema.profileEntries, schema.profileEntries.populatedHeaders);
          await m.createTable(schema.appProxyEntries);
        },
      ),
    );
  }
}

@DataClassName('ProfileEntry')
class ProfileEntries extends Table {
  TextColumn get id => text()();
  TextColumn get type => textEnum<ProfileType>()();
  BoolColumn get active => boolean()();
  TextColumn get name => text().withLength(min: 1)();
  TextColumn get url => text().nullable()();
  DateTimeColumn get lastUpdate => dateTime()();
  IntColumn get updateInterval => integer().nullable().map(DurationTypeConverter())();
  IntColumn get upload => integer().nullable()();
  IntColumn get download => integer().nullable()();
  IntColumn get total => integer().nullable()();
  DateTimeColumn get expire => dateTime().nullable()();
  TextColumn get webPageUrl => text().nullable()();
  TextColumn get supportUrl => text().nullable()();
  TextColumn get populatedHeaders => text().nullable()();
  TextColumn get profileOverride => text().nullable()();
  TextColumn get userOverride => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AppProxyEntry')
class AppProxyEntries extends Table {
  TextColumn get mode => textEnum<AppProxyMode>()();
  TextColumn get pkgName => text()();
  IntColumn get flags => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {mode, pkgName};
}
