import 'dart:convert';
import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:hiddify/core/model/directories.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/core/router/dialog/widgets/admin_bg_service_dialogs.dart';
import 'package:hiddify/core/utils/exception_handler.dart';
import 'package:hiddify/features/connection/model/connection_failure.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/features/profile/data/profile_path_resolver.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/hiddifycore/core_interface/core_interface_desktop_tun.dart';
import 'package:hiddify/hiddifycore/core_interface/core_interface_macos.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pbenum.dart' as hcore;
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

  /// Whether the core is applying a new config without a restart; the connection stays up
  /// (watchConnectionStatus keeps reporting it as connected).
  Stream<bool> watchHotReloading();
  TaskEither<ConnectionFailure, Unit> connect(ProfileEntity activeProfile, bool disableMemoryLimit);
  TaskEither<ConnectionFailure, Unit> disconnect();
  TaskEither<ConnectionFailure, Unit> reconnect(ProfileEntity activeProfile, bool disableMemoryLimit);
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
        CoreHotReloading() => const Connected(),
      },
    );
  }

  @override
  Stream<bool> watchHotReloading() => singbox.watchStatus().map((event) => event is CoreHotReloading).distinct();

  @override
  TaskEither<ConnectionFailure, Unit> connect(ProfileEntity activeProfile, bool disableMemoryLimit) => setup().flatMap(
    (_) => applyConfigOption(activeProfile).flatMap(
      (_) => TaskEither.tryCatch(() async {
        await _prepareAdminBgService(activeProfile);
        return unit;
      }, (err, st) => err is ConnectionFailure ? err : ConnectionFailure.unexpected(err, st)).flatMap(
        (_) => singbox.start(profilePathResolver.file(activeProfile.id).path, activeProfile.name, disableMemoryLimit),
      ),
    ),
  );

  /// Modes A/B/C: ask fg core (Win/Linux) or native tunnel-service status (macOS), show consent.
  Future<void> _prepareAdminBgService(ProfileEntity profile) async {
    final options = _configOptionsSnapshot;
    if (options == null) return;

    if (Platform.isMacOS) {
      await _prepareMacosAdminBgService(profile, options);
      return;
    }
    if (!Platform.isWindows && !Platform.isLinux) return;
    final core = singbox.core;
    if (core is! CoreInterfaceDesktopTun) return;

    final pref = profile.userOverride?.adminPreference ?? UserAdminPreference.unset;
    final serviceMode = options.enableTun
        ? 'vpn'
        : (options.setSystemProxy ? 'system-proxy' : 'proxy');

    final decision = await core.needAdminBgService(
      serviceMode: serviceMode,
      settingsJson: jsonEncode(options.toJson()),
      adminPreference: switch (pref) {
        UserAdminPreference.unset => hcore.AdminPreference.ADMIN_PREFERENCE_UNSET,
        UserAdminPreference.preferAdmin => hcore.AdminPreference.ADMIN_PREFERENCE_PREFER_ADMIN,
        UserAdminPreference.preferNoAdmin => hcore.AdminPreference.ADMIN_PREFERENCE_PREFER_NO_ADMIN,
      },
    );

    final dialogs = ref.read(dialogNotifierProvider.notifier);
    var useAdminBg = false;
    var stripPrivileged = false;
    var needsElevation = false;

    switch (decision.decision) {
      case hcore.AdminBgServiceDecision.ADMIN_BG_SERVICE_NO:
        useAdminBg = false;
        // preferNoAdmin already decided in Go; still strip privileged features for this run.
        if (pref == UserAdminPreference.preferNoAdmin && decision.adminNeededProxies.isNotEmpty) {
          stripPrivileged = true;
        }
      case hcore.AdminBgServiceDecision.ADMIN_BG_SERVICE_ALREADY_CONNECTED:
        useAdminBg = true;
      case hcore.AdminBgServiceDecision.ADMIN_BG_SERVICE_NEEDS_ADMIN:
        if (options.enableTun && pref == UserAdminPreference.unset) {
          final choice = await dialogs.showVpnAdminBgService();
          if (choice != VpnAdminBgDialogResult.connectWithAdmin) {
            throw const ConnectionFailure.missingPrivilege();
          }
        }
        useAdminBg = true;
        needsElevation = true;
      case hcore.AdminBgServiceDecision.ADMIN_BG_SERVICE_OPTIONAL_PROXY_NEED_ADMIN:
        final (choice, neverAsk) = await dialogs.showProxyAdminBgService(
          proxies: decision.adminNeededProxies,
        );
        if (choice == ProxyAdminBgDialogResult.cancel) {
          throw const ConnectionFailure.missingPrivilege();
        }
        if (choice == ProxyAdminBgDialogResult.runAsAdmin) {
          useAdminBg = true;
          needsElevation = true;
          if (neverAsk) {
            await _persistAdminPreference(profile, UserAdminPreference.preferAdmin);
          }
        } else {
          stripPrivileged = true;
          if (neverAsk) {
            await _persistAdminPreference(profile, UserAdminPreference.preferNoAdmin);
          }
        }
      default:
        useAdminBg = false;
    }

    core.useAdminBgService = useAdminBg;
    core.wrapAdminElevation = needsElevation ? dialogs.runWhileVpnAdminWaiting : null;

    if (stripPrivileged) {
      final stripped = options.copyWith(
        tlsTricks: options.tlsTricks.copyWith(mixedSniCase: false),
      );
      _configOptionsSnapshot = stripped;
      final optionsResult = await singbox.changeOptions(stripped).run();
      optionsResult.match((error) => throw ConnectionFailure.unexpected(error), (_) {});
    } else if (useAdminBg) {
      // Re-apply so setOptions sees useAdminBgService.
      final optionsResult = await singbox.changeOptions(options).run();
      optionsResult.match((error) => throw ConnectionFailure.unexpected(error), (_) {});
    }
  }

  /// macOS unsigned builds: root TunnelService / admin_bgservice. Consent before the password prompt.
  Future<void> _prepareMacosAdminBgService(ProfileEntity profile, SingboxConfigOption options) async {
    final core = singbox.core;
    if (core is! CoreInterfaceMacOS) return;
    // Network Extension builds do not use the admin password install path.
    if (!core.tunnelServiceAvailable || !options.enableTun) return;

    final dialogs = ref.read(dialogNotifierProvider.notifier);
    final pref = profile.userOverride?.adminPreference ?? UserAdminPreference.unset;

    if (core.tunnelServiceReady) return;

    if (pref == UserAdminPreference.unset) {
      final choice = await dialogs.showVpnAdminBgService();
      if (choice != VpnAdminBgDialogResult.connectWithAdmin) {
        throw const ConnectionFailure.missingPrivilege();
      }
    }

    try {
      final ok = await dialogs.runWhileVpnAdminWaiting(core.installAdminBgService());
      if (!ok) {
        try {
          await core.stop();
        } catch (_) {}
        throw const ConnectionFailure.missingPrivilege();
      }
    } on ConnectionFailure {
      rethrow;
    } catch (error) {
      final message = error.toString().toLowerCase();
      if (message.contains('cancel') || message.contains('permission') || message.contains('denied')) {
        throw const ConnectionFailure.missingPrivilege();
      }
      throw ConnectionFailure.unexpected(error);
    }
  }

  Future<void> _persistAdminPreference(ProfileEntity profile, UserAdminPreference preference) async {
    final override = (profile.userOverride ?? const UserOverride()).copyWith(adminPreference: preference);
    final updated = profile.copyWith(userOverride: override);
    final profiles = ref.read(profileRepositoryProvider).requireValue;
    final raw = await profiles.getRawConfig(profile.id).run();
    await raw.match(
      (l) {
        loggy.warning('could not persist admin preference: $l');
      },
      (content) async {
        final result = await profiles.offlineUpdate(updated, content).run();
        result.match(
          (l) => loggy.warning('could not persist admin preference: $l'),
          (_) {},
        );
      },
    );
  }

  @override
  TaskEither<ConnectionFailure, Unit> disconnect() => singbox.stop().mapLeft(UnexpectedConnectionFailure.new);

  @override
  TaskEither<ConnectionFailure, Unit> reconnect(ProfileEntity activeProfile, bool disableMemoryLimit) =>
      applyConfigOption(activeProfile).flatMap(
        // hot reload when possible, restart otherwise
        (_) => singbox
            .reload(profilePathResolver.file(activeProfile.id).path, activeProfile.name, disableMemoryLimit)
            .mapLeft(UnexpectedConnectionFailure.new),
      );

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
              final optionsResult = await singbox.changeOptions(overridedOptions).run();
              optionsResult.match((error) => throw ConnectionFailure.unexpected(error), (_) {});
              return unit;
            }, (err, st) => err is ConnectionFailure ? err : ConnectionFailure.unexpected(err, st)),
          );
}
