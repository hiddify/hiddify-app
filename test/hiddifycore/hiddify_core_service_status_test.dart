import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/directories/directories_provider.dart';
import 'package:hiddify/core/model/directories.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/hiddifycore/core_interface/core_interface.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/hiddifycore/hiddify_core_service.dart';
import 'package:hiddify/singbox/model/core_status.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  test("firstReportedCoreStatus uses the first real listener event only", () async {
    final fixture = _ServiceFixture();
    addTearDown(fixture.dispose);
    final statuses = StreamController<CoreInfoResponse>();
    fixture.controllers.add(statuses);

    await fixture.service.startListeningStatusStream("bg", () => statuses.stream);
    statuses.add(CoreInfoResponse(coreState: CoreStates.STARTING));

    expect(await fixture.service.firstReportedCoreStatus, const CoreStatus.starting());

    statuses.add(CoreInfoResponse(coreState: CoreStates.STARTED));
    await Future<void>.delayed(Duration.zero);
    expect(await fixture.service.firstReportedCoreStatus, const CoreStatus.starting());
    expect(fixture.service.currentState, const CoreStatus.started());
  });

  test("synthetic stopped event does not satisfy firstReportedCoreStatus", () async {
    final fixture = _ServiceFixture();
    addTearDown(fixture.dispose);
    final statuses = StreamController<CoreInfoResponse>();
    fixture.controllers.add(statuses);
    final syntheticStatus = fixture.service.statusController.first;

    await fixture.service.startListeningStatusStream("bg", () => statuses.stream);
    await statuses.close();

    expect(await syntheticStatus, isA<CoreStopped>().having((status) => status.alert, "alert", isNull));
    await expectLater(fixture.service.firstReportedCoreStatus, throwsA(isA<StateError>()));
  });

  test("listener error fails firstReportedCoreStatus", () async {
    final fixture = _ServiceFixture();
    addTearDown(fixture.dispose);
    final statuses = StreamController<CoreInfoResponse>();
    fixture.controllers.add(statuses);
    final error = StateError("listener failed");

    await fixture.service.startListeningStatusStream("bg", () => statuses.stream);
    statuses.addError(error, StackTrace.current);

    await expectLater(fixture.service.firstReportedCoreStatus, throwsA(same(error)));
  });

  test("synchronous listener setup error fails firstReportedCoreStatus", () async {
    final fixture = _ServiceFixture();
    addTearDown(fixture.dispose);
    final error = StateError("listener setup failed");

    await expectLater(fixture.service.startListeningStatusStream("bg", () => throw error), throwsA(same(error)));
    await expectLater(fixture.service.firstReportedCoreStatus, throwsA(same(error)));
  });

  test("core setup error fails firstReportedCoreStatus", () async {
    final fixture = _ServiceFixture(coreInterface: _FailingSetupCoreInterface());
    addTearDown(fixture.dispose);

    final result = await fixture.service.setup().run();

    expect(result.isLeft(), isTrue);
    await expectLater(fixture.service.firstReportedCoreStatus, throwsA(isA<StateError>()));
  });
}

class _ServiceFixture {
  _ServiceFixture({CoreInterface? coreInterface}) {
    final serviceProvider = Provider<HiddifyCoreService>(
      (ref) => HiddifyCoreService(ref, coreInterface: coreInterface ?? CoreInterface()),
    );
    container = ProviderContainer(
      overrides: [
        appDirectoriesProvider.overrideWith(_FakeAppDirectories.new),
        debugModeNotifierProvider.overrideWith(_FakeDebugModeNotifier.new),
      ],
    );
    service = container.read(serviceProvider);
  }

  late final ProviderContainer container;
  late final HiddifyCoreService service;
  final controllers = <StreamController<CoreInfoResponse>>[];

  Future<void> dispose() async {
    for (final controller in controllers) {
      if (!controller.isClosed) await controller.close();
    }
    await service.stopListenSingle("");
    await service.statusController.close();
    container.dispose();
  }
}

class _FakeAppDirectories extends AppDirectories {
  @override
  Future<Directories> build() async => (baseDir: Directory("."), workingDir: Directory("."), tempDir: Directory("."));
}

class _FakeDebugModeNotifier extends DebugModeNotifier {
  @override
  bool build() => false;
}

class _FailingSetupCoreInterface extends CoreInterface {
  @override
  Future<String> setup(Directories directories, bool debug, int mode) async => "core setup failed";
}
