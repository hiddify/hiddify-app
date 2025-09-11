import 'package:dartx/dartx.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

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
}

enum SingboxAlert {
  requestVPNPermission,
  requestNotificationPermission,
  emptyConfiguration,
  startCommandServer,
  createService,
  startService;
}
