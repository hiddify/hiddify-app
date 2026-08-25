import 'dart:io';

IOSink? _sink;

void openLogFile(String path) {
  _sink = File(path).openWrite();
}

void writeLogLine(String line) => _sink?.writeln(line);

bool get isLogFileOpen => _sink != null;

Future<void> closeLogFile() async {
  final sink = _sink;
  _sink = null;
  await sink?.flush();
  await sink?.close();
}

Future<void> flushLogFile() async => _sink?.flush();

/// Writes [lines] to [path] in one go, replacing whatever was there.
///
/// Used to hand the in-memory history to the share sheet on platforms that
/// keep no log file of their own.
Future<void> writeLinesToFile(String path, Iterable<String> lines) =>
    File(path).writeAsString(lines.join('\n'));
