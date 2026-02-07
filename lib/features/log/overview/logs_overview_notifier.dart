import 'dart:async';

import 'package:hiddify/features/log/data/log_data_providers.dart';
import 'package:hiddify/features/log/model/log_entity.dart';
import 'package:hiddify/features/log/model/log_level.dart';
import 'package:hiddify/features/log/overview/logs_overview_state.dart';
import 'package:hiddify/hiddifycore/init_signal.dart';
import 'package:hiddify/utils/riverpod_utils.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart';

part 'logs_overview_notifier.g.dart';

@riverpod
class LogsOverviewNotifier extends _$LogsOverviewNotifier with AppLogger {
  @override
  LogsOverviewState build() {
    ref.disposeDelay(const Duration(seconds: 20));
    state = const LogsOverviewState();
    ref.onDispose(() {
      loggy.debug("disposing");
      _listener?.cancel();
      _listener = null;
    });
    ref.onCancel(() {
      if (_listener?.isPaused != true) {
        loggy.debug("pausing");
        _listener?.pause();
      }
    });
    ref.onResume(() {
      if (!state.paused && (_listener?.isPaused ?? false)) {
        loggy.debug("resuming");
        _listener?.resume();
      }
    });

    _addListeners();
    return const LogsOverviewState();
  }

  StreamSubscription? _listener;

  Future<void> _addListeners() async {
    loggy.debug("adding listeners");
    ref.watch(coreRestartSignalProvider);
    await _listener?.cancel();
    _listener = ref
        .read(logRepositoryProvider)
        .requireValue
        .watchLogs()
        .throttle((_) => Stream.value(_listener?.isPaused ?? false), leading: false, trailing: true)
        .throttleTime(const Duration(milliseconds: 250), leading: false, trailing: true)
        .asyncMap((event) async {
          await event.fold(
            (f) {
              _logs = [];
              state = state.copyWith(logs: AsyncError(f, StackTrace.current));
            },
            (a) async {
              _logs = a.reversed;
              state = state.copyWith(logs: AsyncData(await _computeLogs()));
            },
          );
        })
        .listen((event) {});
  }

  Iterable<LogEntity> _logs = [];
  final _debouncer = CallbackDebouncer(const Duration(milliseconds: 200));
  LogLevel? _levelFilter;
  String _filter = "";

  Future<List<LogEntity>> _computeLogs() async {
    if (_levelFilter == null && _filter.isEmpty) return _logs.toList();
    return _logs.where((e) {
      return (_filter.isEmpty || e.message.contains(_filter)) &&
          (_levelFilter == null || e.level == null || e.level!.index >= _levelFilter!.index);
    }).toList();
  }

  void pause() {
    loggy.debug("pausing");
    _listener?.pause();
    state = state.copyWith(paused: true);
  }

  void resume() {
    loggy.debug("resuming");
    _listener?.resume();
    state = state.copyWith(paused: false);
  }

  Future<void> clear() async {
    loggy.debug("clearing");
    await ref
        .read(logRepositoryProvider)
        .requireValue
        .clearLogs()
        .match(
          (l) {
            loggy.warning("error clearing logs", l);
          },
          (_) {
            _logs = [];
            state = state.copyWith(logs: const AsyncData([]));
          },
        )
        .run();
  }

  void filterMessage(String? filter) {
    _filter = filter ?? '';
    _debouncer(() async {
      if (state.logs case AsyncData()) {
        state = state.copyWith(filter: _filter, logs: AsyncData(await _computeLogs()));
      }
    });
  }

  Future<void> filterLevel(LogLevel? level) async {
    _levelFilter = level;
    if (state.logs case AsyncData()) {
      state = state.copyWith(levelFilter: _levelFilter, logs: AsyncData(await _computeLogs()));
    }
  }
}
