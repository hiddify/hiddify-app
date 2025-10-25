import 'package:drift/drift.dart';
import 'package:hiddify/core/db/provider/db_providers.dart';
import 'package:hiddify/core/db/v1/db_v1.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'db_v1_helper.g.dart';

@DriftAccessor(tables: [ProfileEntries])
class DbV1Dao extends DatabaseAccessor<DbV1> with _$DbV1DaoMixin, InfraLogger {
  DbV1Dao(super.db);

  Future<List<ProfileEntry>> getAllProfiles() async {
    return await profileEntries.select().get();
  }

  // Future<void> insertAll() async {
  //   final list = [
  //     ProfileEntriesCompanion.insert(
  //       id: 'a6078d64-40fc-452a-9f0d-f043bd549846',
  //       type: ProfileType.remote,
  //       active: false,
  //       name: '🆓 Github | Barry-far 🥷',
  //       url: const Value('https://raw.githubusercontent.com/barry-far/V2ray-config/main/Splitted-By-Protocol/vless.txt'),
  //       lastUpdate: DateTime.parse('2025-10-06T10:00:28.142930 +03:30'),
  //       updateInterval: const Value(Duration(hours: 1)),
  //       upload: const Value(29),
  //       download: const Value(12),
  //       total: const Value(10737418240000000),
  //       expire: Value(DateTime.parse('2050-09-08T16:02:11.000 +04:30')),
  //       webPageUrl: const Value('https://github.com/barry-far/V2ray-config'),
  //       supportUrl: const Value('https://github.com/barry-far/V2ray-config'),
  //     ),
  //     ProfileEntriesCompanion.insert(
  //       id: '08f1ab79-9880-4c78-bf08-820d4c653549',
  //       type: ProfileType.remote,
  //       active: false,
  //       name: '🆓 Github | Barry-far 🥷',
  //       url: const Value('https://raw.githubusercontent.com/barry-far/V2ray-config/main/Splitted-By-Protocol/ss.txt'),
  //       lastUpdate: DateTime.parse('2025-10-06T10:00:42.725969 +03:30'),
  //       updateInterval: const Value(Duration(hours: 1)),
  //       upload: const Value(29),
  //       download: const Value(12),
  //       total: const Value(10737418240000000),
  //       expire: Value(DateTime.parse('2050-09-08T16:02:11.000 +04:30')),
  //       webPageUrl: const Value('https://github.com/barry-far/V2ray-config'),
  //       supportUrl: const Value('https://github.com/barry-far/V2ray-config'),
  //     ),
  //     ProfileEntriesCompanion.insert(id: 'a7766de4-c3a4-4ed9-b8d0-f480c5e23c5f', type: ProfileType.local, active: true, name: '🆓 Git:barry-far | Sub6 🔥', lastUpdate: DateTime.parse('2025-10-06T10:55:48.159811 +03:30')),
  //   ];
  //   await transaction(() async {
  //     for (final e in list) {
  //       await into(profileEntries).insert(e);
  //     }
  //   });
  // }
}

@riverpod
DbV1Dao dbV1Helper(Ref ref) {
  return DbV1Dao(ref.watch(dbProvider));
}
