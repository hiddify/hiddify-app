import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/proxy/active/ios_active_proxy_measurement.dart';
import 'package:hiddify/features/proxy/data/proxy_data_providers.dart';
import 'package:hiddify/hiddifycore/init_signal.dart';
import 'package:hiddify/utils/platform_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final iosActiveProxyMeasurementEnabledProvider = Provider<bool>((ref) => PlatformUtils.isIOS);

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
  var coreReady = running && _foreground;
  final measurement = IosActiveProxyMeasurement(
    canRefresh: () => coreReady,
    watch: repository.watchActiveProxies,
    request: () async {
      await repository.urlTest('').getOrElse((failure) => throw failure).run();
    },
  );
  final lifecycle = _MeasurementLifecycle(measurement, () => coreReady = false);
  WidgetsBinding.instance.addObserver(lifecycle);
  ref.onDispose(() {
    WidgetsBinding.instance.removeObserver(lifecycle);
    measurement.dispose();
  });
  if (running && _foreground) {
    unawaited(measurement.refresh().catchError((Object _) {}));
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
