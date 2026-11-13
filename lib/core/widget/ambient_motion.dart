import 'package:flutter/foundation.dart';

/// Whether purely decorative, endless motion (the light around the connect button) may run.
///
/// Desktop windows without focus keep updating (connection state, proxies, logs), so TickerMode
/// stays on for them; only this decoration, the costliest thing the app draws, is paused.
final ValueNotifier<bool> ambientMotion = ValueNotifier(true);
