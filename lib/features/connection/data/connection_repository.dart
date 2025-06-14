import 'package:fpdart/fpdart.dart';
import 'package:hiddify/core/model/directories.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/core/utils/exception_handler.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/features/settings/notifier/warp_option_notifier.dart';

import 'package:hiddify/features/connection/model/connection_failure.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/profile/data/profile_parser.dart';

import 'package:hiddify/features/profile/data/profile_path_resolver.dart';
import 'package:hiddify/hiddifycore/hiddify_core_service.dart';
import 'package:hiddify/singbox/model/singbox_config_option.dart';
import 'package:hiddify/singbox/model/singbox_status.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:meta/meta.dart';

abstract interface class ConnectionRepository {
  SingboxConfigOption? get configOptionsSnapshot;

  TaskEither<ConnectionFailure, Unit> setup();
  Stream<ConnectionStatus> watchConnectionStatus();
  TaskEither<ConnectionFailure, Unit> connect(
    String fileName,
    String profileName,
    bool disableMemoryLimit,
    String? override,
  );
  TaskEither<ConnectionFailure, Unit> disconnect();
  TaskEither<ConnectionFailure, Unit> reconnect(
    String fileName,
    String profileName,
    bool disableMemoryLimit,
    String? override,
  );
}

class ConnectionRepositoryImpl with ExceptionHandler, InfraLogger implements ConnectionRepository {
  ConnectionRepositoryImpl({
    required this.ref,
    required this.directories,
    required this.singbox,
    required this.configOptionRepository,
    required this.profilePathResolver,
  });

  final Ref ref;

  final Directories directories;
  final HiddifyCoreService singbox;

  final ConfigOptionRepository configOptionRepository;
  final ProfilePathResolver profilePathResolver;

  SingboxConfigOption? _configOptionsSnapshot;
  @override
  SingboxConfigOption? get configOptionsSnapshot => _configOptionsSnapshot;

  bool _initialized = false;

  @override
  Stream<ConnectionStatus> watchConnectionStatus() {
    return singbox.watchStatus().map(
          (event) => switch (event) {
            SingboxStopped(:final alert?, :final message) => Disconnected(
                switch (alert) {
                  SingboxAlert.emptyConfiguration => ConnectionFailure.invalidConfig(message),
                  SingboxAlert.requestNotificationPermission => ConnectionFailure.missingNotificationPermission(message),
                  SingboxAlert.requestVPNPermission => ConnectionFailure.missingVpnPermission(message),
                  SingboxAlert.startCommandServer || SingboxAlert.createService || SingboxAlert.startService => ConnectionFailure.unexpected(message),
                },
              ),
            SingboxStopped() => const Disconnected(),
            SingboxStarting() => const Connecting(),
            SingboxStarted() => const Connected(),
            SingboxStopping() => const Disconnecting(),
          },
        );
  }

  @visibleForTesting
  TaskEither<ConnectionFailure, SingboxConfigOption> getConfigOption() {
    return TaskEither<ConnectionFailure, SingboxConfigOption>.Do(
      ($) async {
        final options = await $(
          configOptionRepository.getFullSingboxConfigOption().mapLeft((l) => const InvalidConfigOption()),
        );

        return $(
          TaskEither(
            () async {
              // final geoip = geoAssetPathResolver.resolvePath(options.geoipPath);
              // final geosite =
              //     geoAssetPathResolver.resolvePath(options.geositePath);
              // if (!await File(geoip).exists() ||
              //     !await File(geosite).exists()) {
              //   return left(const ConnectionFailure.missingGeoAssets());
              // }
              return right(options);
            },
          ),
        );
      },
    ).handleExceptions(UnexpectedConnectionFailure.new);
  }

  @visibleForTesting
  TaskEither<ConnectionFailure, Unit> applyConfigOption(SingboxConfigOption main, String? override) {
    return TaskEither<ConnectionFailure, Unit>.Do(
      ($) async {
        _configOptionsSnapshot = main;
        final mainJson = ProfileParser.applyOverride(main.toJson(), override);
        final isWarpLicenseAgreed = ref.read(warpLicenseNotifierProvider);
        final isWarpEnabled = (mainJson['warp'] as Map)['enable'] == true;
        if (!isWarpLicenseAgreed && isWarpEnabled) {
          final isAgreed = await ref.read(dialogNotifierProvider.notifier).showWarpLicense();
          if (isAgreed == true) {
            await ref.read(warpLicenseNotifierProvider.notifier).agree();
            final options = await $(getConfigOption());
            return await $(applyConfigOption(options, override));
          } else {
            throw const MissingWarpLicense();
          }
        }
        return $(singbox.changeOptions(SingboxConfigOption.fromJson(mainJson)).mapLeft(InvalidConfigOption.new));
      },
    ).handleExceptions((e, s) => e is MissingWarpLicense ? e : UnexpectedConnectionFailure(e, s));
  }

  @override
  TaskEither<ConnectionFailure, Unit> setup() {
    if (_initialized) return TaskEither.of(unit);
    return exceptionHandler(
      () {
        loggy.debug("setting up singbox");
        return singbox
            .setup(
              directories,
              false,
            )
            .map((r) {
              _initialized = true;
              return r;
            })
            .mapLeft(UnexpectedConnectionFailure.new)
            .run();
      },
      UnexpectedConnectionFailure.new,
    );
  }

  @override
  TaskEither<ConnectionFailure, Unit> connect(
    String fileName,
    String profileName,
    bool disableMemoryLimit,
    String? override,
  ) {
    return TaskEither<ConnectionFailure, Unit>.Do(
      ($) async {
        final options = await $(getConfigOption());
        loggy.info(
          "config options: ${options.format()}\nMemory Limit: ${!disableMemoryLimit}",
        );

        await $(
          TaskEither(() async {
            // if (options.enableTun) {
            //   final hasPrivilege = await platformSource.checkPrivilege();
            //   if (!hasPrivilege) {
            //     loggy.warning("missing privileges for tun mode");
            //     return left(const MissingPrivilege());
            //   }
            // }
            return right(unit);
          }),
        );
        await $(setup());
        await $(applyConfigOption(options, override));
        return await $(
          singbox
              .start(
                profilePathResolver.file(fileName).path,
                profileName,
                disableMemoryLimit,
              )
              .mapLeft(UnexpectedConnectionFailure.new),
        );
      },
    ).handleExceptions(UnexpectedConnectionFailure.new);
  }

  @override
  TaskEither<ConnectionFailure, Unit> disconnect() {
    return TaskEither<ConnectionFailure, Unit>.Do(
      ($) async {
        // final options = await $(getConfigOption());

        await $(
          TaskEither(() async {
            // if (options.enableTun) {
            //   final hasPrivilege = await platformSource.checkPrivilege();
            //   if (!hasPrivilege) {
            //     loggy.warning("missing privileges for tun mode");
            //     return left(const MissingPrivilege());
            //   }
            // }
            return right(unit);
          }),
        );
        return await $(
          singbox.stop().mapLeft(UnexpectedConnectionFailure.new),
        );
      },
    ).handleExceptions(UnexpectedConnectionFailure.new);
  }

  @override
  TaskEither<ConnectionFailure, Unit> reconnect(
    String fileName,
    String profileName,
    bool disableMemoryLimit,
    String? override,
  ) {
    return TaskEither<ConnectionFailure, Unit>.Do(
      ($) async {
        final options = await $(getConfigOption());
        loggy.info(
          "config options: ${options.format()}\nMemory Limit: ${!disableMemoryLimit}",
        );

        await $(applyConfigOption(options, override));
        return await $(
          singbox
              .restart(
                profilePathResolver.file(fileName).path,
                profileName,
                disableMemoryLimit,
              )
              .mapLeft(UnexpectedConnectionFailure.new),
        );
      },
    ).handleExceptions(UnexpectedConnectionFailure.new);
  }
}
