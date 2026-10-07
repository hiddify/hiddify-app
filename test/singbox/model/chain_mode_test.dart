import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';

void main() {
  test('only warp and psiphon are selectable for now', () {
    expect(ChainMode.selectable, unorderedEquals([ChainMode.psiphon, ChainMode.warp]));
  });

  test('a stored profile mode falls back to the default', () {
    expect(ChainMode.fromStored('profile', ChainMode.warp), ChainMode.warp);
    expect(ChainMode.fromStored('profile', ChainMode.psiphon), ChainMode.psiphon);
    expect(ChainMode.fromStored('unknown', ChainMode.psiphon), ChainMode.psiphon);
  });

  test('stored warp and psiphon modes are kept', () {
    expect(ChainMode.fromStored('warp', ChainMode.psiphon), ChainMode.warp);
    expect(ChainMode.fromStored('psiphon', ChainMode.warp), ChainMode.psiphon);
  });
}
