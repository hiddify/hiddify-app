import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/connection/model/connection_failure.dart';

part 'connection_status.freezed.dart';

@freezed
sealed class ConnectionStatus with _$ConnectionStatus {
  const ConnectionStatus._();

  const factory ConnectionStatus.disconnected([ConnectionFailure? connectionFailure]) = Disconnected;
  const factory ConnectionStatus.connecting() = Connecting;
  // the core is up but no ping works yet
  const factory ConnectionStatus.waiting() = Waiting;
  // every proxy was tested and timed out; the core is up and it is not an error
  const factory ConnectionStatus.noAvailableProxies() = NoAvailableProxies;
  const factory ConnectionStatus.connected() = Connected;
  const factory ConnectionStatus.disconnecting() = Disconnecting;
  // the running core is applying a new config; the connection stays up
  const factory ConnectionStatus.hotReloading() = HotReloading;

  bool get isConnected => switch (this) {
    Connected() => true,
    _ => false,
  };

  /// The core is up, with or without a working ping.
  bool get isRunning => switch (this) {
    Connected() || Waiting() || NoAvailableProxies() || HotReloading() => true,
    _ => false,
  };

  bool get isDisconnected => switch (this) {
    Disconnected() => true,
    _ => false,
  };

  bool get isSwitching => switch (this) {
    Connecting() => true,
    Disconnecting() => true,
    HotReloading() => true,
    _ => false,
  };

  String format() => switch (this) {
    Disconnected(:final connectionFailure) =>
      connectionFailure != null ? "CONNECTION FAILURE: $connectionFailure" : "DISCONNECTED",
    Connecting() => "CONNECTING",
    Waiting() => "WAITING",
    NoAvailableProxies() => "NO AVAILABLE PROXIES",
    Connected() => "CONNECTED",
    Disconnecting() => "DISCONNECTING",
    HotReloading() => "HOT RELOADING",
  };

  String present(TranslationsEn t) => switch (this) {
    Disconnected() => t.connection.tapToConnect,
    Connecting() => t.connection.connecting,
    Waiting() => t.connection.waiting,
    NoAvailableProxies() => t.connection.noAvailableProxies,
    Connected() => t.connection.connected,
    Disconnecting() => t.connection.disconnecting,
    HotReloading() => t.connection.hotReloading,
  };
}
