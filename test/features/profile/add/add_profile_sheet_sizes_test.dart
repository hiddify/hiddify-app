import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/profile/add/add_profile_modal.dart';

void main() {
  void expectValid(({double initial, double min, double max}) s) {
    expect(s.min, lessThanOrEqualTo(s.initial));
    expect(s.initial, lessThanOrEqualTo(s.max));
    expect(s.max, lessThanOrEqualTo(1.0));
  }

  test('buttons taller than the whole screen cap the sheet at full height', () {
    // landscape TV: wide buttons and the phone import panel, a 540px high sheet
    const full = 600.0;
    final s = addProfileSheetSizes(initial: full + 180, min: full + 100, max: 0.85, fullHeight: full, height: 540);
    expectValid(s);
    expect(s.max, 1.0);
  });

  test('buttons taller than 85% let the sheet grow to fit them', () {
    const full = 470.0;
    final s = addProfileSheetSizes(initial: full + 180, min: full + 100, max: 0.85, fullHeight: full, height: 500);
    expectValid(s);
    expect(s.max, closeTo(full / 500, 1e-9));
  });

  test('a phone keeps the old sizes', () {
    const full = 200.0;
    final s = addProfileSheetSizes(initial: full + 180, min: full + 100, max: 0.85, fullHeight: full, height: 800);
    expect(s, (initial: 380 / 800, min: 300 / 800, max: 0.85));
  });

  test('without free configs a too-short screen is capped at full height', () {
    const full = 600.0;
    final s = addProfileSheetSizes(initial: full, min: full, max: full / 500, fullHeight: full, height: 500);
    expectValid(s);
  });
}
