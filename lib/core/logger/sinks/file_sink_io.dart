import 'dart:io';

String? _path;

bool get isLogFileOpen => _path != null;

/// A file past this size is cut to its newest [_keepSize] bytes when it opens.
const _maxSize = 1024 * 1024;
const _keepSize = 256 * 1024;

/// Opens by creating the file and proving it is writable, so a bad path is
/// known now rather than silently swallowed at the first error worth recording.
///
/// It spans runs, so it is cut back to its newest part at the start of one
/// once it grows past [_maxSize]: on a phone too, where it is kept for the
/// run a crash ended.
void openLogFile(String path) {
  try {
    final file = File(path);
    file.parent.createSync(recursive: true);
    if (file.existsSync() && file.lengthSync() > _maxSize) {
      final bytes = file.readAsBytesSync();
      file.writeAsBytesSync(bytes.sublist(bytes.length - _keepSize));
    }
    file.writeAsStringSync('', mode: FileMode.append);
    _path = path;
  } catch (_) {
    _path = null;
  }
}

/// Written straight through, no batching.
///
/// Only errors reach this file, and they are rare, so a syscall each is cheap
/// and nothing can be sitting in memory when the crash that follows takes the
/// app down.
void writeLogLine(String line) {
  final path = _path;
  if (path == null) return;

  try {
    File(path).writeAsStringSync('$line\n', mode: FileMode.append);
  } catch (_) {
    // A log file that cannot be written must never take the app down.
  }
}

Future<void> closeLogFile() async {
  _path = null;
}

/// Writes [lines] to [path] in one go, replacing whatever was there. Used by
/// the logs page to export the in-memory history, which is a different file.
Future<void> writeLinesToFile(String path, Iterable<String> lines) async {
  await File(path).writeAsString(lines.join('\n'));
}
