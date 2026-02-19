import 'dart:io';

import 'package:flutter/foundation.dart';

abstract class PlatformUtils {
  static bool get isWindows => !kIsWeb && (Platform.isWindows);

  static bool get isDesktop => !kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS);

  static bool get isInAppStore => !kIsWeb && (Platform.isIOS);

  static bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static bool get isWeb => kIsWeb;

  static bool get isLinux => !kIsWeb && Platform.isLinux;

  static bool get isMacOS => !kIsWeb && Platform.isMacOS;

  static bool get isIOS => !kIsWeb && Platform.isIOS;

  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
}
