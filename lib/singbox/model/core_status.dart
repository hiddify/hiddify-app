import 'package:dartx/dartx.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';

part 'core_status.freezed.dart';

@freezed
sealed class CoreStatus with _$CoreStatus {
  const CoreStatus._();

  const factory CoreStatus.stopped({CoreAlert? alert, String? message}) = CoreStopped;
  const factory CoreStatus.starting() = CoreStarting;
  const factory CoreStatus.started() = CoreStarted;
  const factory CoreStatus.stopping() = CoreStopping;

  factory CoreStatus.fromEvent(dynamic event) {
    switch (event) {
      case {"status": "Stopped", "alert": final String? alertStr, "message": final String? messageStr}:
        final alert = CoreAlert.values.firstOrNullWhere((e) => alertStr?.toLowerCase() == e.name.toLowerCase());
        return CoreStatus.stopped(alert: alert, message: messageStr);
      case {"status": "Stopped"}:
        return const CoreStatus.stopped();
      case {"status": "Starting"}:
        return const CoreStarting();
      case {"status": "Started"}:
        return const CoreStarted();
      case {"status": "Stopping"}:
        return const CoreStopping();
      default:
        throw Exception("unexpected status [$event]");
    }
  }
  factory CoreStatus.fromCoreInfo(CoreInfoResponse event) {
    switch (event.coreState) {
      case CoreStates.STOPPED:
        final CoreAlert? alert = switch (event.messageType) {
          MessageType.EMPTY => null,
          MessageType.ERROR_READING_CONFIG => CoreAlert.emptyConfiguration,
          MessageType.START_COMMAND_SERVER => CoreAlert.startCommandServer,
          MessageType.CREATE_SERVICE => CoreAlert.createService,
          MessageType.START_SERVICE => CoreAlert.startService,
          MessageType.UNEXPECTED_ERROR => CoreAlert.startService,
          MessageType.INSTANCE_NOT_STOPPED => CoreAlert.startService,
          MessageType.INSTANCE_NOT_STARTED => CoreAlert.startService,
          MessageType.INSTANCE_NOT_FOUND => CoreAlert.startService,
          MessageType.ERROR_PARSING_CONFIG => CoreAlert.emptyConfiguration,
          MessageType.ERROR_BUILDING_CONFIG => CoreAlert.emptyConfiguration,
          MessageType.EMPTY_CONFIGURATION => CoreAlert.emptyConfiguration,
          MessageType.ALREADY_STOPPED => CoreAlert.createService,
          MessageType.ALREADY_STARTED => CoreAlert.startService,

          // MessageType.REQUEST_VPN_PERMISSION => SingboxAlert.requestVPNPermission,
          // MessageType.REQUEST_NOTIFICATION_PERMISSION => SingboxAlert.requestNotificationPermission,
          _ => CoreAlert.emptyConfiguration, // Default case
        };
        return CoreStatus.stopped(alert: alert, message: event.message);
      case CoreStates.STARTING:
        return const CoreStarting();
      case CoreStates.STARTED:
        return const CoreStarted();
      case CoreStates.STOPPING:
        return const CoreStopping();
      default:
        throw Exception("unexpected status [$event]");
    }
  }
}

enum CoreAlert { requestVPNPermission, requestNotificationPermission, emptyConfiguration, startCommandServer, createService, startService, alreadyStarted, startFailed }
