import 'package:dartx/dartx.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hiddify/features/connection/model/connection_failure.dart';
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
    event = event as Map<String, dynamic>?;
    switch (event?["status"]) {
      case "Stopped":
        final alertstr = event?["alert"] as String?;
        var msgStr = event?["message"] as String?;
        var alert = CoreAlert.values.firstOrNullWhere((e) => alertstr?.toLowerCase() == e.name.toLowerCase());
        if ((alert == null) && (alertstr ?? "") != "") {
          msgStr = ((msgStr ?? "") != "") ? "$alertstr: $msgStr" : alertstr;
          alert = CoreAlert.unknown;
        }
        return CoreStatus.stopped(alert: alert, message: msgStr);

      case "Starting":
        return const CoreStarting();
      case "Started":
        return const CoreStarted();
      case "Stopping":
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

  ConnectionFailure? getCoreAlert() {
    return switch (this) {
      CoreStopped(alert: final alert, message: final message) when alert != null => switch (alert) {
        CoreAlert.emptyConfiguration => ConnectionFailure.invalidConfig(message),

        CoreAlert.requestNotificationPermission => ConnectionFailure.missingNotificationPermission(message),

        CoreAlert.requestVPNPermission => ConnectionFailure.missingVpnPermission(message),

        CoreAlert.startCommandServer ||
        CoreAlert.createService ||
        CoreAlert.startService ||
        CoreAlert.alreadyStarted ||
        CoreAlert.startFailed => ConnectionFailure.unexpected("${alert.name} - $message"),

        _ => null,
      },

      _ => null,
    };
  }
}

enum CoreAlert {
  requestVPNPermission,
  requestNotificationPermission,
  emptyConfiguration,
  startCommandServer,
  createService,
  startService,
  alreadyStarted,
  startFailed,
  unknown,
}
