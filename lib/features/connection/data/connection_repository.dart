import 'package:fpdart/fpdart.dart';
import 'package:hiddify/core/model/directories.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/core/utils/exception_handler.dart';
import 'package:hiddify/features/connection/model/connection_failure.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/profile/data/merged_config_builder.dart';
import 'package:hiddify/features/profile/data/profile_path_resolver.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/hiddifycore/hiddify_core_service.dart';
import 'package:hiddify/singbox/model/core_status.dart';
import 'package:hiddify/singbox/model/singbox_config_option.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:meta/meta.dart';

abstract interface class ConnectionRepository {
  SingboxConfigOption? get configOptionsSnapshot;

  TaskEither<ConnectionFailure, Unit> setup();
  Stream<ConnectionStatus> watchConnectionStatus();
  /// Connect using a POOL of active profiles. All their outbounds are merged
  /// into a single sing-box config, and a top-level `urltest` group named
  /// `select` is created so the core can auto-pick the fastest outbound
  /// across every profile.
  TaskEither<ConnectionFailure, Unit> connect(List<ProfileEntity> activeProfiles, bool disableMemoryLimit);
  TaskEither<ConnectionFailure, Unit> disconnect();
  TaskEither<ConnectionFailure, Unit> reconnect(List<ProfileEntity> activeProfiles, bool disableMemoryLimit);
}

class ConnectionRepositoryImpl with ExceptionHandler, InfraLogger implements ConnectionRepository {
  ConnectionRepositoryImpl({
    required this.ref,
    required this.directories,
    required this.singbox,
    required this.configOptionRepository,
    required this.profilePathResolver,
    required this.mergedConfigBuilder,
  });

  final Ref ref;

  final Directories directories;
  final HiddifyCoreService singbox;

  final ConfigOptionRepository configOptionRepository;
  final ProfilePathResolver profilePathResolver;
  final MergedConfigBuilder mergedConfigBuilder;

  SingboxConfigOption? _configOptionsSnapshot;
  @override
  SingboxConfigOption? get configOptionsSnapshot => _configOptionsSnapshot;

  bool _initialized = false;

  @override
  TaskEither<ConnectionFailure, Unit> setup() {
    if (_initialized) return TaskEither.of(unit);
    return exceptionHandler(() {
      loggy.debug("setting up singbox");

      return singbox
          .setup()
          .map((r) {
            _initialized = true;
            return r;
          })
          .mapLeft(UnexpectedConnectionFailure.new)
          .run();
    }, UnexpectedConnectionFailure.new);
  }

  @override
  Stream<ConnectionStatus> watchConnectionStatus() {
    return singbox.watchStatus().map(
      (event) => switch (event) {
        CoreStopped() => Disconnected(event.getCoreAlert()),
        CoreStarting() => const Connecting(),
        CoreStarted() => const Connected(),
        CoreStopping() => const Disconnecting(),
      },
    );
  }

  @override
  TaskEither<ConnectionFailure, Unit> connect(List<ProfileEntity> activeProfiles, bool disableMemoryLimit) {
    if (activeProfiles.isEmpty) {
      return TaskEither.left(const UnexpectedConnectionFailure("no active profile to connect"));
    }
    return setup().flatMap((_) => _buildMergedConfig(activeProfiles).flatMap((mergedPath) {
      final displayName = activeProfiles.length == 1
          ? activeProfiles.first.name
          : "Multi (${activeProfiles.length})";
      // Apply the FIRST active profile's user-override (warp/fragment/etc).
      // This is a simplification — the global SingboxConfigOption dominates
      // anyway, and per-profile overrides are rare. If you need per-profile
      // overrides to be merged, see `ProfileParser.applyProfileOverride` /
      // `_mergeJson` and extend `applyConfigOption` to take a list.
      return applyConfigOption(activeProfiles.first).flatMap(
        (_) => singbox.start(mergedPath, displayName, disableMemoryLimit),
      );
    }));
  }

  @override
  TaskEither<ConnectionFailure, Unit> disconnect() => singbox.stop().mapLeft(UnexpectedConnectionFailure.new);

  @override
  TaskEither<ConnectionFailure, Unit> reconnect(List<ProfileEntity> activeProfiles, bool disableMemoryLimit) {
    if (activeProfiles.isEmpty) {
      // Nothing to reconnect to — disconnect instead.
      return disconnect();
    }
    return _buildMergedConfig(activeProfiles).flatMap((mergedPath) {
      final displayName = activeProfiles.length == 1
          ? activeProfiles.first.name
          : "Multi (${activeProfiles.length})";
      return applyConfigOption(activeProfiles.first).flatMap(
        (_) => singbox
            .restart(mergedPath, displayName, disableMemoryLimit)
            .mapLeft(UnexpectedConnectionFailure.new),
      );
    });
  }

  /// Build the merged config from [activeProfiles] and return its file path.
  TaskEither<ConnectionFailure, String> _buildMergedConfig(List<ProfileEntity> activeProfiles) {
    return mergedConfigBuilder
        .buildMergedConfig(activeProfiles)
        .mapLeft((l) => ConnectionFailure.unexpected(l));
  }

  @visibleForTesting
  TaskEither<ConnectionFailure, Unit> applyConfigOption(ProfileEntity prof) =>
      TaskEither.fromEither(configOptionRepository.fullOptionsOverrided(prof.profileOverride()))
          .mapLeft((l) => ConnectionFailure.invalidConfigOption(null, l))
          .flatMap(
            (overridedOptions) => TaskEither.tryCatch(() async {
              if (!overridedOptions.chainStatus.isOff()) {
                final isWarpLicenseAgreed = ref.read(Preferences.warpConsentGiven) == true;
                final isWarpEnabled =
                    overridedOptions.unblocker.mode.isWarp() || overridedOptions.extraSecurity.mode.isWarp();
                if (!isWarpLicenseAgreed && isWarpEnabled) {
                  final isAgreed = await ref.read(dialogNotifierProvider.notifier).showWarpLicense();
                  if (isAgreed == true) {
                    await ref.read(Preferences.warpConsentGiven.notifier).update(true);
                    // return (await applyConfigOption(prof).run()).match((l) => throw l, (_) => unit);
                  } else {
                    throw const MissingWarpLicense();
                  }
                }

                final isPsiphonLicenseAgreed = ref.read(Preferences.psiphonConsentGiven) == true;
                final isPsiphonEnabled =
                    overridedOptions.unblocker.mode.isPsiphon() || overridedOptions.extraSecurity.mode.isPsiphon();
                if (!isPsiphonLicenseAgreed && isPsiphonEnabled) {
                  final isAgreed = await ref.read(dialogNotifierProvider.notifier).showPsiphonLicense();
                  if (isAgreed == true) {
                    await ref.read(Preferences.psiphonConsentGiven.notifier).update(true);
                  } else {
                    throw const MissingPsiphonLicense();
                  }
                }
              }

              _configOptionsSnapshot = overridedOptions;
              await singbox.changeOptions(overridedOptions).run();
              return unit;
            }, (err, st) => err is ConnectionFailure ? err : ConnectionFailure.unexpected(err, st)),
          );
}
