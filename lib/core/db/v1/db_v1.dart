import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:hiddify/core/db/converters/duration_converter.dart';
import 'package:hiddify/core/db/v1/db_v1.steps.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/utils/custom_loggers.dart';

part 'db_v1.g.dart';

@DriftDatabase(tables: [ProfileEntries, GeoAssetEntries])
class DbV1 extends _$DbV1 with InfraLogger {
  DbV1([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 4;

  static QueryExecutor _openConnection() {
    return LazyDatabase(
      () => driftDatabase(
        name: "db",
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
          await m.alterTable(TableMigration(schema.profileEntries, columnTransformer: {schema.profileEntries.type: const Constant<String>("remote")}, newColumns: [schema.profileEntries.type]));
        },
        from2To3: (m, schema) async {
          await m.createTable(schema.geoAssetEntries);
        },
        from3To4: (m, schema) async {
          await m.addColumn(schema.profileEntries, schema.profileEntries.testUrl);
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
  TextColumn get testUrl => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('GeoAssetEntry')
class GeoAssetEntries extends Table {
  TextColumn get id => text()();
  TextColumn get type => textEnum<GeoAssetType>()();
  BoolColumn get active => boolean()();
  TextColumn get name => text().withLength(min: 1)();
  TextColumn get providerName => text().withLength(min: 1)();
  TextColumn get version => text().nullable()();
  DateTimeColumn get lastCheck => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {name, providerName},
  ];
}

enum GeoAssetType { geoip, geosite }
