 

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hiddify/bootstrap.dart';
import 'package:hiddify/core/model/environment.dart';
import 'package:hiddify/core/logger/logger.dart';
import 'package:hiddify/core/logger/logger_controller.dart';

void main() {
  try {
    LoggerController.preInit();
    Logger.bootstrap.info('Starting Hiddify app...');

    final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
    );

    Logger.bootstrap.debug('Calling lazyBootstrap...');
    lazyBootstrap(widgetsBinding, Environment.dev);
  } catch (e, stackTrace) {
    Logger.bootstrap.error('Error in main', e, stackTrace);
    rethrow;
  }
}
