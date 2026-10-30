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

OutboundGroup _group(String tag, List<OutboundInfo> items) => OutboundGroup(tag: tag, items: items);

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
}
