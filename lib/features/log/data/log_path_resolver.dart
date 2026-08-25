import 'dart:io';

import 'package:path/path.dart' as p;

class LogPathResolver {
  const LogPathResolver(this._workingDir);

  final Directory _workingDir;

  Directory get directory => _workingDir;

  File coreFile() {
    return File(p.join(directory.path, "box.log"));
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
