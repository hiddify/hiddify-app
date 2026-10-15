import 'package:loggy/loggy.dart';

const _safeLoggerName = 'safe_diagnostics';

/// Rebuilds a record without reading or serializing any caller-controlled field.
LogRecord safeLogRecord(LogRecord record) {
  final (level, code) = switch (record.level) {
    LogLevel.debug => (LogLevel.debug, 'safe_diagnostic.log.debug'),
    LogLevel.info => (LogLevel.info, 'safe_diagnostic.log.info'),
    LogLevel.warning => (LogLevel.warning, 'safe_diagnostic.log.warning'),
    LogLevel.error => (LogLevel.error, 'safe_diagnostic.log.error'),
    _ => (LogLevel.info, 'safe_diagnostic.log.info'),
  };

  return LogRecord(level, code, _safeLoggerName);
}

/// A sink boundary that guarantees its delegate never receives the raw record.
class SafeLoggyPrinter extends LoggyPrinter {
  const SafeLoggyPrinter(this.delegate);

  final LoggyPrinter delegate;

  @override
  void onLog(LogRecord record) => delegate.onLog(safeLogRecord(record));
}
