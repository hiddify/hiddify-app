import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';

void main() {
  test('completion of a cancelled start cannot unlock a newer in-flight start', () async {
    final call = SingleCall();
    final first = Completer<bool>(), second = Completer<bool>();
    final old = call.run(() => first.future, onIgnored: false);
    call.reset();
    final current = call.run(() => second.future, onIgnored: false);
    first.complete(true); await old;
    expect(call.isRunning, true);
    var entered = false;
    expect(await call.run(() async { entered = true; return true; }, onIgnored: false), false);
    expect(entered, false);
    second.complete(true); await current;
    expect(call.isRunning, false);
  });
}
