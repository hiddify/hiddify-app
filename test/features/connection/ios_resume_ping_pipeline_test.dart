// Recovery regression: exercise readiness, manual retry and closed failure stages.
// Synthetic boundaries do not establish the physical device failure cause.
// Uses the real HiddifyCoreService queue/setup/init, repository, measurement and
// manual action. Only the external core and loopback RPC endpoints are synthetic.
// Lifecycle events plus explicit pause/resume model App dispatch; App is not mounted.
// Host Platform.isIOS remains false: setup failure's desktop notification is sunk.
// Connected is held true to model independent NEVPN status, not to test that bridge.
import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart' hide Response;
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/directories/directories_provider.dart';
import 'package:hiddify/core/http_client/dio_http_client.dart';
import 'package:hiddify/core/model/directories.dart';
import 'package:hiddify/core/model/environment.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/diagnostics/diagnostic_providers.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/proxy/active/ios_active_proxy_measurement.dart';
import 'package:hiddify/features/proxy/active/ios_active_proxy_measurement_providers.dart';
import 'package:hiddify/features/proxy/data/proxy_data_providers.dart';
import 'package:hiddify/features/proxy/data/proxy_repository.dart';
import 'package:hiddify/hiddifycore/core_interface/core_interface.dart';
import 'package:hiddify/hiddifycore/core_interface/core_interface_mobile.dart';
import 'package:hiddify/hiddifycore/generated/google/protobuf/timestamp.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcommon/common.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore_service.pbgrpc.dart';
import 'package:hiddify/hiddifycore/hiddify_core_service.dart';
import 'package:hiddify/hiddifycore/hiddify_core_service_provider.dart';
import 'package:hiddify/hiddifycore/init_signal.dart';
import 'package:hiddify/singbox/model/core_status.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';

class _Directories extends AppDirectories {
  @override
  Future<Directories> build() async => (baseDir: Directory('.'), workingDir: Directory('.'), tempDir: Directory('.'));
}

class _Notifications extends InAppNotificationController {
  @override
  ToastificationItem? showErrorToast(String message) => null;
}

class _Endpoint extends CoreServiceBase {
  final groups = StreamController<OutboundGroupList>.broadcast();
  final closeEntered = Completer<void>();
  Completer<Empty>? closeGate;
  int requests = 0;
  int listeners = 0;

  @override
  Future<Empty> close(ServiceCall call, CloseRequest request) async {
    if (!closeEntered.isCompleted) closeEntered.complete();
    return closeGate == null ? Empty() : closeGate!.future;
  }

  @override
  Stream<OutboundGroupList> mainOutboundsInfo(ServiceCall call, Empty request) {
    listeners++;
    return groups.stream;
  }

  @override
  Future<Response> urlTest(ServiceCall call, UrlTestRequest request) async {
    requests++;
    return Response(code: ResponseCode.OK);
  }

  void publish() => groups.add(
    OutboundGroupList(
      items: [
        OutboundGroup(
          items: [
            OutboundInfo(
              tag: 'synthetic',
              type: 'test',
              urlTestDelay: 84,
              urlTestTime: Timestamp.fromDateTime(DateTime.now().toUtc()),
            ),
          ],
        ),
      ],
    ),
  );

  @override
  Stream<LogMessage> logListener(ServiceCall call, LogRequest request) => const Stream.empty();
  @override
  Stream<CoreInfoResponse> coreInfoListener(ServiceCall call, Empty request) => const Stream.empty();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ExternalCore extends CoreInterface {
  int setups = 0;
  String setupResult = '';
  Object? setupError;
  Completer<void>? setupGate;
  Completer<CoreStatus?>? statusGate;
  final statusEntered = Completer<void>();
  @override
  bool get supportsSystemStatus => true;
  @override
  Future<String> setup(Directories directories, bool debug, int mode) async {
    setups++;
    await setupGate?.future;
    if (setupError case final error?) throw error;
    return setupResult;
  }

  @override
  Future<CoreStatus?> getSystemStatus() async {
    if (!statusEntered.isCompleted) statusEntered.complete();
    return statusGate == null ? const CoreStatus.started() : statusGate!.future;
  }
}

class _Service extends HiddifyCoreService {
  _Service(super.ref, this.external);
  final _ExternalCore external;
  @override
  CoreInterface get core => external;
}

Future<void> _until(bool Function() ready) async {
  final end = DateTime.now().add(const Duration(seconds: 3));
  while (!ready()) {
    if (DateTime.now().isAfter(end)) throw TestFailure('Synthetic boundary not reached');
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  for (final scenario in [
    'close stalls',
    'setup rejects',
    'classified rejection',
    'second hello unavailable',
    'second hello denied',
    'status stalls',
    'success',
    'manual recovery',
    'manual concurrent',
    'manual interrupted',
    'manual disconnected',
  ]) {
    test('diagnostic real service resume pipeline: $scenario', () async {
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      SharedPreferences.setMockInitialValues({'haptic_feedback': false});
      final prefs = await SharedPreferences.getInstance();
      final endpoint = _Endpoint();
      final server = Server.create(services: [endpoint]);
      await server.serve(address: InternetAddress.loopbackIPv4, port: 0);
      final front = ClientChannel(
        '127.0.0.1',
        port: server.port!,
        options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
      );
      final back = ClientChannel(
        '127.0.0.1',
        port: server.port!,
        options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
      );
      final external = _ExternalCore()
        ..fgClient = CoreClient(front)
        ..bgClient = CoreClient(back);
      final connected = StateProvider<bool>((ref) => true);
      final container = ProviderContainer(
        overrides: [
          environmentProvider.overrideWithValue(Environment.prod),
          sharedPreferencesProvider.overrideWith((ref) => prefs),
          appDirectoriesProvider.overrideWith(_Directories.new),
          inAppNotificationControllerProvider.overrideWith((ref) => _Notifications()),
          hiddifyCoreServiceProvider.overrideWith((ref) => _Service(ref, external)),
          iosActiveProxyMeasurementEnabledProvider.overrideWithValue(true),
          serviceRunningProvider.overrideWith((ref) => ref.watch(connected)),
          proxyRepositoryProvider.overrideWith(
            (ref) => ProxyRepositoryImpl(
              singbox: ref.watch(hiddifyCoreServiceProvider),
              client: DioHttpClient(timeout: const Duration(seconds: 1), userAgent: 'probe', debug: false),
            ),
          ),
        ],
      );
      final service = container.read(hiddifyCoreServiceProvider);
      Future<void>? pendingResume;
      addTearDown(() async {
        if (external.setupGate?.isCompleted == false) external.setupGate!.complete();
        if (endpoint.closeGate?.isCompleted == false) endpoint.closeGate!.complete(Empty());
        if (external.statusGate?.isCompleted == false) external.statusGate!.complete(const CoreStatus.started());
        if (pendingResume != null) await pendingResume.timeout(const Duration(seconds: 3));
        container.dispose();
        await service.stopListenSingle('');
        await front.terminate();
        await back.terminate();
        await server.shutdown();
        await endpoint.groups.close();
        await service.statusController.close();
        await service.logController.close();
        binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      });
      await container.read(sharedPreferencesProvider.future);
      await container.read(appDirectoriesProvider.future);
      await container.read(serviceRunningProvider.future);
      final restart = container.listen(coreRestartSignalProvider, (_, _) {});
      final active = container.listen(activeProxyNotifierProvider, (_, _) {});
      addTearDown(restart.close);
      addTearDown(active.close);
      await _until(() => endpoint.requests == 1 && endpoint.listeners == 1);
      endpoint.publish();
      await _until(
        () => container.read(iosActiveProxyMeasurementProvider).state.phase == IosProxyMeasurementPhase.available,
      );
      final original = container.read(iosActiveProxyMeasurementProvider);
      expect(original.state.proxy!.urlTestDelay, 84, reason: 'Numeric ping exists BEFORE lock');
      final generation = container.read(coreRestartSignalProvider);
      if (scenario == 'close stalls') endpoint.closeGate = Completer<Empty>();
      if (scenario == 'setup rejects' || scenario.startsWith('manual ')) {
        external.setupResult = 'synthetic setup failure';
      }
      if (scenario == 'classified rejection') {
        external.setupError = const IosCoreSetupException(
          IosCoreSetupCode.vpnPreferencesFailed,
          stage: IosCoreSetupStage.nativeSetup,
        );
      }
      if (scenario.startsWith('second hello ')) {
        external.setupError = IosCoreSetupException(
          IosCoreSetupCode.helloFailed,
          stage: IosCoreSetupStage.secondHello,
          grpcStatusCode: scenario.endsWith('unavailable') ? StatusCode.unavailable : StatusCode.permissionDenied,
          foregroundListenerReachable: scenario.endsWith('denied'),
        );
      }
      if (scenario == 'status stalls') external.statusGate = Completer<CoreStatus?>();
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      final inactivePause = service.pause();
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      final pausedPause = service.pause();
      if (scenario == 'close stalls') {
        await endpoint.closeEntered.future.timeout(const Duration(seconds: 3));
      } else {
        await Future.wait([inactivePause, pausedPause]);
      }
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      var completed = false;
      pendingResume = service.resume().then((_) => completed = true);
      if (scenario == 'status stalls') {
        await external.statusEntered.future.timeout(const Duration(seconds: 3));
      } else if (scenario != 'close stalls') {
        await pendingResume;
      }
      // Drain runnable work, not a claim that a wall-clock deadline has elapsed.
      await Future<void>.delayed(Duration.zero);
      final events = (container.read(iosPingTraceProvider).snapshot.toJson()['events']! as List)
          .cast<Map<String, Object?>>();
      final names = events.map((event) => event['event']).toList();
      if (scenario == 'close stalls') {
        expect(
          names,
          containsAllInOrder(['corePauseQueued', 'corePauseStarted', 'corePauseCloseNormal', 'coreResumeQueued']),
          reason: 'Trace identifies the external close boundary holding the queue',
        );
        expect(names, isNot(contains('coreResumeStarted')));
      } else if (scenario == 'setup rejects' ||
          scenario == 'classified rejection' ||
          scenario.startsWith('second hello ')) {
        expect(
          names,
          containsAllInOrder(['coreResumeStarted', 'coreSetupFailed', 'coreResumeFailed']),
          reason: 'Trace reports a failed recovery rather than successful completion',
        );
        expect(names, isNot(contains('coreRestarted')));
        if (scenario == 'classified rejection') {
          expect(names, containsAllInOrder(['coreSetupNativeFailed', 'coreSetupPreferencesFailed', 'coreSetupFailed']));
        }
        if (scenario.startsWith('second hello ')) {
          expect(
            names,
            containsAllInOrder([
              'coreSetupSecondHelloFailed',
              'coreSetupHelloFailed',
              scenario.endsWith('unavailable') ? 'coreSetupGrpcUnavailable' : 'coreSetupGrpcPermissionDenied',
              scenario.endsWith('denied') ? 'coreSetupLoopbackReachable' : 'coreSetupLoopbackUnreachable',
              'coreSetupFailed',
            ]),
          );
        }
      } else if (scenario == 'status stalls') {
        expect(
          names,
          containsAllInOrder(['coreResumeStarted', 'coreSetupStatusRequested']),
          reason: 'Trace identifies the status request after successful core setup',
        );
        expect(names, isNot(contains('coreSetupStatusReady')));
        expect(names, isNot(contains('coreResumeCompleted')));
      } else if (scenario.startsWith('manual ')) {
        expect(names, contains('coreSetupFailed'));
        expect(names, isNot(contains('coreRestarted')));
      } else {
        expect(
          names,
          containsAllInOrder(['coreSetupCompleted', 'coreRestarted', 'coreResumeCompleted']),
          reason: 'Real setup publishes restart and completes the queued resume',
        );
      }
      final queuedResume = events.singleWhere((event) => event['event'] == 'coreResumeQueued');
      final resumeId = queuedResume['operation_id'];
      expect(resumeId, isA<int>());
      expect(resumeId, greaterThan(0));
      final pauseIds = events
          .where((event) => event['event'] == 'corePauseQueued')
          .map((event) => event['operation_id'])
          .toSet();
      expect(pauseIds, hasLength(2), reason: 'Inactive and paused enqueue distinct operations');
      expect(pauseIds, isNot(contains(resumeId)));
      for (final event in events.where(
        (event) => event['event'] == 'coreResumeStarted' || event['event'] == 'coreResumeCompleted',
      )) {
        expect(event['operation_id'], resumeId, reason: 'Queue lifecycle stages correlate to one operation');
      }

      if (scenario == 'manual concurrent' || scenario == 'manual interrupted' || scenario == 'manual disconnected') {
        external.setupResult = '';
        external.setupGate = Completer<void>();
        final first = container.read(activeProxyNotifierProvider.notifier).urlTest('');
        final outcome = first.then<Object?>((_) => null, onError: (Object error, StackTrace _) => error);
        final second = scenario == 'manual concurrent'
            ? container.read(activeProxyNotifierProvider.notifier).urlTest('')
            : Future<void>.value();
        await _until(() => external.setups == 2);
        Future<void>? paused;
        if (scenario == 'manual interrupted') {
          binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
          paused = service.pause();
        } else if (scenario == 'manual disconnected') {
          container.read(connected.notifier).state = false;
          await Future<void>.delayed(Duration.zero);
        }
        external.setupGate!.complete();
        final error = await outcome;
        await second;
        if (paused != null) await paused;
        if (scenario == 'manual concurrent') {
          expect(error, isNull);
          expect(external.setups, 2, reason: 'Concurrent taps share one recovery');
          await _until(() => endpoint.requests == 2 && endpoint.listeners == 2);
          endpoint.publish();
          await _until(
            () => container.read(iosActiveProxyMeasurementProvider).state.phase == IosProxyMeasurementPhase.available,
          );
          expect(endpoint.requests, 2, reason: 'Concurrent recovery starts exactly one measurement');
        } else {
          expect(error, scenario == 'manual interrupted' ? isA<HiddifyCoreInitializationException>() : isNull);
          await Future<void>.delayed(Duration.zero);
          expect(endpoint.requests, 1, reason: 'Interrupted/disconnected recovery cannot start a measurement');
        }
      } else if (scenario == 'manual recovery') {
        external.setupResult = '';
        await container.read(activeProxyNotifierProvider.notifier).urlTest('');
        expect(external.setups, 2, reason: 'Tap must retry failed foreground setup');
        final recoveredEvents = container.read(iosPingTraceProvider).snapshot.events.map((entry) => entry.event.name);
        expect(recoveredEvents, contains('refreshRecoveryCompleted'));
        expect(
          recoveredEvents,
          isNot(contains('refreshCompleted')),
          reason: 'Recovered readiness is distinct from a completed ping',
        );
        await _until(() => endpoint.requests == 2 && endpoint.listeners == 2);
        expect(container.read(coreRestartSignalProvider), generation + 1);
        expect(identical(original, container.read(iosActiveProxyMeasurementProvider)), false);
        endpoint.publish();
        await _until(
          () => container.read(iosActiveProxyMeasurementProvider).state.phase == IosProxyMeasurementPhase.available,
        );
        expect(container.read(iosActiveProxyMeasurementProvider).state.proxy!.urlTestDelay, 84);
        expect(endpoint.requests, 2, reason: 'Recovery produces exactly one measurement');
      } else if (scenario == 'success') {
        await _until(() => endpoint.requests == 2 && endpoint.listeners == 2);
        expect(container.read(coreRestartSignalProvider), generation + 1);
        expect(identical(original, container.read(iosActiveProxyMeasurementProvider)), false);
        endpoint.publish();
        await _until(
          () => container.read(iosActiveProxyMeasurementProvider).state.phase == IosProxyMeasurementPhase.available,
        );
        expect(container.read(iosActiveProxyMeasurementProvider).state.proxy!.urlTestDelay, 84);
      } else {
        expect(container.read(coreRestartSignalProvider), generation);
        expect(original.canRefresh, false);
        expect(original.state.phase, IosProxyMeasurementPhase.idle);
        final requests = endpoint.requests;
        if (scenario == 'setup rejects' || scenario == 'classified rejection' || scenario.startsWith('second hello ')) {
          await expectLater(
            container.read(activeProxyNotifierProvider.notifier).urlTest(''),
            throwsA(isA<HiddifyCoreInitializationException>()),
          );
          expect(external.setups, 2, reason: 'Manual retry attempts setup once more');
        } else {
          expect(external.setups, scenario == 'close stalls' ? 0 : 1);
        }
        expect(endpoint.requests, requests, reason: 'No measurement request before foreground readiness');
        expect(
          completed,
          scenario == 'setup rejects' || scenario == 'classified rejection' || scenario.startsWith('second hello '),
        );
      }
    });
  }
}
