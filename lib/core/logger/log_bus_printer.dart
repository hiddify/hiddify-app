import 'package:hiddify/core/logger/log_bus.dart';
import 'package:loggy/loggy.dart';

class LogBusPrinter extends LoggyPrinter {
  LogBusPrinter({LogBus? bus}) : _bus = bus ?? LogBus.instance;

  final LogBus _bus;

  static final RegExp _tagPrefix = RegExp(r'^\[([^\]]+)\]\s*([^\r\n]*)');

  static const Set<String> _processTags = <String>{'hysteria', 'tun2socks'};

  @override
  void onLog(LogRecord record) {
    final timestamp = record.time;

    var message = record.message;
    if (record.error != null) {
      message = '$message | ${record.error}';
    }
    if (record.stackTrace != null) {
      message = '$message\n${record.stackTrace}';
    }

    var kind = LogKind.app;
    var source = record.loggerName;

    if (source == 'bootstrap') {
      kind = LogKind.system;
    }

    final tagMatch = _tagPrefix.firstMatch(message);
    if (tagMatch != null) {
      final tag = (tagMatch.group(1) ?? '').trim();
      final rest = (tagMatch.group(2) ?? '').trimRight();
      final tagLower = tag.toLowerCase();

      if (_processTags.contains(tagLower)) {
        kind = LogKind.process;
        source = tagLower;
        message = rest;
      }
    }

    final severity = switch (record.level) {
      LogLevel.debug => LogSeverity.debug,
      LogLevel.info => LogSeverity.info,
      LogLevel.warning => LogSeverity.warning,
      LogLevel.error => LogSeverity.error,
      _ => LogSeverity.info,
    };

    _bus.add(
      LogEvent(
        timestamp: timestamp,
        severity: severity,
        kind: kind,
        source: source,
        message: message,
      ),
    );
  }
}
