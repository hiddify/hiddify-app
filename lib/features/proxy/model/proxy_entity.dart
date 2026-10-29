import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';

part 'proxy_entity.freezed.dart';

@freezed
class ProxyGroupEntity with _$ProxyGroupEntity {
  const ProxyGroupEntity._();

  const factory ProxyGroupEntity({
    required String tag,
    required String type,
    required String selected,
    @Default([]) List<ProxyItemEntity> items,
  }) = _ProxyGroupEntity;

  String get name => _sanitizedTag(tag);
}

@freezed
class ProxyItemEntity with _$ProxyItemEntity {
  const ProxyItemEntity._();

  const factory ProxyItemEntity({
    required String tag,
    required String type,
    required int urlTestDelay,
    String? selectedTag,
  }) = _ProxyItemEntity;

  String get name => _sanitizedTag(tag);
  String? get selectedName => selectedTag == null ? null : _sanitizedTag(selectedTag!);
  bool get isVisible => !tag.contains("§hide§");
}

String _sanitizedTag(String tag) => tag.replaceFirst(RegExp(r"\§[^]*"), "").trimRight();
// bool get isVisible => !tag.contains("§hide§");

// Names the core gives its own groups (hiddify-core v2/config).
const lowestGroupTag = 'lowest';
const balanceGroupTag = 'balance';

/// What the home proxy card shows, taken from one message of the core's main list.
class ActiveProxyCardData {
  const ActiveProxyCardData({
    required this.server,
    required this.group,
    required this.hop,
    required this.chain,
    required this.hopMode,
  });

  /// Null while the main group has no selection.
  static ActiveProxyCardData? from(OutboundGroupList list, {required ChainStatus chain, required ChainMode hopMode}) {
    // The main group lists only the user's pick.
    final picked = list.items.firstOrNull?.items.firstOrNull;
    if (picked == null) return null;
    // When the pick is a group, its own entry in the list holds the server it chose.
    final chosen = list.items.where((g) => g.tag == picked.tag).firstOrNull?.items.firstOrNull;
    return ActiveProxyCardData(
      server: chosen ?? picked,
      group: picked.isGroup ? picked.name : null,
      hop: !chain.isOff() && list.hasChainHop() ? list.chainHop : null,
      chain: chain,
      hopMode: hopMode,
    );
  }

  /// The server that carries the traffic: the config the user picked, or the one its group chose.
  final OutboundInfo server;

  /// The group that chose the server ("lowest", "balance", …); null when the user picked it.
  final String? group;

  /// The chain hop as the core reports it: IP, ping and status. Null when the chain is off, or
  /// before the core lists it.
  final OutboundInfo? hop;

  final ChainStatus chain;

  /// The hop's mode, from the chain settings.
  final ChainMode hopMode;
}

extension OutboundInfoCard on OutboundInfo {
  /// The name, without the core's hidden suffix.
  String get name => _sanitizedTag(tag);

  /// The name, and the user's own proxy it dials through ("A → B"). The app's own hidden ones,
  /// such as the chain hop, are left out.
  String get nameWithDetour =>
      detour.isEmpty || detour.contains('§hide§') ? tagDisplay : '$tagDisplay → ${_sanitizedTag(detour)}';

  bool get hasIp => ipinfo.ip.isNotEmpty;

  /// The core looks the IP up right after a good ping and sends both together, so a good ping
  /// without an IP means the lookup failed (until the next ping round).
  bool get ipLookupFailed => !hasIp && ConnectionConst.isValidDelay(urlTestDelay);
}
