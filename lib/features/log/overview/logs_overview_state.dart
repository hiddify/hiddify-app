import 'package:hiddify/core/logger/ring/log_ring.dart';
import 'package:logging/logging.dart';

/// What the logs page is showing, and what it is filtered by.
///
/// A plain class rather than a freezed one: it holds five fields and no unions,
/// and the records now come straight from the in-memory ring, so there is no
/// loading or error case left to model.
class LogsOverviewState {
  const LogsOverviewState({
    this.logs = const [],
    this.paused = false,
    this.text = '',
    this.minLevel = Level.WARNING,
    this.category,
  });

  /// oldest first, already filtered
  final List<LogRecord> logs;

  /// while paused the list stops updating, but the ring keeps filling
  final bool paused;

  /// free text the message must contain
  final String text;

  /// Hides anything below this level.
  ///
  /// Not nullable: the filter is a floor, and trace is the lowest level
  /// anything is written at, so trace already means "everything". An "All"
  /// beside it would be the same option twice.
  ///
  /// Starts at warn: below that the page is mostly the app narrating itself,
  /// which buries the lines somebody opened this page to find.
  final Level minLevel;

  /// which group of loggers to show. Null means all of them.
  final LogCategory? category;

  LogsOverviewState copyWith({
    List<LogRecord>? logs,
    bool? paused,
    String? text,
    Level? minLevel,
    LogCategory? category,
    bool clearCategory = false,
  }) {
    return LogsOverviewState(
      logs: logs ?? this.logs,
      paused: paused ?? this.paused,
      text: text ?? this.text,
      minLevel: minLevel ?? this.minLevel,
      category: clearCategory ? null : (category ?? this.category),
    );
  }
}
