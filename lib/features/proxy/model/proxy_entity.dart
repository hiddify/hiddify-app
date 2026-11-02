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

/// Where one step of the connection (the server, or the chain hop) stands.
enum StepStatus {
  /// The step it dials through has not connected yet.
  waiting,
  connecting,

  /// The hop is still connecting after [ActiveProxyCardData.hopSlowAfter].
  slow,
  connected,
  failed,
}

/// What the home proxy card shows, taken from one message of the core's main list.
class ActiveProxyCardData {
  const ActiveProxyCardData({
    required this.server,
    required this.group,
    required this.hop,
    required this.chain,
    required this.hopMode,
    required this.serverStatus,
    required this.hopStatus,
    required this.mainGroup,
    required this.offerLowest,
  });

  /// How long the hop may connect before it counts as slow, then as failed. Psiphon gives up a
  /// round of tries after 60 s, then starts another.
  static const hopSlowAfter = Duration(seconds: 15);
  static const hopFailAfter = Duration(seconds: 60);

  /// Null while the main group has no selection.
  static ActiveProxyCardData? from(OutboundGroupList list, {required ChainStatus chain, required ChainMode hopMode}) {
    // The main group lists only the user's pick.
    final main = list.items.firstOrNull;
    final picked = main?.items.firstOrNull;
    if (main == null || picked == null) return null;
    // When the pick is a group, its own entry in the list holds the server it chose.
    final chosen = list.items.where((g) => g.tag == picked.tag).firstOrNull?.items.firstOrNull;
    final server = chosen ?? picked;
    final hop = !chain.isOff() && list.hasChainHop() ? list.chainHop : null;

    var serverStatus = _serverStatusOf(server);
    var hopStatus = chain.isOff() ? null : _hopStatusOf(hop);
    // A step dials through the one before it: extra security through the server, the server
    // through the unblocker. Until that one connects, the step's own results mean nothing.
    if (chain.isExtraSecurity() && serverStatus != StepStatus.connected) hopStatus = StepStatus.waiting;
    if (chain.isUnblocker() && hopStatus != StepStatus.connected) serverStatus = StepStatus.waiting;

    final lowest = list.items.where((g) => g.tag == lowestGroupTag).firstOrNull?.items.firstOrNull;
    return ActiveProxyCardData(
      server: server,
      group: picked.isGroup ? picked.name : null,
      hop: hop,
      chain: chain,
      hopMode: hopMode,
      serverStatus: serverStatus,
      hopStatus: hopStatus,
      mainGroup: main.tag,
      offerLowest:
          serverStatus == StepStatus.failed &&
          !picked.isGroup &&
          main.selectable &&
          lowest != null &&
          ConnectionConst.isValidDelay(lowest.urlTestDelay),
    );
  }

  static StepStatus _serverStatusOf(OutboundInfo server) => switch (server.urlTestDelay) {
    final delay when ConnectionConst.isValidDelay(delay) => StepStatus.connected,
    0 => StepStatus.connecting, // not tested yet
    _ => StepStatus.failed, // the test timed out
  };

  static StepStatus _hopStatusOf(OutboundInfo? hop) => switch (hop) {
    OutboundInfo(status: Status.FAILED) => StepStatus.failed,
    OutboundInfo(status: Status.READY, :final urlTestDelay) when ConnectionConst.isValidDelay(urlTestDelay) =>
      StepStatus.connected,
    // not listed yet, connecting, or not tested since it got ready
    _ => StepStatus.connecting,
  };

  /// This card once the hop has been connecting for [waited]: slow, then failed.
  ActiveProxyCardData hopWaited(Duration waited) => hopStatus != StepStatus.connecting || waited < hopSlowAfter
      ? this
      : ActiveProxyCardData(
          server: server,
          group: group,
          hop: hop,
          chain: chain,
          hopMode: hopMode,
          serverStatus: serverStatus,
          hopStatus: waited < hopFailAfter ? StepStatus.slow : StepStatus.failed,
          mainGroup: mainGroup,
          offerLowest: offerLowest,
        );

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

  final StepStatus serverStatus;

  /// Null when the chain is off.
  final StepStatus? hopStatus;

  /// The main group's tag: "switch to lowest" changes its selection.
  final String mainGroup;

  /// The proxy the user picked failed while lowest's choice answers, so one tap moves the main group
  /// to lowest. A picked group, such as balance, is never offered the switch.
  final bool offerLowest;
}

extension OutboundInfoCard on OutboundInfo {
  /// The name, without the core's hidden suffix.
  String get name => _sanitizedTag(tag);

  /// The name, and the user's own proxy it dials through ("A → B"). The app's own hidden ones,
  /// such as the chain hop, are left out.
  String get nameWithDetour =>
      detour.isEmpty || detour.contains('§hide§') ? tagDisplay : '$tagDisplay → ${_sanitizedTag(detour)}';

  /// An IP looked up in this run. The core sends the last run's IP, marked, until a lookup
  /// replaces it; it may have changed since, so it does not count.
  bool get hasIp => ipinfo.ip.isNotEmpty && !ipinfo.fromCache;

  /// What a proxies-page row shows: the core's [status] first, then for a ready proxy its ping.
  ProxyRowState get rowState => switch (status) {
    Status.CONNECTING => ProxyRowState.connecting,
    Status.REGISTERING => ProxyRowState.registering,
    Status.SEARCHING => ProxyRowState.searching,
    Status.RECONNECTING => ProxyRowState.reconnecting,
    Status.FAILED => ProxyRowState.failed,
    _ => switch (urlTestDelay) {
      final delay when ConnectionConst.isValidDelay(delay) => ProxyRowState.ready,
      0 => ProxyRowState.untested,
      _ => ProxyRowState.pingFailed,
    },
  };

  /// [type] without the status mark the core adds while the proxy is not ready
  /// ("WARP ⏳ Connecting..."); the row shows the status its own way.
  String get typeWithoutStatus => status == Status.READY ? type : type.replaceFirst(_statusMark, '');
}

/// The endpoint the WARP scanner chose, as the core appends it to the display type
/// (" · 🔍 162.159.192.1:2408", " · 🔍 [2606:4700:…]:443"; hiddify-sing-box hiddify/warpscan/status.go).
final _scannerEndpoint = RegExp(r'^(.*?) · 🔍 (\[[0-9a-fA-F:]+\]:\d+|\d+\.\d+\.\d+\.\d+:\d+)(.*)$');

/// [type] split round the WARP scanner's endpoint: what comes before it, the endpoint, and what
/// follows it, such as the status mark. Null when the type has no endpoint.
({String before, String endpoint, String after})? splitScannerEndpoint(String type) {
  final m = _scannerEndpoint.firstMatch(type);
  return m == null ? null : (before: m[1]!, endpoint: m[2]!, after: m[3]!);
}

/// The core's status mark: a space, one of its emoji, then the word (hiddify-sing-box adapter/h_status.go).
final _statusMark = RegExp(r'\s+(⏳|⌛|🔍|❌|🔑)\s.*$');

/// A proxies-page row's state. [untested] waits for its first ping; [pingFailed] is ready but its
/// ping got no answer; [failed] is the core's FAILED, the proxy gave up.
enum ProxyRowState { ready, untested, pingFailed, connecting, registering, searching, reconnecting, failed }
