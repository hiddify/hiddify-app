import 'dart:io';

import 'package:drift/drift.dart';
import 'package:hiddify/core/db/db.dart';
import 'package:hiddify/features/app_based_routing/model/per_app_proxy_mode.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

/// What could still be read from a database that can not be opened, to add back once it was wiped.
class DbSalvage {
  const DbSalvage({required this.profiles, required this.appProxies});

  static const empty = DbSalvage(profiles: [], appProxies: []);

  final List<ProfileEntriesCompanion> profiles;
  final List<AppProxyEntriesCompanion> appProxies;
}

/// Reads the rows of the database [file] as they are, without migrating it: any version, missing or
/// extra columns, as long as SQLite still reads the table. A row that can not be read is skipped.
///
/// A config in [configsDir] without a row (the table could not be read at all) is added back as a
/// local profile named `Recovered N`: its subscription link is lost, but it still connects.
Future<DbSalvage> salvageDb(File file, {Directory? configsDir}) async {
  final profiles = <ProfileEntriesCompanion>[];
  final appProxies = <AppProxyEntriesCompanion>[];
  if (await file.exists()) {
    if (Platform.isAndroid) await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    Database? raw;
    try {
      raw = sqlite3.open(file.path, mode: OpenMode.readOnly);
      profiles.addAll(_rows(raw, 'profile_entries').map(_profile).nonNulls);
      appProxies.addAll(_rows(raw, 'app_proxy_entries').map(_appProxy).nonNulls);
    } catch (_) {
      // not a database any more: only the configs on disk are left
    } finally {
      raw?.dispose();
    }
  }

  // one active profile at most, as the app keeps it
  var activeSeen = false;
  for (final (i, profile) in profiles.indexed) {
    if (profile.active.value) {
      if (activeSeen) profiles[i] = profile.copyWith(active: const Value(false));
      activeSeen = true;
    }
  }

  if (configsDir != null && await configsDir.exists()) {
    final known = profiles.map((e) => e.id.value).toSet();
    final orphans = await configsDir
        .list()
        .where((e) => e is File && e.path.endsWith('.json') && !e.path.endsWith('.tmp.json'))
        .map((e) => p.basenameWithoutExtension(e.path))
        .where((id) => !known.contains(id))
        .toList();
    orphans.sort();
    for (final (i, id) in orphans.indexed) {
      profiles.add(
        ProfileEntriesCompanion.insert(
          id: id,
          type: ProfileType.local,
          active: false,
          name: 'Recovered ${i + 1}',
          lastUpdate: DateTime.now(),
        ),
      );
    }
  }
  return DbSalvage(profiles: profiles, appProxies: appProxies);
}

/// Adds [salvage] to a fresh [db].
Future<void> restoreSalvage(Db db, DbSalvage salvage) => db.batch((batch) {
  batch
    ..insertAll(db.profileEntries, salvage.profiles, mode: InsertMode.insertOrReplace)
    ..insertAll(db.appProxyEntries, salvage.appProxies, mode: InsertMode.insertOrReplace);
});

Iterable<Map<String, Object?>> _rows(Database raw, String table) {
  try {
    return raw.select('SELECT * FROM "$table"').toList();
  } on SqliteException {
    return const [];
  }
}

ProfileEntriesCompanion? _profile(Map<String, Object?> row) {
  try {
    final id = _text(row['id']);
    if (id == null || id.isEmpty) return null;
    final url = _text(row['url']);
    final type =
        ProfileType.values.asNameMap()[_text(row['type'])] ??
        (url != null && url.isNotEmpty ? ProfileType.remote : ProfileType.local);
    final name = _text(row['name']);
    final interval = _int(row['update_interval']);
    return ProfileEntriesCompanion.insert(
      id: id,
      type: type,
      active: _bool(row['active']) ?? false,
      name: name == null || name.isEmpty ? id : name,
      url: Value(url),
      lastUpdate: _date(row['last_update']) ?? DateTime.now(),
      updateInterval: Value(interval == null ? null : Duration(seconds: interval)),
      upload: Value(_int(row['upload'])),
      download: Value(_int(row['download'])),
      total: Value(_int(row['total'])),
      expire: Value(_date(row['expire'])),
      webPageUrl: Value(_text(row['web_page_url'])),
      supportUrl: Value(_text(row['support_url'])),
      populatedHeaders: Value(_text(row['populated_headers'])),
      userOverride: Value(_text(row['user_override'])),
      pinned: Value(_bool(row['pinned']) ?? false),
    );
  } catch (_) {
    return null;
  }
}

AppProxyEntriesCompanion? _appProxy(Map<String, Object?> row) {
  final mode = AppProxyMode.values.asNameMap()[_text(row['mode'])];
  final pkg = _text(row['pkg_name']);
  if (mode == null || pkg == null || pkg.isEmpty) return null;
  return AppProxyEntriesCompanion.insert(mode: mode, pkgName: pkg, flags: Value(_int(row['flags']) ?? 0));
}

String? _text(Object? v) => v is String ? v : v?.toString();

int? _int(Object? v) => switch (v) {
  final int i => i,
  final double d => d.toInt(),
  final String s => int.tryParse(s),
  _ => null,
};

bool? _bool(Object? v) => switch (_int(v)) {
  null => null,
  final i => i != 0,
};

/// drift stores a date as ISO 8601 text, or as Unix seconds in builds before that.
DateTime? _date(Object? v) => switch (v) {
  final String s => DateTime.tryParse(s) ?? _seconds(int.tryParse(s)),
  final int i => _seconds(i),
  _ => null,
};

DateTime? _seconds(int? s) => s == null ? null : DateTime.fromMillisecondsSinceEpoch(s * 1000);
