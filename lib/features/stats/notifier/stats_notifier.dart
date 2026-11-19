import 'dart:async';

import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/stats/data/stats_data_providers.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/hiddifycore/init_signal.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hiddify/utils/riverpod_utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart';

part 'stats_notifier.g.dart';

@riverpod
class StatsNotifier extends _$StatsNotifier with AppLogger {
  @override
  Stream<SystemInfo> build() {
    ref.disposeDelay(const Duration(seconds: 10));
    final serviceRunning = ref.watch(serviceRunningProvider);
    // the core gets a new gRPC channel when the app comes back from the background
    ref.watch(coreRestartSignalProvider);
    if (!serviceRunning) {
      _resubscribeDelay = _minResubscribeDelay;
      return Stream.value(SystemInfo.create());
    }
    Timer? resubscribe;
    ref.onDispose(() => resubscribe?.cancel());
    var received = 0;
    return ref
        .watch(statsRepositoryProvider)
        .watchStats()
        // a failed event kept the stream but showed zeros; the last numbers stay instead, and the
        // stream is opened again below
        .where((event) => event.isRight())
        .map((event) => event.getOrElse((_) => SystemInfo.create()))
        .doOnData((_) {
          if (++received > 1) _resubscribeDelay = _minResubscribeDelay;
        })
        .doOnDone(() {
          // gRPC ends the stream when its connection drops (the app suspended, the Mac asleep)
          // without a new setup, which alone opened it again: the numbers stayed frozen until the
          // next connect. Opened again here, waiting longer while it keeps failing, as the proxy
          // list does (MainOutboundsNotifier).
          loggy.debug("stats stream ended, resubscribing in $_resubscribeDelay");
          resubscribe = Timer(_resubscribeDelay, ref.invalidateSelf);
          final doubled = _resubscribeDelay * 2;
          _resubscribeDelay = doubled < _maxResubscribeDelay ? doubled : _maxResubscribeDelay;
        });
  }

  Duration _resubscribeDelay = _minResubscribeDelay;
  static const _minResubscribeDelay = Duration(seconds: 2);
  static const _maxResubscribeDelay = Duration(seconds: 30);
}
