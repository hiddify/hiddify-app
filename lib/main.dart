// Dev channel entrypoint. Twin file: lib/main_prod.dart, the prod channel one.
// The Makefile picks between the two through CHANNEL, so keep them in sync.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:hiddify/bootstrap.dart';
import 'package:hiddify/core/model/environment.dart';

Future<void> main() async {
  // Debug and profile builds that ask for it: lets an external client tap, type
  // and scroll the app. Profile too, because the iPhone build running on a Mac
  // only starts as a profile build. Behind a flag because the extension installs
  // a TestTextInput that takes over the text input channel — with it on, no field
  // in the app accepts a real keyboard. Run with --dart-define=driver=true to
  // drive it. Never in release.
  // Must come first: it installs the binding that ensureInitialized() reuses.
  if (!kReleaseMode && const bool.fromEnvironment('driver')) {
    enableFlutterDriverExtension();
  }

  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // final widgetsBinding = SentryWidgetsFlutterBinding.ensureInitialized();
  // debugPaintSizeEnabled = true;

  // The bars stay transparent (MainActivity turns on edge-to-edge); setting their colors
  // calls window APIs Android 15 deprecates and ignores.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  return await lazyBootstrap(widgetsBinding, Environment.dev);
}
