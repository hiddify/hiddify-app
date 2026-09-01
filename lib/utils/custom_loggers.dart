import 'package:logging/logging.dart';

// Re-exported so every class that mixes in a logger also gets the short level
// names — trace, debug, error, fatal. A Dart extension is only visible where it
// is imported, so without this line each of the ~200 call sites would need its
// own import.
export 'package:hiddify/core/logger/log_level_compat.dart';

/// Every logger name starts with the layer it came from, and nothing outside
/// this file is allowed to build a `Logger` directly. That is what keeps the
/// category filter on the logs page honest — a name can only be wrong if it is
/// created here.
///
/// Classes use a mixin. Static and top level code cannot, since a mixin needs
/// an instance, so it uses the matching factory instead.
///
/// The getter is called `loggy` because that is what the call sites already
/// say. Renaming it would touch every class that writes a log.

// ------------------------------------------------------------------- mixins

/// presentation layer — widgets and pages
///
/// Names its loggers `app`, same as [AppLogger]. The layers still differ in the
/// code, which is why both mixins exist, but on the logs page the distinction
/// was noise: a name like `HomePage` already says it is a widget.
mixin PresLogger {
  Logger get loggy => appLogger('$runtimeType');
}

/// application layer — notifiers and controllers
mixin AppLogger {
  Logger get loggy => appLogger('$runtimeType');
}

/// data layer — repositories, data sources, services
mixin InfraLogger {
  Logger get loggy => infraLogger('$runtimeType');
}

/// anything bridging the Go engine into Dart
mixin CoreLogger {
  Logger get loggy => coreLogger('$runtimeType');
}

// ----------------------------------------------------------------- factories

/// For static members and top level code, where there is no instance for a
/// mixin to take a name from. Pass the class or subsystem name.
Logger appLogger(String name) => Logger('app.$name');

/// `infra` keeps a prefix of its own, because "the network layer said this" is
/// worth seeing at a glance.
Logger infraLogger(String name) => Logger('infra.$name');

Logger coreLogger(String name) => Logger('core.$name');

/// Boot, before anything else exists. Read first when the app fails to start,
/// so it is worth keeping out of the other categories.
Logger bootLogger(String name) => Logger('boot.$name');
