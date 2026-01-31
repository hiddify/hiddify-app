import 'package:hiddify/core/logger/log_bus.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final logBusProvider = Provider<LogBus>((ref) => LogBus.instance);

final logBusStreamProvider = StreamProvider<List<LogEvent>>((ref) async* {
  final bus = ref.watch(logBusProvider);
  yield bus.currentBuffer;
  yield* bus.stream;
});
