// Prod channel entrypoint. Twin file: lib/main.dart, the dev channel one.
// The Makefile picks between the two through CHANNEL, so keep them in sync.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:hiddify/bootstrap.dart';
import 'package:hiddify/core/model/environment.dart';

Future<void> main() async {
  // Behind --dart-define=driver=true — see the note in lib/main.dart.
  if (!kReleaseMode && const bool.fromEnvironment('driver')) {
    enableFlutterDriverExtension();
  }

  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // The bars stay transparent (MainActivity turns on edge-to-edge); setting their colors
  // calls window APIs Android 15 deprecates and ignores.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  return await lazyBootstrap(widgetsBinding, Environment.prod);
}
