import 'dart:io';

import 'package:flutter/foundation.dart';

abstract class PlatformUtils {
  static bool get isDesktop => !kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS);
}
