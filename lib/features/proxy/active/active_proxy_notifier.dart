import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:hiddify/core/haptic/haptic_service.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/utils/throttler.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/diagnostics/diagnostic_providers.dart';
import 'package:hiddify/features/diagnostics/ios_ping_trace.dart';
import 'package:hiddify/features/proxy/active/ios_active_proxy_measurement_providers.dart';
import 'package:hiddify/features/proxy/data/proxy_data_providers.dart';
import 'package:hiddify/features/proxy/model/ip_info_entity.dart' as oldipinfo;
import 'package:hiddify/features/proxy/model/proxy_failure.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/hiddifycore/init_signal.dart';
import 'package:hiddify/utils/riverpod_utils.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'active_proxy_notifier.g.dart';

@riverpod
class IpInfoNotifier extends _$IpInfoNotifier with AppLogger {
  @override
  Future<oldipinfo.IpInfo> build() async {
    ref.disposeDelay(const Duration(seconds: 20));
    final cancelToken = CancelToken();
    Timer? timer;
    ref.onDispose(() {
      loggy.debug("disposing");
      cancelToken.cancel();
      timer?.cancel();
    });

    ref.listen(serviceRunningProvider, (_, next) => _idle = false);

    final autoCheck = ref.watch(Preferences.autoCheckIp);
    final serviceRunning = await ref.watch(serviceRunningProvider.future);
    // loggy.debug(
    //   "idle? [$_idle], forced? [$_forceCheck], connected? [$serviceRunning]",
    // );
    if (!_forceCheck && !serviceRunning) {
      throw const ServiceNotRunning();
    } else if ((_idle && !_forceCheck) || (!_forceCheck && serviceRunning && !autoCheck)) {
      throw const UnknownIp();
    }

    _forceCheck = false;
    final info = await ref.watch(proxyRepositoryProvider).getCurrentIpInfo(cancelToken).getOrElse((err) {
      loggy.warning("error getting proxy ip info", err, StackTrace.current);
      // throw err; //hiddify: remove exception to be logged
      throw const UnknownIp();
    }).run();

    timer = Timer(const Duration(seconds: 10), () {
      loggy.debug("entering idle mode");
      _idle = true;
      ref.invalidateSelf();
    });

    return info;
  }

  bool _idle = false;
  bool _forceCheck = false;

  Future<void> refresh() async {
    if (state.isLoading) return;
    loggy.debug("refreshing");
    state = const AsyncLoading();
    await ref.read(hapticServiceProvider.notifier).lightImpact();
    _forceCheck = true;
    ref.invalidateSelf();
  }
}

@Riverpod(keepAlive: true)
class ActiveProxyNotifier extends _$ActiveProxyNotifier with AppLogger {
  int _iosGeneration = 0;

  @override
  Stream<OutboundInfo> build() async* {
    if (ref.watch(iosActiveProxyMeasurementEnabledProvider)) {
      _iosGeneration++;
      ref.onDispose(() => _iosGeneration++);
      yield* ref.watch(iosActiveProxyMeasurementProvider).states.map((snapshot) {
        final proxy = snapshot.proxy;
        if (proxy == null) throw const UnknownIp();
        return proxy;
      });
      return;
    }
    // ref.disposeDelay(const Duration(seconds: 20));
    ref.watch(coreRestartSignalProvider);
    final serviceRunning = await ref.watch(serviceRunningProvider.future);
    if (!serviceRunning) {
      throw const ServiceNotRunning();
    }
    final proxyprovider = ref.watch(proxyRepositoryProvider);
    yield* proxyprovider
        .watchActiveProxies()
        .map((event) => event.getOrElse((l) => List<OutboundGroup>.empty()))
        .map((event) => event.firstOrNull?.items.first ?? OutboundInfo());
  }

  final _urlTestThrottler = Throttler(const Duration(seconds: 1));

  Future<void> urlTest(String? groupTag_) async {
    final groupTag = groupTag_ ?? "";
    if (ref.read(iosActiveProxyMeasurementEnabledProvider) && groupTag.isEmpty) {
      final operationId = beginIosPingOperation(ref, IosPingEvent.refreshTapped);
      if (ref.read(serviceRunningProvider).asData?.value != true) {
        recordIosPingEvent(ref, IosPingEvent.refreshNotConnected, operationId: operationId);
        return;
      }
      final lifecycle = WidgetsBinding.instance.lifecycleState;
      if (lifecycle != null && lifecycle != AppLifecycleState.resumed) {
        recordIosPingEvent(ref, IosPingEvent.refreshNotResumed, operationId: operationId);
        return;
      }
      final generation = _iosGeneration;
      final measurement = ref.read(iosActiveProxyMeasurementProvider);
      if (!measurement.canRefresh) {
        recordIosPingEvent(ref, IosPingEvent.refreshCoreNotReady, operationId: operationId);
        return ref.read(iosForegroundRefreshRecoveryProvider)(operationId);
      }
      recordIosPingEvent(ref, IosPingEvent.hapticRequested, operationId: operationId);
      try {
        await ref.read(hapticServiceProvider.notifier).lightImpact();
      } catch (_) {
        recordIosPingEvent(ref, IosPingEvent.refreshFailed, operationId: operationId);
        rethrow;
      }
      recordIosPingEvent(ref, IosPingEvent.hapticCompleted, operationId: operationId);
      if (generation != _iosGeneration) {
        recordIosPingEvent(ref, IosPingEvent.refreshInvalidated, operationId: operationId);
        return;
      }
      if (ref.read(serviceRunningProvider).asData?.value != true) {
        recordIosPingEvent(ref, IosPingEvent.refreshNotConnected, operationId: operationId);
        return;
      }
      final currentLifecycle = WidgetsBinding.instance.lifecycleState;
      if (currentLifecycle != null && currentLifecycle != AppLifecycleState.resumed) {
        recordIosPingEvent(ref, IosPingEvent.refreshNotResumed, operationId: operationId);
        return;
      }
      if (!identical(measurement, ref.read(iosActiveProxyMeasurementProvider))) {
        recordIosPingEvent(ref, IosPingEvent.refreshInvalidated, operationId: operationId);
        return;
      }
      if (!measurement.canRefresh) {
        recordIosPingEvent(ref, IosPingEvent.refreshCoreNotReady, operationId: operationId);
        return;
      }
      recordIosPingEvent(ref, IosPingEvent.refreshIssued, operationId: operationId);
      try {
        await measurement.refresh(operationId: operationId);
        recordIosPingEvent(ref, IosPingEvent.refreshCompleted, operationId: operationId);
      } catch (_) {
        recordIosPingEvent(ref, IosPingEvent.refreshFailed, operationId: operationId);
        rethrow;
      }
      return;
    }
    _urlTestThrottler(() async {
      if (state case AsyncData()) {
        await ref.read(hapticServiceProvider.notifier).lightImpact();
        await ref.read(proxyRepositoryProvider).urlTest(groupTag).getOrElse((err) {
          loggy.warning("error testing group", err);
          throw err;
        }).run();
      }
    });
  }
}
