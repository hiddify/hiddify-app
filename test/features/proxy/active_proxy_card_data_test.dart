import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/proxy/model/proxy_entity.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';

OutboundInfo _info(
  String tag, {
  String type = 'VLESS',
  String ip = '',
  int delay = 0,
  bool selected = true,
  bool isGroup = false,
  Status status = Status.READY,
}) => OutboundInfo(
  tag: tag,
  type: type,
  ipinfo: IpInfo(ip: ip),
  urlTestDelay: delay,
  isSelected: selected,
  isGroup: isGroup,
  status: status,
);

OutboundGroup _group(String tag, List<OutboundInfo> items, {bool selectable = false}) =>
    OutboundGroup(tag: tag, items: items, selectable: selectable);

ActiveProxyCardData? _card(List<OutboundGroup> groups, {ChainStatus chain = ChainStatus.off, OutboundInfo? hop}) =>
    ActiveProxyCardData.from(
      OutboundGroupList(items: groups, chainHop: hop),
      chain: chain,
      hopMode: ChainMode.warp,
    );

void main() {
  test('no selection yet', () {
    expect(_card([]), isNull);
    expect(_card([_group('select', [])]), isNull);
  });

  test('a config picked by the user', () {
    final card = _card([
      _group('select', [_info('🇳🇱 M-NL §hide§', ip: '45.12.3.9')]),
    ])!;
    expect(card.server.name, '🇳🇱 M-NL');
    expect(card.server.type, 'VLESS');
    expect(card.server.ipinfo.ip, '45.12.3.9');
    expect(card.group, isNull);
    expect(card.hop, isNull);
  });

  test('a group picked: the server is the one the group chose', () {
    final card = _card([
      _group('select', [_info('lowest', type: 'Balancer', isGroup: true)]),
      _group('lowest', [_info('🇳🇱 M-NL', type: 'Trojan', ip: '45.12.3.9')]),
    ])!;
    expect(card.group, 'lowest');
    expect(card.server.name, '🇳🇱 M-NL');
    expect(card.server.type, 'Trojan');
    expect(card.server.ipinfo.ip, '45.12.3.9');
  });

  test('extra security: the hop comes from its own field', () {
    final card = _card(
      chain: ChainStatus.extraSecurity,
      hop: _info('🔒 Extra Security · Psiphon §hide§', type: 'Psiphon', ip: '104.28.9.2'),
      [
        _group('select', [_info('🇳🇱 M-NL')]),
      ],
    )!;
    expect(card.server.name, '🇳🇱 M-NL');
    expect(card.hop?.ipinfo.ip, '104.28.9.2');
  });

  test('unblocker: the hop and its status', () {
    final card = _card(
      chain: ChainStatus.unblocker,
      hop: _info('🔓 Unblocker · WARP · Auto §hide§', status: Status.CONNECTING),
      [
        _group('select', [_info('🇳🇱 M-NL')]),
      ],
    )!;
    expect(card.server.type, 'VLESS');
    expect(card.hop?.status, Status.CONNECTING);
  });

  test('chain off: a hop the core still lists is not shown', () {
    final card = _card(hop: _info('🔓 Unblocker · WARP · Auto §hide§'), [
      _group('select', [_info('M-NL')]),
    ])!;
    expect(card.hop, isNull);
  });

  test('chain on, but the core has not listed the hop yet', () {
    expect(
      _card(chain: ChainStatus.unblocker, [
        _group('select', [_info('M-NL')]),
      ])!.hop,
      isNull,
    );
  });

  test("a proxy's own detour shows in its name, the app's hidden ones do not", () {
    expect(OutboundInfo(tagDisplay: 'Via P', detour: 'P socks § 0').nameWithDetour, 'Via P → P socks');
    expect(OutboundInfo(tagDisplay: 'M-NL', detour: '🔓 Unblocker · Psiphon §hide§').nameWithDetour, 'M-NL');
    expect(OutboundInfo(tagDisplay: 'M-NL').nameWithDetour, 'M-NL');
  });

  test('a good ping without an IP means the IP lookup failed', () {
    expect(_info('M-NL', delay: 150).ipLookupFailed, isTrue);
    expect(_info('M-NL').ipLookupFailed, isFalse);
    expect(_info('M-NL', delay: 150, ip: '45.12.3.9').ipLookupFailed, isFalse);
  });

  group('connection steps', () {
    StepStatus? server(int delay, {ChainStatus chain = ChainStatus.off, OutboundInfo? hop}) => _card(
      chain: chain,
      hop: hop,
      [
        _group('select', [_info('M-NL', delay: delay)]),
      ],
    )!.serverStatus;
    StepStatus? hop(OutboundInfo? hop, {int serverDelay = 150}) => _card(
      chain: ChainStatus.extraSecurity,
      hop: hop,
      [
        _group('select', [_info('M-NL', delay: serverDelay)]),
      ],
    )!.hopStatus;
    OutboundInfo psiphon({Status status = Status.READY, int delay = 0}) =>
        _info('🔒 Extra Security · Psiphon §hide§', status: status, delay: delay);

    test('the server: not tested, answering, timed out', () {
      expect(server(0), StepStatus.connecting);
      expect(server(150), StepStatus.connected);
      expect(server(65535), StepStatus.failed);
      expect(_card([_group('select', [_info('M-NL')])])!.hopStatus, isNull);
    });

    test('the hop is connected once it is ready and answers', () {
      expect(hop(null), StepStatus.connecting);
      expect(hop(psiphon(status: Status.CONNECTING, delay: 65535)), StepStatus.connecting);
      expect(hop(psiphon()), StepStatus.connecting);
      expect(hop(psiphon(delay: 230)), StepStatus.connected);
      expect(hop(psiphon(status: Status.FAILED)), StepStatus.failed);
    });

    test('extra security waits for the server it dials through', () {
      expect(hop(psiphon(delay: 230), serverDelay: 0), StepStatus.waiting);
      expect(hop(psiphon(status: Status.FAILED), serverDelay: 65535), StepStatus.waiting);
    });

    test('the server waits for the unblocker it dials through', () {
      final down = _info('🔓 Unblocker · WARP §hide§', status: Status.CONNECTING);
      final up = _info('🔓 Unblocker · WARP §hide§', delay: 180);
      expect(server(65535, chain: ChainStatus.unblocker, hop: down), StepStatus.waiting);
      expect(server(65535, chain: ChainStatus.unblocker, hop: up), StepStatus.failed);
      expect(server(150, chain: ChainStatus.unblocker, hop: up), StepStatus.connected);
    });

    test('a hop that keeps connecting turns slow, then failed', () {
      final card = _card(chain: ChainStatus.extraSecurity, hop: psiphon(status: Status.CONNECTING), [
        _group('select', [_info('M-NL', delay: 150)]),
      ])!;
      expect(card.hopWaited(const Duration(seconds: 14)).hopStatus, StepStatus.connecting);
      expect(card.hopWaited(const Duration(seconds: 15)).hopStatus, StepStatus.slow);
      expect(card.hopWaited(const Duration(seconds: 59)).hopStatus, StepStatus.slow);
      expect(card.hopWaited(const Duration(seconds: 60)).hopStatus, StepStatus.failed);
      final waiting = _card(chain: ChainStatus.extraSecurity, hop: psiphon(), [
        _group('select', [_info('M-NL')]),
      ])!;
      expect(waiting.hopWaited(const Duration(minutes: 2)).hopStatus, StepStatus.waiting);
    });

    test('switch to lowest is offered only for a dead pick while lowest answers', () {
      bool offer({int pick = 65535, int lowest = 120, bool selectable = true, bool hasLowest = true}) =>
          _card([
            _group('select', [_info('M-NL', delay: pick)], selectable: selectable),
            if (hasLowest) _group('lowest', [_info('M-DE', delay: lowest)]),
          ])!.offerLowest;
      expect(offer(), isTrue);
      expect(offer(lowest: 65535), isFalse);
      expect(offer(lowest: 0), isFalse);
      expect(offer(pick: 150), isFalse);
      expect(offer(pick: 0), isFalse);
      expect(offer(selectable: false), isFalse);
      expect(offer(hasLowest: false), isFalse);
      expect(_card(chain: ChainStatus.unblocker, [
        _group('select', [_info('M-NL', delay: 65535)], selectable: true),
        _group('lowest', [_info('M-DE', delay: 120)]),
      ])!.offerLowest, isFalse, reason: 'the server waits for the unblocker, so it has not failed');
    });
  });
}
