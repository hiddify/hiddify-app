import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/features/diagnostics/diagnostic_providers.dart';
import 'package:hiddify/features/diagnostics/ios_ping_trace.dart';
import 'package:hiddify/hiddifycore/core_interface/core_interface.dart';
import 'package:hiddify/hiddifycore/hiddify_core_service.dart';
import 'package:hiddify/hiddifycore/init_signal.dart';
import 'package:hiddify/singbox/model/core_status.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:toastification/toastification.dart';

class _IosCore extends CoreInterface {
  int vpnStarts = 0;
  int vpnStops = 0;

  @override
  bool get supportsSystemStatus => true;

  @override
  Future<CoreStatus> setupBackground(String path, String name) async {
    vpnStarts++;
    return const CoreStatus.started();
  }

  @override
  Future<bool> stop() async {
    vpnStops++;
    return true;
  }
}

class _ControlledService extends HiddifyCoreService {
  _ControlledService(super.ref, this.external);

  final _IosCore external;
  final attempts = <Completer<Either<String, Unit>>>[];
  int closes = 0;

  @override
  CoreInterface get core => external;

  @override
  TaskEither<String, Unit> setup() => TaskEither(() {
    final attempt = Completer<Either<String, Unit>>();
    attempts.add(attempt);
    return attempt.future;
  });

  @override
  Future<void> closeFront() async {
    closes++;
  }
}

class _Notifications extends InAppNotificationController {
  @override
  ToastificationItem? showErrorToast(String message) => null;
}

class _Fixture {
  _Fixture._(this.container, this.core, this.service, this.restartSubscription);

  factory _Fixture.create() {
    final core = _IosCore();
    final container = ProviderContainer(
      overrides: [inAppNotificationControllerProvider.overrideWith((ref) => _Notifications())],
    );
    final service = container.read(Provider((ref) => _ControlledService(ref, core)));
    final restartSubscription = container.listen(coreRestartSignalProvider, (_, _) {}, fireImmediately: true);
    container.read(iosPingTraceProvider);
    return _Fixture._(container, core, service, restartSubscription);
  }

  final ProviderContainer container;
  final _IosCore core;
  final _ControlledService service;
  final ProviderSubscription<int> restartSubscription;

  int get restartGeneration => container.read(coreRestartSignalProvider);

  List<IosPingEvent> get events =>
      container.read(iosPingTraceProvider).snapshot.events.map((entry) => entry.event).toList(growable: false);

  Future<void> waitForAttempts(int count) => _until(() => service.attempts.length == count);

  void completeAttempt(int index, Either<String, Unit> result) {
    service.attempts[index].complete(result);
  }

  Future<void> dispose() async {
    for (final attempt in service.attempts) {
      if (!attempt.isCompleted) attempt.complete(left('test cleanup'));
    }
    restartSubscription.close();
    container.dispose();
    await service.statusController.close();
    await service.logController.close();
  }
}

Future<void> _until(bool Function() ready) async {
  final deadline = DateTime.now().add(const Duration(seconds: 3));
  while (!ready()) {
    if (DateTime.now().isAfter(deadline)) throw TestFailure('Expected asynchronous boundary was not reached');
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('failed iOS resume reports failure without publishing a restart', () async {
    final fixture = _Fixture.create();
    addTearDown(fixture.dispose);

    final resume = fixture.service.resume();
    await fixture.waitForAttempts(1);
    fixture.completeAttempt(0, left('closed setup failure'));

    await expectLater(resume, completes);
    expect(fixture.restartGeneration, 0);
    expect(fixture.events, containsAllInOrder([IosPingEvent.coreResumeStarted, IosPingEvent.coreResumeFailed]));
    expect(fixture.events, isNot(contains(IosPingEvent.coreResumeCompleted)));
    expect(fixture.events, isNot(contains(IosPingEvent.coreRestarted)));
  });

  test('successful foreground readiness publishes one restart', () async {
    final fixture = _Fixture.create();
    addTearDown(fixture.dispose);

    final ready = fixture.service.ensureForegroundReady();
    await fixture.waitForAttempts(1);
    fixture.completeAttempt(0, right(unit));

    expect(await ready, isTrue);
    expect(fixture.restartGeneration, 1);
    expect(
      fixture.events,
      containsAllInOrder([
        IosPingEvent.coreResumeStarted,
        IosPingEvent.coreRestarted,
        IosPingEvent.coreResumeCompleted,
      ]),
    );
  });

  test('concurrent ensure and resume share one foreground setup', () async {
    final fixture = _Fixture.create();
    addTearDown(fixture.dispose);

    final ready = fixture.service.ensureForegroundReady();
    await fixture.waitForAttempts(1);
    final resume = fixture.service.resume();
    await Future<void>.delayed(Duration.zero);
    expect(fixture.service.attempts, hasLength(1));
    fixture.completeAttempt(0, right(unit));

    expect(await ready, isTrue);
    await resume;
    expect(fixture.service.attempts, hasLength(1));
    expect(fixture.restartGeneration, 1);
  });

  test('a later readiness attempt can succeed after setup returns Left', () async {
    final fixture = _Fixture.create();
    addTearDown(fixture.dispose);

    final first = fixture.service.ensureForegroundReady();
    await fixture.waitForAttempts(1);
    fixture.completeAttempt(0, left('closed setup failure'));
    expect(await first, isFalse);

    final second = fixture.service.ensureForegroundReady();
    await fixture.waitForAttempts(2);
    fixture.completeAttempt(1, right(unit));
    expect(await second, isTrue);

    expect(fixture.restartGeneration, 1);
    expect(fixture.events.where((event) => event == IosPingEvent.coreResumeFailed), hasLength(1));
    expect(fixture.events.where((event) => event == IosPingEvent.coreResumeCompleted), hasLength(1));
  });

  test('queued pause invalidates late readiness and a new resume waits for the pause', () async {
    final fixture = _Fixture.create();
    addTearDown(fixture.dispose);

    final stale = fixture.service.ensureForegroundReady();
    await fixture.waitForAttempts(1);
    final pause = fixture.service.pause();
    final resume = fixture.service.resume();

    fixture.completeAttempt(0, right(unit));
    expect(await stale, isFalse);
    await pause;
    await fixture.waitForAttempts(2);
    final joined = fixture.service.ensureForegroundReady();
    await Future<void>.delayed(Duration.zero);
    expect(fixture.service.closes, 1);
    expect(fixture.service.attempts, hasLength(2));
    expect(fixture.restartGeneration, 0);

    fixture.completeAttempt(1, right(unit));
    await resume;
    expect(await joined, isTrue);

    expect(fixture.restartGeneration, 1);
    expect(fixture.core.vpnStarts, 0);
    expect(fixture.core.vpnStops, 0);
    expect(
      fixture.events,
      containsAllInOrder([
        IosPingEvent.coreResumeFailed,
        IosPingEvent.corePauseStarted,
        IosPingEvent.corePauseCompleted,
        IosPingEvent.coreResumeStarted,
        IosPingEvent.coreRestarted,
        IosPingEvent.coreResumeCompleted,
      ]),
    );
  });
}
