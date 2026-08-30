import 'dart:collection';

import 'package:logging/logging.dart';

/// The groups the page filters by.
///
/// A group is not the same as a layer. Widgets and notifiers both write `app.`
/// because telling them apart on screen never helped — the class name already
/// does. `infra` keeps its own prefix, since "the network layer said this" is
/// worth seeing, but it answers the same question as `app`: was this the app or
/// the engine?
enum LogCategory {
  boot,
  app,
  core;

  bool matches(String loggerName) => switch (this) {
    LogCategory.boot => loggerName.startsWith('boot.'),
    LogCategory.core => loggerName.startsWith('core.'),
    // Everything the other two do not claim, which includes loggers from
    // packages that never heard of our naming — neat_periodic_task and the
    // like. They are still the app talking, so they belong somewhere rather
    // than nowhere.
    LogCategory.app =>
      !loggerName.startsWith('boot.') && !loggerName.startsWith('core.'),
  };
}

/// The in-memory history the logs page reads from.
///
/// Stores the records themselves, never formatted strings — formatting 5000
/// lines on every burst is exactly the cost we are trying to remove. Rows are
/// formatted only when they are drawn.
///
/// It deliberately publishes no stream. One event per record is what made the
/// old core buffer expensive. Instead it bumps [revision], and the page checks
/// that on a timer.
class LogRing {
  LogRing(this._capacity);

  int _capacity;
  final ListQueue<LogRecord> _records = ListQueue<LogRecord>();

  /// bumped on every change — the page compares it against what it last drew
  int revision = 0;

  int get capacity => _capacity;

  set capacity(int value) {
    _capacity = value;
    _trim();
    revision++;
  }

  int get length => _records.length;

  /// oldest first
  Iterable<LogRecord> get records => _records;

  void add(LogRecord record) {
    _records.addLast(record);
    _trim();
    revision++;
  }

  void clear() {
    _records.clear();
    revision++;
  }

  void _trim() {
    while (_records.length > _capacity) {
      _records.removeFirst();
    }
  }

  /// Oldest first, which is how a log reads — on the page, in the clipboard
  /// and in a file.
  ///
  /// Every filter only hides rows; nothing is removed from the ring.
  List<LogRecord> view({
    Level? minLevel,
    LogCategory? category,
    String? text,
  }) {
    final out = <LogRecord>[];
    for (final r in _records) {
      if (minLevel != null && r.level < minLevel) continue;
      if (category != null && !category.matches(r.loggerName)) continue;
      if (text != null && text.isNotEmpty && !r.message.contains(text)) continue;
      out.add(r);
    }
    return out;
  }
}
