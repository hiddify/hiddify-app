import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hiddify/core/logger/custom_logger.dart';
import 'package:hiddify/core/logger/log_bus_printer.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:loggy/loggy.dart';

class LoggerController extends LoggyPrinter with InfraLogger {
  LoggerController(this.consolePrinter, this.otherPrinters) {
    if (kDebugMode || Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      _streamPrinter = StreamLogPrinter();
      otherPrinters['stream'] = _streamPrinter!;
    }
  }

  final LoggyPrinter consolePrinter;
  final Map<String, LoggyPrinter> otherPrinters;
  StreamLogPrinter? _streamPrinter;

  Stream<List<String>> get logStream => 
      _streamPrinter?.logStream ?? Stream.value([]);

  List<String> get currentLogs => _streamPrinter?.currentBuffer ?? [];

  void clearBuffer() {
    _streamPrinter?.clearBuffer();
  }

  static LoggerController get instance => _instance;

  static late LoggerController _instance;

  static void preInit() {
    Loggy.initLoggy(logPrinter: const ConsolePrinter());
  }

  static void init(String appLogPath) {
    _instance = LoggerController(const ConsolePrinter(), {
      'app': FileLogPrinter(appLogPath),
      'bus': LogBusPrinter(),
    });
    Loggy.initLoggy(logPrinter: _instance);
  }

  static Future<void> postInit({required bool debugMode}) async {
    final logLevel = debugMode ? LogLevel.all : LogLevel.info;
    final logToFile = debugMode || (!Platform.isAndroid && !Platform.isIOS);

    if (!logToFile) _instance.removePrinter('app');

    Loggy.initLoggy(logPrinter: _instance, logOptions: LogOptions(logLevel));
  }

  void addPrinter(String name, LoggyPrinter printer) {
    loggy.debug('adding [$name] printer');
    otherPrinters.putIfAbsent(name, () => printer);
  }

  void removePrinter(String name) {
    loggy.debug('removing [$name] printer');
    final printer = otherPrinters[name];
    if (printer is FileLogPrinter) {
      printer.dispose();
    } else if (printer is StreamLogPrinter) {
      printer.dispose();
    }
    otherPrinters.remove(name);
  }

  @override
  void onLog(LogRecord record) {
    consolePrinter.onLog(record);
    for (final printer in otherPrinters.values) {
      printer.onLog(record);
    }
  }
}
