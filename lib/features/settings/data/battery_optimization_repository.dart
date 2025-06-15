import 'package:flutter/services.dart';
import 'package:hiddify/core/utils/exception_handler.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:loggy/loggy.dart';

abstract interface class BatteryOptimizationRepository {
  Future<bool?> isIgnoringBatteryOptimizations();
  Future<bool?> requestIgnoreBatteryOptimizations();
}

class BatteryOptimizationRepositoryImpl with ExceptionHandler, InfraLogger implements BatteryOptimizationRepository {
  final _methodChannel = const MethodChannel("com.hiddify.app/platform");

  @override
  Future<bool?> isIgnoringBatteryOptimizations() async {
    bool? result;
    try {
      loggy.debug("checking battery optimization status");
      result = await _methodChannel.invokeMethod<bool>("is_ignoring_battery_optimizations");
      loggy.debug("is ignoring battery optimizations? [$result]");
    } catch (e) {
      loggy.log(LogLevel.error, e.toString());
    }
    return result;
  }

  @override
  Future<bool?> requestIgnoreBatteryOptimizations() async {
    bool? result;
    try {
      loggy.debug("requesting ignore battery optimization");
      result = await _methodChannel.invokeMethod<bool>("request_ignore_battery_optimizations");
      loggy.debug("ignore battery optimization result: [$result]");
    } catch (e) {
      loggy.log(LogLevel.error, e.toString());
    }
    return result;
  }
}
