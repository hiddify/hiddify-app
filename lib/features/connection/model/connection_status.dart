import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/connection/model/connection_failure.dart';

part 'connection_status.freezed.dart';

@freezed
sealed class ConnectionStatus with _$ConnectionStatus {
  const ConnectionStatus._();

  const factory ConnectionStatus.disconnected([ConnectionFailure? connectionFailure]) = Disconnected;
  const factory ConnectionStatus.connecting() = Connecting;
  const factory ConnectionStatus.connected() = Connected;
  const factory ConnectionStatus.disconnecting() = Disconnecting;

  bool get isConnected => switch (this) {
    Connected() => true,
    _ => false,
  };

  bool get isDisconnected => switch (this) {
    Disconnected() => true,
    _ => false,
  };

  bool get isSwitching => switch (this) {
    Connecting() => true,
    Disconnecting() => true,
    _ => false,
  };

  String format() => switch (this) {
    Disconnected(:final connectionFailure) =>
      connectionFailure != null ? "CONNECTION FAILURE: $connectionFailure" : "DISCONNECTED",
    Connecting() => "CONNECTING",
    Connected() => "CONNECTED",
    Disconnecting() => "DISCONNECTING",
  };

  String present(TranslationsEn t) => switch (this) {
    Disconnected() => t.connection.tapToConnect,
    Connecting() => t.connection.connecting,
    Connected() => t.connection.connected,
    Disconnecting() => t.connection.disconnecting,
  };
}
