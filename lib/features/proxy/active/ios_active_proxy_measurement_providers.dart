import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/diagnostics/diagnostic_providers.dart';
import 'package:hiddify/features/diagnostics/ios_ping_trace.dart';
import 'package:hiddify/features/proxy/active/ios_active_proxy_measurement.dart';
import 'package:hiddify/features/proxy/data/proxy_data_providers.dart';
import 'package:hiddify/hiddifycore/hiddify_core_service.dart';
import 'package:hiddify/hiddifycore/hiddify_core_service_provider.dart';
import 'package:hiddify/hiddifycore/init_signal.dart';
import 'package:hiddify/utils/platform_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final iosActiveProxyMeasurementEnabledProvider = Provider<bool>((ref) => PlatformUtils.isIOS);

// This reader remains valid when successful setup rebuilds the active-proxy notifier.
final iosForegroundRefreshRecoveryProvider = Provider<Future<void> Function(int)>((ref) {
  var disposed = false;
  ref.onDispose(() => disposed = true);
  return (operationId) async {
    final ready = await ref.read(hiddifyCoreServiceProvider).ensureForegroundReady();
    if (disposed) return;
    if (!ready) {
      recordIosPingEvent(ref, IosPingEvent.refreshFailed, operationId: operationId);
      throw const HiddifyCoreInitializationException();
    }
    if (ref.read(serviceRunningProvider).asData?.value != true) {
      recordIosPingEvent(ref, IosPingEvent.refreshNotConnected, operationId: operationId);
      return;
    }
    if (!_foreground) {
      recordIosPingEvent(ref, IosPingEvent.refreshNotResumed, operationId: operationId);
      return;
    }
    // Recreating the suspended provider starts exactly one automatic measurement.
    if (!ref.read(iosActiveProxyMeasurementProvider).canRefresh) {
      recordIosPingEvent(ref, IosPingEvent.refreshFailed, operationId: operationId);
      throw const HiddifyCoreInitializationException();
    }
    recordIosPingEvent(ref, IosPingEvent.refreshRecoveryCompleted, operationId: operationId);
  };
});

final iosActiveProxyMeasurementProvider = Provider<IosActiveProxyMeasurement>((ref) {
  final enabled = ref.watch(iosActiveProxyMeasurementEnabledProvider);
  if (!enabled) {
    final inactive = IosActiveProxyMeasurement(watch: () => const Stream.empty(), request: () async {});
    ref.onDispose(inactive.dispose);
    return inactive;
  }

  ref.watch(coreRestartSignalProvider);
  final running = ref.watch(serviceRunningProvider).asData?.value == true;
  final repository = ref.watch(proxyRepositoryProvider);
  final operationId = beginIosPingOperation(ref, IosPingEvent.measurementCreated);
  var coreReady = running && _foreground;
  final measurement = IosActiveProxyMeasurement(
    canRefresh: () => coreReady,
    watch: repository.watchActiveProxies,
    request: () async {
      await repository.urlTest('').getOrElse((failure) => throw failure).run();
    },
    observer: (event, operationId) => recordIosPingEvent(ref, event, operationId: operationId),
  );
  recordIosPingEvent(
    ref,
    coreReady ? IosPingEvent.measurementReady : IosPingEvent.measurementBlocked,
    operationId: operationId,
  );
  final lifecycle = _MeasurementLifecycle(measurement, () {
    coreReady = false;
    recordIosPingEvent(ref, IosPingEvent.measurementSuspended, operationId: operationId);
  });
  WidgetsBinding.instance.addObserver(lifecycle);
  ref.onDispose(() {
    WidgetsBinding.instance.removeObserver(lifecycle);
    measurement.dispose();
  });
  if (running && _foreground) {
    unawaited(measurement.refresh(operationId: operationId).catchError((Object _) {}));
  }
  return measurement;
});

final iosActiveProxyMeasurementStateProvider = StreamProvider<IosProxyMeasurementState>(
  (ref) => ref.watch(iosActiveProxyMeasurementProvider).states,
);

bool get _foreground =>
    WidgetsBinding.instance.lifecycleState == null ||
    WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

class _MeasurementLifecycle extends WidgetsBindingObserver {
  _MeasurementLifecycle(this.measurement, this.suspend);

  final IosActiveProxyMeasurement measurement;
  final void Function() suspend;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      suspend();
      measurement.stop();
    }
    // App.resume completes core setup and emits coreRestartSignal before a new attempt.
  }
}
