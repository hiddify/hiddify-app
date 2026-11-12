import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

/// The native splash, the Hiddify logo on the app's background, from the tap until the app shows its first
/// screen. Removed once: removing it twice fails an assertion.
abstract final class NativeSplash {
  static bool _removed = false;

  /// Holds Flutter's first frame, so the native splash stays.
  static void preserve(WidgetsBinding binding) {
    if (kIsWeb) return;
    FlutterNativeSplash.preserve(widgetsBinding: binding);
  }

  /// Lets Flutter's frames through: the splash goes.
  static void remove() {
    if (kIsWeb || _removed) return;
    _removed = true;
    FlutterNativeSplash.remove();
  }
}
