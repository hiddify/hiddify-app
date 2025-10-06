import 'package:drift/drift.dart';
import 'package:hiddify/core/db/provider/db_providers.dart';
import 'package:hiddify/core/db/v1/db_v1.dart' as db_v1;
import 'package:hiddify/core/db/v2/db_v2.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'db_v2_helper.g.dart';

@DriftAccessor(tables: [ProfileEntries])
class DbV2Dao extends DatabaseAccessor<DbV2> with _$DbV2DaoMixin, InfraLogger {
  DbV2Dao(super.db);

  Future<void> insert(List<db_v1.ProfileEntry> v1List) async {
    final v2List = <ProfileEntriesCompanion>[];
    for (final e in v1List) {
      switch (e.type) {
        case ProfileType.remote:
          v2List.add(
            ProfileEntriesCompanion.insert(
              id: e.id,
              type: e.type,
              active: e.active,
              name: e.name,
              url: Value(e.url),
              lastUpdate: e.lastUpdate,
              updateInterval: Value(e.updateInterval),
              upload: Value(e.upload),
              download: Value(e.download),
              total: Value(e.total),
              expire: Value(e.expire),
              webPageUrl: Value(e.webPageUrl),
              supportUrl: Value(e.supportUrl),
              profileOverride: Value(e.testUrl),
            ),
          );
        case ProfileType.local:
          v2List.add(ProfileEntriesCompanion.insert(id: e.id, type: e.type, active: e.active, name: e.name, lastUpdate: e.lastUpdate, profileOverride: Value(e.testUrl)));
      }
    }

    await batch((batch) {
      batch.insertAll(profileEntries, v2List);
    });
  }
}

@riverpod
DbV2Dao dbV2Helper(Ref ref) {
  return DbV2Dao(ref.watch(dbV2Provider));
}
