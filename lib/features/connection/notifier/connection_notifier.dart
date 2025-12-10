import 'dart:io';

import 'package:hiddify/core/haptic/haptic_service.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/features/config_option/data/config_option_repository.dart';
import 'package:hiddify/features/config_option/service/region_detection_service.dart';
import 'package:hiddify/features/connection/data/connection_data_providers.dart';
import 'package:hiddify/features/connection/data/connection_repository.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/proxy/data/proxy_data_providers.dart';
import 'package:hiddify/utils/utils.dart';
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

    ref.listenSelf(
      (previous, next) async {
        if (previous == next) return;
        if (previous case AsyncData(:final value) when !value.isConnected) {
          if (next case AsyncData(value: final Connected _)) {
            await ref.read(hapticServiceProvider.notifier).heavyImpact();

            // Apply selected location after connection
            await _applySelectedLocation();

            if (Platform.isAndroid && !ref.read(Preferences.storeReviewedByUser)) {
              if (await InAppReview.instance.isAvailable()) {
                InAppReview.instance.requestReview();
                ref.read(Preferences.storeReviewedByUser.notifier).update(true);
              }
            }
          }
        }
      },
    );

    ref.listen(
      activeProfileProvider.select((value) => value.asData?.value),
      (previous, next) async {
        if (previous == null) return;
        final shouldReconnect = next == null || previous.id != next.id;
        if (shouldReconnect) {
          await reconnect(next);
        }
      },
    );
    yield* _connectionRepo.watchConnectionStatus().doOnData((event) {
      if (event case Disconnected(connectionFailure: final _?) when PlatformUtils.isDesktop) {
        ref.read(Preferences.startedByUser.notifier).update(false);
      }
      loggy.info("connection status: ${event.format()}");
    });
  }

  ConnectionRepository get _connectionRepo => ref.read(connectionRepositoryProvider);

  Future<void> mayConnect() async {
    if (state case AsyncData(:final value)) {
      if (value case Disconnected()) return _connect();
    }
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
        case Connected():
          await haptic.mediumImpact();
          await ref.read(Preferences.startedByUser.notifier).update(false);
          await _disconnect();
        default:
          loggy.warning("switching status, debounce");
      }
    }
  }

  Future<void> reconnect(ProfileEntity? profile) async {
    if (state case AsyncData(:final value) when value == const Connected()) {
      if (profile == null) {
        loggy.info("no active profile, disconnecting");
        return _disconnect();
      }
      loggy.info("active profile changed, reconnecting");
      await ref.read(Preferences.startedByUser.notifier).update(true);
      await _connectionRepo
          .reconnect(
        profile.id,
        profile.name,
        ref.read(Preferences.disableMemoryLimit),
        profile.testUrl,
      )
          .mapLeft((err) {
        loggy.warning("error reconnecting", err);
        state = AsyncError(err, StackTrace.current);
      }).run();
    }
  }

  Future<void> abortConnection() async {
    if (state case AsyncData(:final value)) {
      switch (value) {
        case Connected() || Connecting():
          loggy.debug("aborting connection");
          await _disconnect();
        default:
      }
    }
  }

  Future<void> _connect() async {
    final activeProfile = await ref.read(activeProfileProvider.future);
    if (activeProfile == null) {
      loggy.info("no active profile, not connecting");
      return;
    }

    // Auto-detect region if enabled
    final autoDetectRegion = ref.read(ConfigOptions.autoDetectRegion);
    if (autoDetectRegion) {
      try {
        loggy.debug("Auto-detecting region before connecting");
        final regionDetectionService = ref.read(regionDetectionServiceProvider);
        final detectedRegion = await regionDetectionService.detectRegion();
        loggy.info("Auto-detected region: ${detectedRegion.name}");
        await ref.read(ConfigOptions.region.notifier).update(detectedRegion);
        await ref.read(ConfigOptions.directDnsAddress.notifier).reset();
      } catch (e, stackTrace) {
        loggy.warning("Failed to auto-detect region, continuing with current region", e, stackTrace);
        // Continue with connection even if detection fails
      }
    }

    await _connectionRepo
        .connect(
      activeProfile.id,
      activeProfile.name,
      ref.read(Preferences.disableMemoryLimit),
      activeProfile.testUrl,
    )
        .mapLeft((err) async {
      loggy.warning("error connecting", err);
      //Go err is not normal object to see the go errors are string and need to be dumped
      loggy.warning(err);
      if (err.toString().contains("panic")) {
        await Sentry.captureException(Exception(err.toString()));
      }
      await ref.read(Preferences.startedByUser.notifier).update(false);
      state = AsyncError(err, StackTrace.current);
    }).run();
  }

  Future<void> _disconnect() async {
    await _connectionRepo.disconnect().mapLeft((err) {
      loggy.warning("error disconnecting", err);
      state = AsyncError(err, StackTrace.current);
    }).run();
  }

  /// Apply selected location after connection
  Future<void> _applySelectedLocation() async {
    try {
      // Read saved selection directly from preferences (common storage)
      final activeProfile = await ref.read(activeProfileProvider.future);
      if (activeProfile == null) {
        loggy.debug("no active profile, skipping location selection");
        return;
      }

      final prefs = await ref.read(sharedPreferencesProvider.future);
      final key = "selected_location_${activeProfile.id}";
      final selectedLocation = prefs.getString(key);
      
      if (selectedLocation == null || selectedLocation.isEmpty) {
        loggy.debug("no saved location selection to apply");
        return;
      }

      loggy.debug("applying saved location selection: [$selectedLocation]");

      // Wait a bit for singbox to be ready
      await Future.delayed(const Duration(milliseconds: 500));

      // Try to find the correct group tag (usually "select" or "auto")
      final proxyRepo = ref.read(proxyRepositoryProvider);
      
      // Try "select" first, then "auto"
      final groupTags = ["select", "auto"];
      bool applied = false;

      for (final groupTag in groupTags) {
        try {
          await proxyRepo.selectProxy(groupTag, selectedLocation).getOrElse((err) {
            loggy.debug("failed to select proxy in group [$groupTag]: $err");
            throw err;
          }).run();
          
          loggy.info("successfully applied location selection [$selectedLocation] in group [$groupTag]");
          applied = true;
          break;
        } catch (e) {
          loggy.debug("group [$groupTag] not available, trying next");
          continue;
        }
      }

      if (!applied) {
        loggy.warning("could not apply location selection [$selectedLocation] - no suitable group found");
      }
    } catch (e, stackTrace) {
      loggy.warning("error applying selected location", e, stackTrace);
      // Don't throw - connection is successful, location selection failure is non-critical
    }
  }
}

@Riverpod(keepAlive: true)
Future<bool> serviceRunning(ServiceRunningRef ref) => ref
    .watch(
      connectionNotifierProvider.selectAsync((data) => data.isConnected),
    )
    .onError((error, stackTrace) => false);
