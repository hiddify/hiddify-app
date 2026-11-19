import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';

void main() {
  test('ignores a concurrent call until the current task finishes', () async {
    final gate = SingleCall();
    final pending = Completer<String>();
    final first = gate.run(() => pending.future, onIgnored: 'ignored');
    var calls = 0;

    expect(gate.isRunning, isTrue);
    expect(
      await gate.run(() async {
        calls++;
        return 'unexpected';
      }, onIgnored: 'ignored'),
      'ignored',
    );
    expect(calls, 0);

    pending.complete('first');
    expect(await first, 'first');
    expect(gate.isRunning, isFalse);
    expect(await gate.run(() async => 'next', onIgnored: 'ignored'), 'next');
  });

  for (final oldTaskFails in [false, true]) {
    test('late ${oldTaskFails ? 'error' : 'success'} after reset keeps the new task locked', () async {
      final gate = SingleCall();
      final oldTask = Completer<String>();
      final currentTask = Completer<String>();
      final oldResult = gate.run(() => oldTask.future, onIgnored: 'ignored');
      final oldError = StateError('old task failed');
      final oldExpectation = expectLater(oldResult, oldTaskFails ? throwsA(same(oldError)) : completion('old'));

      gate.reset();
      expect(gate.isRunning, isFalse);
      final currentResult = gate.run(() => currentTask.future, onIgnored: 'ignored');
      expect(gate.isRunning, isTrue);

      if (oldTaskFails) {
        oldTask.completeError(oldError);
      } else {
        oldTask.complete('old');
      }
      await oldExpectation;
      expect(gate.isRunning, isTrue);

      var calls = 0;
      expect(
        await gate.run(() async {
          calls++;
          return 'unexpected';
        }, onIgnored: 'ignored'),
        'ignored',
      );
      expect(calls, 0);

      currentTask.complete('current');
      expect(await currentResult, 'current');
      expect(gate.isRunning, isFalse);
      expect(await gate.run(() async => 'next', onIgnored: 'ignored'), 'next');
    });
  }

  test('a failure from the current task releases the gate and propagates', () async {
    final gate = SingleCall();
    final error = StateError('current task failed');

    await expectLater(gate.run<String>(() async => throw error, onIgnored: 'ignored'), throwsA(same(error)));

    expect(gate.isRunning, isFalse);
    expect(await gate.run(() async => 'next', onIgnored: 'ignored'), 'next');
  });

  test('reset without a replacement task leaves the gate unlocked', () async {
    final gate = SingleCall();
    final pending = Completer<String>();
    final result = gate.run(() => pending.future, onIgnored: 'ignored');

    gate.reset();
    expect(gate.isRunning, isFalse);
    expect(gate.isStale, isFalse);
    pending.complete('old');
    expect(await result, 'old');
    expect(gate.isRunning, isFalse);
  });
}
