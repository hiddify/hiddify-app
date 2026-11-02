import 'package:flutter/foundation.dart';

warn(bool condition, String message) {
  if (condition) return;
  debugPrint('${_bg(229)}${_fg(0)}[flutter_animate] $message$_reset');
}

// generate the control codes to set console colors:
String _bg(int color) => '\x1B[48;5;${color}m';
String _fg(int color) => '\x1B[38;5;${color}m';
String _reset = '\x1B[0m';

/*
printColorTest() {
    String str = '';
    for (int i=0; i<256; i++) {
      str += '\x1B[48;5;${i}m$i ';
    }
    debugPrint(str);
}
*/
