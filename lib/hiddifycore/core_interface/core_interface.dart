import 'dart:async';

import 'package:hiddify/core/model/directories.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcommon/common.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore_service.pbgrpc.dart';
import 'package:hiddify/singbox/model/core_status.dart';
import 'package:hiddify/singbox/model/singbox_config_option.dart';

/// Starts the core through [client] once it has stopped. A stop sent just before may still be under
/// way, as the core answers a stop at once and stops in the background, and it refuses a start
/// until then (INSTANCE_NOT_STOPPED); so it is asked again, for [patience] at most.
Future<CoreInfoResponse> startOnceStopped(
  CoreClient client,
  StartRequest request, {
  Duration patience = const Duration(seconds: 10),
}) async {
  final deadline = DateTime.now().add(patience);
  while (true) {
    final response = await client.start(request);
    if (response.messageType != MessageType.INSTANCE_NOT_STOPPED || DateTime.now().isAfter(deadline)) {
      return response;
    }
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }
}

/// Starts the core through [client] (see [startOnceStopped]) and returns how the start ended. The
/// core answers Start as soon as it has queued it, and a start that fails afterwards (its port in
/// use, a config the engine refuses) is reported only on its status stream: STARTING, then STOPPED
/// with the reason. Taken from the answer alone, such a start was a connect that worked, with no
/// core behind it. The answer is returned when it is already the outcome (a refusal, or already
/// started); otherwise the status that ends the start, within [timeout].
Future<CoreInfoResponse> startAndConfirm(
  CoreClient client,
  StartRequest request, {
  Duration patience = const Duration(seconds: 10),
  Duration timeout = const Duration(minutes: 2),
}) async {
  final outcome = Completer<CoreInfoResponse>();
  var starting = false;
  // listened to before the start: its STARTING and its outcome may come before Start's answer
  final statuses = client
      .coreInfoListener(Empty())
      .listen(
        (info) {
          if (outcome.isCompleted) return;
          switch (info.coreState) {
            case CoreStates.STARTING:
              starting = true;
            case CoreStates.STARTED || CoreStates.WAITING || CoreStates.NO_AVAILABLE_PROXIES:
              outcome.complete(info);
            // a STOPPED before STARTING is the state before this start (a new listener is told it);
            // one after it ends the start, with the reason, or as not started when it has none
            case CoreStates.STOPPED when starting:
              outcome.complete(
                info.messageType == MessageType.EMPTY
                    ? CoreInfoResponse(
                        coreState: CoreStates.STOPPED,
                        messageType: MessageType.INSTANCE_NOT_STARTED,
                        message: info.message.isEmpty ? 'the core stopped while it started' : info.message,
                      )
                    : info,
              );
            default:
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!outcome.isCompleted) outcome.completeError(error, stackTrace);
        },
        cancelOnError: true,
      );
  try {
    final response = await startOnceStopped(client, request, patience: patience);
    if (response.messageType != MessageType.EMPTY) return response;
    return await outcome.future.timeout(timeout);
  } finally {
    unawaited(statuses.cancel());
  }
}

class CoreInterface {
  late CoreClient fgClient;
  late CoreClient bgClient;

  bool get managesLifecycle => false;
  bool get persistsAfterAppExit => false;
  Stream<CoreStatus>? get managedStatus => null;
  Stream<void>? get clientChanges => null;

  /// An event each time a core process the app started crashed while the app runs (desktop), once
  /// its crash output can be listed: the crash report is offered then, not only at the next start.
  Stream<void> get coreCrashes => const Stream.empty();

  Future<void> setOptions(SingboxConfigOption options) async {}
  Future<void> dispose() async {}

  /// Stops the core's own process, when it has one, before the app quits (desktop).
  Future<void> shutdown() async {}

  /// Applies a changed config to a connection that runs in a privileged engine (the VPN service, a
  /// Network Extension), whose control port refuses the core's own hot reload: true when it was
  /// applied, false when the connection must be started again. Null when the connection does not
  /// run there, so the core's hot reload applies.
  Future<bool?> reloadManaged(String path, String name, bool disableMemoryLimit) async => null;

  /// Starts a connection that runs in the VPN service again with a changed config, in the service,
  /// when the new settings still need it: true when it was restarted there. Null when it does not
  /// run there or should move out of it (a VPN switched to a proxy mode); [startManaged] applies.
  Future<bool?> restartManaged(String path, String name, bool disableMemoryLimit) async => null;
  Future<void> startManaged(String path, String name, bool disableMemoryLimit) =>
      Future<void>.error(UnimplementedError());

  Future<String> setup(Directories directories, bool debug, int mode) async {
    return "";
  }

  Future<CoreStatus> setupBackground(String path, String name) async {
    return const CoreStarted();
  }

  Future<bool> restart(String path, String name) async {
    return false;
  }

  Future<bool> stop() async {
    return false;
  }

  Future<bool> isBgClientAvailable() async {
    return true;
  }

  bool isSingleChannel() {
    // return true;
    return fgClient == bgClient;
  }

  /// Whether the two channels reach one core process, so its log comes down both of them. On
  /// Android the VPN service runs in the app's process (no android:process), and a listener on
  /// each channel logged every core line twice.
  bool get coreSharesProcess => false;

  /// Whether the system keeps a VPN profile for the app that [resetTunnel] can remove.
  bool get hasVpnProfile => false;

  Future<bool> resetTunnel() async {
    return false;
  }

  Future<bool> isActiveFg() async {
    return true;
  }

  Future<bool> isActiveBg() async {
    return true;
  }

  bool isInitialized() {
    try {
      final _ = bgClient; // Check whether the late client field has been initialized.
      return true;
    } catch (_) {
      return false;
    }
  }
}
