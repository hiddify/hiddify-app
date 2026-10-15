import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hiddify/features/connection/data/connection_repository.dart';
import 'package:hiddify/features/connection/model/connection_failure.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/diagnostics/observed_connection_repository.dart';
import 'package:hiddify/features/diagnostics/safe_diagnostic_event.dart';
import 'package:hiddify/features/diagnostics/safe_diagnostic_journal.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/singbox/model/singbox_config_option.dart';

class _Poison {
  @override
  String toString() => throw StateError('private payload must not be read');
}

class _Repository implements ConnectionRepository {
  final calls = <String>[];
  final arguments = <(ProfileEntity, bool)>[];
  final controller = StreamController<ConnectionStatus>.broadcast();
  Either<ConnectionFailure, Unit> result = right(unit);
  Object? thrown;
  void Function()? duringCall;
  int watches = 0;
  final constructions = <String>[];

  @override
  SingboxConfigOption? get configOptionsSnapshot => null;

  TaskEither<ConnectionFailure, Unit> _call(String name, [ProfileEntity? profile, bool? memory]) {
    constructions.add(name);
    return TaskEither(() async {
      calls.add(name);
      if (profile != null) arguments.add((profile, memory!));
      duringCall?.call();
      if (thrown case final error?) throw error;
      return result;
    });
  }

  @override
  TaskEither<ConnectionFailure, Unit> setup() => _call('setup');
  @override
  TaskEither<ConnectionFailure, Unit> connect(ProfileEntity profile, bool memory) => _call('connect', profile, memory);
  @override
  TaskEither<ConnectionFailure, Unit> reconnect(ProfileEntity profile, bool memory) =>
      _call('reconnect', profile, memory);
  @override
  TaskEither<ConnectionFailure, Unit> disconnect() => _call('disconnect');
  @override
  Stream<ConnectionStatus> watchConnectionStatus() {
    watches++;
    return controller.stream;
  }
}

void main() {
  late _Repository delegate;
  late SafeDiagnosticJournal journal;
  late ObservedConnectionRepository repository;
  late int now;
  final profile = ProfileEntity.local(
    id: 'fixture-private-profile-id',
    active: true,
    name: 'https://fixture.invalid/private-token',
    lastUpdate: DateTime.utc(2026),
  );

  setUp(() {
    now = 100;
    delegate = _Repository();
    journal = SafeDiagnosticJournal();
    repository = ObservedConnectionRepository(delegate, journal, elapsedMilliseconds: () => now);
  });
  tearDown(() async {
    await delegate.controller.close();
    journal.dispose();
  });

  test('commands stay lazy, preserve arguments/results and record command acceptance without traffic claims', () async {
    delegate.duringCall = () => now += 35;
    final task = repository.connect(profile, true);
    expect(delegate.calls, isEmpty);
    expect(delegate.constructions, ['connect']);
    expect(journal.events, isEmpty);

    final result = await task.run();

    expect(result, same(delegate.result));
    expect(delegate.calls, ['connect']);
    expect(delegate.arguments, [(profile, true)]);
    expect(journal.events.map((e) => e.stage), [DiagnosticStage.requested, DiagnosticStage.accepted]);
    expect(journal.events.last.durationMs, 35);
    expect(journal.events.first.operationId, journal.events.last.operationId);
    expect(journal.exportJson(), contains('not_checked'));
    expect(journal.exportJson(), isNot(contains(profile.name)));
    expect(journal.exportJson(), isNot(contains(profile.id)));
  });

  test('setup, disconnect and reconnect call their original delegate once with separate operation ids', () async {
    await repository.setup().run();
    await repository.disconnect().run();
    await repository.reconnect(profile, false).run();

    expect(delegate.calls, ['setup', 'disconnect', 'reconnect']);
    expect(delegate.arguments, [(profile, false)]);
    expect(journal.events.where((e) => e.stage == DiagnosticStage.requested).map((e) => e.operation), [
      DiagnosticOperation.setup,
      DiagnosticOperation.disconnect,
      DiagnosticOperation.reconnect,
    ]);
    expect(journal.events.map((e) => e.operationId).toSet(), hasLength(3));
  });

  test('a returned failure stays identical and never reads its private payload', () async {
    delegate.result = left(ConnectionFailure.unexpected(_Poison(), StackTrace.fromString('private-stack')));

    expect(await repository.connect(profile, false).run(), same(delegate.result));
    expect(journal.events.last.stage, DiagnosticStage.failed);
    expect(journal.events.last.code, DiagnosticCode.unexpected);
    expect(journal.exportJson(), isNot(contains('private-stack')));
  });

  test('a thrown object is rethrown unchanged after a single closed failure event', () async {
    final error = _Poison();
    delegate.thrown = error;
    Object? caught;
    try {
      await repository.disconnect().run();
    } catch (value) {
      caught = value;
    }
    expect(identical(caught, error), isTrue);
    expect(journal.events.where((e) => e.stage == DiagnosticStage.failed), hasLength(1));
    expect(journal.events.last.code, DiagnosticCode.unexpected);
  });

  test(
    'status observation keeps a single subscription and preserves data/error ordering and object identity',
    () async {
      final statuses = <ConnectionStatus>[];
      final errors = <Object>[];
      final done = Completer<void>();
      repository.watchConnectionStatus().listen(statuses.add, onError: errors.add, onDone: done.complete);
      const first = Connecting();
      const second = Connected();
      final last = Disconnected(ConnectionFailure.unexpected(_Poison()));
      final error = _Poison();
      delegate.controller.add(first);
      delegate.controller.add(second);
      delegate.controller.addError(error);
      delegate.controller.add(last);
      await delegate.controller.close();
      await done.future;

      expect(delegate.watches, 1);
      expect(statuses, [same(first), same(second), same(last)]);
      expect(errors, [same(error)]);
      expect(journal.events.map((e) => e.code), [
        DiagnosticCode.starting,
        DiagnosticCode.started,
        DiagnosticCode.unexpected,
      ]);
      expect(journal.events.every((e) => e.operation == DiagnosticOperation.tunnel), isTrue);
      expect(journal.events.every((e) => e.operationId == 0), isTrue);
    },
  );

  test('diagnostic persistence and clock failures cannot change a successful VPN command', () async {
    journal.dispose();
    journal = SafeDiagnosticJournal(persist: (_) async => throw StateError('private-storage-detail'));
    repository = ObservedConnectionRepository(delegate, journal, elapsedMilliseconds: () => now);
    expect(await repository.disconnect().run(), same(delegate.result));
    await journal.flush();
    expect(journal.persistenceFailed, isTrue);
    expect(journal.exportJson(), isNot(contains('private-storage-detail')));

    repository = ObservedConnectionRepository(delegate, journal, elapsedMilliseconds: () => throw _Poison());
    expect(await repository.connect(profile, false).run(), same(delegate.result));
    expect(delegate.calls, ['disconnect', 'connect']);
  });

  test('a disposed journal cannot interfere with commands or stream delivery', () async {
    journal.dispose();
    expect(await repository.setup().run(), same(delegate.result));
    final next = repository.watchConnectionStatus().first;
    const status = Connected();
    delegate.controller.add(status);
    expect(await next, same(status));
  });
}
