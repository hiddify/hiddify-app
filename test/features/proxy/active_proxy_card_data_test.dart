import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/proxy/model/proxy_entity.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  test("the last run's IP does not count until this run looks it up", () {
    final cached = _info('M-NL', delay: 150)..ipinfo = IpInfo(ip: '45.12.3.9', fromCache: true);
    expect(cached.hasIp, isFalse);
  });

  group('connection steps', () {
    StepStatus? server(int delay, {ChainStatus chain = ChainStatus.off, OutboundInfo? hop}) =>
        _card(chain: chain, hop: hop, [
          _group('select', [_info('M-NL', delay: delay)]),
        ])!.serverStatus;
    StepStatus? hop(OutboundInfo? hop, {int serverDelay = 150}) => _card(chain: ChainStatus.extraSecurity, hop: hop, [
      _group('select', [_info('M-NL', delay: serverDelay)]),
    ])!.hopStatus;
    OutboundInfo psiphon({Status status = Status.READY, int delay = 0}) =>
        _info('🔒 Extra Security · Psiphon §hide§', status: status, delay: delay);

    test('the server: not tested, answering, timed out', () {
      expect(server(0), StepStatus.connecting);
      expect(server(150), StepStatus.connected);
      expect(server(65535), StepStatus.failed);
      expect(
        _card([
          _group('select', [_info('M-NL')]),
        ])!.hopStatus,
        isNull,
      );
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
      bool offer({int pick = 65535, int lowest = 120, bool selectable = true, bool hasLowest = true}) => _card([
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
      expect(
        _card([
          _group('select', [_info('balance', isGroup: true)], selectable: true),
          _group('balance', [_info('M-NL', delay: 65535)]),
          _group('lowest', [_info('M-DE', delay: 120)]),
        ])!.offerLowest,
        isFalse,
        reason: 'a picked group is not offered the switch',
      );
      expect(
        _card(chain: ChainStatus.unblocker, [
          _group('select', [_info('M-NL', delay: 65535)], selectable: true),
          _group('lowest', [_info('M-DE', delay: 120)]),
        ])!.offerLowest,
        isFalse,
        reason: 'the server waits for the unblocker, so it has not failed',
      );
    });
  });

  group("the hop's wait", () {
    late StreamController<OutboundGroupList> core;
    late ProviderContainer container;
    var clock = DateTime(2026, 10, 31, 12);
    var sent = 0;

    setUp(() async {
      core = StreamController<OutboundGroupList>();
      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWith(
            (ref) => _Prefs({'chain-status': 'extraSecurity', 'extra-security-mode': 'psiphon'}),
          ),
          mainOutboundsNotifierProvider.overrideWith(() => _Main(core.stream)),
          activeProxyCardProvider.overrideWith(() => _Card(() => clock)),
        ],
      );
      await container.read(sharedPreferencesProvider.future);
      container.listen(activeProxyCardProvider, (_, _) {});
    });

    tearDown(() async {
      container.dispose();
      await core.close();
    });

    /// One message of the core, with the server answering; each differs, like the hop's live type.
    Future<StepStatus?> hopAfter(Duration time, {Status status = Status.CONNECTING, int delay = 0}) async {
      clock = clock.add(time);
      core.add(
        OutboundGroupList(
          items: [
            _group('select', [_info('M-NL', delay: 150)]),
          ],
          chainHop: _info(
            '🔒 Extra Security · Psiphon §hide§',
            type: 'Psiphon ${sent++}',
            status: status,
            delay: delay,
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      return container.read(activeProxyCardProvider)?.hopStatus;
    }

    test('counts from when the hop started connecting, and starts over after it connects', () async {
      expect(await hopAfter(Duration.zero), StepStatus.connecting);
      expect(await hopAfter(const Duration(seconds: 14)), StepStatus.connecting);
      expect(await hopAfter(const Duration(seconds: 6)), StepStatus.slow);
      expect(await hopAfter(const Duration(seconds: 45)), StepStatus.failed);
      expect(await hopAfter(const Duration(seconds: 5), status: Status.READY, delay: 230), StepStatus.connected);
      expect(await hopAfter(const Duration(minutes: 5), status: Status.RECONNECTING), StepStatus.connecting);
      expect(await hopAfter(const Duration(seconds: 16), status: Status.RECONNECTING), StepStatus.slow);
    });
  });

  group('proxies page row', () {
    test("the core's status comes first, then a ready proxy's ping", () {
      expect(_info('a', status: Status.CONNECTING, delay: 200).rowState, ProxyRowState.connecting);
      expect(_info('a', status: Status.REGISTERING).rowState, ProxyRowState.registering);
      expect(_info('a', status: Status.SEARCHING).rowState, ProxyRowState.searching);
      expect(_info('a', status: Status.RECONNECTING, delay: 200).rowState, ProxyRowState.reconnecting);
      expect(_info('a', status: Status.FAILED).rowState, ProxyRowState.failed);
      expect(_info('a', delay: 200).rowState, ProxyRowState.ready);
      expect(_info('a').rowState, ProxyRowState.untested);
      expect(_info('a', delay: 65535).rowState, ProxyRowState.pingFailed);
    });

    test("the type loses only the core's status mark", () {
      expect(_info('a', type: 'WARP ⏳ Connecting...', status: Status.CONNECTING).typeWithoutStatus, 'WARP');
      expect(_info('a', type: 'WARP ⌛ Reconnecting...', status: Status.RECONNECTING).typeWithoutStatus, 'WARP');
      expect(
        _info('a', type: 'WARP · Auto 🔍 Searching...', status: Status.SEARCHING).typeWithoutStatus,
        'WARP · Auto',
      );
      expect(_info('a', type: 'DNSTT ❌ Failed', status: Status.FAILED).typeWithoutStatus, 'DNSTT');
      expect(_info('a', type: 'WARP 🔑 Registering...', status: Status.REGISTERING).typeWithoutStatus, 'WARP');
      // a ready proxy's type is left alone, even if it holds one of the emoji
      expect(_info('a', type: 'VLESS ❌ x').typeWithoutStatus, 'VLESS ❌ x');
    });
  });
}

class _Prefs implements SharedPreferences {
  _Prefs(this._values);
  final Map<String, Object> _values;

  @override
  Object? get(String key) => _values[key];

  @override
  String? getString(String key) => _values[key] as String?;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Main extends MainOutboundsNotifier {
  _Main(this._stream);
  final Stream<OutboundGroupList> _stream;

  @override
  Stream<OutboundGroupList> build() => _stream;
}

class _Card extends ActiveProxyCard {
  _Card(this._clock);
  final DateTime Function() _clock;

  @override
  DateTime now() => _clock();
}
