import 'package:drift/drift.dart';
import 'package:hiddify/core/database/app_database.dart';
import 'package:hiddify/core/database/tables/database_tables.dart';
import 'package:hiddify/features/profile/model/profile_sort_enum.dart';
import 'package:hiddify/utils/utils.dart';

part 'profile_data_source.g.dart';

abstract interface class ProfileDataSource {
  Future<ProfileEntry?> getById(String id);
  Future<ProfileEntry?> getByUrl(String url);
  Future<ProfileEntry?> getByName(String name);
  Stream<ProfileEntry?> watchActiveProfile();
  Stream<int> watchProfilesCount();
  Stream<List<ProfileEntry>> watchAll({
    required ProfilesSort sort,
    required SortMode sortMode,
  });
  Future<void> insert(ProfileEntriesCompanion entry);
  Future<void> edit(String id, ProfileEntriesCompanion entry);
  Future<void> deleteById(String id);
}

Map<SortMode, OrderingMode> orderMap = {
  SortMode.ascending: OrderingMode.asc,
  SortMode.descending: OrderingMode.desc,
};

@DriftAccessor(tables: [ProfileEntries])
class ProfileDao extends DatabaseAccessor<AppDatabase>
    with _$ProfileDaoMixin, InfraLogger
    implements ProfileDataSource {
  ProfileDao(super.db);

  @override
  Future<ProfileEntry?> getById(String id) {
    return (profileEntries.select()..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  @override
  Future<ProfileEntry?> getByUrl(String url) {
    return (select(profileEntries)
          ..where((tbl) => tbl.url.like('%$url%'))
          ..limit(1))
        .getSingleOrNull();
  }

  @override
  Future<ProfileEntry?> getByName(String name) {
    return (select(profileEntries)
          ..where((tbl) => tbl.name.equals(name))
          ..limit(1))
        .getSingleOrNull();
  }

  @override
  Stream<ProfileEntry?> watchActiveProfile() {
    return (profileEntries.select()
          ..where((tbl) => tbl.active.equals(true))
          ..limit(1))
        .watchSingleOrNull();
  }

  @override
  Stream<int> watchProfilesCount() {
    final count = profileEntries.id.count();
    return (profileEntries.selectOnly()..addColumns([count]))
        .map((exp) => exp.read(count)!)
        .watchSingle();
  }

  @override
  Stream<List<ProfileEntry>> watchAll({
    required ProfilesSort sort,
    required SortMode sortMode,
  }) {
    return (profileEntries.select()
          ..orderBy(
            [
              (tbl) => OrderingTerm(
                    expression: tbl.active,
                    mode: OrderingMode.desc,
                  ),
              (tbl) {
                final trafficRatio = (tbl.download + tbl.upload) / tbl.total;
                final isExpired =
                    tbl.expire.isSmallerOrEqualValue(DateTime.now());
                return OrderingTerm(
                  expression: (trafficRatio.isNull() |
                          trafficRatio.isSmallerThanValue(1)) &
                      (isExpired.isNull() | isExpired.equals(false)),
                  mode: OrderingMode.desc,
                );
              },
              switch (sort) {
                ProfilesSort.name => (tbl) => OrderingTerm(
                      expression: tbl.name,
                      mode: orderMap[sortMode]!,
                    ),
                ProfilesSort.lastUpdate => (tbl) => OrderingTerm(
                      expression: tbl.lastUpdate,
                      mode: orderMap[sortMode]!,
                    ),
              },
            ],
          ))
        .watch();
  }

  @override
  Future<void> insert(ProfileEntriesCompanion entry) async {
    await transaction(
      () async {
        if (entry.active.present && entry.active.value) {
          await update(profileEntries)
              .write(const ProfileEntriesCompanion(active: Value(false)));
        }
        await into(profileEntries).insert(entry);
      },
    );
  }

  @override
  Future<void> edit(String id, ProfileEntriesCompanion entry) async {
    await transaction(
      () async {
        
        if (entry.active.present && entry.active.value) {
          await update(profileEntries)
              .write(const ProfileEntriesCompanion(active: Value(false)));
        }
        await (update(profileEntries)..where((tbl) => tbl.id.equals(id)))
            .write(entry.copyWith(lastUpdate: Value(DateTime.now())));
      },
    );
  }

  @override
  Future<void> deleteById(String id) async {
    await transaction(
      () async {
        await (delete(profileEntries)..where((tbl) => tbl.id.equals(id))).go();
      },
    );
  }
}
