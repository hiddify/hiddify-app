import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/app/startup/ios_startup_gate.dart';

void main() {
  const deadline = Duration(milliseconds: 20);

  for (final stage in IosStartupStage.values) {
    testWidgets('$stage hang exposes terminal report and retains ownership', (tester) async {
      final gate = IosStartupGate(deadline: deadline);
      final operation = Completer<int>();
      final result = gate.runStage(stage, () => operation.future);
      final settlement = expectLater(result, throwsA(isA<IosStartupAborted>()));
      await tester.pump(deadline);
      expect(gate.state, IosStartupState.timedOut);
      expect(gate.stage, stage);
      expect(gate.pending, isTrue);
      var called = false;
      await expectLater(
        gate.runStage(IosStartupStage.core, () async {
          called = true;
          return 1;
        }),
        throwsA(isA<IosStartupAborted>()),
      );
      expect(called, isFalse);
      operation.complete(42);
      await settlement;
      expect(gate.pending, isFalse);
      expect(gate.state, IosStartupState.timedOut);
      gate.complete();
      expect(gate.state, IosStartupState.timedOut);
      gate.dispose();
    });
  }

  testWidgets('success is sequential and ready requires explicit complete', (tester) async {
    final gate = IosStartupGate(deadline: deadline);
    final operation = Completer<int>();
    final result = gate.runStage(IosStartupStage.directories, () => operation.future);
    expect(gate.pending, isTrue);
    gate.complete();
    expect(gate.state, IosStartupState.loading);
    var called = false;
    await expectLater(
      gate.runStage(IosStartupStage.core, () async {
        called = true;
        return 0;
      }),
      throwsA(isA<IosStartupAborted>()),
    );
    expect(called, isFalse);
    operation.complete(42);
    expect(await result, 42);
    expect(gate.pending, isFalse);
    expect(await gate.runStage(IosStartupStage.core, () async => 7), 7);
    gate.complete();
    expect(gate.state, IosStartupState.ready);
    await tester.pump(deadline);
    expect(gate.state, IosStartupState.ready);
    gate.dispose();
  });

  for (final synchronous in [true, false]) {
    testWidgets('error is closed and terminal, synchronous=$synchronous', (tester) async {
      final gate = IosStartupGate(deadline: deadline);
      const secret = 'https://secret.invalid/path token=CANARY_SECRET 192.0.2.10 /private/file';
      await expectLater(
        gate.runStage(IosStartupStage.preferencesMigration, () {
          if (synchronous) throw StateError(secret);
          return Future<int>.error(StateError(secret));
        }),
        throwsA(isA<IosStartupAborted>()),
      );
      expect(gate.state, IosStartupState.failed);
      expect(gate.pending, isFalse);
      final report = jsonDecode(gate.report) as Map<String, dynamic>;
      expect(report.keys.toSet(), {'schema', 'stage', 'state', 'code', 'pending', 'elapsed_ms'});
      expect(report['stage'], 'preferencesMigration');
      expect(report['code'], 'unexpected');
      expect(report['elapsed_ms'], inInclusiveRange(0, 3600000));
      expect(gate.report, isNot(contains(secret)));
      expect(gate.report, isNot(contains('CANARY_SECRET')));
      var called = false;
      await expectLater(
        gate.runStage(IosStartupStage.core, () async {
          called = true;
          return 0;
        }),
        throwsA(isA<IosStartupAborted>()),
      );
      expect(called, isFalse);
      gate.dispose();
    });
  }

  testWidgets('late error is observed without changing timeout classification', (tester) async {
    final gate = IosStartupGate(deadline: deadline);
    final operation = Completer<void>();
    final result = gate.runStage(IosStartupStage.core, () => operation.future);
    final settlement = expectLater(result, throwsA(isA<IosStartupAborted>()));
    await tester.pump(deadline);
    operation.completeError(StateError('CANARY_SECRET'));
    await settlement;
    expect(gate.state, IosStartupState.timedOut);
    expect((jsonDecode(gate.report) as Map<String, dynamic>)['code'], 'deadlineExceeded');
    expect(gate.pending, isFalse);
    gate.dispose();
  });

  testWidgets('dispose does not cancel native work or notify on settlement', (tester) async {
    final gate = IosStartupGate(deadline: deadline);
    final operation = Completer<void>();
    final result = gate.runStage(IosStartupStage.core, () => operation.future);
    final settlement = expectLater(result, throwsA(isA<IosStartupAborted>()));
    var notifications = 0;
    gate.addListener(() => notifications++);
    gate.dispose();
    await tester.pump(deadline);
    expect(operation.isCompleted, isFalse);
    operation.completeError(StateError('CANARY_SECRET'));
    await settlement;
    expect(notifications, 0);
  });

  testWidgets('standalone shell renders recovery and copies exact closed report', (tester) async {
    final gate = IosStartupGate(deadline: deadline);
    String? copied;
    await tester.pumpWidget(
      IosStartupShell(
        gate: gate,
        locale: const Locale('ru'),
        copyReport: (value) async {
          copied = value;
        },
      ),
    );
    expect(find.text('Запускаем приложение…'), findsOneWidget);
    final operation = Completer<void>();
    final result = gate.runStage(IosStartupStage.preferences, () => operation.future);
    final settlement = expectLater(result, throwsA(isA<IosStartupAborted>()));
    await tester.pump(deadline);
    await tester.pump();
    expect(find.text('Не удалось запустить приложение'), findsOneWidget);
    expect(find.textContaining('полностью закройте'), findsOneWidget);
    expect(find.textContaining('preferences'), findsNothing);
    await tester.tap(find.byKey(const Key('ios-startup-copy')));
    await tester.pump();
    expect(copied, gate.report);
    operation.complete();
    await settlement;
    await tester.pumpWidget(const SizedBox.shrink());
    gate.dispose();
  });
}
