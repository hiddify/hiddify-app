import 'dart:io';

import 'package:hiddify/core/logger/custom_logger.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:loggy/loggy.dart';

class LoggerController extends LoggyPrinter with InfraLogger {
  LoggerController(
    this.consolePrinter,
    this.otherPrinters,
  );

  final LoggyPrinter consolePrinter;
  final Map<String, LoggyPrinter> otherPrinters;

  static LoggerController get instance => _instance;

  static late LoggerController _instance;

  static void preInit() {
    Loggy.initLoggy(logPrinter: const ConsolePrinter(showColors: true));
  }

  static void init(String appLogPath) {
    _instance = LoggerController(
      const ConsolePrinter(showColors: true),
      {"app": FileLogPrinter(appLogPath)},
    );
    Loggy.initLoggy(logPrinter: _instance);
  }

  static Future<void> postInit(bool debugMode) async {
    final logLevel = debugMode ? LogLevel.all : LogLevel.info;
    final logToFile = debugMode || (!Platform.isAndroid && !Platform.isIOS);

    if (!logToFile) {
      _instance.removePrinter("app");
    } else {
      final printer = _instance.otherPrinters["app"];
      if (printer case FileLogPrinter()) {
        // Use a sensible file min level: debug in debug mode, info otherwise
        printer.minLevel = debugMode ? LogLevel.debug : LogLevel.info;
      }
    }

    Loggy.initLoggy(
      logPrinter: _instance,
      logOptions: LogOptions(logLevel),
    );
  }

  void addPrinter(String name, LoggyPrinter printer) {
    loggy.debug("adding [$name] printer");
    otherPrinters.putIfAbsent(name, () => printer);
  }

  void removePrinter(String name) {
    loggy.debug("removing [$name] printer");
    final printer = otherPrinters[name];
    if (printer case FileLogPrinter()) {
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
