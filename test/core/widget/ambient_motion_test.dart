import 'dart:ui' show AppLifecycleState;

import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/widget/ambient_motion.dart';

void main() {
  tearDown(() {
    seeLifecycle(AppLifecycleState.resumed);
    seeWindow(hidden: false);
  });

  testWidgets('the clock stops as soon as the app goes to the background, and goes on when it is back', (tester) async {
    var ticks = 0;
    final unsubscribe = AmbientClock.subscribe(AmbientClock.decoration, () => ticks++);

    await tester.pump(const Duration(seconds: 1));
    expect(ticks, greaterThan(10));

    // a phone goes from resumed to the background: no frame is drawn, and none needs to be for this
    seeLifecycle(AppLifecycleState.hidden);
    seeLifecycle(AppLifecycleState.paused);
    expect(appSeen.value, isFalse);
    ticks = 0;
    await tester.pump(const Duration(seconds: 5));
    expect(ticks, 0);

    seeLifecycle(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 1));
    expect(ticks, greaterThan(10));
    unsubscribe();
  });

  testWidgets('a desktop window hidden in the tray or minimized stops the clock', (tester) async {
    var ticks = 0;
    final unsubscribe = AmbientClock.subscribe(AmbientClock.decoration, () => ticks++);

    seeWindow(hidden: true);
    await tester.pump(const Duration(seconds: 2));
    expect(ticks, 0);

    // shown again, or brought back with the focus however it was
    seeLifecycle(AppLifecycleState.resumed);
    expect(appSeen.value, isTrue);
    await tester.pump(const Duration(seconds: 1));
    expect(ticks, greaterThan(10));
    unsubscribe();
  });

  test('a window shown without the focus counts as seen; the engine reporting it hidden does not', () {
    seeWindow(hidden: true);
    seeLifecycle(AppLifecycleState.inactive);
    expect(appSeen.value, isFalse);
    seeWindow(hidden: false);
    expect(appSeen.value, isTrue);
    seeLifecycle(AppLifecycleState.hidden);
    expect(appSeen.value, isFalse);
  });
}
