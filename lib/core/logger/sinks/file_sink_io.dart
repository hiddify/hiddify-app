import 'dart:io';

/// The file is kept across runs, so a crash from the previous launch is still
/// there to read. That means it has to be bounded: once it passes [maxBytes],
/// the older half is dropped and the newer half is kept.
const maxBytes = 5 * 1024 * 1024;

/// checked every so often rather than on every line, since a stat call per
/// record would cost more than the write itself
const _checkEvery = 500;

String? _path;
IOSink? _sink;
int _sinceCheck = 0;

bool get isLogFileOpen => _sink != null;

void openLogFile(String path) {
  _path = path;
  _sink = File(path).openWrite(mode: FileMode.append);
}

void writeLogLine(String line) {
  _sink?.writeln(line);

  if (++_sinceCheck < _checkEvery) return;
  _sinceCheck = 0;
  _trimIfTooBig();
}

/// Keeps the newest half and throws away the rest.
///
/// Starting the file fresh would lose exactly what is most wanted after a
/// crash — what led up to it — so the recent half survives instead.
void _trimIfTooBig() {
  final path = _path;
  if (path == null) return;

  try {
    final file = File(path);
    if (!file.existsSync() || file.lengthSync() <= maxBytes) return;

    final lines = file.readAsLinesSync();
    final keep = lines.sublist(lines.length ~/ 2);

    _sink?.close();
    file.writeAsStringSync(
      '${keep.join('\n')}\n',
      flush: true,
    );
    _sink = file.openWrite(mode: FileMode.append);
  } catch (_) {
    // A log file that cannot be trimmed must never take the app down.
  }
}

Future<void> closeLogFile() async {
  final sink = _sink;
  _sink = null;
  _path = null;
  await sink?.flush();
  await sink?.close();
}

Future<void> flushLogFile() async => _sink?.flush();

/// Writes [lines] to [path] in one go, replacing whatever was there.
///
/// Used to hand the in-memory history to the share sheet, and on platforms
/// that keep no log file of their own it is the only way to share at all.
Future<void> writeLinesToFile(String path, Iterable<String> lines) =>
    File(path).writeAsString(lines.join('\n'));
