import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/proxy/deep_search/deep_search_prompt.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';

OutboundGroupList _list({List<OutboundInfo> picks = const [], OutboundInfo? hop}) => OutboundGroupList(
  items: [
    for (final (i, pick) in picks.indexed) OutboundGroup(tag: 'group$i', items: [pick]),
  ],
  chainHop: hop,
);

void main() {
  final warpGaveUp = OutboundInfo(tag: 'warp', deepSearchAvailable: true, urlTestDelay: 65535);
  final working = OutboundInfo(tag: 'vless', urlTestDelay: 120);
  final failed = OutboundInfo(tag: 'trojan', urlTestDelay: 65535);
  final hopGaveUp = OutboundInfo(tag: '🔓 Unblocker · Psiphon §hide§', deepSearchAvailable: true);

  test('the unblocker hop is offered even while a proxy works', () {
    final list = _list(picks: [working], hop: hopGaveUp);
    expect(deepSearchCandidate(list, ChainStatus.unblocker)?.tag, hopGaveUp.tag);
  });

  test('a proxy is offered when no proxy works', () {
    expect(deepSearchCandidate(_list(picks: [warpGaveUp, failed]), ChainStatus.off)?.tag, 'warp');
  });

  test('nothing is offered while another proxy works', () {
    expect(deepSearchCandidate(_list(picks: [warpGaveUp, working]), ChainStatus.off), isNull);
  });

  test('nothing is offered when no search gave up', () {
    expect(deepSearchCandidate(_list(picks: [failed]), ChainStatus.off), isNull);
    expect(
      deepSearchCandidate(
        _list(
          picks: [working],
          hop: OutboundInfo(tag: 'hop'),
        ),
        ChainStatus.unblocker,
      ),
      isNull,
    );
  });
}
