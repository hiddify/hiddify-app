import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/connection/model/connection_failure.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/desktop_connection_restore.dart';
import 'package:hiddify/singbox/model/core_status.dart';

void main() {
  test("does not wait for core status when restore was not requested", () async {
    var waitedForCoreStatus = false;

    await restoreDesktopConnectionWhenReady(
      isRestoreRequested: () => false,
      waitForFirstReportedCoreStatus: () {
        waitedForCoreStatus = true;
        return Future.value(const CoreStatus.stopped());
      },
      waitForConnectionStatus: () => Future.value(const ConnectionStatus.disconnected()),
      connect: () => Future.value(),
    );

    expect(waitedForCoreStatus, isFalse);
  });

  test("waits for real core and connection states and for connect completion", () async {
    final coreStatus = Completer<CoreStatus>();
    final connectionStatus = Completer<ConnectionStatus>();
    final connection = Completer<void>();
    var waitedForConnectionStatus = false;
    var connectCalls = 0;
    var completed = false;

    final restore = restoreDesktopConnectionWhenReady(
      isRestoreRequested: () => true,
      waitForFirstReportedCoreStatus: () => coreStatus.future,
      waitForConnectionStatus: () {
        waitedForConnectionStatus = true;
        return connectionStatus.future;
      },
      connect: () {
        connectCalls++;
        return connection.future;
      },
    ).whenComplete(() => completed = true);

    await Future<void>.delayed(Duration.zero);
    expect(waitedForConnectionStatus, isFalse);
    expect(connectCalls, 0);

    coreStatus.complete(const CoreStatus.stopped());
    await Future<void>.delayed(Duration.zero);
    expect(waitedForConnectionStatus, isTrue);
    expect(connectCalls, 0);

    connectionStatus.complete(const ConnectionStatus.disconnected());
    await Future<void>.delayed(Duration.zero);
    expect(connectCalls, 1);
    expect(completed, isFalse);

    connection.complete();
    await restore;
    expect(completed, isTrue);
  });

  for (final coreStatus in <CoreStatus>[
    const CoreStatus.starting(),
    const CoreStatus.started(),
    const CoreStatus.stopping(),
    const CoreStatus.stopped(alert: CoreAlert.startFailed),
  ]) {
    test("does not restore from ${coreStatus.runtimeType}", () async {
      var waitedForConnectionStatus = false;
      var connectCalls = 0;

      await restoreDesktopConnectionWhenReady(
        isRestoreRequested: () => true,
        waitForFirstReportedCoreStatus: () => Future.value(coreStatus),
        waitForConnectionStatus: () {
          waitedForConnectionStatus = true;
          return Future.value(const ConnectionStatus.disconnected());
        },
        connect: () async {
          connectCalls++;
        },
      );

      expect(waitedForConnectionStatus, isFalse);
      expect(connectCalls, 0);
    });
  }

  test("rechecks restore preference after waiting for connection state", () async {
    var restoreRequested = true;
    var connectCalls = 0;
    final connectionStatus = Completer<ConnectionStatus>();

    final restore = restoreDesktopConnectionWhenReady(
      isRestoreRequested: () => restoreRequested,
      waitForFirstReportedCoreStatus: () => Future.value(const CoreStatus.stopped()),
      waitForConnectionStatus: () => connectionStatus.future,
      connect: () async {
        connectCalls++;
      },
    );
    await Future<void>.delayed(Duration.zero);

    restoreRequested = false;
    connectionStatus.complete(const ConnectionStatus.disconnected());
    await restore;

    expect(connectCalls, 0);
  });

  test("does not restore a disconnected state with a failure", () async {
    var connectCalls = 0;

    await restoreDesktopConnectionWhenReady(
      isRestoreRequested: () => true,
      waitForFirstReportedCoreStatus: () => Future.value(const CoreStatus.stopped()),
      waitForConnectionStatus: () =>
          Future.value(const ConnectionStatus.disconnected(ConnectionFailure.unexpected("startup failed"))),
      connect: () async {
        connectCalls++;
      },
    );

    expect(connectCalls, 0);
  });

  test("propagates a failure reported before the first core status", () async {
    final error = StateError("core setup failed");

    await expectLater(
      restoreDesktopConnectionWhenReady(
        isRestoreRequested: () => true,
        waitForFirstReportedCoreStatus: () => Future.error(error),
        waitForConnectionStatus: () => Future.value(const ConnectionStatus.disconnected()),
        connect: () => Future.value(),
      ),
      throwsA(same(error)),
    );
  });
}
