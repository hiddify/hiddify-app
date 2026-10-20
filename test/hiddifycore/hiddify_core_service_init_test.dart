import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/hiddifycore/hiddify_core_service.dart';
import 'package:hiddify/hiddifycore/init_signal.dart';
import 'package:hiddify/singbox/model/core_status.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:toastification/toastification.dart';

class _ControlledSetupService extends HiddifyCoreService {
  _ControlledSetupService(super.ref, this.result);

  final Either<String, Unit> result;

  @override
  TaskEither<String, Unit> setup() => TaskEither.fromEither(result);
}

class _Notifications extends InAppNotificationController {
  final errors = <String>[];

  @override
  ToastificationItem? showErrorToast(String message) {
    errors.add(message);
    return null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('strict init throws a closed typed exception and does not restart after setup failure', () async {
    const privateSetupFailure = 'private setup details must stay closed';
    final notifications = _Notifications();
    final container = ProviderContainer(
      overrides: [inAppNotificationControllerProvider.overrideWith((ref) => notifications)],
    );
    final service = container.read(Provider((ref) => _ControlledSetupService(ref, left(privateSetupFailure))));
    final restartValues = <int>[];
    final restartSubscription = container.listen(
      coreRestartSignalProvider,
      (_, value) => restartValues.add(value),
      fireImmediately: true,
    );
    addTearDown(() async {
      restartSubscription.close();
      container.dispose();
      await service.statusController.close();
      await service.logController.close();
    });

    Object? thrown;
    try {
      await service.init(requireSuccess: true);
    } catch (error) {
      thrown = error;
    }

    expect(thrown, isNotNull);
    expect(thrown, isA<HiddifyCoreInitializationException>());
    expect(thrown.toString(), 'HiddifyCoreInitializationException');
    expect(thrown.toString(), isNot(contains(privateSetupFailure)));
    expect(restartValues, [0]);
  });

  test('strict init emits the restart signal after successful setup', () async {
    final container = ProviderContainer();
    final service = container.read(Provider((ref) => _ControlledSetupService(ref, right(unit))));
    final restartValues = <int>[];
    final restartSubscription = container.listen(
      coreRestartSignalProvider,
      (_, value) => restartValues.add(value),
      fireImmediately: true,
    );
    addTearDown(() async {
      restartSubscription.close();
      container.dispose();
      await service.statusController.close();
      await service.logController.close();
    });

    await service.init(requireSuccess: true);

    expect(restartValues, [0, 1]);
  });

  test('default init swallows setup failure and preserves desktop side effects', () async {
    const setupFailure = 'default setup failure';
    final notifications = _Notifications();
    final container = ProviderContainer(
      overrides: [inAppNotificationControllerProvider.overrideWith((ref) => notifications)],
    );
    final service = container.read(Provider((ref) => _ControlledSetupService(ref, left(setupFailure))));
    final restartValues = <int>[];
    final restartSubscription = container.listen(
      coreRestartSignalProvider,
      (_, value) => restartValues.add(value),
      fireImmediately: true,
    );
    addTearDown(() async {
      restartSubscription.close();
      container.dispose();
      await service.statusController.close();
      await service.logController.close();
    });

    await service.init();

    expect(service.statusController.value, const CoreStatus.stopped());
    expect(notifications.errors, [setupFailure]);
    expect(restartValues, [0]);
  });
}
