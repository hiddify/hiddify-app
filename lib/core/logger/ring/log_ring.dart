import 'dart:collection';

import 'package:logging/logging.dart';

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

  /// newest first, which is how the page shows them
  ///
  /// [category] is a logger name prefix — 'core', 'ui', 'app', 'infra'.
  /// Both filters only hide rows; nothing is removed from the ring.
  /// [limit] keeps only the newest N matches, so drawing 8 rows never
  /// allocates a list of the whole buffer.
  List<LogRecord> view({
    Level? minLevel,
    String? category,
    String? text,
    int? limit,
  }) {
    final out = <LogRecord>[];
    for (final r in _records) {
      if (minLevel != null && r.level < minLevel) continue;
      if (category != null && !r.loggerName.startsWith('$category.')) continue;
      if (text != null && text.isNotEmpty && !r.message.contains(text)) continue;
      out.add(r);
      if (limit != null && out.length > limit) out.removeAt(0);
    }
    return out.reversed.toList(growable: false);
  }

  int _countsRevision = -1;
  Map<String, int> _counts = const {};

  /// how many records each category holds right now — recomputed only when
  /// the ring actually changed, not on every rebuild
  Map<String, int> countByCategory() {
    if (_countsRevision == revision) return _counts;
    final counts = <String, int>{};
    for (final r in _records) {
      final dot = r.loggerName.indexOf('.');
      final key = dot == -1 ? r.loggerName : r.loggerName.substring(0, dot);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    _counts = counts;
    _countsRevision = revision;
    return counts;
  }
}
