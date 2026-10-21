import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hiddify/core/db/db.dart';
import 'package:hiddify/features/profile/data/profile_data_mapper.dart';
import 'package:hiddify/features/profile/data/profile_data_source.dart';
import 'package:hiddify/features/profile/data/profile_parser.dart';
import 'package:hiddify/features/profile/data/profile_path_resolver.dart';
import 'package:hiddify/features/profile/data/profile_repository.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/model/profile_failure.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/hiddifycore/hiddify_core_service.dart';

/// Writes the temp file inside the task, like the real download does.
class _FakeParser implements ProfileParser {
  TaskEither<ProfileFailure, ProfileEntriesCompanion> _download(String tempFilePath) => TaskEither(() async {
    await File(tempFilePath).writeAsString('{}');
    return right(const ProfileEntriesCompanion());
  });

  @override
  TaskEither<ProfileFailure, ProfileEntriesCompanion> addRemote({
    required String id,
    required String url,
    required String tempFilePath,
    required UserOverride? userOverride,
    CancelToken? cancelToken,
  }) => _download(tempFilePath);

  @override
  TaskEither<ProfileFailure, ProfileEntriesCompanion> updateRemote({
    required RemoteProfileEntity rp,
    required String tempFilePath,
    CancelToken? cancelToken,
  }) => _download(tempFilePath);

  @override
  Either<ProfileFailure, ProfileEntriesCompanion> offlineUpdate({
    required ProfileEntity profile,
    required String tempFilePath,
  }) => right(const ProfileEntriesCompanion());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDataSource implements ProfileDataSource {
  _FakeDataSource([this.entry]);

  final ProfileEntry? entry;

  @override
  Future<ProfileEntry?> getById(String id) async => entry;

  @override
  Future<ProfileEntry?> getByUrl(String url) async => entry;

  @override
  Future<void> insert(ProfileEntriesCompanion entry) async {}

  @override
  Future<void> edit(String id, ProfileEntriesCompanion entry) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedCore implements HiddifyCoreService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedOptions implements ConfigOptionRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Stands in for the core check: it records whether the temp file still exists when the config is validated.
class _Repo extends ProfileRepositoryImpl {
  _Repo(ProfileDataSource dataSource, ProfilePathResolver paths, {this.valid = true})
    : super(
        profileDataSource: dataSource,
        profilePathResolver: paths,
        singbox: _UnusedCore(),
        configOptionRepository: _UnusedOptions(),
        profileParser: _FakeParser(),
      );

  final bool valid;
  bool? tempFileSeen;

  @override
  TaskEither<ProfileFailure, Unit> validateConfig(String path, String tempPath, String? profileOverride, bool debug) =>
      TaskEither(() async {
        tempFileSeen = File(tempPath).existsSync();
        return valid ? right(unit) : left(const ProfileFailure.invalidConfig());
      });
}

void main() {
  late Directory root;
  late ProfilePathResolver paths;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('hiddify_profile_test');
    paths = ProfilePathResolver(root);
    await paths.directory.create();
  });

  tearDown(() => root.delete(recursive: true));

  /// The `<id>.tmp.json` files left in the configs folder.
  List<String> leftTempFiles() =>
      paths.directory.listSync().map((f) => f.path).where((path) => path.endsWith('.tmp.json')).toList();

  final remoteEntry = ProfileEntry(
    id: 'remote-id',
    type: ProfileType.remote,
    active: true,
    name: 'remote',
    url: 'https://example.com/sub',
    lastUpdate: DateTime(2026),
    pinned: false,
  );

  group("temp file is deleted after the task", () {
    test("upsertRemote adds a profile", () async {
      final repo = _Repo(_FakeDataSource(), paths);
      final result = await repo.upsertRemote('https://example.com/sub').run();
      expect(result.isRight(), true);
      expect(repo.tempFileSeen, true);
      expect(leftTempFiles(), isEmpty);
    });

    test("upsertRemote fails to add a profile", () async {
      final repo = _Repo(_FakeDataSource(), paths, valid: false);
      final result = await repo.upsertRemote('https://example.com/sub').run();
      expect(result.isLeft(), true);
      expect(repo.tempFileSeen, true);
      expect(leftTempFiles(), isEmpty);
    });

    test("upsertRemote updates a profile", () async {
      final repo = _Repo(_FakeDataSource(remoteEntry), paths);
      final result = await repo.upsertRemote('https://example.com/sub').run();
      expect(result.isRight(), true);
      expect(repo.tempFileSeen, true);
      expect(leftTempFiles(), isEmpty);
    });

    test("offlineUpdate updates a profile", () async {
      final repo = _Repo(_FakeDataSource(remoteEntry), paths);
      final result = await repo.offlineUpdate(remoteEntry.toEntity(), '{}').run();
      expect(result.isRight(), true);
      expect(repo.tempFileSeen, true);
      expect(leftTempFiles(), isEmpty);
    });
  });
}
