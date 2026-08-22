// Prod channel entrypoint. Twin file: lib/main.dart, the dev channel one.
// The Makefile picks between the two through CHANNEL, so keep them in sync.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:hiddify/bootstrap.dart';
import 'package:hiddify/core/model/environment.dart';

Future<void> main() async {
  // Debug builds only — see the note in lib/main.dart.
  if (kDebugMode) enableFlutterDriverExtension();

  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent, systemNavigationBarColor: Colors.transparent),
  );

  return await lazyBootstrap(widgetsBinding, Environment.prod);
}
