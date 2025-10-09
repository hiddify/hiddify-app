import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/stats/data/stats_data_providers.dart';
import 'package:hiddify/features/stats/model/stats_entity.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hiddify/utils/riverpod_utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'stats_notifier.g.dart';

@riverpod
class StatsNotifier extends _$StatsNotifier with AppLogger {
  @override
  Stream<StatsEntity> build() async* {
    ref.disposeDelay(const Duration(seconds: 10));
    final serviceRunning = ref.watch(serviceRunningProvider).asData?.value ?? false;
    if (!serviceRunning) {
      yield* Stream.value(StatsEntity.empty());
      return;
    }
    yield* ref
        .watch(statsRepositoryProvider)
        .watchStats()
        .map((event) => event.getOrElse((_) => StatsEntity.empty()));
  }
}
