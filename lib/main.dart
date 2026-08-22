// Dev channel entrypoint. Twin file: lib/main_prod.dart, the prod channel one.
// The Makefile picks between the two through CHANNEL, so keep them in sync.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:hiddify/bootstrap.dart';
import 'package:hiddify/core/model/environment.dart';

Future<void> main() async {
  // Debug builds only: lets an external client tap, type and scroll the app.
  // kDebugMode is a compile-time const, so release builds drop this branch.
  // Must come first — it installs the binding ensureInitialized() then reuses.
  if (kDebugMode) enableFlutterDriverExtension();

  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // final widgetsBinding = SentryWidgetsFlutterBinding.ensureInitialized();
  // debugPaintSizeEnabled = true;

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent, systemNavigationBarColor: Colors.transparent),
  );

  return await lazyBootstrap(widgetsBinding, Environment.dev);
}
