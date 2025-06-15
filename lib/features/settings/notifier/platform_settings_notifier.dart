import 'package:hiddify/features/settings/data/battery_optimization.dart/battery_optimization_provider.dart';
import 'package:hiddify/hiddifycore/hiddify_core_service_provider.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'platform_settings_notifier.g.dart';

@riverpod
class IgnoreBatteryOptimizations extends _$IgnoreBatteryOptimizations {
  @override
  Future<bool> build() async {
    return await ref.read(batteryOptimizationRepositoryProvider).isIgnoringBatteryOptimizations() ?? false;
  }

  Future<void> request() async {
    state = const AsyncLoading();
    await ref.read(batteryOptimizationRepositoryProvider).requestIgnoreBatteryOptimizations();
    Future.delayed(const Duration(seconds: 1));
    ref.invalidateSelf();
  }
}

@riverpod
class ResetTunnel extends _$ResetTunnel with AppLogger {
  @override
  Future<void> build() async {}

  Future<void> run() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(hiddifyCoreServiceProvider).resetTunnel().getOrElse(
        (err) {
          loggy.warning("error resetting tunnel", err);
          throw err;
        },
      ).run(),
    );
  }
}
