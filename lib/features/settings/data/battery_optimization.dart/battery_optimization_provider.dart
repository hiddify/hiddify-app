import 'package:hiddify/features/settings/data/battery_optimization.dart/battery_optimization_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'battery_optimization_provider.g.dart';

@riverpod
BatteryOptimizationRepositoryImpl batteryOptimizationRepository(Ref ref) {
  return BatteryOptimizationRepositoryImpl();
}
