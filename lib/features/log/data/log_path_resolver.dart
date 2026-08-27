import 'dart:io';

import 'package:path/path.dart' as p;

class LogPathResolver {
  const LogPathResolver(this._workingDir);

  final Directory _workingDir;

  Directory get directory => _workingDir;

  /// The engine's own log. It writes into `data/`, not the working directory
  /// root — the root box.log the app used to point at was always empty.
  File coreFile() {
    return File(p.join(directory.path, "data", "box.log"));
  }

  /// A dump of every goroutine, written by the engine. Not a log — a snapshot
  /// of what its threads were doing, which is what a hang needs.
  File coreHangFile() {
    return File(p.join(directory.path, "data", "goroutine-start.log"));
  }

  File appFile() {
    return File(p.join(directory.path, "app.log"));
  }

  /// Where the in-memory history is written when the user shares it. A
  /// separate name, so it never collides with the app.log the sink is still
  /// writing to on desktop.
  File appExportFile() {
    return File(p.join(directory.path, "app-logs.txt"));
  }
}
