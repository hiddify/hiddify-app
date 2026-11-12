import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hiddify/core/db/db.dart';

import 'package:hiddify/core/utils/exception_handler.dart';
import 'package:hiddify/features/profile/data/profile_data_mapper.dart';
import 'package:hiddify/features/profile/data/profile_data_source.dart';
import 'package:hiddify/features/profile/data/profile_parser.dart';
import 'package:hiddify/features/profile/data/profile_path_resolver.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/model/profile_failure.dart';
import 'package:hiddify/features/profile/model/profile_sort_enum.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/hiddifycore/hiddify_core_service.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:uuid/uuid.dart';

abstract interface class ProfileRepository {
  TaskEither<ProfileFailure, Unit> init();
  TaskEither<ProfileFailure, ProfileEntity?> getById(String id);
  TaskEither<ProfileFailure, Unit> setAsActive(String id);
  TaskEither<ProfileFailure, Unit> setPinned(String id, bool pinned);

  /// Saves the user's choices for the profile, without reading its configs again.
  TaskEither<ProfileFailure, Unit> setUserOverride(String id, UserOverride userOverride);
  TaskEither<ProfileFailure, Unit> deleteById(String id, bool isActive);
  Stream<Either<ProfileFailure, ProfileEntity?>> watchActiveProfile();
  Stream<Either<ProfileFailure, bool>> watchHasAnyProfile();
  Stream<Either<ProfileFailure, List<ProfileEntity>>> watchAll({
    ProfilesSort sort = ProfilesSort.lastUpdate,
    SortMode sortMode = SortMode.ascending,
  });

  /// Adds the profile at [url], or updates it when one with that URL exists. With [activate] (the user adding a
  /// profile, not an update), an existing one becomes the active profile, as a new one does.
  TaskEither<ProfileFailure, Unit> upsertRemote(
    String url, {
    UserOverride? userOverride,
    CancelToken? cancelToken,
    bool activate = false,
  });

  /// Adds [content] as a local profile; returns its id.
  TaskEither<ProfileFailure, String> addLocal(String content, {UserOverride? userOverride});
  TaskEither<ProfileFailure, Unit> offlineUpdate(ProfileEntity nProfile, String nContent);
  TaskEither<ProfileFailure, Unit> validateConfig(String path, String tempPath, String? profileOverride, bool debug);
  TaskEither<ProfileFailure, String> generateConfig(String id);
  TaskEither<ProfileFailure, String> getRawConfig(String id);
}

class ProfileRepositoryImpl with ExceptionHandler, InfraLogger implements ProfileRepository {
  ProfileRepositoryImpl({
    required ProfileDataSource profileDataSource,
    required ProfilePathResolver profilePathResolver,
    required HiddifyCoreService singbox,
    required ConfigOptionRepository configOptionRepository,
    required ProfileParser profileParser,
  }) : _profileParser = profileParser,
       _configOptionRepo = configOptionRepository,
       _singbox = singbox,
       _profilePathResolver = profilePathResolver,
       _profileDataSource = profileDataSource;

  final ProfileDataSource _profileDataSource;
  final ProfilePathResolver _profilePathResolver;
  final HiddifyCoreService _singbox;
  final ConfigOptionRepository _configOptionRepo;
  final ProfileParser _profileParser;

  @override
  TaskEither<ProfileFailure, Unit> init() {
    return exceptionHandler(() async {
      if (!kIsWeb) {
        if (!await _profilePathResolver.directory.exists()) {
          await _profilePathResolver.directory.create(recursive: true);
        }
      }

      return right(unit);
    }, ProfileUnexpectedFailure.new);
  }

  @override
  TaskEither<ProfileFailure, ProfileEntity?> getById(String id) {
    return TaskEither.tryCatch(
      () => _profileDataSource.getById(id).then((value) => value?.toEntity()),
      ProfileUnexpectedFailure.new,
    );
  }

  @override
  TaskEither<ProfileFailure, Unit> setAsActive(String id) {
    return TaskEither.tryCatch(() async {
      await _profileDataSource.edit(id, const ProfileEntriesCompanion(active: Value(true)));
      return unit;
    }, ProfileUnexpectedFailure.new);
  }

  @override
  TaskEither<ProfileFailure, Unit> setPinned(String id, bool pinned) {
    return TaskEither.tryCatch(() async {
      await _profileDataSource.edit(id, ProfileEntriesCompanion(pinned: Value(pinned)));
      return unit;
    }, ProfileUnexpectedFailure.new);
  }

  @override
  TaskEither<ProfileFailure, Unit> setUserOverride(String id, UserOverride userOverride) {
    return TaskEither.tryCatch(() async {
      await _profileDataSource.edit(id, ProfileEntriesCompanion(userOverride: Value(userOverride.toStr())));
      return unit;
    }, ProfileUnexpectedFailure.new);
  }

  @override
  TaskEither<ProfileFailure, Unit> deleteById(String id, bool isActive) {
    return TaskEither.tryCatch(() async {
      await _profileDataSource.deleteById(id, isActive);
      await _profilePathResolver.file(id).delete();
      return unit;
    }, ProfileUnexpectedFailure.new);
  }

  @override
  Stream<Either<ProfileFailure, ProfileEntity?>> watchActiveProfile() {
    return _profileDataSource.watchActiveProfile().map((event) => event?.toEntity()).handleExceptions((
      error,
      stackTrace,
    ) {
      loggy.error("error watching active profile", error, stackTrace);
      return ProfileUnexpectedFailure(error, stackTrace);
    });
  }

  @override
  Stream<Either<ProfileFailure, bool>> watchHasAnyProfile() {
    return _profileDataSource
        .watchProfilesCount()
        .map((event) => event != 0)
        .handleExceptions(ProfileUnexpectedFailure.new);
  }

  /// [entry] as a profile, or null when it can not be read, logged.
  ProfileEntity? _readable(ProfileEntry entry) {
    try {
      return entry.toEntity();
    } catch (error, stackTrace) {
      loggy.warning("profile [${entry.id}] (${entry.name}) can not be read, left out of the list", error, stackTrace);
      return null;
    }
  }

  @override
  Stream<Either<ProfileFailure, List<ProfileEntity>>> watchAll({
    ProfilesSort sort = ProfilesSort.lastUpdate,
    SortMode sortMode = SortMode.ascending,
  }) {
    return _profileDataSource
        .watchAll(sort: sort, sortMode: sortMode)
        // each profile on its own: one that can not be read is left out, not every profile with it
        .map((event) => [for (final entry in event) ?_readable(entry)])
        .handleExceptions(ProfileUnexpectedFailure.new);
  }

  @override
  TaskEither<ProfileFailure, Unit> upsertRemote(
    String url, {
    UserOverride? userOverride,
    CancelToken? cancelToken,
    bool activate = false,
  }) =>
      TaskEither.tryCatch(() async {
        final profEntity = await _profileDataSource.getByUrl(url).then((profEntry) => profEntry?.toEntity());
        // adding a profile that is already there selects it, before the update, which may fail on a server that
        // is down: the profile is there either way
        if (activate && profEntity != null && !profEntity.active) {
          await _profileDataSource.edit(profEntity.id, const ProfileEntriesCompanion(active: Value(true)));
        }
        return profEntity;
      }, ProfileFailure.unexpected).flatMap((profEntity) {
        // if profile is null, generate id
        final id = profEntity?.id ?? const Uuid().v4();
        final file = _profilePathResolver.file(id);
        final tempFile = _profilePathResolver.tempFile(id);
        final TaskEither<ProfileFailure, Unit> task;
        if (profEntity != null && profEntity is RemoteProfileEntity) {
          // Update
          if (userOverride != null) {
            profEntity = profEntity.copyWith(userOverride: userOverride);
          }
          task = _profileParser
              .updateRemote(rp: profEntity, tempFilePath: tempFile.path, cancelToken: cancelToken)
              .flatMap(
                (profEntity) =>
                    validateConfig(
                      file.path,
                      tempFile.path,
                      ProfileParser.profileOverrideHelper(profile: profEntity),
                      false,
                    ).flatMap(
                      (unit) => TaskEither.tryCatch(() async {
                        await _profileDataSource.edit(id, profEntity);
                        return unit;
                      }, ProfileFailure.unexpected),
                    ),
              );
        } else {
          // Add
          task = _profileParser
              .addRemote(
                id: id,
                url: url,
                tempFilePath: tempFile.path,
                userOverride: userOverride,
                cancelToken: cancelToken,
              )
              .flatMap(
                (profEntity) =>
                    validateConfig(
                      file.path,
                      tempFile.path,
                      ProfileParser.profileOverrideHelper(profile: profEntity),
                      false,
                    ).flatMap(
                      (unit) => TaskEither.tryCatch(() async {
                        await _profileDataSource.insert(profEntity);
                        return unit;
                      }, ProfileFailure.unexpected),
                    ),
              );
        }
        // The task is lazy: run it inside the try, so finally runs after it, not before.
        return TaskEither(() async {
          try {
            return await task.run();
          } finally {
            if (tempFile.existsSync()) tempFile.deleteSync();
          }
        });
      });

  @override
  TaskEither<ProfileFailure, String> addLocal(String content, {UserOverride? userOverride}) =>
      TaskEither.tryCatch(() async {
        final id = const Uuid().v4();
        final file = _profilePathResolver.file(id);
        final tempFile = _profilePathResolver.tempFile(id);
        try {
          await tempFile.writeAsString(content);
          final task = _profileParser
              .addLocal(id: id, content: content, tempFilePath: tempFile.path, userOverride: userOverride)
              .flatMap(
                (profEntity) =>
                    validateConfig(
                      file.path,
                      tempFile.path,
                      ProfileParser.profileOverrideHelper(profile: profEntity),
                      false,
                    ).flatMap(
                      (_) => TaskEither.tryCatch(() async {
                        await _profileDataSource.insert(profEntity);
                        return id;
                      }, ProfileFailure.unexpected),
                    ),
              );
          return (await task.run()).getOrElse((l) => throw l);
        } finally {
          if (tempFile.existsSync()) tempFile.deleteSync();
        }
      }, ProfileFailure.unexpected);

  @override
  TaskEither<ProfileFailure, Unit> offlineUpdate(ProfileEntity profile, String nContent) =>
      TaskEither.tryCatch(
        () async => await _profileDataSource.getById(profile.id).then((profEntry) => profEntry?.toEntity()),
        ProfileFailure.unexpected,
      ).flatMap((oProfile) {
        if (oProfile == null || oProfile.runtimeType != profile.runtimeType) throw const ProfileFailure.notFound();
        if (profile.userOverride == null) loggy.warning('Updaing profile content with "userOverride" == null');
        final id = oProfile.id;
        final file = _profilePathResolver.file(id);
        final tempFile = _profilePathResolver.tempFile(id);
        final task = TaskEither.tryCatch(() async => await tempFile.writeAsString(nContent), ProfileFailure.unexpected)
            .flatMap(
              (_) =>
                  TaskEither.fromEither(
                    _profileParser.offlineUpdate(
                      profile: oProfile.copyWith(userOverride: profile.userOverride),
                      tempFilePath: tempFile.path,
                    ),
                  ).flatMap(
                    (profEntity) =>
                        validateConfig(
                          file.path,
                          tempFile.path,
                          ProfileParser.profileOverrideHelper(profile: profEntity),
                          false,
                        ).flatMap(
                          (unit) => TaskEither.tryCatch(() async {
                            await _profileDataSource.edit(id, profEntity);
                            return unit;
                          }, ProfileFailure.unexpected),
                        ),
                  ),
            );
        // The task is lazy: run it inside the try, so finally runs after it, not before.
        return TaskEither(() async {
          try {
            return await task.run();
          } finally {
            if (tempFile.existsSync()) tempFile.deleteSync();
          }
        });
      });

  @override
  TaskEither<ProfileFailure, Unit> validateConfig(String path, String tempPath, String? profileOverride, bool debug) =>
      TaskEither.fromEither(_configOptionRepo.fullOptionsOverrided(profileOverride))
          .mapLeft((configOptionFailure) => ProfileFailure.invalidConfig(null, configOptionFailure))
          .flatMap(
            (overridedOptions) => _singbox
                .changeOptions(overridedOptions)
                .mapLeft(ProfileFailure.invalidConfig)
                .flatMap(
                  (_) => _singbox.validateConfigByPath(path, tempPath, debug).mapLeft(ProfileFailure.invalidConfig),
                ),
          );

  @override
  TaskEither<ProfileFailure, String> generateConfig(String id) => TaskEither.fromEither(
    Either.tryCatch(() => _profilePathResolver.file(id), ProfileFailure.unexpected),
  ).flatMap((configFile) => _singbox.generateFullConfigByPath(configFile.path).mapLeft(ProfileFailure.unexpected));

  @override
  TaskEither<ProfileFailure, String> getRawConfig(String id) {
    return TaskEither.fromEither(
      Either.tryCatch(() => _profilePathResolver.file(id), ProfileFailure.unexpected),
    ).flatMap((configFile) => TaskEither.tryCatch(() => configFile.readAsString(), ProfileFailure.unexpected));
  }
}
