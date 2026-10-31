import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/features/chain/model/chain_enum.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/proxy/model/proxy_entity.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';

/// How far one step of the path has got.
enum HealthState {
  ok,
  pending,
  failed,

  /// Cannot work before the step it goes through does: the hop dials through the user's pick.
  blocked;

  static HealthState ofDelay(int delay) => switch (delay) {
    0 => pending,
    _ when ConnectionConst.isValidDelay(delay) => ok,
    _ => failed,
  };
}

/// The path the traffic takes, step by step, for the home screen to explain what is wrong.
///
/// The core is connected as soon as any proxy of the "lowest" group answers, so connected alone
/// does not say the traffic gets through: the user's own pick, or the chain hop, can still be down.
class ConnectionHealth {
  const ConnectionHealth({
    required this.status,
    required this.mainGroup,
    required this.pickTag,
    required this.server,
    required this.fastest,
    required this.hop,
    required this.chain,
  });

  factory ConnectionHealth.from(ConnectionStatus status, OutboundGroupList list, ChainStatus chain) {
    final main = list.items.firstOrNull;
    final picked = main?.items.firstOrNull;
    // a group the user picked lists the server it chose under its own tag
    OutboundInfo? chosenBy(String tag) => list.items.where((g) => g.tag == tag).firstOrNull?.items.firstOrNull;
    return ConnectionHealth(
      status: status,
      mainGroup: main?.tag,
      pickTag: picked?.tag,
      server: picked == null ? null : (picked.isGroup ? chosenBy(picked.tag) : null) ?? picked,
      fastest: chosenBy(lowestGroupTag),
      hop: !chain.isOff() && list.hasChainHop() ? list.chainHop : null,
      chain: chain.isOff() ? null : (chain.isUnblocker() ? ChainType.unblocker : ChainType.extraSecurity),
    );
  }

  final ConnectionStatus status;

  /// The selector the user picks in; switching to the fastest selects "lowest" in it.
  final String? mainGroup;
  final String? pickTag;

  /// The server the user's pick reaches: the config itself, or the one its group chose.
  final OutboundInfo? server;

  /// The server the "lowest" group chose; null for a profile with one proxy.
  final OutboundInfo? fastest;

  final OutboundInfo? hop;

  /// Null with the chain off.
  final ChainType? chain;

  HealthState get core => switch (status) {
    Connected() => HealthState.ok,
    NoAvailableProxies() => HealthState.failed,
    _ => HealthState.pending,
  };

  HealthState get fastestState => fastest == null ? core : HealthState.ofDelay(fastest!.urlTestDelay);

  /// Whether the user picked a server or group other than "lowest".
  bool get pickedByHand => pickTag != null && pickTag != lowestGroupTag;

  HealthState get pick => server == null ? HealthState.pending : HealthState.ofDelay(server!.urlTestDelay);

  HealthState get hopState {
    final hop = this.hop;
    if (chain == null) return HealthState.ok;
    // extra security dials through the pick; the unblocker goes before it and does not wait for it
    if (chain == ChainType.extraSecurity && pick == HealthState.failed) return HealthState.blocked;
    if (hop == null) return HealthState.pending;
    return switch (hop.status) {
      Status.FAILED => HealthState.failed,
      // set up; its first ping can take a minute, so only a timed out one counts against it
      Status.READY => hop.urlTestDelay == 0 ? HealthState.ok : HealthState.ofDelay(hop.urlTestDelay),
      _ => HealthState.pending,
    };
  }

  /// The hop is up but its ping times out, as opposed to the hop failing to set up.
  bool get hopNoReply => hop?.status == Status.READY && hopState == HealthState.failed;

  /// The user's pick is down while "lowest" has a working server to offer instead.
  bool get canSwitchToFastest =>
      core == HealthState.ok && pickedByHand && pick == HealthState.failed && fastestState == HealthState.ok;

  /// Connected, but the traffic does not get through.
  bool get degraded =>
      core == HealthState.ok &&
      (pick == HealthState.failed || hopState == HealthState.failed || hopState == HealthState.blocked);

  /// Connected, and the chain hop is still on its way.
  bool get hopPending => core == HealthState.ok && pick != HealthState.failed && hopState == HealthState.pending;
}
