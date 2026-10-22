import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:hiddify/core/observability/better_stack_log_printer.dart';
import 'package:hiddify/features/diagnostics/ios_ping_trace.dart';

/// Exports closed trace events, including the bounded current-launch startup ring.
final class RemoteIosPingSubscription extends WidgetsBindingObserver {
  RemoteIosPingSubscription(this.trace, this.remote, {int afterSequence = 0, this.onSequence}) {
    _lastSequence = afterSequence;
    _lifecycle = WidgetsBinding.instance.lifecycleState;
    _subscription = trace.changes.listen(_onSnapshot);
    _onSnapshot(trace.snapshot);
    WidgetsBinding.instance.addObserver(this);
  }

  final IosPingTrace trace;
  final BetterStackLogPrinter remote;
  final void Function(int)? onSequence;
  late final StreamSubscription<IosPingTraceSnapshot> _subscription;
  AppLifecycleState? _lifecycle;
  var _lastSequence = 0;
  var _disposed = false;

  void _onSnapshot(IosPingTraceSnapshot snapshot) {
    if (_disposed) return;
    for (final entry in snapshot.events) {
      if (entry.sequence <= _lastSequence) continue;
      _lastSequence = entry.sequence;
      onSequence?.call(entry.sequence);
      remote.addIosPingEvent(entry);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed || state == _lifecycle) return;
    _lifecycle = state;
    trace.record(switch (state) {
      AppLifecycleState.inactive => IosPingEvent.appInactive,
      AppLifecycleState.hidden => IosPingEvent.appHidden,
      AppLifecycleState.paused => IosPingEvent.appPaused,
      AppLifecycleState.resumed => IosPingEvent.appResumed,
      AppLifecycleState.detached => IosPingEvent.appDetached,
    });
    unawaited(_flushSafely(resuming: state == AppLifecycleState.resumed));
  }

  Future<void> _flushSafely({required bool resuming}) async {
    try {
      if (resuming) {
        await remote.resumePending();
      } else {
        await remote.flush();
      }
    } on Object {
      // Diagnostics must never interrupt an application lifecycle transition.
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_subscription.cancel());
  }
}
