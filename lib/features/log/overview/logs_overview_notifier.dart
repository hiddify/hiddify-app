import 'dart:async';

import 'package:hiddify/core/logger/logger_setup.dart';
import 'package:hiddify/core/logger/ring/log_ring.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/features/log/overview/logs_overview_state.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'logs_overview_notifier.g.dart';

/// Reads the in-memory ring rather than the engine's gRPC stream.
///
/// The ring holds every category — core, app, boot — so the page shows the
/// whole picture instead of only what the engine said, and it has history the
/// moment it opens.
///
/// Nothing is pushed here. The ring bumps a revision counter as records
/// arrive and this polls it, so one log line never costs one rebuild.
@riverpod
class LogsOverviewNotifier extends _$LogsOverviewNotifier with AppLogger {
  Timer? _poll;
  int _drawn = -1;
  bool _visible = true;

  @override
  LogsOverviewState build() {
    ref.onDispose(() {
      _poll?.cancel();
      _poll = null;
    });
    _startPolling();

    // Deliberately not _view(): that reads `state`, which does not exist until
    // this method returns. A bare instance carries the same defaults, so the
    // first view is filtered the same way every later one is.
    _drawn = logRing.revision;
    const initial = LogsOverviewState();
    return initial.copyWith(
      logs: logRing.view(
        minLevel: initial.minLevel,
        category: initial.category,
      ),
    );
  }

  void _startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (!_visible || state.paused) return;
      if (logRing.revision == _drawn) return;
      state = state.copyWith(logs: _view());
    });
  }

  List<LogRecord> _view() {
    _drawn = logRing.revision;
    return logRing.view(
      minLevel: state.minLevel,
      category: state.category,
      text: state.text,
    );
  }

  /// Called from TickerMode, so a shell route that keeps this page mounted off
  /// screen stops paying for refreshes it cannot show.
  void setVisible(bool visible) {
    if (visible == _visible) return;
    _visible = visible;
    if (visible) state = state.copyWith(logs: _view());
  }

  void pause() {
    loggy.debug("pausing");
    state = state.copyWith(paused: true);
  }

  void resume() {
    loggy.debug("resuming");
    state = state.copyWith(paused: false, logs: _view());
  }

  /// Clears the history everything reads from, not only this view.
  void clear() {
    loggy.debug("clearing");
    logRing.clear();
    state = state.copyWith(logs: _view());
  }

  void filterText(String? text) {
    state = state.copyWith(text: text ?? '');
    state = state.copyWith(logs: _view());
  }

  void filterLevel(Level level) {
    state = state.copyWith(minLevel: level);
    state = state.copyWith(logs: _view());
  }

  void filterCategory(LogCategory? category) {
    state = category == null
        ? state.copyWith(clearCategory: true)
        : state.copyWith(category: category);
    state = state.copyWith(logs: _view());
  }

  /// How many records the ring keeps. Saved, so the size survives a restart —
  /// the ring itself is a plain object with no idea preferences exist, so the
  /// two are set together here.
  Future<void> setCapacity(int capacity) async {
    logRing.capacity = capacity;
    state = state.copyWith(logs: _view());
    await ref.read(Preferences.logBufferSize.notifier).update(capacity);
  }
}
