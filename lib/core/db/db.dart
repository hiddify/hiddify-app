import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:hiddify/core/db/converters/duration_converter.dart';
import 'package:hiddify/core/db/db.steps.dart';
import 'package:hiddify/core/directories/directories_provider.dart';
import 'package:hiddify/features/app_based_routing/model/per_app_proxy_mode.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/utils/custom_loggers.dart';

part 'db.g.dart';

/// The database on disk was written by a newer app version than this one, so
/// its schema is unknown here. Thrown on open instead of running with it.
class DbNewerThanAppException implements Exception {
  const DbNewerThanAppException(this.dbVersion, this.appVersion);

  final int dbVersion;
  final int appVersion;

  @override
  String toString() => "DbNewerThanAppException(db schema v$dbVersion, app schema v$appVersion)";
}

@DriftDatabase(tables: [ProfileEntries, AppProxyEntries])
class Db extends _$Db with InfraLogger {
  Db([QueryExecutor? executor]) : super(executor ?? _openConnection());

  // Changing the schema? Bump `schemaVersion`, add a matching `stepByStep` step
  // below, and regenerate — full checklist in `README.md` next to this file.
  // Migrations run on every user's device on update; a wrong one can lose data.
  @override
  int get schemaVersion => 7;

  static const _name = "db";

  static QueryExecutor _openConnection() {
    return LazyDatabase(
      () => driftDatabase(
        name: _name,
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
      onUpgrade: (m, from, to) async {
        // drift treats a downgrade like an upgrade: no step runs and the lower
        // version is written over the newer one, so the app then fails on
        // columns it does not know about. Refusing here aborts the open before
        // that write, which leaves the database untouched for the newer app.
        if (from > to) throw DbNewerThanAppException(from, to);
        await _steps(m, from, to);
      },
    );
  }

  /// The database file on disk.
  static Future<File> file() async {
    final dir = await AppDirectories.getDatabaseDirectory();
    return File("${dir.path}${Platform.pathSeparator}$_name.sqlite");
  }

  /// Deletes the database files, for when they cannot be opened. Close the
  /// database first. The last broken database is kept beside it as
  /// `db.broken.sqlite`, for a bug report.
  static Future<void> deleteFiles() async {
    final main = await file();
    if (await main.exists()) {
      try {
        await main.copy("${main.parent.path}${Platform.pathSeparator}$_name.broken.sqlite");
      } catch (_) {}
    }
    for (final suffix in const ["", "-wal", "-shm", "-journal"]) {
      final file = File("${main.path}$suffix");
      if (await file.exists()) await file.delete();
    }
  }

  // Each step must also work on a database that already has its changes: an
  // older app that downgraded the database lowers the stored version but keeps
  // the newer columns, and the steps then run again on the next upgrade.
  OnUpgrade get _steps => stepByStep(
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
      final testUrlExists = await _columnExists(
        schema.profileEntries.actualTableName,
        schema.profileEntries.testUrl.name,
      );
      if (!testUrlExists) {
        await m.addColumn(schema.profileEntries, schema.profileEntries.testUrl);
      }
    },
    from4To5: (m, schema) async {
      final table = schema.profileEntries.actualTableName;
      await m.deleteTable('geo_asset_entries');
      // A database lowered back to v4 can already have profile_override, with or
      // without test_url beside it (#2078): renaming onto it fails.
      final hasTestUrl = await _columnExists(table, 'test_url');
      if (!await _columnExists(table, schema.profileEntries.profileOverride.name)) {
        if (hasTestUrl) {
          await m.renameColumn(schema.profileEntries, 'test_url', schema.profileEntries.profileOverride);
        } else {
          await m.addColumn(schema.profileEntries, schema.profileEntries.profileOverride);
        }
      } else if (hasTestUrl) {
        await m.dropColumn(schema.profileEntries, 'test_url');
      }
      for (final column in [schema.profileEntries.userOverride, schema.profileEntries.populatedHeaders]) {
        if (!await _columnExists(table, column.name)) await m.addColumn(schema.profileEntries, column);
      }

      await m.createTable(schema.appProxyEntries);
    },
    from5To6: (m, schema) async {
      final profileOverrideExists = await _columnExists(schema.profileEntries.actualTableName, 'profile_override');
      if (profileOverrideExists) {
        await m.dropColumn(schema.profileEntries, 'profile_override');
      }
    },
    from6To7: (m, schema) async {
      final pinnedExists = await _columnExists(
        schema.profileEntries.actualTableName,
        schema.profileEntries.pinned.name,
      );
      if (!pinnedExists) {
        await m.addColumn(schema.profileEntries, schema.profileEntries.pinned);
      }
    },
  );

  Future<bool> _columnExists(String table, String column) async {
    final result = await customSelect('PRAGMA table_info($table);').get();
    return result.any((row) => row.data['name'] == column);
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
  TextColumn get userOverride => text().nullable()();
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();

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
