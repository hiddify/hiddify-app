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

  /// The engine's last crash, or null when it has not crashed.
  ///
  /// Go's runtime writes its fatal traceback to `CrashReport-.log`
  /// (`debug.SetCrashOutput`). On the next launch the engine moves that file
  /// into `crash_reports/<UTC timestamp>/go.log` and deletes the original, so
  /// crashes pile up as one folder each. The newest archived one is what is
  /// wanted; the live file only still exists when the app has not restarted
  /// since the crash.
  File? coreCrashFile() {
    final archive = Directory(p.join(directory.path, "crash_reports"));
    if (archive.existsSync()) {
      final reports = archive.listSync().whereType<Directory>().toList()
        ..sort((a, b) => a.path.compareTo(b.path));
      for (final report in reports.reversed) {
        final log = File(p.join(report.path, "go.log"));
        if (log.existsSync()) return log;
      }
    }

    final live = File(p.join(directory.path, "CrashReport-.log"));
    return live.existsSync() && live.lengthSync() > 0 ? live : null;
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
