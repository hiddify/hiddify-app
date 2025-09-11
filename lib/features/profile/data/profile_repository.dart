import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hiddify/core/database/app_database.dart';
import 'package:hiddify/core/http_client/dio_http_client.dart';
import 'package:hiddify/core/utils/exception_handler.dart';
import 'package:hiddify/features/config_option/data/config_option_repository.dart';
import 'package:hiddify/features/connection/model/connection_failure.dart';
import 'package:hiddify/features/profile/data/profile_data_mapper.dart';
import 'package:hiddify/features/profile/data/profile_data_source.dart';
import 'package:hiddify/features/profile/data/profile_parser.dart';
import 'package:hiddify/features/profile/data/profile_path_resolver.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/model/profile_failure.dart';
import 'package:hiddify/features/profile/model/profile_sort_enum.dart';
import 'package:hiddify/singbox/service/singbox_service.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hiddify/utils/link_parsers.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

abstract interface class ProfileRepository {
  TaskEither<ProfileFailure, Unit> init();
  TaskEither<ProfileFailure, ProfileEntity?> getById(String id);
  Future<ProfileEntity?> getByName(String name);
  Stream<Either<ProfileFailure, ProfileEntity?>> watchActiveProfile();
  Stream<Either<ProfileFailure, bool>> watchHasAnyProfile();

  Stream<Either<ProfileFailure, List<ProfileEntity>>> watchAll({
    ProfilesSort sort = ProfilesSort.lastUpdate,
    SortMode sortMode = SortMode.ascending,
  });

  TaskEither<ProfileFailure, Unit> addByUrl(
    String url, {
    bool markAsActive = false,
    CancelToken? cancelToken,
  });
  TaskEither<ProfileFailure, Unit> updateContent(
    String profileId,
    String content,
  );
  TaskEither<ProfileFailure, Unit> addByContent(
    String content, {
    required String name,
    bool markAsActive = false,
  });

  TaskEither<ProfileFailure, Unit> add(
    RemoteProfileEntity baseProfile, {
    CancelToken? cancelToken,
  });

  TaskEither<ProfileFailure, String> generateConfig(String id);

  /// using [patchBaseProfile] name, url, etc will also be patched (useful when editing with a new url)
  TaskEither<ProfileFailure, Unit> updateSubscription(
    RemoteProfileEntity baseProfile, {
    bool patchBaseProfile = false,
    CancelToken? cancelToken,
  });

  TaskEither<ProfileFailure, Unit> patch(ProfileEntity profile);
  TaskEither<ProfileFailure, Unit> setAsActive(String id);
  TaskEither<ProfileFailure, Unit> deleteById(String id);
}

class ProfileRepositoryImpl with ExceptionHandler, InfraLogger implements ProfileRepository {
  ProfileRepositoryImpl({
    required this.profileDataSource,
    required this.profilePathResolver,
    required this.singbox,
    required this.configOptionRepository,
    required this.httpClient,
  });

  final ProfileDataSource profileDataSource;
  final ProfilePathResolver profilePathResolver;
  final SingboxService singbox;
  final ConfigOptionRepository configOptionRepository;
  final DioHttpClient httpClient;

  @override
  TaskEither<ProfileFailure, Unit> init() {
    return exceptionHandler(
      () async {
        if (!await profilePathResolver.directory.exists()) {
          await profilePathResolver.directory.create(recursive: true);
        }
        return right(unit);
      },
      ProfileUnexpectedFailure.new,
    );
  }

  @override
  TaskEither<ProfileFailure, ProfileEntity?> getById(String id) {
    return TaskEither.tryCatch(
      () => profileDataSource.getById(id).then((value) => value?.toEntity()),
      ProfileUnexpectedFailure.new,
    );
  }

  @override
  Future<ProfileEntity?> getByName(String name) async {
    return (await profileDataSource.getByName(name))?.toEntity();
  }

  @override
  Stream<Either<ProfileFailure, ProfileEntity?>> watchActiveProfile() {
    return profileDataSource.watchActiveProfile().map((event) => event?.toEntity()).handleExceptions(
      (error, stackTrace) {
        loggy.error("error watching active profile", error, stackTrace);
        return ProfileUnexpectedFailure(error, stackTrace);
      },
    );
  }

  @override
  Stream<Either<ProfileFailure, bool>> watchHasAnyProfile() {
    return profileDataSource.watchProfilesCount().map((event) => event != 0).handleExceptions(ProfileUnexpectedFailure.new);
  }

  @override
  Stream<Either<ProfileFailure, List<ProfileEntity>>> watchAll({
    ProfilesSort sort = ProfilesSort.lastUpdate,
    SortMode sortMode = SortMode.ascending,
  }) {
    return profileDataSource.watchAll(sort: sort, sortMode: sortMode).map((event) => event.map((e) => e.toEntity()).toList()).handleExceptions(ProfileUnexpectedFailure.new);
  }

  @override
  TaskEither<ProfileFailure, Unit> addByUrl(
    String url, {
    bool markAsActive = false,
    CancelToken? cancelToken,
  }) {
    return exceptionHandler(
      () async {
        final existingProfile = await profileDataSource.getByUrl(url).then((value) => value?.toEntity());
        if (existingProfile case RemoteProfileEntity()) {
          loggy.info("profile with same url already exists, updating");
          final baseProfile = markAsActive ? existingProfile.copyWith(active: true) : existingProfile;
          return updateSubscription(
            baseProfile,
            cancelToken: cancelToken,
          ).run();
        }

        final profileId = const Uuid().v4();
        return fetch(url, profileId, cancelToken: cancelToken)
            .flatMap(
              (profile) => TaskEither(
                () async {
                  await profileDataSource.insert(
                    profile.copyWith(id: profileId, active: markAsActive).toEntry(),
                  );
                  return right(unit);
                },
              ),
            )
            .run();
      },
      (error, stackTrace) {
        loggy.warning("error adding profile by url", error, stackTrace);
        return ProfileUnexpectedFailure(error, stackTrace);
      },
    );
  }

  @visibleForTesting
  TaskEither<ProfileFailure, Unit> validateConfig(
    String path,
    String tempPath,
    bool debug,
  ) {
    return exceptionHandler(
      () async {
        singbox.changeOptions(await configOptionRepository.getConfigOptions()).run();

        return singbox.validateConfigByPath(path, tempPath, debug).mapLeft(ProfileFailure.invalidConfig).run();
      },
      ProfileUnexpectedFailure.new,
    );
  }

  @override
  TaskEither<ProfileFailure, Unit> updateContent(
    String profileId,
    String content,
  ) {
    return exceptionHandler(
      () async {
        final file = profilePathResolver.file(profileId);
        final tempFile = profilePathResolver.tempFile(profileId);

        try {
          await tempFile.writeAsString(content);
          return await validateConfig(file.path, tempFile.path, false).run();
        } finally {
          if (tempFile.existsSync()) tempFile.deleteSync();
        }
      },
      (error, stackTrace) {
        loggy.warning("error adding profile by content", error, stackTrace);
        return ProfileUnexpectedFailure(error, stackTrace);
      },
    );
  }

  @override
  TaskEither<ProfileFailure, Unit> addByContent(
    String content, {
    required String name,
    bool markAsActive = false,
  }) {
    return exceptionHandler(
      () async {
        final profileId = const Uuid().v4();

        return await updateContent(profileId, content)
            .andThen(
              () => TaskEither(() async {
                final profile = LocalProfileEntity(
                  id: profileId,
                  active: markAsActive,
                  name: name,
                  lastUpdate: DateTime.now(),
                );
                await profileDataSource.insert(profile.toEntry());

                return right(unit);
              }),
            )
            .run();
      },
      (error, stackTrace) {
        loggy.warning("error adding profile by content", error, stackTrace);
        return ProfileUnexpectedFailure(error, stackTrace);
      },
    );
  }

  @override
  TaskEither<ProfileFailure, Unit> add(
    RemoteProfileEntity baseProfile, {
    CancelToken? cancelToken,
  }) {
    return exceptionHandler(
      () async {
        return fetch(baseProfile.url, baseProfile.id, cancelToken: cancelToken)
            .flatMap(
              (remoteProfile) => TaskEither(() async {
                await profileDataSource.insert(
                  baseProfile
                      .copyWith(
                        subInfo: remoteProfile.subInfo,
                        lastUpdate: DateTime.now(),
                      )
                      .toEntry(),
                );
                return right(unit);
              }),
            )
            .run();
      },
      (error, stackTrace) {
        loggy.warning("error adding profile", error, stackTrace);
        return ProfileUnexpectedFailure(error, stackTrace);
      },
    );
  }

  @override
  TaskEither<ProfileFailure, String> generateConfig(String id) {
    return TaskEither<ProfileFailure, String>.Do(
      ($) async {
        final configFile = profilePathResolver.file(id);

        final options = await configOptionRepository.getConfigOptions();

        singbox.changeOptions(options).mapLeft(InvalidConfigOption.new).run();

        return await $(
          singbox.generateFullConfigByPath(configFile.path).mapLeft(ProfileFailure.unexpected),
        );
      },
    ).handleExceptions(ProfileFailure.unexpected);
  }

  @override
  TaskEither<ProfileFailure, Unit> updateSubscription(
    RemoteProfileEntity baseProfile, {
    bool patchBaseProfile = false,
    CancelToken? cancelToken,
  }) {
    return exceptionHandler(
      () async {
        loggy.debug(
          "updating profile [${baseProfile.name} (${baseProfile.id})]",
        );
        return fetch(baseProfile.url, baseProfile.id, cancelToken: cancelToken)
            .flatMap(
              (remoteProfile) => TaskEither(
                () async {
                  final profilePatch = remoteProfile.subInfoPatch().copyWith(lastUpdate: Value(DateTime.now()), active: Value(baseProfile.active));

                  await profileDataSource.edit(
                    baseProfile.id,
                    patchBaseProfile
                        ? profilePatch.copyWith(
                            name: Value(baseProfile.name),
                            url: Value(baseProfile.url),
                            testUrl: Value(baseProfile.testUrl),
                            updateInterval: Value(baseProfile.options?.updateInterval),
                          )
                        : profilePatch,
                  );
                  return right(unit);
                },
              ),
            )
            .run();
      },
      (error, stackTrace) {
        loggy.warning("error updating profile", error, stackTrace);
        return ProfileUnexpectedFailure(error, stackTrace);
      },
    );
  }

  @override
  TaskEither<ProfileFailure, Unit> patch(ProfileEntity profile) {
    return exceptionHandler(
      () async {
        loggy.debug(
          "editing profile [${profile.name} (${profile.id})]",
        );
        await profileDataSource.edit(profile.id, profile.toEntry());
        return right(unit);
      },
      (error, stackTrace) {
        loggy.warning("error editing profile", error, stackTrace);
        return ProfileUnexpectedFailure(error, stackTrace);
      },
    );
  }

  @override
  TaskEither<ProfileFailure, Unit> setAsActive(String id) {
    return TaskEither.tryCatch(
      () async {
        await profileDataSource.edit(
          id,
          const ProfileEntriesCompanion(active: Value(true)),
        );
        return unit;
      },
      ProfileUnexpectedFailure.new,
    );
  }

  @override
  TaskEither<ProfileFailure, Unit> deleteById(String id) {
    return TaskEither.tryCatch(
      () async {
        await profileDataSource.deleteById(id);
        await profilePathResolver.file(id).delete();
        return unit;
      },
      ProfileUnexpectedFailure.new,
    );
  }

  static final _subInfoHeaders = [
    'profile-title',
    'content-disposition',
    'subscription-userinfo',
    'profile-update-interval',
    'support-url',
    'profile-web-page-url',
    'test-url',
  ];

  @visibleForTesting
  TaskEither<ProfileFailure, RemoteProfileEntity> fetch(
    String url,
    String fileName, {
    CancelToken? cancelToken,
  }) {
    return TaskEither(
      () async {
        final file = profilePathResolver.file(fileName);
        final tempFile = profilePathResolver.tempFile(fileName);

        try {
          final configs = await configOptionRepository.getConfigOptions();

          final response = await httpClient.download(
            url.trim(),
            tempFile.path,
            cancelToken: cancelToken,
            userAgent: configs.useXrayCoreWhenPossible ? "v2rayNG/1.8.23" : null,
          );
          final headers = await _populateHeaders(response.headers.map, tempFile.path);
          return await validateConfig(file.path, tempFile.path, false)
              .andThen(
                () => TaskEither(() async {
                  final profile = ProfileParser.parse(url, headers);
                  return right(profile);
                }),
              )
              .run();
        } finally {
          if (tempFile.existsSync()) tempFile.deleteSync();
        }
      },
    );
  }

  Future<Map<String, List<String>>> _populateHeaders(
    Map<String, List<String>> headers,
    String path,
  ) async {
    var headersFound = 0;
    for (final key in _subInfoHeaders) {
      if (headers.containsKey(key)) headersFound++;
    }
    if (headersFound >= 4) return headers;

    loggy.debug(
      "only [$headersFound] headers found, checking file content for possible information",
    );
    final content = await File(path).readAsString();
    final contentHeaders = parseHeadersFromContent(content);
    for (final entry in contentHeaders.entries) {
      if (!headers.keys.contains(entry.key) && entry.value.isNotEmpty) {
        headers[entry.key] = entry.value;
      }
    }

    return headers;
  }

  static Map<String, List<String>> parseHeadersFromContent(String content) {
    final headers = <String, List<String>>{};
    final content_ = safeDecodeBase64(content);
    final lines = content_.split("\n");
    final linesToProcess = lines.length < 10 ? lines.length : 10;
    for (int i = 0; i < linesToProcess; i++) {
      final line = lines[i];
      if (line.startsWith("#") || line.startsWith("//")) {
        final index = line.indexOf(':');
        if (index == -1) continue;
        final key = line.substring(0, index).replaceFirst(RegExp("^#|//"), "").trim().toLowerCase();
        final value = line.substring(index + 1).trim();
        if (!headers.keys.contains(key) && _subInfoHeaders.contains(key) && value.isNotEmpty) {
          headers[key] = [value];
        }
      }
    }
    return headers;
  }
}
