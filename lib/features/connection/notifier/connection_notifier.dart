import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:hiddify/core/haptic/haptic_service.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/features/connection/data/connection_data_providers.dart';
import 'package:hiddify/features/connection/data/connection_repository.dart';
import 'package:hiddify/features/connection/model/connection_failure.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/utils/connection_retry_strategy.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part 'connection_notifier.g.dart';

@Riverpod(keepAlive: true)
class ConnectionNotifier extends _$ConnectionNotifier with AppLogger {
  final _retryStrategy = ConnectionRetryStrategy();
  final List<ConnectionEvent> _connectionEvents = [];
  
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
      // ثبت رویداد در تاریخچه
      switch (event) {
        case Connected():
          _connectionEvents.add(ConnectionEvent(ConnectionEventType.connected, DateTime.now()));
        case Disconnected(:final connectionFailure):
          _connectionEvents.add(
            ConnectionEvent(
              ConnectionEventType.disconnected,
              DateTime.now(),
              connectionFailure?.toString(),
            ),
          );
        case Connecting():
          _connectionEvents.add(ConnectionEvent(ConnectionEventType.connecting, DateTime.now()));
        default:
      }
      
      // محدود کردن اندازه تاریخچه به 100 رویداد اخیر
      if (_connectionEvents.length > 100) {
        _connectionEvents.removeAt(0);
      }
      
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
    
    // استفاده از retry strategy برای اتصال با exponential backoff
    final result = await _retryStrategy.executeWithRetry<ConnectionFailure, Unit>(
      () => _connectionRepo.connect(
        activeProfile.id,
        activeProfile.name,
        ref.read(Preferences.disableMemoryLimit),
        activeProfile.testUrl,
      ).run(),
      shouldRetry: (error) {
        // فقط برای برخی خطاها retry می‌کنیم
        return error is! MissingVpnPermission && 
               error is! MissingNotificationPermission &&
               error is! InvalidConfigOption;
      },
    );
    
    await result.mapLeft((err) async {
      loggy.warning("error connecting after retries", err);
      //Go err is not normal object to see the go errors are string and need to be dumped
      loggy.warning(err);
      if (err.toString().contains("panic")) {
        await Sentry.captureException(Exception(err.toString()));
      }
      
      _connectionEvents.add(
        ConnectionEvent(
          ConnectionEventType.error,
          DateTime.now(),
          err.toString(),
        ),
      );
      
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
}

@Riverpod(keepAlive: true)
Future<bool> serviceRunning(ServiceRunningRef ref) => ref
    .watch(
      connectionNotifierProvider.selectAsync((data) => data.isConnected),
    )
    .onError((error, stackTrace) => false);
