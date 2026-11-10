import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/db/db.dart';
import 'package:hiddify/core/db/db_recovery.dart';
import 'package:hiddify/features/app_based_routing/model/per_app_proxy_mode.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory dir;
  late File file;
  late Directory configs;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('db_recovery');
    file = File('${dir.path}/db.sqlite');
    configs = Directory('${dir.path}/configs')..createSync();
  });
  tearDown(() => dir.delete(recursive: true));

  test('adds back the profiles of the broken v4 database from #2078', () async {
    // user_version 4, with test_url and profile_override side by side
    sqlite3.open(file.path)
      ..execute('''
        CREATE TABLE profile_entries (id TEXT NOT NULL PRIMARY KEY, type TEXT NOT NULL, active INTEGER NOT NULL,
          name TEXT NOT NULL, url TEXT, last_update INTEGER NOT NULL, update_interval INTEGER, upload INTEGER,
          download INTEGER, total INTEGER, expire INTEGER, web_page_url TEXT, support_url TEXT, test_url TEXT,
          profile_override TEXT);
        INSERT INTO profile_entries VALUES
          ('r1', 'remote', 1, 'My sub', 'https://sub.example.com/x', 1700000000, 3600, 10, 20, 300, 1800000000,
           'https://panel.example.com', NULL, NULL, NULL),
          ('l1', 'local', 1, 'Local one', NULL, 1700000000, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
          ('', 'local', 0, 'no id', NULL, 1700000000, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
        PRAGMA user_version = 4;
      ''')
      ..dispose();
    File('${configs.path}/r1.json').writeAsStringSync('{}');
    File('${configs.path}/l1.json').writeAsStringSync('{}');

    final salvage = await salvageDb(file, configsDir: configs);
    final db = Db(NativeDatabase.memory());
    await restoreSalvage(db, salvage);
    final rows = await (db.select(db.profileEntries)..orderBy([(t) => OrderingTerm(expression: t.id)])).get();
    await db.close();

    expect(rows.map((e) => e.id), ['l1', 'r1']);
    final remote = rows[1];
    expect(remote.type, ProfileType.remote);
    expect(remote.name, 'My sub');
    expect(remote.url, 'https://sub.example.com/x');
    expect(remote.active, isTrue);
    expect(remote.lastUpdate, DateTime.fromMillisecondsSinceEpoch(1700000000 * 1000));
    expect(remote.updateInterval, const Duration(hours: 1));
    expect(remote.total, 300);
    expect(remote.webPageUrl, 'https://panel.example.com');
    // only one stays active
    expect(rows[0].active, isFalse);
    expect(rows[0].type, ProfileType.local);
  });

  test('reads a current database, app proxy entries too', () async {
    final source = Db(NativeDatabase(file));
    await source
        .into(source.profileEntries)
        .insert(
          ProfileEntriesCompanion.insert(
            id: 'a',
            type: ProfileType.remote,
            active: true,
            name: 'A',
            url: const Value('https://a'),
            lastUpdate: DateTime.utc(2026, 1, 2, 3, 4, 5),
            userOverride: const Value('{"x":1}'),
            pinned: const Value(true),
          ),
        );
    await source
        .into(source.appProxyEntries)
        .insert(AppProxyEntriesCompanion.insert(mode: AppProxyMode.exclude, pkgName: 'org.app', flags: const Value(3)));
    await source.close();

    final salvage = await salvageDb(file);
    final db = Db(NativeDatabase.memory());
    await restoreSalvage(db, salvage);
    final profile = await db.select(db.profileEntries).getSingle();
    final app = await db.select(db.appProxyEntries).getSingle();
    await db.close();

    expect(profile.lastUpdate.toUtc(), DateTime.utc(2026, 1, 2, 3, 4, 5));
    expect(profile.userOverride, '{"x":1}');
    expect(profile.pinned, isTrue);
    expect((app.mode, app.pkgName, app.flags), (AppProxyMode.exclude, 'org.app', 3));
  });

  test('a file that is no database leaves the configs on disk, added as local profiles', () async {
    file.writeAsStringSync('not a database at all, just garbage bytes' * 100);
    File('${configs.path}/b.json').writeAsStringSync('{}');
    File('${configs.path}/a.json').writeAsStringSync('{}');
    File('${configs.path}/a.tmp.json').writeAsStringSync('{}');

    final salvage = await salvageDb(file, configsDir: configs);
    final db = Db(NativeDatabase.memory());
    await restoreSalvage(db, salvage);
    final rows = await (db.select(db.profileEntries)..orderBy([(t) => OrderingTerm(expression: t.name)])).get();
    await db.close();

    expect(rows.map((e) => (e.id, e.name, e.type)), [
      ('a', 'Recovered 1', ProfileType.local),
      ('b', 'Recovered 2', ProfileType.local),
    ]);
  });

  test('no database file at all salvages nothing', () async {
    final salvage = await salvageDb(file);
    expect(salvage.profiles, isEmpty);
    expect(salvage.appProxies, isEmpty);
  });
}
