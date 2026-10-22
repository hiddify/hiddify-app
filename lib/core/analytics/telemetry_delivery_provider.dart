import 'dart:async';

import 'package:hiddify/core/observability/telemetry_delivery_status.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Local delivery observations must be readable without initializing analytics,
/// preferences, or a measurement operation from the report screen.
final class TelemetryDeliveryMonitor {
  final _changes = StreamController<TelemetryDeliveryStatus>.broadcast();
  TelemetryDeliveryStatus _status = const TelemetryDeliveryStatus.disabled();

  TelemetryDeliveryStatus get status => _status;
  Stream<TelemetryDeliveryStatus> get changes => _changes.stream;

  void update(TelemetryDeliveryStatus value) {
    if (_changes.isClosed || value == _status) return;
    _status = value;
    _changes.add(value);
  }

  void dispose() => unawaited(_changes.close());
}

final telemetryDeliveryMonitorProvider = Provider<TelemetryDeliveryMonitor>((ref) {
  final monitor = TelemetryDeliveryMonitor();
  ref.onDispose(monitor.dispose);
  return monitor;
});

final telemetryDeliveryStatusProvider = StreamProvider<TelemetryDeliveryStatus>((ref) {
  final monitor = ref.watch(telemetryDeliveryMonitorProvider);
  return Stream<TelemetryDeliveryStatus>.multi((listener) {
    final subscription = monitor.changes.listen(listener.add, onError: listener.addError);
    listener.add(monitor.status);
    listener.onCancel = subscription.cancel;
  });
});
