import 'dart:io';

abstract class PlatformUtils {
  static bool get isDesktop =>
      Platform.isLinux || Platform.isWindows || Platform.isMacOS;
}
