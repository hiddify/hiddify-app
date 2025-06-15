import 'package:hiddify/features/settings/data/battery_optimization_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'battery_optimizations_notifier.g.dart';

@riverpod
class BatteryOptimizationNotifier extends _$BatteryOptimizationNotifier {
  @override
  Future<bool> build() async {
    return await BatteryOptimizationRepositoryImpl().isIgnoringBatteryOptimizations() ?? false;
  }

  Future<void> requestToIgnore() async {
    state = const AsyncLoading();
    await BatteryOptimizationRepositoryImpl().requestIgnoreBatteryOptimizations();
    Future.delayed(const Duration(seconds: 1));
    ref.invalidateSelf();
  }
}
