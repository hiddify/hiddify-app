import 'dart:io';

import 'package:path/path.dart' as p;

/// The app's own crashes, one file each in `app_crashes/` in the working directory, so the next
/// run can offer them in a report: the in-memory log of the run that crashed is gone by then.
///
/// The Android side writes its crashes here too (AppCrashRecorder.kt), with the same names:
/// `<UTC time to the millisecond>-<kind>.txt`, kind `dart`, `android`, `native` or `anr`.
const appCrashDirectory = 'app_crashes';

/// The newest files kept; older ones are deleted as new ones come.
const _keep = 10;

/// Errors recorded in one run at most: a broken widget can throw on every frame.
const _maxPerRun = 20;

Directory? _directory;
var _recorded = 0;
String? _last;
DateTime? _lastTime;

/// Called once the working directory is known; an error before that is in the log only.
void openAppCrashStore(String workingDir) {
  try {
    final directory = Directory(p.join(workingDir, appCrashDirectory))..createSync(recursive: true);
    _directory = directory;
  } catch (_) {
    _directory = null;
  }
}

/// Writes [text] at once, without waiting: the process may be about to end.
void recordAppCrash(String kind, String text) {
  final directory = _directory;
  if (directory == null || _recorded >= _maxPerRun || text == _last) return;
  _recorded++;
  _last = text;
  try {
    // to the millisecond, and never the same one twice, so names sort by when they were written
    var time = DateTime.now().toUtc();
    if (_lastTime case final last? when !time.isAfter(last)) time = last.add(const Duration(milliseconds: 1));
    var file = _file(directory, time, kind);
    while (file.existsSync()) {
      time = time.add(const Duration(milliseconds: 1));
      file = _file(directory, time, kind);
    }
    _lastTime = time;
    file.writeAsStringSync(text, flush: true);
    _prune(directory);
  } catch (_) {
    // recording a crash must never be what crashes
  }
}

File _file(Directory directory, DateTime time, String kind) {
  final stamp = time.toIso8601String().substring(0, 23).replaceAll(':', '-').replaceAll('.', '-');
  return File(p.join(directory.path, '$stamp-$kind.txt'));
}

void _prune(Directory directory) {
  final files = directory.listSync().whereType<File>().toList()..sort((a, b) => a.path.compareTo(b.path));
  for (final file in files.take(files.length - _keep < 0 ? 0 : files.length - _keep)) {
    file.deleteSync();
  }
}
