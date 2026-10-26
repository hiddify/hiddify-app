import 'dart:io';

import 'package:hiddify/core/haptic/haptic_service.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/features/connection/data/connection_data_providers.dart';
import 'package:hiddify/features/connection/data/connection_repository.dart';
import 'package:hiddify/features/connection/model/connection_failure.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/model/startup_connection.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/hiddifycore/hiddify_core_service_provider.dart';
import 'package:hiddify/singbox/model/core_status.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part 'connection_notifier.g.dart';

@Riverpod(keepAlive: true)
class ConnectionNotifier extends _$ConnectionNotifier with AppLogger {
  @override
  Stream<ConnectionStatus> build() async* {
    if (Platform.isIOS) {
      await _connectionRepo.setup().mapLeft((l) {
        loggy.error("error setting up connection repository", l);
      }).run();
    }

    listenSelf((previous, next) async {
      if (previous == next) return;
      if (previous case AsyncData(:final value) when !value.isConnected) {
        if (next case AsyncData(value: final Connected _)) {
          if (Platform.isAndroid && !ref.read(Preferences.storeReviewedByUser)) {
            if (await InAppReview.instance.isAvailable()) {
              InAppReview.instance.requestReview();
              ref.read(Preferences.storeReviewedByUser.notifier).update(true);
            }
          }
        }
      }
    });

    ref.listen(activeProfileProvider.select((value) => value.asData?.value), (previous, next) async {
      if (previous == null) return;
      final shouldReconnect = next == null || previous.id != next.id;
      if (shouldReconnect) {
        await reconnect(next);
      }
    });
    // Do not watch coreRestartSignal here. A mid-connect client switch (macOS stop-before-start)
    // increments that signal, rebuilds this stream to Disconnected, and leaves SingleCall locked so
    // further taps are ignored with no error. Proxy/stats notifiers already watch the signal.

    yield* _connectionRepo.watchConnectionStatus().doOnData((event) {
      if (event case Disconnected(connectionFailure: final _?) when PlatformUtils.isDesktop) {
        Future.microtask(() => ref.read(Preferences.startedByUser.notifier).update(false));
      }
      // One call for every status buried failures at info, next to the ordinary
      // comings and goings. A failure carries the core's own panic text, which
      // is the last thing that should need hunting for.
      final status = "connection status: ${event.format()}";
      if (event case Disconnected(connectionFailure: final _?)) {
        loggy.error(status);
      } else {
        loggy.info(status);
      }
    });
  }

  ConnectionRepository get _connectionRepo => ref.read(connectionRepositoryProvider);

  Future<void> mayConnect() async {
    if (state case AsyncData(:final value)) {
      if (value case Disconnected()) return _connect();
    }
  }

  /// Restores the tunnel on desktop start when the user had it running before quitting,
  /// so a session started manually survives a reboot or an autostart login.
  Future<void> restoreConnectionOnStartup() async {
    final startedByUser = ref.read(Preferences.startedByUser);
    final activeProfile = await ref.read(activeProfileProvider.future);
    // macOS can restore a running system VPN during core setup. Reconnecting
    // it here would unnecessarily stop and restart that tunnel.
    final coreStatus = ref.read(hiddifyCoreServiceProvider).currentState;
    final shouldRestore = shouldRestoreConnectionOnStartup(
      isDesktop: PlatformUtils.isDesktop,
      startedByUser: startedByUser,
      hasActiveProfile: activeProfile != null,
      isAlreadyRunning:
          coreStatus is CoreStarted ||
          coreStatus is CoreWaiting ||
          coreStatus is CoreNoAvailableProxies ||
          coreStatus is CoreStarting,
    );
    if (!shouldRestore) {
      loggy.debug("no previous connection to restore");
      return;
    }
    loggy.info("restoring previous connection on startup");
    await ref.read(Preferences.startedByUser.notifier).update(true);
    await _connect();
  }

  Future<void> toggleConnection() async {
    final haptic = ref.read(hapticServiceProvider.notifier);
    if (state case AsyncError()) {
      await haptic.lightImpact();
      await _connect();
    } else if (state case AsyncData(:final value)) {
      switch (value) {
        case Disconnected():
          await haptic.lightImpact();
          await ref.read(Preferences.startedByUser.notifier).update(true);
          await _connect();
        // the core cancels a start or a hot reload that a stop comes after, so a stop is always
        // allowed, however early
        case Connected() || Waiting() || NoAvailableProxies() || Connecting() || HotReloading():
          await haptic.mediumImpact();
          await ref.read(Preferences.startedByUser.notifier).update(false);
          await _disconnect();
        default:
          loggy.warning("switching status, debounce");
      }
    }
  }

  Future<void> reconnect(ProfileEntity? profile) async {
    if (state case AsyncData(:final value) when value.isRunning) {
      if (profile == null) {
        loggy.info("no active profile, disconnecting");
        return _disconnect();
      }
      loggy.info("active profile changed, reconnecting");
      await ref.read(Preferences.startedByUser.notifier).update(true);
      await _connectionRepo.reconnect(profile, ref.read(Preferences.disableMemoryLimit)).mapLeft((err) async {
        loggy.warning("error reconnecting", err);
        state = AsyncError(err, StackTrace.current);
        await ref
            .read(dialogNotifierProvider.notifier)
            .showCustomAlertFromErr(err.present(ref.read(translationsProvider).requireValue));
      }).run();
    }
  }

  Future<void> abortConnection() async {
    if (state case AsyncData(:final value)) {
      switch (value) {
        case Connected() || Waiting() || NoAvailableProxies() || Connecting() || HotReloading():
          loggy.debug("aborting connection");
          await _disconnect();
        default:
      }
    }
  }

  final _singleStart = SingleCall();

  /// Bumped on disconnect / stuck-retry so a superseded in-flight connect cannot overwrite UI.
  int _connectEpoch = 0;

  Future<void> _connect() async {
    // UI can show Disconnected while a native start is still blocked on the macOS
    // serial queue. Stacking another start made that worse; cancel once, then retry.
    if (_singleStart.isRunning && (state.valueOrNull is Disconnected || _singleStart.isStale)) {
      loggy.warning("connect was blocked by a stuck in-flight start; cancelling then retrying");
      _connectEpoch++;
      _singleStart.reset();
      await _connectionRepo.disconnect().mapLeft((err) {
        loggy.debug("cancel-before-retry disconnect: $err");
      }).run();
    }

    final epoch = _connectEpoch;
    final ignored = await _singleStart.run(() async {
      await _connectThrottled(epoch);
      return false;
    }, onIgnored: true);
    if (ignored) {
      loggy.debug("connect called while another connect is still running, ignoring");
    }
  }

  Future<void> _connectThrottled(int epoch) async {
    final activeProfile = await ref.read(activeProfileProvider.future);
    if (activeProfile == null) {
      loggy.info("no active profile, not connecting");
      return;
    }
    if (epoch != _connectEpoch) return;
    // Read before connecting: a failed start sends the core restart signal, which marks this
    // notifier out of date until the next frame, and debug builds refuse any ref call until then.
    final dialogs = ref.read(dialogNotifierProvider.notifier);
    final t = ref.read(translationsProvider).requireValue;
    final startedByUser = ref.read(Preferences.startedByUser.notifier);
    // The core reports Starting only once the config is built, about a second
    // later; the app is connecting from here on.
    state = const AsyncData(Connecting());
    await _connectionRepo.connect(activeProfile, ref.read(Preferences.disableMemoryLimit)).mapLeft((
      ConnectionFailure err,
    ) async {
      if (epoch != _connectEpoch) return;
      loggy.warning("error connecting", err);
      // Prefer Disconnected(failure) over AsyncError so the button shows failed + details,
      // and a late bare Disconnected from the status stream is less likely to erase it.
      state = AsyncData(Disconnected(err));
      await dialogs.showCustomAlertFromErr(err.present(t));
      loggy.warning(err);
      if (err.toString().contains("panic")) {
        await Sentry.captureException(Exception(err.toString()));
      }
      await startedByUser.update(false);
    }).run();
  }

  Future<void> _disconnect() async {
    // Free a stuck connect lock so the next tap can start again.
    _connectEpoch++;
    _singleStart.reset();
    // The core often goes Started → Stopped with no Stopping in between, and the
    // button would hold green "connected" until then. Mirror connect: show
    // disconnecting from the tap.
    state = const AsyncData(Disconnecting());
    await _connectionRepo.disconnect().mapLeft((err) {
      loggy.warning("error disconnecting", err);
      ref
          .read(dialogNotifierProvider.notifier)
          .showCustomAlertFromErr(err.present(ref.read(translationsProvider).requireValue));
      state = AsyncError(err, StackTrace.current);
    }).run();
  }
}

@Riverpod(keepAlive: true)
bool serviceRunning(Ref ref) {
  // ref.watch(coreRestartSignalProvider);
  return ref.watch(connectionNotifierProvider).valueOrNull?.isRunning ?? false;
}

class SingleCall {
  bool _running = false;
  DateTime? _started;

  bool get isRunning => _running;

  bool get isStale =>
      _running && _started != null && DateTime.now().difference(_started!) > const Duration(seconds: 25);

  void reset() {
    _running = false;
    _started = null;
  }

  Future<T> run<T>(Future<T> Function() task, {required T onIgnored}) async {
    if (_running) return onIgnored;

    _running = true;
    _started = DateTime.now();
    try {
      return await task();
    } finally {
      _running = false;
      _started = null;
    }
  }
}

/// Whether the core is hot reloading; only the connection button shows it.
