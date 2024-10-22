import 'package:dartx/dartx.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';

part 'singbox_status.freezed.dart';

@freezed
sealed class SingboxStatus with _$SingboxStatus {
  const SingboxStatus._();

  const factory SingboxStatus.stopped({
    SingboxAlert? alert,
    String? message,
  }) = SingboxStopped;
  const factory SingboxStatus.starting() = SingboxStarting;
  const factory SingboxStatus.started() = SingboxStarted;
  const factory SingboxStatus.stopping() = SingboxStopping;

  factory SingboxStatus.fromEvent(dynamic event) {
    switch (event) {
      case {
          "status": "Stopped",
          "alert": final String? alertStr,
          "message": final String? messageStr,
        }:
        final alert = SingboxAlert.values.firstOrNullWhere(
          (e) => alertStr?.toLowerCase() == e.name.toLowerCase(),
        );
        return SingboxStatus.stopped(alert: alert, message: messageStr);
      case {"status": "Stopped"}:
        return const SingboxStatus.stopped();
      case {"status": "Starting"}:
        return const SingboxStarting();
      case {"status": "Started"}:
        return const SingboxStarted();
      case {"status": "Stopping"}:
        return const SingboxStopping();
      default:
        throw Exception("unexpected status [$event]");
    }
  }
  factory SingboxStatus.fromCoreInfo(CoreInfoResponse event) {
    switch (event.coreState) {
      case CoreStates.STOPPED:
        final SingboxAlert? alert = switch (event.messageType) {
          MessageType.EMPTY => null,
          MessageType.ERROR_READING_CONFIG => SingboxAlert.emptyConfiguration,
          MessageType.START_COMMAND_SERVER => SingboxAlert.startCommandServer,
          MessageType.CREATE_SERVICE => SingboxAlert.createService,
          MessageType.START_SERVICE => SingboxAlert.startService,
          MessageType.UNEXPECTED_ERROR => SingboxAlert.startService,
          MessageType.INSTANCE_NOT_STOPPED => SingboxAlert.startService,
          MessageType.INSTANCE_NOT_STARTED => SingboxAlert.startService,
          MessageType.INSTANCE_NOT_FOUND => SingboxAlert.startService,
          MessageType.ERROR_PARSING_CONFIG => SingboxAlert.emptyConfiguration,
          MessageType.ERROR_BUILDING_CONFIG => SingboxAlert.emptyConfiguration,
          MessageType.EMPTY_CONFIGURATION => SingboxAlert.emptyConfiguration,
          MessageType.ALREADY_STOPPED => SingboxAlert.createService,
          MessageType.ALREADY_STARTED => SingboxAlert.startService,

          // MessageType.REQUEST_VPN_PERMISSION => SingboxAlert.requestVPNPermission,
          // MessageType.REQUEST_NOTIFICATION_PERMISSION => SingboxAlert.requestNotificationPermission,
          _ => SingboxAlert.emptyConfiguration, // Default case
        };
        return SingboxStatus.stopped(alert: alert, message: event.message);
      case CoreStates.STARTING:
        return const SingboxStarting();
      case CoreStates.STARTED:
        return const SingboxStarted();
      case CoreStates.STOPPING:
        return const SingboxStopping();
      default:
        throw Exception("unexpected status [$event]");
    }
  }
}

enum SingboxAlert {
  requestVPNPermission,
  requestNotificationPermission,
  emptyConfiguration,
  startCommandServer,
  createService,
  startService;
}
