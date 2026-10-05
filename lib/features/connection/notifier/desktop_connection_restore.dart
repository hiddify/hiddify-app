import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/singbox/model/core_status.dart';

Future<void> restoreDesktopConnectionWhenReady({
  required bool Function() isRestoreRequested,
  required Future<CoreStatus> Function() waitForFirstReportedCoreStatus,
  required Future<ConnectionStatus> Function() waitForConnectionStatus,
  required Future<void> Function() connect,
}) async {
  if (!isRestoreRequested()) return;

  final coreStatus = await waitForFirstReportedCoreStatus();
  final coreCanRestore = switch (coreStatus) {
    CoreStopped(alert: null) => true,
    _ => false,
  };
  if (!coreCanRestore) return;

  final connectionStatus = await waitForConnectionStatus();
  if (!isRestoreRequested() || !connectionStatus.canRestoreConnection) return;

  await connect();
}
