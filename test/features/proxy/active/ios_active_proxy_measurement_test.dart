import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hiddify/features/proxy/active/ios_active_proxy_measurement.dart';
import 'package:hiddify/features/proxy/model/proxy_failure.dart';
import 'package:hiddify/hiddifycore/generated/google/protobuf/timestamp.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';

void main() {
  test('starts idle and states replays the current snapshot', () async {
    final probe = _Probe();
    addTearDown(probe.dispose);

    expect(probe.measurement.state.phase, IosProxyMeasurementPhase.idle);
    expect(probe.measurement.state.proxy, isNull);
    final replay = await probe.measurement.states.first;
    expect(replay.phase, IosProxyMeasurementPhase.idle);
    expect(replay.proxy, isNull);
  });

  for (final invalid in <({String name, List<OutboundGroup> groups})>[
    (name: 'empty groups', groups: <OutboundGroup>[]),
    (name: 'empty items', groups: [OutboundGroup()]),
    (
      name: 'default tag',
      groups: [
        OutboundGroup(items: [OutboundInfo(type: 'vless', urlTestDelay: 120)]),
      ],
    ),
  ]) {
    test('${invalid.name} does not fabricate an active proxy', () async {
      final probe = _Probe();
      addTearDown(probe.dispose);
      probe.requestAction = () async {};

      final refresh = probe.measurement.refresh();
      await probe.requestStarted.future;
      probe.events.add(right(invalid.groups));

      final error = await _expectFailure(refresh, IosProxyMeasurementCode.timedOut);
      expect(error.code, IosProxyMeasurementCode.timedOut);
      expect(probe.measurement.state.phase, IosProxyMeasurementPhase.timedOut);
      expect(probe.measurement.state.proxy, isNull);
    });
  }

  test('Either.left is exposed as a sanitized unavailable failure', () async {
    final probe = _Probe();
    addTearDown(probe.dispose);
    probe.requestAction = () async {};

    final refresh = probe.measurement.refresh();
    await probe.requestStarted.future;
    probe.events.add(left(const ProxyUnexpectedFailure()));

    final error = await _expectFailure(refresh, IosProxyMeasurementCode.streamFailed);
    expect(error.code, IosProxyMeasurementCode.streamFailed);
    expect(probe.measurement.state.phase, IosProxyMeasurementPhase.unavailable);
    expect(probe.measurement.state.proxy, isNull);
  });

  test('stream errors are typed and do not expose source details', () async {
    final probe = _Probe();
    addTearDown(probe.dispose);
    probe.requestAction = () async {};

    final refresh = probe.measurement.refresh();
    await probe.requestStarted.future;
    probe.events.addError(StateError('private stream detail'));

    final error = await _expectFailure(refresh, IosProxyMeasurementCode.streamFailed);
    expect(error.code, IosProxyMeasurementCode.streamFailed);
    expect(error.toString(), isNot(contains('private stream detail')));
    expect(probe.measurement.state.phase, IosProxyMeasurementPhase.failed);
    expect(probe.measurement.state.proxy, isNull);
  });

  test('request errors are typed and do not expose source details', () async {
    final probe = _Probe();
    addTearDown(probe.dispose);
    probe.requestAction = () async => throw StateError('private request detail');

    final error = await _expectFailure(probe.measurement.refresh(), IosProxyMeasurementCode.requestFailed);
    expect(error.code, IosProxyMeasurementCode.requestFailed);
    expect(error.toString(), isNot(contains('private request detail')));
    expect(probe.measurement.state.phase, IosProxyMeasurementPhase.failed);
    expect(probe.measurement.state.proxy, isNull);
  });

  test('event arriving before RPC completion is retained', () async {
    final probe = _Probe();
    addTearDown(probe.dispose);
    probe.requestAction = () async {
      probe.events.add(
        right([
          OutboundGroup(items: [probe.validProxy()]),
        ]),
      );
      await probe.requestGate.future;
    };

    final refresh = probe.measurement.refresh();
    await probe.requestStarted.future;
    expect(probe.measurement.state.phase, IosProxyMeasurementPhase.checking);
    probe.requestGate.complete();

    await refresh;
    expect(probe.measurement.state.phase, IosProxyMeasurementPhase.available);
    expect(probe.measurement.state.proxy?.urlTestDelay, 120);
  });

  test('RPC completion before a valid event still completes the attempt', () async {
    final probe = _Probe();
    addTearDown(probe.dispose);
    probe.requestAction = () => probe.requestGate.future;

    final refresh = probe.measurement.refresh();
    await probe.requestStarted.future;
    probe.requestGate.complete();
    await Future<void>.delayed(Duration.zero);
    expect(probe.measurement.state.phase, IosProxyMeasurementPhase.checking);
    probe.events.add(
      right([
        OutboundGroup(items: [probe.validProxy()]),
      ]),
    );

    await refresh;
    expect(probe.measurement.state.phase, IosProxyMeasurementPhase.available);
    final replay = await probe.measurement.states.first;
    expect(replay.phase, IosProxyMeasurementPhase.available);
    expect(replay.proxy?.tag, 'active');
  });

  test('successful RPC without a positive fresh result times out', () async {
    final probe = _Probe();
    addTearDown(probe.dispose);
    probe.requestAction = () async {};

    final refresh = probe.measurement.refresh();
    await probe.requestStarted.future;
    final error = await _expectFailure(refresh, IosProxyMeasurementCode.timedOut);

    expect(error.code, IosProxyMeasurementCode.timedOut);
    expect(probe.measurement.state.phase, IosProxyMeasurementPhase.timedOut);
    expect(probe.measurement.state.proxy, isNull);
  });

  for (final cached in <({String name, int delay, DateTime timestamp})>[
    (name: 'zero latency cache', delay: 0, timestamp: DateTime.utc(2026, 10, 18, 12, 0, 1)),
    (name: 'stale positive latency cache', delay: 120, timestamp: DateTime.utc(2026, 10, 18, 11, 59, 59)),
  ]) {
    test('${cached.name} is not accepted as a fresh result', () async {
      final probe = _Probe();
      addTearDown(probe.dispose);
      probe.requestAction = () async {};

      final refresh = probe.measurement.refresh();
      await probe.requestStarted.future;
      probe.events.add(
        right([
          OutboundGroup(
            items: [probe.validProxy(delay: cached.delay, timestamp: cached.timestamp)],
          ),
        ]),
      );

      await _expectFailure(refresh, IosProxyMeasurementCode.timedOut);
      expect(probe.measurement.state.phase, IosProxyMeasurementPhase.timedOut);
      expect(probe.measurement.state.proxy, isNull);
    });
  }

  test('positive fresh latency is accepted when IP information is empty', () async {
    final probe = _Probe();
    addTearDown(probe.dispose);
    probe.requestAction = () async {};

    final refresh = probe.measurement.refresh();
    await probe.requestStarted.future;
    final proxy = probe.validProxy();
    expect(proxy.ipinfo.ip, isEmpty);
    probe.events.add(
      right([
        OutboundGroup(items: [proxy]),
      ]),
    );

    await refresh;
    expect(probe.measurement.state.phase, IosProxyMeasurementPhase.available);
    expect(probe.measurement.state.proxy?.urlTestDelay, 120);
  });

  test('duplicate refresh calls share the same in-flight attempt', () async {
    final probe = _Probe();
    addTearDown(probe.dispose);
    probe.requestAction = () => probe.requestGate.future;

    final first = probe.measurement.refresh();
    await probe.requestStarted.future;
    final second = probe.measurement.refresh();
    expect(second, same(first));
    expect(probe.requestCalls, 1);
    expect(probe.watchCalls, 1);

    probe.requestGate.complete();
    probe.events.add(
      right([
        OutboundGroup(items: [probe.validProxy()]),
      ]),
    );
    await first;
    expect(probe.measurement.state.phase, IosProxyMeasurementPhase.available);
  });

  test('a retry opens a fresh stream after a timed-out attempt', () async {
    final probe = _Probe();
    addTearDown(probe.dispose);
    probe.requestAction = () async {};

    await _expectFailure(probe.measurement.refresh(), IosProxyMeasurementCode.timedOut);
    expect(probe.watchCalls, 1);

    final retry = probe.measurement.refresh();
    await probe.requestStarted.future;
    probe.events.add(
      right([
        OutboundGroup(items: [probe.validProxy()]),
      ]),
    );

    await retry;
    expect(probe.watchCalls, 2);
    expect(probe.requestCalls, 2);
    expect(probe.measurement.state.phase, IosProxyMeasurementPhase.available);
  });

  test('stop cancels the logical epoch and ignores late RPC and stream events', () async {
    final probe = _Probe();
    addTearDown(probe.dispose);
    probe.requestAction = () => probe.requestGate.future;

    final refresh = probe.measurement.refresh();
    await probe.requestStarted.future;
    probe.measurement.stop();

    final error = await _expectFailure(refresh, IosProxyMeasurementCode.cancelled);
    expect(error.code, IosProxyMeasurementCode.cancelled);
    expect(probe.measurement.state.phase, IosProxyMeasurementPhase.idle);
    expect(probe.measurement.state.proxy, isNull);

    probe.requestGate.complete();
    probe.events.add(
      right([
        OutboundGroup(items: [probe.validProxy()]),
      ]),
    );
    await Future<void>.delayed(Duration.zero);
    expect(probe.measurement.state.phase, IosProxyMeasurementPhase.idle);
    expect(probe.measurement.state.proxy, isNull);
  });

  test('dispose cancels a pending attempt and suppresses late completion', () async {
    final probe = _Probe();
    probe.requestAction = () => probe.requestGate.future;

    final refresh = probe.measurement.refresh();
    await probe.requestStarted.future;
    probe.measurement.dispose();

    final error = await _expectFailure(refresh, IosProxyMeasurementCode.cancelled);
    expect(error.code, IosProxyMeasurementCode.cancelled);
    probe.requestGate.complete();
    probe.events.add(
      right([
        OutboundGroup(items: [probe.validProxy()]),
      ]),
    );
    await Future<void>.delayed(Duration.zero);
    expect(probe.measurement.state.phase, IosProxyMeasurementPhase.idle);
    expect(probe.measurement.state.proxy, isNull);
    await probe.events.close();
  });

  test('refresh after dispose returns a typed cancelled failure immediately', () async {
    final probe = _Probe();
    addTearDown(probe.dispose);
    probe.measurement.dispose();

    final error = await _expectFailure(
      _refresh(probe.measurement).timeout(const Duration(milliseconds: 100)),
      IosProxyMeasurementCode.cancelled,
    );
    expect(error.code, IosProxyMeasurementCode.cancelled);
    expect(probe.requestCalls, 0);
    expect(probe.measurement.state.phase, IosProxyMeasurementPhase.idle);
    expect(probe.measurement.state.proxy, isNull);
  });

  test('stream error after available clears the proxy and enters failed', () async {
    final probe = _Probe();
    addTearDown(probe.dispose);
    probe.requestAction = () async {};

    final refresh = probe.measurement.refresh();
    await probe.requestStarted.future;
    probe.events.add(
      right([
        OutboundGroup(items: [probe.validProxy()]),
      ]),
    );
    await refresh;
    expect(probe.measurement.state.phase, IosProxyMeasurementPhase.available);
    expect(probe.measurement.state.proxy, isNotNull);

    probe.events.addError(StateError('post-available stream detail'));
    await Future<void>.delayed(Duration.zero);
    expect(probe.measurement.state.phase, IosProxyMeasurementPhase.failed);
    expect(probe.measurement.state.proxy, isNull);
  });

  test('Either.left after available clears the proxy and enters unavailable', () async {
    final probe = _Probe();
    addTearDown(probe.dispose);
    probe.requestAction = () async {};

    final refresh = probe.measurement.refresh();
    await probe.requestStarted.future;
    probe.events.add(
      right([
        OutboundGroup(items: [probe.validProxy()]),
      ]),
    );
    await refresh;
    expect(probe.measurement.state.phase, IosProxyMeasurementPhase.available);

    probe.events.add(left(const ProxyUnexpectedFailure()));
    await Future<void>.delayed(Duration.zero);
    expect(probe.measurement.state.phase, IosProxyMeasurementPhase.unavailable);
    expect(probe.measurement.state.proxy, isNull);
  });

  test('new outer tag after available clears stale proxy as unavailable', () async {
    final probe = _Probe();
    addTearDown(probe.dispose);
    probe.requestAction = () async {};

    final refresh = probe.measurement.refresh();
    await probe.requestStarted.future;
    probe.events.add(
      right([
        OutboundGroup(items: [probe.validProxy()]),
      ]),
    );
    await refresh;

    probe.events.add(
      right([
        OutboundGroup(items: [probe.validProxy(tag: 'other')]),
      ]),
    );
    await Future<void>.delayed(Duration.zero);
    expect(probe.measurement.state.phase, IosProxyMeasurementPhase.unavailable);
    expect(probe.measurement.state.proxy, isNull);
  });

  test('new groupSelectedTag with the same outer tag clears stale proxy', () async {
    final probe = _Probe();
    addTearDown(probe.dispose);
    probe.requestAction = () async {};

    final refresh = probe.measurement.refresh();
    await probe.requestStarted.future;
    probe.events.add(
      right([
        OutboundGroup(items: [probe.validProxy(groupSelectedTag: 'group-a')]),
      ]),
    );
    await refresh;

    probe.events.add(
      right([
        OutboundGroup(items: [probe.validProxy(groupSelectedTag: 'group-b')]),
      ]),
    );
    await Future<void>.delayed(Duration.zero);
    expect(probe.measurement.state.phase, IosProxyMeasurementPhase.unavailable);
    expect(probe.measurement.state.proxy, isNull);
  });

  test('older same-tag result after available cannot replace current delay', () async {
    final probe = _Probe();
    addTearDown(probe.dispose);
    probe.requestAction = () async {};

    final refresh = probe.measurement.refresh();
    await probe.requestStarted.future;
    probe.events.add(
      right([
        OutboundGroup(items: [probe.validProxy()]),
      ]),
    );
    await refresh;
    expect(probe.measurement.state.proxy?.urlTestDelay, 120);

    probe.events.add(
      right([
        OutboundGroup(
          items: [probe.validProxy(delay: 240, timestamp: probe.clock.add(const Duration(milliseconds: 500)))],
        ),
      ]),
    );
    await Future<void>.delayed(Duration.zero);
    expect(probe.measurement.state.phase, IosProxyMeasurementPhase.available);
    expect(probe.measurement.state.proxy?.urlTestDelay, 120);
  });

  test('same identity and timestamp can enrich an available proxy with IP info', () async {
    final probe = _Probe();
    addTearDown(probe.dispose);
    probe.requestAction = () async {};
    final timestamp = probe.clock.add(const Duration(seconds: 1));

    final refresh = probe.measurement.refresh();
    await probe.requestStarted.future;
    probe.events.add(
      right([
        OutboundGroup(items: [probe.validProxy(delay: 84, timestamp: timestamp)]),
      ]),
    );
    await refresh;
    expect(probe.measurement.state.phase, IosProxyMeasurementPhase.available);
    expect(probe.measurement.state.proxy?.urlTestDelay, 84);
    expect(probe.measurement.state.proxy?.ipinfo.ip, isEmpty);

    probe.events.add(
      right([
        OutboundGroup(
          items: [probe.validProxy(delay: 84, timestamp: timestamp, ip: '192.0.2.1')],
        ),
      ]),
    );
    await Future<void>.delayed(Duration.zero);
    expect(probe.measurement.state.phase, IosProxyMeasurementPhase.available);
    expect(probe.measurement.state.proxy?.urlTestDelay, 84);
    expect(probe.measurement.state.proxy?.ipinfo.ip, '192.0.2.1');
  });

  for (final invalid in <({String name, List<OutboundGroup> groups})>[
    (name: 'empty groups', groups: <OutboundGroup>[]),
    (name: 'empty items', groups: [OutboundGroup()]),
    (
      name: 'default tag',
      groups: [
        OutboundGroup(items: [OutboundInfo(type: 'vless', urlTestDelay: 84)]),
      ],
    ),
  ]) {
    test('fresh ${invalid.name} after available clears stale proxy', () async {
      final probe = _Probe();
      addTearDown(probe.dispose);
      probe.requestAction = () async {};

      final refresh = probe.measurement.refresh();
      await probe.requestStarted.future;
      probe.events.add(
        right([
          OutboundGroup(items: [probe.validProxy(delay: 84)]),
        ]),
      );
      await refresh;
      expect(probe.measurement.state.phase, IosProxyMeasurementPhase.available);
      expect(probe.measurement.state.proxy, isNotNull);

      probe.events.add(right(invalid.groups));
      await Future<void>.delayed(Duration.zero);
      expect(probe.measurement.state.phase, IosProxyMeasurementPhase.unavailable);
      expect(probe.measurement.state.proxy, isNull);
    });
  }

  for (final identity in <({String name, OutboundInfo first, OutboundInfo second})>[
    (
      name: 'outer tag',
      first: OutboundInfo(
        tag: 'active',
        tagDisplay: 'A',
        type: 'vless',
        urlTestDelay: 120,
        urlTestTime: Timestamp.fromDateTime(DateTime.utc(2026, 10, 18, 12, 0, 1)),
      ),
      second: OutboundInfo(
        tag: 'other',
        tagDisplay: 'B',
        type: 'vless',
        urlTestDelay: 120,
        urlTestTime: Timestamp.fromDateTime(DateTime.utc(2026, 10, 18, 12, 0, 2)),
      ),
    ),
    (
      name: 'groupSelectedTag',
      first: OutboundInfo(
        tag: 'active',
        tagDisplay: 'A',
        groupSelectedTag: 'group-a',
        type: 'vless',
        urlTestDelay: 120,
        urlTestTime: Timestamp.fromDateTime(DateTime.utc(2026, 10, 18, 12, 0, 1)),
      ),
      second: OutboundInfo(
        tag: 'active',
        tagDisplay: 'B',
        groupSelectedTag: 'group-b',
        type: 'vless',
        urlTestDelay: 120,
        urlTestTime: Timestamp.fromDateTime(DateTime.utc(2026, 10, 18, 12, 0, 2)),
      ),
    ),
  ]) {
    test('identity change from ${identity.name} before RPC completion clears mixed result', () async {
      final probe = _Probe();
      addTearDown(probe.dispose);
      probe.requestAction = () async {
        probe.events.add(
          right([
            OutboundGroup(items: [identity.first]),
          ]),
        );
        await probe.requestGate.future;
      };

      final refresh = probe.measurement.refresh();
      await probe.requestStarted.future;
      probe.events.add(
        right([
          OutboundGroup(items: [identity.second]),
        ]),
      );
      probe.requestGate.complete();

      await refresh;
      expect(probe.measurement.state.phase, IosProxyMeasurementPhase.unavailable);
      expect(probe.measurement.state.proxy, isNull);
    });
  }

  test('synchronous watch factory failure returns typed stream failure without orphan request', () async {
    final probe = _Probe(watchFactory: () => throw StateError('private watch detail'));
    addTearDown(probe.dispose);

    final error = await _expectFailure(_refresh(probe.measurement), IosProxyMeasurementCode.streamFailed);
    expect(error.code, IosProxyMeasurementCode.streamFailed);
    expect(error.toString(), isNot(contains('private watch detail')));
    expect(probe.requestCalls, 0);
    expect(probe.measurement.state.phase, IosProxyMeasurementPhase.failed);
    expect(probe.measurement.state.proxy, isNull);
  });
}

Future<IosProxyMeasurementException> _expectFailure(Future<void> future, IosProxyMeasurementCode expectedCode) async {
  Object? caught;
  try {
    await future;
  } catch (error) {
    caught = error;
  }
  expect(caught, isA<IosProxyMeasurementException>());
  final typed = caught! as IosProxyMeasurementException;
  expect(typed.code, expectedCode);
  return typed;
}

Future<void> _refresh(IosActiveProxyMeasurement measurement) async {
  await measurement.refresh();
}

class _Probe {
  _Probe({Duration deadline = const Duration(milliseconds: 40), this.watchFactory}) {
    measurement = IosActiveProxyMeasurement(
      watch: () {
        watchCalls++;
        return watchFactory?.call() ?? events.stream;
      },
      request: () async {
        requestCalls++;
        if (!requestStarted.isCompleted) requestStarted.complete();
        final action = requestAction;
        if (action == null) {
          await requestGate.future;
        } else {
          await action();
        }
      },
      deadline: deadline,
      now: () => clock,
    );
  }

  final events = StreamController<Either<ProxyFailure, List<OutboundGroup>>>.broadcast(sync: true);
  final requestStarted = Completer<void>();
  final requestGate = Completer<void>();
  final clock = DateTime.utc(2026, 10, 18, 12);
  final Stream<Either<ProxyFailure, List<OutboundGroup>>> Function()? watchFactory;
  late final IosActiveProxyMeasurement measurement;
  Future<void> Function()? requestAction;
  int requestCalls = 0;
  int watchCalls = 0;

  OutboundInfo validProxy({
    int delay = 120,
    DateTime? timestamp,
    String tag = 'active',
    String groupSelectedTag = '',
    String? ip,
  }) => OutboundInfo(
    tag: tag,
    tagDisplay: 'Synthetic active proxy',
    type: 'vless',
    groupSelectedTag: groupSelectedTag,
    ipinfo: ip == null ? null : IpInfo(ip: ip),
    urlTestDelay: delay,
    urlTestTime: Timestamp.fromDateTime(timestamp ?? clock.add(const Duration(seconds: 1))),
  );

  Future<void> dispose() async {
    measurement.dispose();
    if (!events.isClosed) await events.close();
  }
}
