import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';

void main() {
  test('every warp mode and psiphon are selectable', () {
    expect(
      ChainMode.selectable,
      unorderedEquals([
        ChainMode.psiphon,
        ChainMode.warpWireGuard,
        ChainMode.warpMasque,
        ChainMode.warpAwg,
        ChainMode.warpAuto,
      ]),
    );
  });

  test('a stored profile mode falls back to the default', () {
    expect(ChainMode.fromStored('profile', ChainMode.warpAuto), ChainMode.warpAuto);
    expect(ChainMode.fromStored('profile', ChainMode.psiphon), ChainMode.psiphon);
    expect(ChainMode.fromStored('unknown', ChainMode.psiphon), ChainMode.psiphon);
  });

  test('a stored mode this build knows is kept', () {
    expect(ChainMode.fromStored('warpMasque', ChainMode.warpAuto), ChainMode.warpMasque);
    expect(ChainMode.fromStored('psiphon', ChainMode.warpAuto), ChainMode.psiphon);
  });

  test('a stored "warp" keeps meaning every tunnel', () {
    // The name predates the split, when "warp" was the one mode that raced WireGuard, AmneziaWG
    // and MASQUE. No member carries it now, so it falls back — and the fallback is the auto mode.
    expect(ChainMode.fromStored('warp', ChainMode.warpAuto), ChainMode.warpAuto);
    expect(ChainMode.warpWireGuard.key, 'warp');
  });

  test('a subscription "warp" names the auto mode, a named mode names itself', () {
    expect(ChainMode.tryFromLink('warp'), ChainMode.warpAuto);
    expect(ChainMode.tryFromLink('warp_masque'), ChainMode.warpMasque);
    expect(ChainMode.tryFromLink('warp_awg'), ChainMode.warpAwg);
    expect(ChainMode.tryFromLink('warp_auto'), ChainMode.warpAuto);
    expect(ChainMode.tryFromLink('Marsque'), isNull);
    expect(ChainMode.tryFromLink(''), isNull);
  });
}
